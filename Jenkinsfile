pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'trunng5703/petclinic'
        SONAR_HOST = 'http://172.16.10.41:9000'
        GIT_STAGING_REPO = 'https://github.com/Trunng5703/app-demo-staging.git'
        GIT_PROD_REPO = 'https://github.com/Trunng5703/app-demo-production.git'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
                    env.GIT_BRANCH_NAME = sh(returnStdout: true, script: "git rev-parse --abbrev-ref HEAD").trim()
                }
            }
        }
        
        stage('Build & Test') {
            steps {
                sh './mvnw clean compile test'
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh './mvnw sonar:sonar -Dsonar.projectKey=petclinic -Dsonar.host.url=$SONAR_HOST'
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def tag = env.GIT_BRANCH_NAME == 'main' ? 'latest' : env.GIT_BRANCH_NAME
                    sh """
                        ./mvnw spring-boot:build-image -DskipTests \
                        -Dspring-boot.build-image.imageName=${DOCKER_IMAGE}:${tag}
                    """
                    
                    // Also tag with commit SHA
                    sh "docker tag ${DOCKER_IMAGE}:${tag} ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                        
                        def tag = env.GIT_BRANCH_NAME == 'main' ? 'latest' : env.GIT_BRANCH_NAME
                        sh "docker push ${DOCKER_IMAGE}:${tag}"
                        sh "docker push ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}"
                    }
                }
            }
        }
        
        stage('Update GitOps Repository') {
            when {
                anyOf {
                    branch 'staging'
                    branch 'main'
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        def gitRepo = env.GIT_BRANCH_NAME == 'main' ? env.GIT_PROD_REPO : env.GIT_STAGING_REPO
                        def imagePath = env.GIT_BRANCH_NAME == 'main' ? 
                            'k8s/overlays/production/deployment-patch.yaml' : 
                            'k8s/overlays/staging/deployment-patch.yaml'
                        def imageTag = env.GIT_BRANCH_NAME == 'main' ? 'latest' : 'staging'
                        
                        sh """
                            git config --global user.email "jenkins@devops.local"
                            git config --global user.name "Jenkins CI"
                            
                            rm -rf gitops-tmp
                            git clone https://${GIT_USER}:${GIT_TOKEN}@${gitRepo.replace('https://', '')} gitops-tmp
                            cd gitops-tmp
                            
                            # Update image tag
                            sed -i "s|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}|g" ${imagePath}
                            
                            git add .
                            git commit -m "Update image to ${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}" || true
                            git push origin main
                        """
                    }
                }
            }
        }
        
        stage('Trigger ArgoCD Sync') {
            when {
                anyOf {
                    branch 'staging'
                    branch 'main'
                }
            }
            steps {
                script {
                    def appName = env.GIT_BRANCH_NAME == 'main' ? 'production' : 'staging'
                    
                    withCredentials([string(credentialsId: 'argocd-admin-token', variable: 'ARGOCD_TOKEN')]) {
                        sh """
                            curl -k -X POST \
                            -H "Authorization: Bearer ${ARGOCD_TOKEN}" \
                            -H "Content-Type: application/json" \
                            https://172.16.10.11:32120/api/v1/applications/${appName}/sync
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
