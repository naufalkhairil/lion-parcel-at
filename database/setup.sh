#!/usr/bin/env bash

BASEDIR=$(cd $(dirname $0) && pwd)

ENV_FILE="${BASEDIR}/.env"
MIGRATE_FILE=""
MIGRATE_TYPE=""

showHelp() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo " -e <filepath>    : dot env filepath, default: ${ENV_FILE}"
    echo " -m <up/down>     : migrate type up or down"
    echo " -s <filepath>    : migrate sql filepath"
    echo " -h               : show this help"
    echo ""
}

while getopts "e:s:m:h" opt; do
    case ${opt} in
    e)
        ENV_FILE="${OPTARG}"
        ;;
    m)
        MIGRATE_TYPE="${OPTARG}"
        ;;
    s)
        MIGRATE_FILE="${OPTARG}"
        ;;
    h)
        showHelp
        exit 0
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        showHelp
        exit 1
        ;;
    esac
done


if [ -f "${ENV_FILE}" ]; then
    export $(grep -v '^#' "${ENV_FILE}" | xargs)
fi

echo "===================================="
echo "============ ENV INFO =============="
echo "===================================="
echo ""
echo "Database  : $EXAMPLE_DB_NAME"
echo "User      : $EXAMPLE_DB_USER"
echo "Host      : $EXAMPLE_DB_HOST"
echo "Port      : $EXAMPLE_DB_PORT"
echo ""
echo "===================================="
echo ""

if [ "${MIGRATE_TYPE}" == "up" ]; then
    echo "Migrating database ..."
    # Check if the database exists
    DB_EXISTS=$(PGPASSWORD=$EXAMPLE_DB_PASSWORD psql -h $EXAMPLE_DB_HOST -p $EXAMPLE_DB_PORT -U $EXAMPLE_DB_USER -lqt | cut -d \| -f 1 | grep -w $DB_NAME | wc -l)

    # If the database doesn't exist, create it
    if [ "$DB_EXISTS" -eq "0" ]; then
        echo "Database '$EXAMPLE_DB_NAME' does not exist. Creating database..."
        PGPASSWORD=$EXAMPLE_DB_PASSWORD createdb -h $EXAMPLE_DB_HOST -p $EXAMPLE_DB_PORT -U $EXAMPLE_DB_USER $EXAMPLE_DB_NAME

        # Check if the creation was successful
        if [ $? -eq 0 ]; then
            echo "Database '$EXAMPLE_DB_NAME' created successfully."
        else
            echo "Error creating the database."
        fi
    else
        echo "Database '$EXAMPLE_DB_NAME' already exists."
    fi

    # Check if SQL file exists
    if [ -f "$MIGRATE_FILE" ]; then
        # Execute the SQL file in PostgreSQL
        PGPASSWORD=$EXAMPLE_DB_PASSWORD psql -h $EXAMPLE_DB_HOST -p $EXAMPLE_DB_PORT -U $EXAMPLE_DB_USER -d $EXAMPLE_DB_NAME -f "$MIGRATE_FILE"

        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "SQL script executed successfully."
        else
            echo "Error executing the SQL script."
        fi
    else
        echo "SQL file not found: $MIGRATE_FILE"
    fi

elif [ "${MIGRATE_TYPE}" == "down" ]; then
    echo "Migrating down database ..."
    # Check if SQL file exists
    if [ -f "$MIGRATE_FILE" ]; then
        # Execute the SQL file in PostgreSQL
        PGPASSWORD=$EXAMPLE_DB_PASSWORD psql -h $EXAMPLE_DB_HOST -p $EXAMPLE_DB_PORT -U $EXAMPLE_DB_USER -d $EXAMPLE_DB_NAME -f "$MIGRATE_FILE"

        # Check if the command was successful
        if [ $? -eq 0 ]; then
            echo "SQL script executed successfully."
        else
            echo "Error executing the SQL script."
        fi
    else
        echo "SQL file not found: $MIGRATE_FILE"
    fi
elif [ "${MIGRATE_TYPE}" == "" ]; then
    echo "Please specify migration type"
    showHelp
    exit 1
else
    echo "Unkown migrate type"
    exit 1
fi

