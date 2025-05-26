pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        DOCKER_IMAGE = "trunng5703/app-demo"
        SONAR_TOKEN = credentials('sonarqube-token')
        GIT_CREDENTIALS = credentials('github-credentials')
        ARGOCD_SERVER = "172.16.10.11:32120"
        ARGOCD_TOKEN = credentials('argocd-admin-token') // Sử dụng token đã lưu
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
                // Không cần withCredentials cho password nữa, chỉ dùng token
                sh '''
                    /bin/bash -x -c "argocd app sync app-demo-staging --server $ARGOCD_SERVER --auth-token \"$ARGOCD_TOKEN\" --insecure"
                '''
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
                sh '''
                    /bin/bash -x -c "argocd app sync app-demo-production --server $ARGOCD_SERVER --auth-token \"$ARGOCD_TOKEN\" --insecure"
                '''
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
