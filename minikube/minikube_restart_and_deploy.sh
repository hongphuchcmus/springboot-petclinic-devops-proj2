minikube delete
sleep 5
minikube start --addons=ingress --cpus=3 --memory=6144
sleep 10
chmod 640 ~/.minikube/profiles/minikube/client.key
./helm/scripts/deploy_all.sh
