SELECT id, customer_id, last_status, pos_origin, pos_destination, created_at, updated_at, deleted_at
FROM {{ params.source_table }}
WHERE updated_at 
BETWEEN '{{ task_instance.xcom_pull(task_ids="date_eval", key="start_date") }}'
AND '{{ task_instance.xcom_pull(task_ids="date_eval", key="end_date") }}'