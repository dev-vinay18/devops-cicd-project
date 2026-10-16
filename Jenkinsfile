pipeline {
    agent any

    environment {
        IMAGE_NAME = 'vinayw123/static-site'
        // Jenkins credential (Username with password) holding the Docker Hub login
        DOCKERHUB  = credentials('dockerhub-cred')
        REPO_URL   = 'https://github.com/dev-vinay18/devops-cicd-project.git'
        // Elastic IP from `terraform output public_ip`
        EC2_HOST   = '13.201.20.175'
    }

    triggers {
        // Fires when the GitHub webhook calls /github-webhook/
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${REPO_URL}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$BUILD_NUMBER -t $IMAGE_NAME:latest .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh 'echo $DOCKERHUB_PSW | docker login -u $DOCKERHUB_USR --password-stdin'
                sh 'docker push $IMAGE_NAME:$BUILD_NUMBER'
                sh 'docker push $IMAGE_NAME:latest'
            }
        }

        stage('Deploy to EC2') {
            steps {
                // Needs the "SSH Agent" plugin and an SSH credential with ID ec2-ssh-key
                sshagent(credentials: ['ec2-ssh-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ec2-user@$EC2_HOST "
                          sudo docker pull $IMAGE_NAME:latest &&
                          (sudo docker rm -f static-site || true) &&
                          sudo docker run -d --name static-site --restart always -p 80:80 $IMAGE_NAME:latest
                        "
                    '''
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'sleep 5 && curl -fsS http://$EC2_HOST/ > /dev/null'
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
    }
}
