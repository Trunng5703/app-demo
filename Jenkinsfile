pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        GITHUB_CREDENTIALS = credentials('github-credentials')
        SONARQUBE_TOKEN = credentials('sonarqube-token')
        IMAGE_NAME = 'trunng5703/petclinic'
    }
    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Trunng5703/app-demo.git', credentialsId: 'github-credentials'
            }
        }
        stage('Build and Test') {
            steps {
                sh './mvnw clean package'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh './mvnw sonar:sonar -Dsonar.login=$SONARQUBE_TOKEN'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh './mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=$IMAGE_NAME:${BUILD_NUMBER}'
            }
        }
        stage('Push Docker Image') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker push $IMAGE_NAME:${BUILD_NUMBER}'
            }
        }
        stage('Update GitOps Repo - Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh '''
                    git clone https://$GITHUB_CREDENTIALS_USR:$GITHUB_CREDENTIALS_PSW@github.com/Trunng5703/app-demo-staging.git
                    cd app-demo-staging
                    sed -i "s|image: trunng5703/petclinic:.*|image: trunng5703/petclinic:${BUILD_NUMBER}|" k8s/deployment.yaml
                    git add k8s/deployment.yaml
                    git commit -m "Update image tag to ${BUILD_NUMBER}" || true
                    git push origin main
                '''
            }
        }
        stage('Update GitOps Repo - Production') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    git clone https://$GITHUB_CREDENTIALS_USR:$GITHUB_CREDENTIALS_PSW@github.com/Trunng5703/app-demo-production.git
                    cd app-demo-production
                    sed -i "s|image: trunng5703/petclinic:.*|image: trunng5703/petclinic:${BUILD_NUMBER}|" k8s/deployment.yaml
                    git add k8s/deployment.yaml
                    git commit -m "Update image tag to ${BUILD_NUMBER}" || true
                    git push origin main
                '''
            }
        }
    }
}
