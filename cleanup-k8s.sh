#!/bin/bash

# MLOps Kubernetes Cleanup Script
# This script removes all deployed resources from Minikube

set -e

echo "=================================="
echo "MLOps Kubernetes Cleanup Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Confirm deletion
read -p "Are you sure you want to delete all resources? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Cleanup cancelled"
    exit 0
fi

echo ""
echo "Deleting Kubernetes resources..."

# Delete deployments
echo "Deleting deployments..."
kubectl delete -f k8s/frontend-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/backend-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/auth-service-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/mongodb-deployment.yaml --ignore-not-found=true
print_status "Deployments deleted"

# Delete services
echo "Deleting services..."
kubectl delete -f k8s/frontend-service.yaml --ignore-not-found=true
kubectl delete -f k8s/backend-service.yaml --ignore-not-found=true
kubectl delete -f k8s/auth-service-service.yaml --ignore-not-found=true
kubectl delete -f k8s/mongodb-service.yaml --ignore-not-found=true
print_status "Services deleted"

# Delete ConfigMaps and Secrets
echo "Deleting ConfigMaps and Secrets..."
kubectl delete -f k8s/mongodb-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/secrets.yaml --ignore-not-found=true
print_status "ConfigMaps and Secrets deleted"

# Delete PVC
echo "Deleting PVC..."
kubectl delete -f k8s/mongodb-pvc.yaml --ignore-not-found=true
print_status "PVC deleted"

echo ""
print_status "All resources cleaned up successfully!"

# Ask if user wants to stop Minikube
echo ""
read -p "Do you want to stop Minikube? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube stop
    print_status "Minikube stopped"
fi

echo ""
echo "Cleanup complete!"
