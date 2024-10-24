DELETE FROM `{{ params.target_table }}`
WHERE created_at
    BETWEEN TIMESTAMP_SUB('{{ task_instance.xcom_pull(task_ids="date_eval", key="start_date") }}', INTERVAL 7 DAY)
    AND '{{ task_instance.xcom_pull(task_ids="date_eval", key="end_date") }}'
AND last_status = "DONE"