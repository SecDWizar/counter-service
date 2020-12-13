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
                sh 'docker stack deploy -c stack-testing.yml counter-service-test'
                sleep(time:30,unit:"SECONDS")
                sh 'docker run --rm --network counter-service-test_counter-service curlimages/curl:7.73.0 sh -c \'for i in $(seq 1 100); do curl -so /dev/null -w "%{http_code}:%{time_total}\n" -X POST http://counter-service:8000/; done; curl -s -w "\n%{http_code}:%{time_total}\n" -X GET http://counter-service:8000/ > /tmp/outfile; out=$(cat /tmp/outfile); echo out=$out; [ $out -eq 100 ] && echo success || exit 1\''
            }
            post {
                always {
                    sh 'docker stack rm counter-service-test'
                }
           }
        }
    }
}
