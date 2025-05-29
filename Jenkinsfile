pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = "trunng5703/petclinic"
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        SONAR_TOKEN = credentials('sonarqube-token')
        GIT_CREDENTIALS = credentials('github-credentials')
        ARGOCD_TOKEN = credentials('argocd-admin-token')
        // Biến môi trường cho PostgreSQL
        SPRING_PROFILES_ACTIVE = 'postgres'
        SPRING_DATASOURCE_URL = 'jdbc:postgresql://postgres-service.staging.svc.cluster.local:5432/petclinic'
        SPRING_DATASOURCE_USERNAME = 'petclinic'
        SPRING_DATASOURCE_PASSWORD = 'petclinic'
    }
    stages {
        stage('Checkout') {
            steps {
                script {
                    if (!env.BRANCH_NAME) {
                        error "Không có nhánh nào được chỉ định. Vui lòng kích hoạt build với một nhánh cụ thể (ví dụ: develop hoặc main)."
                    }
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${env.BRANCH_NAME}"]],
                        userRemoteConfigs: [[
                            url: 'https://github.com/Trunng5703/app-demo.git',
                            credentialsId: 'github-credentials'
                        ]]
                    ])
                }
            }
        }
        stage('Build and Test (Develop)') {
            when {
                branch 'develop'
            }
            steps {
                // Build và test với profile postgres
                sh './mvnw clean package -Dspring.profiles.active=postgres'
            }
        }
        stage('SonarQube Scan (Develop)') {
            when {
                branch 'develop'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh './mvnw sonar:sonar -Dsonar.host.url=http://172.16.10.41:9000 -Dsonar.login=$SONAR_TOKEN'
                }
            }
        }
        stage('Build Docker Image (Develop)') {
            when {
                branch 'develop'
            }
            steps {
                // Build Docker image bằng docker build
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }
        stage('Push Docker Image (Develop)') {
            when {
                branch 'develop'
            }
            steps {
                // Đẩy image lên DockerHub
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                sh "docker push ${DOCKER_IMAGE}:latest"
            }
        }
        stage('Trigger ArgoCD Sync (Staging)') {
            when {
                branch 'develop'
            }
            steps {
                sh '''
                    /bin/bash -c "argocd app sync app-demo-staging --server 172.16.10.11:32120 --auth-token $ARGOCD_TOKEN --insecure"
                '''
            }
        }
        stage('Build and Test (Main)') {
            when {
                branch 'main'
            }
            steps {
                // Build và test với profile postgres
                sh './mvnw clean package -Dspring.profiles.active=postgres'
            }
        }
        stage('Build Docker Image (Main)') {
            when {
                branch 'main'
            }
            steps {
                // Build Docker image bằng docker build
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }
        stage('Push Docker Image (Main)') {
            when {
                branch 'main'
            }
            steps {
                // Đẩy image lên DockerHub
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
                sh "docker push ${DOCKER_IMAGE}:latest"
            }
        }
        stage('Trigger ArgoCD Sync (Production)') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    /bin/bash -c "argocd app sync app-demo-production --server 172.16.10.11:32120 --auth-token $ARGOCD_TOKEN --insecure"
                '''
            }
        }
    }
    post {
        always {
            cleanWs()
            // Dọn dẹp Docker images
            sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true"
            sh "docker rmi ${DOCKER_IMAGE}:latest || true"
        }
        success {
            echo 'Build, test, and deployment successful!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
