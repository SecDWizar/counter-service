pipeline {
    parameters {
        string(name: 'test_sleeptime', defaultValue: '10', description: 'sleep before starting the test')
        string(name: 'production_tag', defaultValue: '001', description: 'production tag to use in registry')
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }
    agent any 
    stages {
        stage('build') {
            steps {
                sh 'docker build -t ${JOB_NAME}:${BUILD_NUMBER} -t ${JOB_NAME}:latest -t ${DOCKERHUBREGISTRY}:${TAG} -t ${DOCKERHUBREGISTRY}:latest .'
            }
        }
        stage('test') {
            steps {
                sh 'docker stack deploy -c stack-testing.yml counter-service-test'
                sleep(time:"${params.test_sleeptime}",unit:"SECONDS")
                sh 'docker run --rm --network counter-service-test_counter-service curlimages/curl:7.73.0 sh -c \'for i in $(seq 1 100); do curl -so /dev/null -w "%{http_code}:%{time_total}\n" -X POST http://counter-service:8000/; done; curl -s -w "\n%{http_code}:%{time_total}\n" -X GET http://counter-service:8000/ -o /tmp/outfile; out=$(cat /tmp/outfile); echo out="\"$out\""; if [ $out -eq 100 ]; then echo success; else exit 1; fi\''
            }
            post {
                always {
                    sh 'docker stack rm counter-service-test'
                }
            }
        }
        stage('deploy') {
            environment {
                TAG = "${params.production_tag}"
                DOCKERHUBREGISTRY = "thewizard/counter-service"
                DOCKERHUBCREDENTIALS = credentials('dockerhub')
            }
            steps {
                sh 'env | grep DOCKER'
                sh 'docker login -u $DOCKERHUBCREDENTIALS_USR -p $DOCKERHUBCREDENTIALS_PSW; docker tag ${JOB_NAME}:${BUILD_NUMBER} ${DOCKERHUBREGISTRY}:${TAG}; docker tag ${JOB_NAME}:${BUILD_NUMBER} ${DOCKERHUBREGISTRY}:latest; docker push ${DOCKERHUBREGISTRY}:${TAG}'
                sh 'docker stack deploy -c stack-production.yml counter-service'
            }
            post {
                always {
                    sh 'docker logout'
                    sh 'rm -rf ~/.docker/config.json'
                }
            }
        }
    }
}
