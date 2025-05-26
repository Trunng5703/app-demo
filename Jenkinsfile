pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = "trunng5703/app-demo"
        SONAR_TOKEN = credentials('sonarqube-token')
        GIT_CREDENTIALS = credentials('github-credentials')
        ARGOCD_SERVER = "172.16.10.11:32120"
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
                sh './mvnw clean package -Dspring.profiles.active=test'
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
                withEnv(["DOCKER_IMAGE=${DOCKER_IMAGE}", "BUILD_NUMBER=${env.BUILD_NUMBER}"]) {
                    sh '/bin/bash -c "./mvnw compile com.google.cloud.tools:jib-maven-plugin:3.4.3:build -Dimage=$DOCKER_IMAGE:$BUILD_NUMBER -Djib.to.auth.username=${DOCKERHUB_CREDENTIALS_USR} -Djib.to.auth.password=${DOCKERHUB_CREDENTIALS_PSW}"'
                }
            }
        }
        stage('Trigger ArgoCD Sync (Staging)') {
            when {
                branch 'develop'
            }
            steps {
                withCredentials([string(credentialsId: 'argocd-admin-password', variable: 'ARGOCD_PASSWORD')]) {
                    // Bước 1: Đăng nhập vào ArgoCD và lưu context
                    sh '''
                        /bin/bash -x -c "argocd login $ARGOCD_SERVER --username admin --password \"$ARGOCD_PASSWORD\" --insecure --grpc-web || \
                        { echo 'Failed to login to ArgoCD'; exit 1; }"
                    '''
                    // Bước 2: Tạo token và đồng bộ ứng dụng
                    sh '''
                        /bin/bash -x -c "TOKEN=$(argocd account generate-token --account admin) && \
                        echo 'Generated token: $TOKEN' && \
                        argocd app sync app-demo-staging --server $ARGOCD_SERVER --auth-token \"$TOKEN\" --insecure"
                    '''
                }
            }
        }
        stage('Build Docker Image (Main)') {
            when {
                branch 'main'
            }
            steps {
                withEnv(["DOCKER_IMAGE=${DOCKER_IMAGE}", "BUILD_NUMBER=${env.BUILD_NUMBER}"]) {
                    sh '/bin/bash -c "./mvnw compile com.google.cloud.tools:jib-maven-plugin:3.4.3:build -Dimage=$DOCKER_IMAGE:$BUILD_NUMBER -Djib.to.auth.username=${DOCKERHUB_CREDENTIALS_USR} -Djib.to.auth.password=${DOCKERHUB_CREDENTIALS_PSW}"'
                }
            }
        }
        stage('Trigger ArgoCD Sync (Production)') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([string(credentialsId: 'argocd-admin-password', variable: 'ARGOCD_PASSWORD')]) {
                    // Bước 1: Đăng nhập vào ArgoCD và lưu context
                    sh '''
                        /bin/bash -x -c "argocd login $ARGOCD_SERVER --username admin --password \"$ARGOCD_PASSWORD\" --insecure --grpc-web || \
                        { echo 'Failed to login to ArgoCD'; exit 1; }"
                    '''
                    // Bước 2: Tạo token và đồng bộ ứng dụng
                    sh '''
                        /bin/bash -x -c "TOKEN=$(argocd account generate-token --account admin) && \
                        echo 'Generated token: $TOKEN' && \
                        argocd app sync app-demo-production --server $ARGOCD_SERVER --auth-token \"$TOKEN\" --insecure"
                    '''
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
