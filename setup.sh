#!/bin/bash
DATAHUB_NAMESPACE=datahub-ns
DENODO_NAMESPACE=denodo-ns
JENKINS_NAMESPACE=jenkins-ns
MARIADB_NAMESPACE=mariadb-ns
MINIO_NAMESPACE=minio-ns
ZAMMAD_NAMESPACE=zammad-ns

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
kubectl get namespace $DATAHUB_NAMESPACE &> /dev/null || kubectl create namespace $DATAHUB_NAMESPACE
kubectl get namespace $DENODO_NAMESPACE &> /dev/null || kubectl create namespace $DENODO_NAMESPACE
kubectl get namespace $JENKINS_NAMESPACE &> /dev/null || kubectl create namespace $JENKINS_NAMESPACE
kubectl get namespace $MARIADB_NAMESPACE &> /dev/null || kubectl create namespace $MARIADB_NAMESPACE
kubectl get namespace $MINIO_NAMESPACE &> /dev/null || kubectl create namespace $MINIO_NAMESPACE
kubectl get namespace $ZAMMAD_NAMESPACE &> /dev/null || kubectl create namespace $ZAMMAD_NAMESPACE

# Create required secrets
kubectl get secret mysql-secrets -n $DATAHUB_NAMESPACE &> /dev/null || kubectl create secret generic mysql-secrets --from-literal=mysql-root-password='datahub' -n $DATAHUB_NAMESPACE


helm install datahub-prerequisites ./demo/datahub-prerequisites -n $DATAHUB_NAMESPACE
helm install denodo ./demo/denodo -n $DENODO_NAMESPACE
helm install jenkins ./demo/jenkins -n $JENKINS_NAMESPACE
helm install mariadb ./demo/mariadb -n $MARIADB_NAMESPACE
helm install minio ./demo/minio -n $MINIO_NAMESPACE
helm install zammad ./demo/zammad -n $ZAMMAD_NAMESPACE
helm install datahub ./demo/datahub -n $DATAHUB_NAMESPACE

