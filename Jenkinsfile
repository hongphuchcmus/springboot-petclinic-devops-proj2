pipeline {
    agent any

    environment {
        MINIKUBE_HOME = "/opt/minikube-jenkins"
        SERVICES = "spring-petclinic-vets-service,spring-petclinic-customers-service,spring-petclinic-visits-service,spring-petclinic-admin-server,spring-petclinic-api-gateway,spring-petclinic-config-server,spring-petclinic-genai-service,spring-petclinic-discovery-server"
    }

    stages {
        stage("Detect Changed Services") {
            steps {
                script {
                    sh 'git fetch origin main:refs/remotes/origin/main'
                    sh 'git branch -a'
                    def changedFiles = sh(script: "git diff --name-only origin/main...", returnStdout: true).trim().split("\n")
                    def affectedServices = []

                    env.SERVICES.split(',').each { service ->
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
                        sh "docker tag springcommunity/${service} ${env.REPOSITORY_PREFIX}/${service}:${env.VERSION}"
                        sh "docker push ${env.REPOSITORY_PREFIX}/${service}:${env.VERSION}"
                    }
                }
            }
        }

        stage("Deploy to Minikube") {
            steps {
                script {
                    // Ensure MINIKUBE_HOME exists and is accessible
                    sh """
                        mkdir -p ${env.MINIKUBE_HOME}
                        chmod -R u+wrx ${env.MINIKUBE_HOME}
                    """

                    // Connect to Minikube Docker daemon
                    sh "eval \$(minikube -p minikube docker-env)"

                    // Ensure Minikube is running
                    def minikubeStatus = sh(script: "minikube -p minikube status --format '{{.Host}}'", returnStdout: true).trim()
                    if (minikubeStatus != "Running") {
                        echo "Minikube not running. Starting..."
                        sh "minikube -p minikube start"
                    } else {
                        echo "Minikube is already running."
                    }

                    env.BUILD_SERVICES.split(',').each { service ->
                        def serviceName = service.replaceFirst("spring-petclinic-", "")
                        def chartPath = "helm/spring-petclinic-chart"
                        def valuesFile = "${chartPath}/values-${serviceName}.yaml"

                        echo "Pulling image ${env.REPOSITORY_PREFIX}/${service}:${env.VERSION}"
                        sh "docker pull ${env.REPOSITORY_PREFIX}/${service}:${env.VERSION}"

                        // Check if Helm release exists
                        def releaseExists = sh(script: "helm list -q | grep -w ${serviceName} || true", returnStdout: true).trim()
                        if (releaseExists) {
                            echo "Helm release '${serviceName}' found. Performing upgrade..."
                            sh """
                                helm upgrade "${serviceName}" ${chartPath} \
                                -f "${valuesFile}" --set image.tag=${env.VERSION}
                            """
                        } else {
                            echo "Helm release '${serviceName}' not found. Installing..."
                            sh """
                                helm install "${serviceName}" ${chartPath} \
                                -f "${valuesFile}" --set image.tag=${env.VERSION}
                            """
                        }

                        // Wait until pod is running
                        sh """
                            echo "Waiting for pod of service ${serviceName} to be running..."
                            kubectl wait --for=condition=ready pod -l app=${serviceName} --timeout=120s
                        """
                    }
                }
            }
        }
    }
}
