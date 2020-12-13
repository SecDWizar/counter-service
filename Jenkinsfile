pipeline {
    environment {
        registry = "thewizard/counter-service"
        registryCredential = 'dockerhub_id'
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    agent any 
    stages {
        stage('build') {
            steps {
                sh 'docker build -t ${JOB_NAME}:${BUILD_NUMBER} -t ${JOB_NAME}:latest .'
            }
        }
        stage('test') {
            steps {
                sh 'docker stack deploy -c stack-testing.yml counter-service.test'
                sh 'docker run --rm --network counter-service_counter-service curlimages/curl:7.73.0 sh -c \'seq 1 100 | xargs -P 10 curl -so /dev/null -X POST -w "%{time_total}\n" http://counter-service:8000/\''
                sh 'docker run --rm --network counter-service_counter-service curlimages/curl:7.73.0 curl -X GET -w "%{time_total}\n" http://counter-service:8000/'
                sh 'docker stack rm counter-service.test'
            }
        }
    }
}
