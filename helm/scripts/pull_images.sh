#!/bin/bash
# Pull images directly onto Minikube

echo "Pulling images onto Minikube"

# List of service names
services=(
  config-server
  discovery-server
  admin-server
  vets-service
  customers-service
  visits-service
  api-gateway
)
# Prefix
prefix=hongphuchcmus
# Image Prefix
image_prefix=spring-petclinic

# Change docker to minikube's
eval $(minikube -p minikube docker-env)

# Loop over each service
for service in "${services[@]}"; do
  echo "Pulling $prefix/$image_prefix-$service ..."
  docker pull "$prefix/$image_prefix-$service"
  echo "Done"
done
