table_schema = [
    {"name": "id","mode": "NULLABLE","type": "INTEGER","description": "","fields": []},
    {"name": "customer_id","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "last_status","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "pos_origin","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "pos_destination","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "created_at","mode": "NULLABLE","type": "TIMESTAMP","description": "","fields": []},
    {"name": "updated_at","mode": "NULLABLE","type": "TIMESTAMP","description": "","fields": []},
    {"name": "deleted_at","mode": "NULLABLE","type": "TIMESTAMP","description": "","fields": []}
]

table_hd_schema = [
    {"name": "id","mode": "NULLABLE","type": "INTEGER","description": "","fields": []},
    {"name": "customer_id","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "last_status","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "pos_origin","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "pos_destination","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "created_at","mode": "NULLABLE","type": "TIMESTAMP","description": "","fields": []},
    {"name": "updated_at","mode": "NULLABLE","type": "TIMESTAMP","description": "","fields": []}
]

table_schema_arcv = [
    {"name": "customer_id","mode": "NULLABLE","type": "STRING","description": "","fields": []},
    {"name": "deleted_at","mode": "NULLABLE","type": "TIMESTAMP","description": "","fields": []}
]

partition_field = {"type": "DAY", "field": "created_at", "requirePartitionFilter": True}

cluster_fields = ["customer_id", "last_status"]