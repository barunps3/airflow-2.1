FROM apache/airflow:2.1.1-python3.7

USER root

RUN apt-get update && \
    apt-get upgrade -y
RUN apt-get install -y python3-rtree
RUN pip install gitpython==3.1.9
RUN pip install werkzeug==0.16.*
RUN pip install SQLAlchemy==1.3.15

COPY script/entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/bin/sh", "-c" ]
CMD ["/bin/bash", "-c", "echo", "Hello World"]