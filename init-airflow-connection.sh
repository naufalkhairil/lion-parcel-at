#!/usr/bin/env bash

BASEDIR=$(cd $(dirname $0) && pwd)
ENV_FILE="${BASEDIR}/.env"

if [ -f "${ENV_FILE}" ]; then
    export $(grep -v '^#' "${ENV_FILE}" | xargs)
fi

AIRFLOW_CID=$(docker ps | grep airflow-worker | cut -d " " -f1)

echo "Adding google cloud connection..."
docker exec -it ${AIRFLOW_CID} airflow connections add google_cloud_default \
    --conn-type google_cloud_platform \
    --conn-extra '{"key_path": "/var/tmp/credentials.json", "num_retries": "5"}'

echo "Adding postgre example db connection..."
docker exec -it ${AIRFLOW_CID} airflow connections add example_db \
    --conn-type postgres \
    --conn-host ${EXAMPLE_DB_HOST} \
    --conn-schema ${EXAMPLE_DB_NAME} \
    --conn-login ${EXAMPLE_DB_USER} \
    --conn-password ${EXAMPLE_DB_PASSWORD} \
    --conn-port 5432