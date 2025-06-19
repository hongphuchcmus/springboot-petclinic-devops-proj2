#!/bin/bash

echo "Upgrading all services using Helm ..."

# List of service names
services=(
  config-server
  discovery-server
  admin-server
  vets-service
  customers-service
  visits-service
  api-gateway
  tracing-server
  grafana
  prometheus
)

# Loop over each service
for service in "${services[@]}"; do
  echo "Upgrading $service ..."
  helm upgrade "$service" helm/spring-petclinic-chart -f "helm/spring-petclinic-chart/values-$service.yaml"
  echo "Done"
done

echo "Upgrading alloy ..."
helm upgrade alloy grafana/alloy -f helm/spring-petclinic-chart/config-alloy.yaml
echo "Done."