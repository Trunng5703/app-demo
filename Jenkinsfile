pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'trunng5703/petclinic'
        SONAR_HOST = 'http://172.16.10.41:9000'
        ARGOCD_SERVER = '172.16.10.11:31189'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
                junit 'target/surefire-reports/*.xml'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            mvn sonar:sonar \
                                -Dsonar.projectKey=petclinic \
                                -Dsonar.host.url=${SONAR_HOST} \
                                -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def imageTag = "${env.BRANCH_NAME}-${gitCommit}-${env.BUILD_NUMBER}"
                    
                    docker.build("${DOCKER_IMAGE}:${imageTag}")
                    
                    env.IMAGE_TAG = imageTag
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'dockerhub-creds') {
                        docker.image("${DOCKER_IMAGE}:${env.IMAGE_TAG}").push()
                        docker.image("${DOCKER_IMAGE}:${env.IMAGE_TAG}").push("${env.BRANCH_NAME}-latest")
                    }
                }
            }
        }
        
        stage('Update K8s Manifests') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                script {
                    def targetRepo = env.BRANCH_NAME == 'develop' ? 'app-demo-staging' : 'app-demo-production'
                    def targetEnv = env.BRANCH_NAME == 'develop' ? 'staging' : 'production'
                    
                    withCredentials([usernamePassword(
                        credentialsId: 'github-creds',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                        sh """
                            # Clone target repo
                            rm -rf ${targetRepo}
                            git clone https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/Trunng5703/${targetRepo}.git
                            
                            # Update image tag
                            cd ${targetRepo}
                            sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${env.IMAGE_TAG}|' k8s/deployment.yaml
                            
                            # Commit and push
                            git config user.email "jenkins@cicd.local"
                            git config user.name "Jenkins CI"
                            git add .
                            git commit -m "Update image to ${env.IMAGE_TAG}"
                            git push origin main
                        """
                    }
                }
            }
        }
        
        stage('Deploy with ArgoCD') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
            }
            steps {
                script {
                    def appName = env.BRANCH_NAME == 'develop' ? 'petclinic-staging' : 'petclinic-production'
                    
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            # ArgoCD sync
                            export KUBECONFIG=${KUBECONFIG}
                            argocd app sync ${appName} --insecure --server ${ARGOCD_SERVER}
                            argocd app wait ${appName} --sync --health --timeout 300 --insecure --server ${ARGOCD_SERVER}
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
