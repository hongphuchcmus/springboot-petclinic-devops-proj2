minikube ssh -- sudo find /var/log/pods -type d -exec chmod a+rx {} +
minikube ssh -- sudo find /var/log/pods -type f -exec chmod a+r {} +