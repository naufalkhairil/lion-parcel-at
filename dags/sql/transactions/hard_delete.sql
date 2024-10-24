MERGE `{{ params.target_table }}` _target
USING (
    SELECT * FROM `{{ params.source_table }}{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}`
    QUALIFY ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY deleted_at DESC) = 1
) _source
ON _target.created_at
    BETWEEN TIMESTAMP_SUB('{{ task_instance.xcom_pull(task_ids="date_eval", key="start_date") }}', INTERVAL 7 DAY)
    AND '{{ task_instance.xcom_pull(task_ids="date_eval", key="end_date") }}'
AND _target.customer_id=_source.customer_id
WHEN MATCHED
THEN DELETE