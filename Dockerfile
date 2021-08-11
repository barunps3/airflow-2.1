FROM apache/airflow:2.1.2-python3.8

# Install apt packages as root
USER root
RUN apt-get update && \
    apt-get upgrade -y
RUN apt-get install -y python3-rtree
RUN apt-get install -y git

# Install airflow/python packages as airflow user
USER airflow
RUN pip install werkzeug==0.16.*

COPY script/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["webserver"]