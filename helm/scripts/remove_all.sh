#!/bin/bash

echo "Removing all services using Helm ..."

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

# Loop over each service
for service in "${services[@]}"; do
  echo "Removing $service ..."
  helm uninstall "$service"
  echo "Done"
done
