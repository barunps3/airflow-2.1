#!/bin/bash

export AIRFLOW_HOME="/usr/local/airflow"
export AIRFLOW__CORE__FERNET_KEY=${FERNET_KEY:=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")}
export ${AIRFLOW__CORE__EXECUTOR:="${EXECUTOR:-Sequential}Executor"}
