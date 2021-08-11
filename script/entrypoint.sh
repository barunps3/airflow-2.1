#!/bin/bash

export AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY:=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}
export ${AIRFLOW__CORE__EXECUTOR:="SequentialExecutor"} # default executor
export AIRFLOW__CORE__LOAD_EXAMPLES=False


# Install custom python package if requirements.txt is present
if [ "${AIRFLOW_FETCH_DAGS}" = true ] ; then
    cd ${AIRFLOW_HOME}/dags
    echo "Populating DAG folder"
    if [ -n "${AIRFLOW_DAG_BRANCH}" ] ; then
        echo "Importing from ${AIRFLOW_DAG_BRANCH}"
        git clone https://${AIRFLOW_GIT_USERNAME}:${AIRFLOW_GIT_TOKEN}@devstack.vwgroup.com/bitbucket/scm/wepoi/airflow-dag.git dags -b ${AIRFLOW_DAG_BRANCH}

    else
        echo "Importing Master Branch..."
        #Initialize DAG Directory
        git clone https://${AIRFLOW_GIT_USERNAME}:${AIRFLOW_GIT_TOKEN}@devstack.vwgroup.com/bitbucket/scm/wepoi/airflow-dag.git dags
    fi
fi

# Install custom python package if requirements.txt is present
if [ -e "${AIRFLOW_HOME}/dags/requirements.txt" ]; then
    $(command -v pip) install --user -r ${AIRFLOW_HOME}/dags/requirements.txt
    $(command -v pip) install --user -r ${AIRFLOW_HOME}/dags/dev-requirements.txt
fi

wait_for_port() {
    local name="$1" host="$2" port="$3"
    local j=0
    while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
        j=$((j+1))
        if [ $j -ge $TRY_LOOP ]; then
            echo >&2 "$(date) - $host:$port still not reachable, giving up"
            exit 1
        fi
            echo "$(date) - waiting for $name... $j/$TRY_LOOP"
            sleep 5
    done
}


# Other executors than SequentialExecutor drive the need for an SQL database, here PostgreSQL is used
if [ "$AIRFLOW__CORE__EXECUTOR" != "SequentialExecutor" ]; then
    # Check if the user has provided explicit Airflow configuration concerning the database
    if [ -z "$AIRFLOW__CORE__SQL_ALCHEMY_CONN" ]; then
        # Default values corresponding to the default compose files
        : "${POSTGRES_HOST:="postgres"}"
        : "${POSTGRES_PORT:="5432"}"
        : "${POSTGRES_USER:="airflow"}"
        : "${POSTGRES_PASSWORD:="airflow"}"
        : "${POSTGRES_DB:="airflow"}"
        : "${POSTGRES_EXTRAS:-""}"

        AIRFLOW__CORE__SQL_ALCHEMY_CONN="postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}${POSTGRES_EXTRAS}"
        export AIRFLOW__CORE__SQL_ALCHEMY_CONN

        # Check if the user has provided explicit Airflow configuration for the broker's connection to the database
        if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]; then
            AIRFLOW__CELERY__RESULT_BACKEND="db+postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}${POSTGRES_EXTRAS}"
            export AIRFLOW__CELERY__RESULT_BACKEND
        fi
    else
        if [[ "$AIRFLOW__CORE__EXECUTOR" == "CeleryExecutor" && -z "$AIRFLOW__CELERY__RESULT_BACKEND" ]]; then
            >&2 printf '%s\n' "FATAL: if you set AIRFLOW__CORE__SQL_ALCHEMY_CONN manually with CeleryExecutor you must also set AIRFLOW__CELERY__RESULT_BACKEND"
            exit 1
        fi
    fi
fi


# CeleryExecutor drives the need for a Celery broker, here Redis is used
if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]; then
    # Check if the user has provided explicit Airflow configuration concerning the broker
    if [ -z "$AIRFLOW__CELERY__BROKER_URL" ]; then
        # Default values corresponding to the default compose files
        : "${REDIS_PROTO:="redis://"}"
        : "${REDIS_HOST:="redis"}"
        : "${REDIS_PORT:="6379"}"
        : "${REDIS_PASSWORD:=""}"
        : "${REDIS_DBNUM:="1"}"

        # When Redis is secured by basic auth, it does not handle the username part of basic auth, only a token
        if [ -n "$REDIS_PASSWORD" ]; then
        REDIS_PREFIX=":${REDIS_PASSWORD}@"
        else
        REDIS_PREFIX=
        fi
    fi 
    AIRFLOW__CELERY__BROKER_URL="${REDIS_PROTO}${REDIS_PREFIX}${REDIS_HOST}:${REDIS_PORT}/${REDIS_DBNUM}"
    export AIRFLOW__CELERY__BROKER_URL
fi


case "$1" in
    webserver)
        airflow version
        airflow db init
        airflow users create \
            --username ADMIN_USER \
            --firstname ADMIN_FIRST_NAME \
            --lastname ADMIN_LAST_NAME \
            --email ADMIN_EMAIL \
            --role "Admin" \
            --password ADMIN_PASSWORD
        if [ "$AIRFLOW__CORE__EXECUTOR" = "LocalExecutor" ] || [ "$AIRFLOW__CORE__EXECUTOR" = "SequentialExecutor" ]; then
            # With the "Local" and "Sequential" executors it should all run in one container.
            airflow scheduler &
        fi
        exec airflow webserver
        ;;
    scheduler)
        # Give the webserver time to run initdb.
        sleep 10
        exec airflow "$@"
        ;;
    flower|worker)
        # Give the webserver time to run initdb.
        sleep 10
        if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]; then
            exec airflow celery "$@"
        else
            echo "Running in ${AIRFLOW__CORE__EXECUTOR}, no Celery processes nedded here."
        fi
        ;;
    version)
        exec airflow "$@"
        ;;
    *)
        # The command is something like bash, not an airflow subcommand. Just run it in the right environment.
        exec "$@"
        ;;
esac