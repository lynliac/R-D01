pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
  }

  environment {
    REGISTRY        = 'docker.io'
    DOCKERHUB_NS    = 'your-dockerhub-namespace'   // TODO: change to your Docker Hub namespace
    APP_NAME        = 'node-chat-app'
    IMAGE           = "${env.DOCKERHUB_NS}/${env.APP_NAME}"
    COMMIT_SHA      = "${env.GIT_COMMIT?.take(7) ?: 'local'}"
    IMAGE_TAG       = "${env.BUILD_NUMBER}-${env.COMMIT_SHA}"
    APP_SERVER_IP   = 'YOUR.SERVER.IP.HERE'        // TODO: change to your server IP
    REMOTE_DEPLOY_DIR = '/opt/chatapp'
  }

  parameters {
    string(name: 'DOCKERHUB_NS', defaultValue: 'your-dockerhub-namespace', description: 'Docker Hub namespace/org')
    string(name: 'APP_SERVER_IP', defaultValue: 'YOUR.SERVER.IP.HERE', description: 'App server IP (for deployment)')
    string(name: 'REMOTE_DEPLOY_DIR', defaultValue: '/opt/chatapp', description: 'Remote path with docker-compose.yml')
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }

    stage('Cloning Git') {
      steps {
        sh '''
          echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
          echo "Commit: $(git rev-parse --short HEAD)"
          git log -1 --oneline
        '''
      }
    }

    stage('BUILD-AND-TAG') {
      steps {
        sh '''
          echo "Building image: ${IMAGE}:${IMAGE_TAG}"
          docker build -t ${IMAGE}:${IMAGE_TAG} -t ${IMAGE}:latest .
        '''
      }
    }

    stage('POST-TO-DOCKERHUB') {
      environment {
        DOCKERHUB_CREDS = credentials('dockerhub-creds') // create in Jenkins
      }
      steps {
        sh '''
          echo "Logging into Docker Hub"
          echo "${DOCKERHUB_CREDS_PSW}" | docker login -u "${DOCKERHUB_CREDS_USR}" --password-stdin ${REGISTRY}
          docker push ${IMAGE}:${IMAGE_TAG}
          docker push ${IMAGE}:latest
          docker logout ${REGISTRY}
        '''
      }
    }

    stage('DEPLOYMENT') {
      steps {
        sshagent(credentials: ['appserver-ssh']) {
          sh '''
            set -e
            echo "Deploying to ${APP_SERVER_IP} ..."
            ssh -o StrictHostKeyChecking=no ubuntu@${APP_SERVER_IP} "mkdir -p ${REMOTE_DEPLOY_DIR}"
            ssh -o StrictHostKeyChecking=no ubuntu@${APP_SERVER_IP}               "cd ${REMOTE_DEPLOY_DIR} &&                export IMAGE=${IMAGE} && export IMAGE_TAG=${IMAGE_TAG} &&                docker login -u '${DOCKERHUB_CREDS_USR}' -p '${DOCKERHUB_CREDS_PSW}' ${REGISTRY} &&                docker compose pull && docker compose up -d &&                docker image prune -f"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Deployed ${IMAGE}:${IMAGE_TAG} to ${APP_SERVER_IP}"
    }
  }
}
