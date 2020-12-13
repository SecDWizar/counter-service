pipeline {
    agent any 
    stages {
        stage('build local container') {
            steps {
                sh 'docker build -t ${JOB_NAME}:${BUILD_NUMBER}'
            }
        }
    }
}
