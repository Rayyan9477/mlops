#!/bin/bash

# MLOps Kubernetes Deployment Script
# This script automates the deployment of all services to Minikube

set -e  # Exit on error

echo "=================================="
echo "MLOps Kubernetes Deployment Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if Minikube is running
echo "Checking Minikube status..."
if ! minikube status &> /dev/null; then
    print_warning "Minikube is not running. Starting Minikube..."
    minikube start --cpus=4 --memory=8192 --driver=docker
    print_status "Minikube started successfully"
else
    print_status "Minikube is already running"
fi

# Configure Docker environment to use Minikube's Docker daemon
echo ""
echo "Configuring Docker environment..."
eval $(minikube docker-env)
print_status "Docker environment configured to use Minikube"

# Build Docker images
echo ""
echo "Building Docker images..."
echo "This may take several minutes..."

echo "Building frontend image..."
docker build -t mlops-frontend:latest ./frontend
print_status "Frontend image built"

echo "Building backend image..."
docker build -t mlops-backend:latest ./backend
print_status "Backend image built"

echo "Building auth-service image..."
docker build -t mlops-auth-service:latest ./auth-service
print_status "Auth-service image built"

# Verify images
echo ""
echo "Verifying images..."
docker images | grep mlops
print_status "All images built successfully"

# Deploy to Kubernetes
echo ""
echo "Deploying to Kubernetes..."

# Deploy MongoDB components
echo ""
echo "Deploying MongoDB..."
kubectl apply -f k8s/mongodb-pvc.yaml
kubectl apply -f k8s/mongodb-configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml
print_status "MongoDB deployment created"

# Wait for MongoDB to be ready
echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=180s
print_status "MongoDB is ready"

# Deploy Auth Service
echo ""
echo "Deploying Auth Service..."
kubectl apply -f k8s/auth-service-deployment.yaml
kubectl apply -f k8s/auth-service-service.yaml
print_status "Auth Service deployment created"

# Wait for Auth Service
echo "Waiting for Auth Service to be ready..."
kubectl wait --for=condition=ready pod -l app=auth-service --timeout=180s
print_status "Auth Service is ready"

# Deploy Backend Service
echo ""
echo "Deploying Backend Service..."
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
print_status "Backend Service deployment created"

# Wait for Backend
echo "Waiting for Backend Service to be ready..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=180s
print_status "Backend Service is ready"

# Deploy Frontend Service
echo ""
echo "Deploying Frontend Service..."
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
print_status "Frontend Service deployment created"

# Wait for Frontend
echo "Waiting for Frontend Service to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend --timeout=180s
print_status "Frontend Service is ready"

# Display deployment status
echo ""
echo "=================================="
echo "Deployment Status"
echo "=================================="
echo ""

echo "Pods:"
kubectl get pods
echo ""

echo "Services:"
kubectl get services
echo ""

echo "Deployments:"
kubectl get deployments
echo ""

# Get application URL
echo "=================================="
echo "Application Access Information"
echo "=================================="
echo ""

MINIKUBE_IP=$(minikube ip)
print_status "Minikube IP: $MINIKUBE_IP"

echo ""
echo "Application URLs:"
echo "  Frontend:     http://$MINIKUBE_IP:30000"
echo "  Auth Service: http://$MINIKUBE_IP:30001"
echo "  Backend:      http://$MINIKUBE_IP:30002"
echo ""
echo "Or use: minikube service frontend-service"
echo ""

print_status "Deployment completed successfully!"
echo ""
echo "To access the application, run:"
echo "  minikube service frontend-service"
echo ""
echo "To view logs:"
echo "  kubectl logs -l app=frontend"
echo "  kubectl logs -l app=backend"
echo "  kubectl logs -l app=auth-service"
echo ""
echo "To check pod status:"
echo "  kubectl get pods"
echo ""
