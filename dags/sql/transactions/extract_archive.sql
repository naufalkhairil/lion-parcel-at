SELECT customer_id, deleted_at
FROM {{ params.source_table }}
WHERE deleted_at 
BETWEEN '{{ task_instance.xcom_pull(task_ids="date_eval", key="start_date") }}'
AND '{{ task_instance.xcom_pull(task_ids="date_eval", key="end_date") }}'