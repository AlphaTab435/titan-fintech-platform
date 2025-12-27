#!/bin/bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add Repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Stack
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Wait instruction
echo "Wait for pods to start, then run:"
echo "kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "Get Password command:"
echo 'kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo'