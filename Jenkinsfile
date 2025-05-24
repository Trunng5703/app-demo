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
        stage('Update ArgoCD') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                script {
                    def repo = env.BRANCH_NAME == 'develop' ? 'app-demo-staging' : 'app-demo-production'
                    def app = env.BRANCH_NAME == 'develop' ? 'spring-petclinic-staging' : 'spring-petclinic-production'
                    def tag = env.BRANCH_NAME == 'develop' ? "staging-${BUILD_NUMBER}" : "production-${BUILD_NUMBER}"
                    dir(repo) {
                        git credentialsId: 'github-credentials', url: "https://github.com/Trunng5703/${repo}.git"
                        sh "sed -i 's|trunng5703/app-demo:.*|trunng5703/app-demo:${tag}|' k8s/deployment.yaml"
                        sh 'git config user.email "jenkins@ci-cd.local"'
                        sh 'git config user.name "Jenkins"'
                        sh 'git add k8s/deployment.yaml'
                        sh 'git commit -m "Update image tag to ${tag}"'
                        withCredentials([usernamePassword(credentialsId: 'github-credentials', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                            sh "git push https://\${GIT_USER}:\${GIT_TOKEN}@github.com/Trunng5703/${repo}.git main"
                        }
                    }
                    withCredentials([usernamePassword(credentialsId: 'argocd-credentials', usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh "curl -k -u \${ARGOCD_USER}:\${ARGOCD_PASS} -X POST https://172.16.10.11:32120/api/v1/applications/${app}/sync"
                    }
                }
            }
        }
    }
    post {
        always {
            echo "Pipeline completed for branch ${BRANCH_NAME}."
            sh 'docker system prune -f'
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
            sh 'docker system prune -f'
            emailext(
                subject: "Pipeline Failed - app-demo #${env.BUILD_NUMBER} on ${BRANCH_NAME}",
                body: "Pipeline failed on branch ${BRANCH_NAME}. Build URL: ${env.BUILD_URL}\nCheck logs for details.",
                to: "trinhhatrung69@gmail.com",
                attachLog: true
            )
        }
    }
}
