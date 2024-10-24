MERGE `{{ params.target_table }}` _target
USING (
    SELECT * EXCEPT(deleted_at) FROM `{{ params.source_table }}{{ task_instance.xcom_pull(task_ids="date_eval", key="ymdh") }}`
    QUALIFY ROW_NUMBER() OVER(PARTITION BY id ORDER BY updated_at DESC) = 1
) _source
ON _target.created_at
    BETWEEN TIMESTAMP_SUB('{{ task_instance.xcom_pull(task_ids="date_eval", key="start_date") }}', INTERVAL 7 DAY)
    AND '{{ task_instance.xcom_pull(task_ids="date_eval", key="end_date") }}'
AND _target.id=_source.id
WHEN NOT MATCHED BY TARGET THEN INSERT ROW
WHEN MATCHED AND _target.updated_at < _source.updated_at
THEN UPDATE SET
    _target.id=_source.id,
    _target.customer_id=_source.customer_id,
    _target.last_status=_source.last_status,
    _target.pos_origin=_source.pos_origin,
    _target.pos_destination=_source.pos_destination,
    _target.created_at=_source.created_at,
    _target.updated_at=_source.updated_at