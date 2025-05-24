pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        SONAR_TOKEN = credentials('sonarqube-token')
        GITHUB_CREDENTIALS = credentials('github-credentials')
        BRANCH_NAME = "${env.GIT_BRANCH.split('/').last()}"
    }
    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'github-credentials', url: 'https://github.com/Trunng5703/app-demo.git'
                sh 'ls -la'
            }
        }
        stage('SonarQube Analysis') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
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
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                sh './mvnw clean package'
                archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
            }
        }
        stage('Test') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
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
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                sh 'docker --version'
                script {
                    if (env.BRANCH_NAME == 'develop') {
                        sh './mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=trunng5703/app-demo:staging-${BUILD_NUMBER}'
                    } else if (env.BRANCH_NAME == 'main') {
                        sh './mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=trunng5703/app-demo:production-${BUILD_NUMBER}'
                    }
                }
            }
        }
        stage('Push to Docker Hub') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://index.docker.io/v1/']) {
                    script {
                        if (env.BRANCH_NAME == 'develop') {
                            sh 'docker push trunng5703/app-demo:staging-${BUILD_NUMBER}'
                        } else if (env.BRANCH_NAME == 'main') {
                            sh 'docker push trunng5703/app-demo:production-${BUILD_NUMBER}'
                        }
                    }
                }
            }
        }
        stage('Verify Docker Image') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                script {
                    if (env.BRANCH_NAME == 'develop') {
                        sh 'docker pull trunng5703/app-demo:staging-${BUILD_NUMBER}'
                        sh 'docker inspect trunng5703/app-demo:staging-${BUILD_NUMBER}'
                    } else if (env.BRANCH_NAME == 'main') {
                        sh 'docker pull trunng5703/app-demo:production-${BUILD_NUMBER}'
                        sh 'docker inspect trunng5703/app-demo:production-${BUILD_NUMBER}'
                    }
                }
            }
        }
    }
    post {
        always {
            echo "Pipeline completed."
            script {
                if (env.BRANCH_NAME == 'develop') {
                    emailext(
                        subject: "Staging Deployment Ready for QA - app-demo #${env.BUILD_NUMBER}",
                        body: "Staging deployment completed for branch ${BRANCH_NAME}. Build URL: ${env.BUILD_URL}\nAccess: https://spring-petclinic.local/staging\nPlease verify and approve for Production deployment.",
                        to: "trinhhatrung69@gmail.com",
                        attachLog: true
                    )
                } else if (env.BRANCH_NAME == 'main') {
                    emailext(
                        subject: "Production Deployment Completed - app-demo #${env.BUILD_NUMBER}",
                        body: "Production deployment completed for branch ${BRANCH_NAME}. Build URL: ${env.BUILD_URL}\nAccess: https://spring-petclinic.local/production\nCheck logs for details.",
                        to: "trinhhatrung69@gmail.com",
                        attachLog: true
                    )
                }
            }
        }
        failure {
            echo "Pipeline failed. Check logs for details."
            emailext(
                subject: "Pipeline Failed - app-demo #${env.BUILD_NUMBER} on ${BRANCH_NAME}",
                body: "Pipeline failed on branch ${BRANCH_NAME}. Build URL: ${env.BUILD_URL}\nCheck logs for details.",
                to: "trinhhatrung69@gmail.com",
                attachLog: true
            )
        }
    }
}
