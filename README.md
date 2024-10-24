create airflow user and database

```
CREATE USER airflow WITH PASSWORD 'airflow';
CREATE DATABASE airflow WITH OWNER = airflow;
```

make .env

```
AIRFLOW_UID=1000
AIRFLOW_DB_NAME="airflow"
AIRFLOW_DB_USER="airflow"
AIRFLOW_DB_PASSWORD="airflow"
AIRFLOW_DB_HOST="localhost"
AIRFLOW_DB_PORT=5432
EXAMPLE_DB_NAME="example"
EXAMPLE_DB_USER="postgres"
EXAMPLE_DB_HOST="localhost"
EXAMPLE_DB_PASSWORD="postgres"
EXAMPLE_DB_PORT="5432"
GOOGLE_APPLICATION_CREDENTIALS="./credential.json"
AIRFLOW_LOCAL_PATH="./mount"
```

run compose

> Make sure compose and env file in same path

```
docker compose up -d
```

after airflow up, run this to initialize connections

```
./init-airflow-connection.sh
```

for the test case, run setup.sh to create example table

```
./database/setup.sh -e .env -m up -s database/migrate.up.sql
```

> for resetting the test case, run migrate down

```
./database/setup.sh -e .env -m down -s database/migrate.down.sql
```
