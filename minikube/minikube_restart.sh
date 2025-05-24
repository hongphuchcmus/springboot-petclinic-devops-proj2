minikube delete
sleep 5
minikube start --addons=ingress
sleep 10
chmod 640 ~/.minikube/profiles/minikube/client.key
./helm/scripts/deploy_all.sh
