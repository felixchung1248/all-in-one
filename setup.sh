#!/bin/bash
echo current user: $USER
echo home path: $HOME
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install K8s
sudo snap install microk8s --classic
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Run the microk8s commands with the new group using sg
sg microk8s -c "microk8s enable dashboard dns ingress"
sg microk8s -c "microk8s start"
sg microk8s -c "microk8s enable hostpath-storage"
sg microk8s -c "microk8s config > $HOME/.kube/config"

# Create the namespace if it doesn't exist
kubectl get namespace datahub-ns &> /dev/null || kubectl create namespace datahub-ns
kubectl get namespace denodo-ns &> /dev/null || kubectl create namespace denodo-ns
kubectl get namespace spinnaker-ns &> /dev/null || kubectl create namespace spinnaker-ns
kubectl get namespace mariadb-ns &> /dev/null || kubectl create namespace mariadb-ns
kubectl get namespace minio-ns &> /dev/null || kubectl create namespace minio-ns
kubectl get namespace zammad-ns &> /dev/null || kubectl create namespace zammad-ns


helm install datahub-prerequisites ./demo/datahub-prerequisites -n datahub-ns
helm install denodo ./demo/denodo -n denodo-ns
helm install spinnaker ./demo/spinnaker -n spinnaker-ns
helm install mariadb ./demo/mariadb -n mariadb-ns
helm install minio ./demo/minio -n minio-ns
helm install zammad ./demo/zammad -n zammad-ns

