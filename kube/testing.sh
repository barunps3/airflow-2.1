#!/bin/bash


echo -e '---------------------------------------------------------------------------------------\n'
echo 'TESTING ENVIRONMENT DETAILS'
echo -e '\n---------------------------------------------------------------------------------------'
echo "AIRFLOW_VERSION: $(airflow version)"
echo "PYTHON_VERSION: $(python --version)"
echo "AIRFLOW_HOME: ${AIRFLOW_HOME}"


echo -e '---------------------------------------------------------------------------------------\n'
echo 'PIP INSTALL ADDITIONAL PACKAGES'
echo -e '\n---------------------------------------------------------------------------------------'

# pip installation 
pip install pip-licenses
pip install coverage==4.5.4
pip install pytest==5.4.3
pip install pytest-cov
pip install coverage2clover
python -m pip-licenses --with-urls --with-description --order=name --with-license-file --format=html --output-file=/usr/local/airflow/foss/foss_list.html


echo -e '---------------------------------------------------------------------------------------\n'
echo 'INITIALIZE DB AND ADD TEST VARIABLES'
echo -e '\n---------------------------------------------------------------------------------------'

# Initialize airflow db 
airflow db init
airflow variables import ${AIRFLOW_HOME}/dags/testing/variables.json


echo -e '---------------------------------------------------------------------------------------\n'
echo 'START TESTING'
echo -e '\n---------------------------------------------------------------------------------------'

# Start Python Testing 
echo "Present Working Directory: $PWD"
mkdir ${AIRFLOW_HOME}/test-reports
cd ${AIRFLOW_HOME}/test-reports
export PYTHONPATH=${AIRFLOW_HOME}/dags

# Create a empty array
declare -a test_folder_abs_path
# Add abs path to each of relative testing folder path
for folder in $@
do
    test_folder_abs_path+="${AIRFLOW_HOME}/dags/$folder "
done
# Give abs path to pytest
python -m pytest ${test_folder_abs_path[@]} --junitxml=results.xml --cov=dags --cov-report=xml:coverage.xml --cov-report=html --cov-config=.coveragerc