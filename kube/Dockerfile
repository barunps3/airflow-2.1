FROM apache/airflow:2.0.2-python3.8

# Set environment variables required to pull dags from bitbucket
ARG AIRFLOW_GIT_USER
ENV AIRFLOW_GIT_USERNAME=$AIRFLOW_GIT_USER

ARG AIRFLOW_GIT_PASS
ENV AIRFLOW_GIT_TOKEN=$AIRFLOW_GIT_PASS

ARG AIRFLOW_FETCH_DAGS
ENV AIRFLOW_FETCH_DAGS=$AIRFLOW_FETCH_DAGS

ARG AIRFLOW_GIT_BRANCH
ENV AIRFLOW_DAG_BRANCH=$AIRFLOW_GIT_BRANCH

# Set airflow home as default
ENV AIRFLOW_HOME=/opt/airflow

# Install apt packages as root
USER root
RUN apt-get update && \
    apt-get upgrade -y
RUN apt-get install -y python3-rtree
RUN apt-get install -y git

COPY script/entrypoint.sh /entrypoint.sh
COPY testing.sh ${AIRFLOW_HOME}/testing.sh
RUN mkdir ${AIRFLOW_HOME}/temp

# Set airflow user after chmod
RUN chown -R airflow: ${AIRFLOW_HOME}
USER airflow

WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["webserver"]