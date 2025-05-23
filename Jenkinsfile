pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CREDENTIALS = credentials('github-credentials')
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/Trunng5703/app-demo.git'
                sh 'ls -la'
            }
        }
        stage('SonarQube Analysis') {
            options {
                timeout(time: 30, unit: 'MINUTES')
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh './mvnw sonar:sonar -Dsonar.login=$SONAR_TOKEN'
                }
            }
        }
        stage('Build') {
            steps {
                sh './mvnw clean package'
                archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
            }
        }
        stage('Test') {
            steps {
                script {
                    try {
                        sh './mvnw test'
                    } catch (Exception e) {
                        echo "Tests failed, but pipeline will continue."
                    }
                }
                archiveArtifacts artifacts: 'target/surefire-reports/*.xml', allowEmptyArchive: true
            }
        }
        stage('Build Docker Image') {
            steps {
                sh 'docker --version'
                sh './mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=trunng5703/app-demo:latest'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/']) {
                    sh 'docker push trunng5703/app-demo:latest'
                }
            }
        }
        stage('Verify Docker Image') {
            steps {
                sh 'docker pull trunng5703/app-demo:latest'
                sh 'docker inspect trunng5703/app-demo:latest'
            }
        }
    }
    post {
        always {
            echo "Pipeline completed."
            emailext(
                subject: "Pipeline ${currentBuild.result ?: 'SUCCESS'} for app-demo #${env.BUILD_NUMBER}",
                body: "Pipeline ${currentBuild.result ?: 'SUCCESS'}. Build URL: ${env.BUILD_URL}\nCheck logs for details.",
                to: "your.email@example.com",
                attachLog: true
            )
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
