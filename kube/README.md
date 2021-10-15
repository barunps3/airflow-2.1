# Onboarding to 3rd Party Management

We are using [Airflow](https://airflow.apache.org/) for the data pipeline. This repository contains a Docker Image for running Airflow.

## Easy set up Airflow with Git Pull 
In this setup, when running the docker container, the DAG code is directly pulled from bitbucket. By default it pulls the code from the DAG repo (https://devstack.vwgroup.com/bitbucket/scm/wepoi/airflow-dag.git).

1. Build the Docker image with bitbucket credentials for airflow DAG repo. Run the following command in this root directory:

```bash
docker build -t airflow-test-image --build-arg AIRFLOW_GIT_USER=<your-bitbucket-fix-id> --build-arg AIRFLOW_GIT_PASS=<your-bitbucket-token> --build-arg AIRFLOW_FETCH_DAGS=true --build-arg AIRFLOW_GIT_BRANCH=dev .
```

| Build Arguments| Definitions |
|------|---|
| AIRFLOW_GIT_USER   |  User for the Airflow DAG repo |
| AIRFLOW_GIT_PASS   |  Token or password for the Airflow DAG repo. [How to create your own token in Bitbucket.](https://confluence.atlassian.com/bitbucketserver/personal-access-tokens-939515499.html) |
| AIRFLOW_GIT_BRANCH | Branch to pull DAGs from. If empty, DAGs get pulled from `dev`.  |


2. To run the docker container, run the following command in this root directory:
```bash
docker run --name airflow-test -p 8080:8080 airflow-test-image
```

3. The Web UI of airflow should be available in few (~10) minutes at: [http://localhost:8080](http://localhost:8080).
Login with the following credentials:

  - __User__: ADMIN_USER
  - __Password:__ ADMIN_PASSWORD

4. Import the credentials of the data suppliers in the Airflow Web UI via `Admin -> Variables`.


## Debug mode Airflow setup

In debug mode, local DAG code can be tested with local airflow web UI setup. The code can be tested either by running a single container or celery cluster as setup on AWS. 

### I. Debug with single airflow container
1. Build a fresh image from Dockerfile, run the following command in this root directory:
```bash
docker build -t airflow-test-image .
```
2. Run the following command in your local dag folder (in the root directory of cloned DAG repo), and append to it the name of virtualenvironment folder. In this example, venv folder was appended to .airflowignore. 
```bash
touch .airflowignore
echo venv >> .airflowignore
```

3. When running the docker container mount the folder path of your local dags, which are you are testing. Replace <span style="color:blue"><strong>\<location-local-dag-folder></strong></span> in the following command:

```bash
docker run --name airflow-single-test -p 8080:8080 -v <location-local-dag-folder>:/opt/airflow/dags airflow-test-image
```

4. The Web UI of airflow should be available in few (~10) minutes at: [http://localhost:8080](http://localhost:8080).
Login with the following credentials:

  - __User__: ADMIN_USER
  - __Password:__ ADMIN_PASSWORD

5. Check that your DAGs are imported and visible in your local airflow Web UI. 

### II. Debug on airflow celery cluster
1. Create a .airflowignore file in your local dags folder, which you are testing, and append to it virtualenv folder name. In this example, venv folder was appended to .airflowignore. 
```bash
touch .airflowignore
echo venv >> .airflowignore
```

2. Update the placeholder <span style="color:blue"><strong>\<location-local-dag-folder></strong></span> in docker-compose.yml with the local absolute path of dags folder.

3. Update the <span style="color:blue"><strong>\<your-generated-fernet-key></strong></span> placeholder in docker-compose.yml by generating it in your bash terminal
```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

4. To run the cluster, run the following command in this root directory:
```bash
docker-compose up
```

5. The Web UI of airflow should be available in few (~10-15) minutes at: [http://localhost:8080](http://localhost:8080).
Login with the following credentials:

  - __User__: ADMIN_USER
  - __Password:__ ADMIN_PASSWORD
