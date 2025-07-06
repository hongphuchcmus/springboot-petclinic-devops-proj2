#!/bin/bash

echo "Deploying all services using Helm ..."

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
  loki
)

# Create namespaces
echo "Create namespaces ..."
kubectl create namespace monitoring
kubectl create namespace tracing
echo "Done."

# Loop over each service
for service in "${services[@]}"; do
  echo "Deploying $service ..."
  helm install "$service" helm/spring-petclinic-chart -f "helm/spring-petclinic-chart/values-$service.yaml" --create-namespace
  echo "Done."
done

# Add grafana repo 
if ! helm repo list | grep -p grafana; then
  echo "Adding grafana repo ..."
  helm repo add grafana https://grafana.github.io/helm-charts
  echo "Done." 
fi

# Deploy alloy (alloy didn't work when using images)
echo "Deploying alloy ..."
helm install alloy grafana/alloy -f helm/spring-petclinic-chart/config-alloy.yaml -n monitoring
echo "Done."