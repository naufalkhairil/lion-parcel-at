from pendulum import timezone
from datetime import datetime, timedelta

from airflow.models import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.transfers.postgres_to_gcs import PostgresToGCSOperator
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.utils.task_group import TaskGroup
from airflow.providers.google.cloud.operators.bigquery import BigQueryExecuteQueryOperator, BigQueryDeleteTableOperator, BigQueryCreateEmptyTableOperator
from airflow.providers.google.cloud.operators.gcs import GCSDeleteObjectsOperator

from schema.transactions import schema as transactions_schema


def date_eval(**kwargs):
    kwargs['task_instance'].xcom_push(
        key="start_date",
        value=[
            kwargs['dag_run'].conf.get("start_date", "") if "start_date" in kwargs['dag_run'].conf
            else (kwargs['logical_date'] + timedelta(hours=7)).strftime("%Y-%m-%d %H:00:00")
        ][0]
    )
    
    kwargs['task_instance'].xcom_push(
        key="end_date",
        value=[
            kwargs['dag_run'].conf.get("end_date", "") if "end_date" in kwargs['dag_run'].conf
            else (kwargs['logical_date'] + timedelta(hours=8)).strftime("%Y-%m-%d %H:00:00")
        ][0]
    )

    kwargs['task_instance'].xcom_push(
        key='ymd',
        value=[
            kwargs['dag_run'].conf.get("start_date", "").replace("-", "") + "_" + 
            kwargs['dag_run'].conf.get("end_date","").replace("-", "")
            if kwargs['dag_run'].conf.get("start_date", "")
            else (kwargs['logical_date']).strftime("%Y%m%d")
        ][0]
    )

    kwargs['task_instance'].xcom_push(
        key='ymdh',
        value=[
            kwargs['dag_run'].conf.get("start_date", "").replace("-", "") + "_" + 
            kwargs['dag_run'].conf.get("end_date","").replace("-", "")
            if kwargs['dag_run'].conf.get("start_date", "")
            else (kwargs['logical_date']).strftime("%Y%m%d%H")
        ][0]
    )

start_date = datetime(2024, 10, 23, tzinfo=timezone('Asia/Jakarta'))
end_date = None
catchup=True
schedule='0 * * * *'
# schedule=None

PARENT_DAG_NAME = 'extract_transactions_hard_delete'
gcs_bucket = "bbg-datatemp-dev"
gcs_filename = "playground/{ymd}/transactions-hd-{ymdh}.json"
gcs_filename_arcv = "playground/{ymd}/transactions-hd-arcv-{ymdh}.json"
dest_table = "data-dev-270120.playground.transactions_hd"
dest_table_arcv = "data-dev-270120.playground.transactions_hd_arcv"
temp_table = dest_table + "_{ymdh}"
temp_table_arcv = dest_table_arcv + "_{ymdh}"

default_args = {
    'owner': 'Naufal',
    'retries': 1,
    'retry_delay': timedelta(minutes=5)
}

dag = DAG(
    dag_id=PARENT_DAG_NAME,
    default_args=default_args,
    schedule=schedule,
    catchup=catchup,
    start_date=start_date,
    end_date=end_date,
    max_active_runs=3,
    tags=['extract', 'transactions']
)

task_init_table = BigQueryCreateEmptyTableOperator(
    task_id="init_table",
    dataset_id=dest_table.split(".")[1],
    table_id=dest_table.split(".")[2],
    schema_fields=transactions_schema.table_hd_schema,
    time_partitioning=transactions_schema.partition_field,
    cluster_fields=transactions_schema.cluster_fields,
    gcp_conn_id="google_cloud_default",
    dag=dag
)

task_date_eval = PythonOperator(
    task_id='date_eval',
    python_callable=date_eval,
    dag=dag
)

with TaskGroup(dag=dag, group_id='extract_temp', prefix_group_id=False) as task_extract_temp:

    task_extract_to_gcs = PostgresToGCSOperator(
        task_id="extract_to_gcs",
        sql="sql/transactions/extract.sql",
        params=dict(
            source_table="public.retail_transactions"
        ),
        bucket=gcs_bucket,
        filename=gcs_filename.format(
            ymd='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymd") }}',
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        ),
        postgres_conn_id="example_db",
        gcp_conn_id="google_cloud_default",
        dag=dag
    )

    task_load_to_temp = GCSToBigQueryOperator(
        task_id="load_to_temp",
        bucket=gcs_bucket,
        source_objects=[gcs_filename.format(
            ymd='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymd") }}',
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        )],
        destination_project_dataset_table=temp_table.format(
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        ),
        schema_fields=transactions_schema.table_schema,
        source_format="NEWLINE_DELIMITED_JSON",
        create_disposition="CREATE_IF_NEEDED",
        write_disposition="WRITE_TRUNCATE",
        gcp_conn_id="google_cloud_default",
        ignore_unknown_values=True, allow_quoted_newlines=True,
        dag=dag
    )

    task_extract_to_gcs_arcv = PostgresToGCSOperator(
        task_id="extract_to_gcs_arcv",
        sql="sql/transactions/extract_archive.sql",
        params=dict(
            source_table="public.retail_transactions_archive"
        ),
        bucket=gcs_bucket,
        filename=gcs_filename_arcv.format(
            ymd='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymd") }}',
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        ),
        postgres_conn_id="example_db",
        gcp_conn_id="google_cloud_default",
        dag=dag
    )

    task_load_to_temp_arcv = GCSToBigQueryOperator(
        task_id="load_to_temp_arcv",
        bucket=gcs_bucket,
        source_objects=[gcs_filename_arcv.format(
            ymd='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymd") }}',
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        )],
        destination_project_dataset_table=temp_table_arcv.format(
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        ),
        schema_fields=transactions_schema.table_schema_arcv,
        source_format="NEWLINE_DELIMITED_JSON",
        create_disposition="CREATE_IF_NEEDED",
        write_disposition="WRITE_TRUNCATE",
        gcp_conn_id="google_cloud_default",
        ignore_unknown_values=True, allow_quoted_newlines=True,
        dag=dag
    )

    task_extract_to_gcs >> task_load_to_temp
    task_extract_to_gcs_arcv >> task_load_to_temp_arcv


with TaskGroup(dag=dag, group_id='hard_delete_table', prefix_group_id=False) as task_hard_delete_table:

    task_update_table_hd = BigQueryExecuteQueryOperator(
        task_id="update_table_hd",
        sql="sql/transactions/update_table_hd.sql",
        params=dict(
            target_table = dest_table,
            source_table = temp_table.format(ymdh="")
        ),
        use_legacy_sql=False,
        gcp_conn_id="google_cloud_default",
        dag=dag
    )

    task_hard_delete = BigQueryExecuteQueryOperator(
        task_id="hard_delete",
        sql="sql/transactions/hard_delete.sql",
        params=dict(
            target_table = dest_table,
            source_table = temp_table_arcv.format(ymdh="")
        ),
        use_legacy_sql=False,
        gcp_conn_id="google_cloud_default",
        dag=dag
    )

    task_update_table_hd >> task_hard_delete

with TaskGroup(dag=dag, group_id='clean_temp', prefix_group_id=False) as task_clean_temp:

    task_delete_temp_table = BigQueryDeleteTableOperator(
        task_id="delete_temp_table",
        deletion_dataset_table=temp_table.format(ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'),
        gcp_conn_id="google_cloud_default",
        ignore_if_missing=True,
        dag=dag
    )

    task_delete_temp_file = GCSDeleteObjectsOperator(
        task_id="delete_temp_file",
        bucket_name=gcs_bucket,
        objects=[gcs_filename.format(
            ymd='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymd") }}',
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        )],
        gcp_conn_id="google_cloud_default",
        dag=dag
    )

    task_delete_temp_table_arcv = BigQueryDeleteTableOperator(
        task_id="delete_temp_table_arcv",
        deletion_dataset_table=temp_table_arcv.format(ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'),
        gcp_conn_id="google_cloud_default",
        ignore_if_missing=True,
        dag=dag
    )

    task_delete_temp_file_arcv = GCSDeleteObjectsOperator(
        task_id="delete_temp_file_arcv",
        bucket_name=gcs_bucket,
        objects=[gcs_filename_arcv.format(
            ymd='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymd") }}',
            ymdh='{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}'
        )],
        gcp_conn_id="google_cloud_default",
        dag=dag
    )

task_init_table >> task_date_eval >> task_extract_to_gcs >> task_load_to_temp >> task_hard_delete_table >> task_clean_temp
