#!/bin/bash
CONFIG_FILE="namespace.conf"
DATAHUB_NAMESPACE=datahub-ns
TIMEOUT=15m0s

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

# First loop: Create all namespaces
declare -A namespace_created
while IFS=',' read -r namespace path chart; do
  # Check if the namespace has already been processed
  if [ -z "${namespace_created[$namespace]}" ]; then
    kubectl get namespace "$namespace" &> /dev/null || kubectl create namespace "$namespace"
    namespace_created[$namespace]=1
  fi
done < "$CONFIG_FILE"

# Create required secrets
kubectl get secret mysql-secrets -n $DATAHUB_NAMESPACE &> /dev/null || kubectl create secret generic mysql-secrets --from-literal=mysql-root-password='datahub' -n $DATAHUB_NAMESPACE
[ ! -z $OPENAI_KEY ] && kubectl create secret generic openai-secret --from-literal=openai-key=${OPENAI_KEY} --namespace=langchain-chatbot-denodo-ns

# Second loop: Deploy Helm charts
while IFS=',' read -r namespace path chart; do
  # Deploy the specified Helm chart to the namespace
  helm install "$chart" "$path" -n "$namespace" --timeout $TIMEOUT
done < "$CONFIG_FILE"



