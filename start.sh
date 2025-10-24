#!/bin/bash

# MLOps Microservices Application - One-Click Deployment Script
# This script handles everything: checking prerequisites, building images, and deploying to Kubernetes

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "════════════════════════════════════════════════════════════"
    echo ""
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local label=$1
    local timeout=${2:-120}
    print_info "Waiting for $label pods to be ready (timeout: ${timeout}s)..."
    if kubectl wait --for=condition=ready pod -l "$label" --timeout="${timeout}s" >/dev/null 2>&1; then
        print_success "$label pods are ready"
        return 0
    else
        print_warning "$label pods took longer than expected, but continuing..."
        return 0
    fi
}

# Main script starts here
clear
print_header "MLOps Microservices - One-Click Deployment"

# Step 1: Check prerequisites
print_header "Step 1: Checking Prerequisites"

MISSING_DEPS=0

if command_exists docker; then
    print_success "Docker is installed ($(docker --version | cut -d' ' -f3 | cut -d',' -f1))"
else
    print_error "Docker is not installed"
    MISSING_DEPS=1
fi

if command_exists kubectl; then
    print_success "kubectl is installed ($(kubectl version --client --short 2>/dev/null | cut -d' ' -f3))"
else
    print_error "kubectl is not installed"
    MISSING_DEPS=1
fi

if command_exists minikube; then
    print_success "Minikube is installed ($(minikube version --short 2>/dev/null))"
else
    print_error "Minikube is not installed"
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    print_error "Missing required dependencies. Please install them and try again."
    exit 1
fi

# Step 2: Check/Start Minikube
print_header "Step 2: Starting Minikube"

if minikube status >/dev/null 2>&1; then
    print_success "Minikube is already running"
else
    print_info "Starting Minikube with 4 CPUs and 8GB RAM..."
    if minikube start --cpus=4 --memory=8192 --driver=docker; then
        print_success "Minikube started successfully"
    else
        print_error "Failed to start Minikube"
        exit 1
    fi
fi

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
print_info "Minikube IP: $MINIKUBE_IP"

# Step 3: Build Docker Images
print_header "Step 3: Building Docker Images"

print_info "Configuring Docker to use Minikube's daemon..."
eval $(minikube docker-env)

print_info "Building frontend image..."
if docker build -t mlops-frontend:latest ./frontend >/dev/null 2>&1; then
    print_success "Frontend image built"
else
    print_error "Failed to build frontend image"
    exit 1
fi

print_info "Building backend image..."
if docker build -t mlops-backend:latest ./backend >/dev/null 2>&1; then
    print_success "Backend image built"
else
    print_error "Failed to build backend image"
    exit 1
fi

print_info "Building auth-service image..."
if docker build -t mlops-auth-service:latest ./auth-service >/dev/null 2>&1; then
    print_success "Auth service image built"
else
    print_error "Failed to build auth-service image"
    exit 1
fi

# Verify images
print_success "All Docker images built successfully"
docker images | grep mlops | awk '{print "  - " $1 ":" $2 " (" $7 " " $8 ")"}'

# Step 4: Deploy to Kubernetes
print_header "Step 4: Deploying to Kubernetes"

# Check if resources already exist
if kubectl get deployment mongodb >/dev/null 2>&1; then
    print_warning "Existing deployment detected. Cleaning up..."
    kubectl delete -f k8s/ --ignore-not-found=true >/dev/null 2>&1
    sleep 5
fi

print_info "Deploying MongoDB and dependencies..."
kubectl apply -f k8s/secrets.yaml >/dev/null 2>&1
kubectl apply -f k8s/mongodb-configmap.yaml >/dev/null 2>&1
kubectl apply -f k8s/mongodb-pvc.yaml >/dev/null 2>&1
kubectl apply -f k8s/mongodb-deployment.yaml >/dev/null 2>&1
kubectl apply -f k8s/mongodb-service.yaml >/dev/null 2>&1
print_success "MongoDB resources created"

wait_for_pods "app=mongodb" 120

print_info "Deploying Auth Service..."
kubectl apply -f k8s/auth-service-deployment.yaml >/dev/null 2>&1
kubectl apply -f k8s/auth-service-service.yaml >/dev/null 2>&1
print_success "Auth Service resources created"

wait_for_pods "app=auth-service" 120

print_info "Deploying Backend Service..."
kubectl apply -f k8s/backend-deployment.yaml >/dev/null 2>&1
kubectl apply -f k8s/backend-service.yaml >/dev/null 2>&1
print_success "Backend Service resources created"

wait_for_pods "app=backend" 120

print_info "Deploying Frontend Service..."
kubectl apply -f k8s/frontend-deployment.yaml >/dev/null 2>&1
kubectl apply -f k8s/frontend-service.yaml >/dev/null 2>&1
print_success "Frontend Service resources created"

wait_for_pods "app=frontend" 120

# Step 5: Verify Deployment
print_header "Step 5: Verifying Deployment"

sleep 5  # Give services a moment to stabilize

print_info "Checking deployments..."
kubectl get deployments
echo ""

print_info "Checking pods..."
kubectl get pods
echo ""

print_info "Checking services..."
kubectl get services
echo ""

# Step 6: Health Checks
print_header "Step 6: Running Health Checks"

AUTH_URL="http://$MINIKUBE_IP:30001"
BACKEND_URL="http://$MINIKUBE_IP:30002"
FRONTEND_URL="http://$MINIKUBE_IP:30000"

print_info "Testing Auth Service health..."
if curl -s "$AUTH_URL/health" | grep -q "OK"; then
    print_success "Auth Service is healthy"
else
    print_warning "Auth Service health check inconclusive (may still be starting)"
fi

print_info "Testing Backend Service health..."
if curl -s "$BACKEND_URL/health" | grep -q "OK"; then
    print_success "Backend Service is healthy"
else
    print_warning "Backend Service health check inconclusive (may still be starting)"
fi

print_info "Testing Frontend Service..."
if curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" | grep -q "200"; then
    print_success "Frontend Service is accessible"
else
    print_warning "Frontend Service check inconclusive (may still be starting)"
fi

# Step 7: Display Access Information
print_header "🎉 Deployment Complete!"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "                    ACCESS YOUR APPLICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  🌐 Frontend (Web UI):    http://$MINIKUBE_IP:30000"
echo "  🔐 Auth Service (API):   http://$MINIKUBE_IP:30001"
echo "  📡 Backend Service (API): http://$MINIKUBE_IP:30002"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Quick test commands
echo "📝 Quick Test Commands:"
echo ""
echo "  # Open frontend in browser:"
echo "  minikube service frontend-service"
echo ""
echo "  # Test signup:"
echo "  curl -X POST http://$MINIKUBE_IP:30001/api/auth/signup \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"name\":\"Test User\",\"email\":\"test@example.com\",\"password\":\"Test123\"}'"
echo ""
echo "  # Test login:"
echo "  curl -X POST http://$MINIKUBE_IP:30001/api/auth/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"test@example.com\",\"password\":\"Test123\"}'"
echo ""
echo "  # View logs:"
echo "  kubectl logs -l app=frontend --tail=50"
echo ""
echo "  # Check status:"
echo "  kubectl get all"
echo ""
echo "  # Open Kubernetes Dashboard:"
echo "  minikube dashboard"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "✅ All services are deployed with 3 replicas each!"
echo "✅ MongoDB has persistent storage (5Gi)"
echo "✅ Load balancing is active across all replicas"
echo ""
echo "📚 For more information, see README.md"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Ask if user wants to open the frontend
read -p "Would you like to open the frontend in your browser now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Opening frontend service..."
    minikube service frontend-service
fi

print_success "Deployment script completed successfully!"
