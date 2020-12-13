pipeline {
    agent any 
    stages {
        stage('build local container') {
            steps {
                ls
                echo 'Hello world 5!' 
                docker --version
            }
        }
    }
}
