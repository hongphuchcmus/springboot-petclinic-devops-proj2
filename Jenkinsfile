pipeline {
    agent any

    environment {
        SERVICES = "spring-petclinic-vets-service,spring-petclinic-customers-service,spring-petclinic-visits-service,spring-petclinic-admin-server,spring-petclinic-api-gateway,spring-petclinic-config-server,spring-petclinic-genai-service,spring-petclinic-discovery-server"
    }

    stages {
        stage("Detect Changed Services") {
            steps {
                script {
                    // Fetch lastest main
                    sh 'git fetch origin main'
                    sh 'git branch -a'
                    def changedFiles = sh(script: "git diff --name-only HEAD main", returnStdout: true).trim().split("\n")
                    def affectedServices = []

                    SERVICES.split(',').each { service ->
                        if (changedFiles.find { it.startsWith(service + "/") }) {
                            affectedServices.add(service)
                        }
                    }

                    if (affectedServices.isEmpty()) {
                        echo "No services changed. Skipping build."
                        currentBuild.result = "SUCCESS"
                        return
                    }

                    env.BUILD_SERVICES = affectedServices.join(',')
                }
            }
        }

        stage("Login to Docker Hub") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        env.REPOSITORY_PREFIX = DOCKER_USER
                        sh "echo \"$DOCKER_PASS\" | docker login -u \"$DOCKER_USER\" --password-stdin"
                    }
                }
            }
        }

        stage("Docker Build") {
            when {
                expression { return env.BUILD_SERVICES?.trim() }
            }
            steps {
                script {
                    def commitId = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.VERSION = commitId
                    
                    env.BUILD_SERVICES.split(',').each { service ->
                        dir(service) {
                            // As PREPOSITORY_PREFIX is set to this docker user,
                            // the images prefixes would all be "$DOCKER_USER" instead
                            // of "springcommunity" as default
                            sh "../mvnw clean install -P buildDocker"
                        }
                    }
                }
            }
        }

        stage("Tag & Push Images") {
            steps {
                script {
                    env.BUILD_SERVICES.split(',').each { service ->
                        sh "docker tag $REPOSITORY_PREFIX/${service} $REPOSITORY_PREFIX/${service}:${VERSION}"
                        sh "docker push $REPOSITORY_PREFIX/${service}:${VERSION}"
                    }
                }
            }
        }
    }
}
