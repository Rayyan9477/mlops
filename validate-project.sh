#!/bin/bash

# MLOps Application Test Script
# This script validates that all components are properly configured

set -e

echo "=================================="
echo "MLOps Application Validation Script"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "[INFO] $1"
}

echo "1. Checking Project Structure..."
echo "================================"

# Check if all required directories exist
for dir in frontend backend auth-service database k8s; do
    if [ -d "/workspaces/mlops/$dir" ]; then
        pass "Directory $dir exists"
    else
        fail "Directory $dir is missing"
    fi
done

echo ""
echo "2. Checking Frontend Files..."
echo "=============================="

frontend_files=(
    "frontend/Dockerfile"
    "frontend/package.json"
    "frontend/src/App.js"
    "frontend/src/config.js"
    "frontend/src/components/Login.js"
    "frontend/src/components/Signup.js"
    "frontend/src/components/ForgotPassword.js"
    "frontend/src/components/ResetPassword.js"
    "frontend/src/components/Dashboard.js"
    "frontend/nginx.conf"
    "frontend/entrypoint.sh"
)

for file in "${frontend_files[@]}"; do
    if [ -f "/workspaces/mlops/$file" ]; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done

echo ""
echo "3. Checking Backend Files..."
echo "============================="

backend_files=(
    "backend/Dockerfile"
    "backend/package.json"
    "backend/server.js"
    "backend/.env"
)

for file in "${backend_files[@]}"; do
    if [ -f "/workspaces/mlops/$file" ]; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done

echo ""
echo "4. Checking Auth Service Files..."
echo "=================================="

auth_files=(
    "auth-service/Dockerfile"
    "auth-service/package.json"
    "auth-service/server.js"
    "auth-service/.env"
)

for file in "${auth_files[@]}"; do
    if [ -f "/workspaces/mlops/$file" ]; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done

echo ""
echo "5. Checking Docker Configuration..."
echo "===================================="

if [ -f "/workspaces/mlops/docker-compose.yml" ]; then
    pass "docker-compose.yml exists"
else
    fail "docker-compose.yml is missing"
fi

# Check if docker-compose has all services
services=("mongodb" "auth-service" "backend" "frontend")
for service in "${services[@]}"; do
    if grep -q "$service:" /workspaces/mlops/docker-compose.yml; then
        pass "Service $service defined in docker-compose.yml"
    else
        fail "Service $service not found in docker-compose.yml"
    fi
done

echo ""
echo "6. Checking Kubernetes Manifests..."
echo "===================================="

k8s_files=(
    "k8s/mongodb-deployment.yaml"
    "k8s/mongodb-service.yaml"
    "k8s/mongodb-pvc.yaml"
    "k8s/mongodb-configmap.yaml"
    "k8s/auth-service-deployment.yaml"
    "k8s/auth-service-service.yaml"
    "k8s/backend-deployment.yaml"
    "k8s/backend-service.yaml"
    "k8s/frontend-deployment.yaml"
    "k8s/frontend-service.yaml"
    "k8s/secrets.yaml"
)

for file in "${k8s_files[@]}"; do
    if [ -f "/workspaces/mlops/$file" ]; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done

echo ""
echo "7. Verifying Replica Counts..."
echo "==============================="

# Check frontend replicas
frontend_replicas=$(grep "replicas:" /workspaces/mlops/k8s/frontend-deployment.yaml | awk '{print $2}')
if [ "$frontend_replicas" == "3" ]; then
    pass "Frontend has 3 replicas"
else
    fail "Frontend should have 3 replicas, found: $frontend_replicas"
fi

# Check backend replicas
backend_replicas=$(grep "replicas:" /workspaces/mlops/k8s/backend-deployment.yaml | awk '{print $2}')
if [ "$backend_replicas" == "3" ]; then
    pass "Backend has 3 replicas"
else
    fail "Backend should have 3 replicas, found: $backend_replicas"
fi

# Check auth-service replicas
auth_replicas=$(grep "replicas:" /workspaces/mlops/k8s/auth-service-deployment.yaml | awk '{print $2}')
if [ "$auth_replicas" == "3" ]; then
    pass "Auth Service has 3 replicas"
else
    fail "Auth Service should have 3 replicas, found: $auth_replicas"
fi

echo ""
echo "8. Verifying Service Types..."
echo "=============================="

# Check frontend service type (should be NodePort)
if grep -q "type: NodePort" /workspaces/mlops/k8s/frontend-service.yaml; then
    pass "Frontend service is NodePort"
else
    fail "Frontend service should be NodePort"
fi

# Check nodePort value
if grep -q "nodePort: 30000" /workspaces/mlops/k8s/frontend-service.yaml; then
    pass "Frontend NodePort is 30000"
else
    fail "Frontend should use NodePort 30000"
fi

# Check auth service NodePort
if grep -q "nodePort: 30001" /workspaces/mlops/k8s/auth-service-service.yaml; then
    pass "Auth Service NodePort is 30001"
else
    fail "Auth Service should use NodePort 30001"
fi

# Check backend service NodePort
if grep -q "nodePort: 30002" /workspaces/mlops/k8s/backend-service.yaml; then
    pass "Backend Service NodePort is 30002"
else
    fail "Backend Service should use NodePort 30002"
fi

echo ""
echo "9. Checking Documentation..."
echo "============================="

doc_files=(
    "README.md"
    "QUICKSTART.md"
    "ARCHITECTURE.md"
    "TESTING.md"
    "PROJECT_SUMMARY.md"
    "VIDEO_DEMO_SCRIPT.md"
)

for file in "${doc_files[@]}"; do
    if [ -f "/workspaces/mlops/$file" ]; then
        pass "$file exists"
    else
        warn "$file is missing (optional)"
    fi
done

echo ""
echo "10. Checking Automation Scripts..."
echo "==================================="

if [ -f "/workspaces/mlops/deploy-k8s.sh" ] && [ -x "/workspaces/mlops/deploy-k8s.sh" ]; then
    pass "deploy-k8s.sh exists and is executable"
else
    fail "deploy-k8s.sh is missing or not executable"
fi

if [ -f "/workspaces/mlops/cleanup-k8s.sh" ] && [ -x "/workspaces/mlops/cleanup-k8s.sh" ]; then
    pass "cleanup-k8s.sh exists and is executable"
else
    fail "cleanup-k8s.sh is missing or not executable"
fi

echo ""
echo "11. Validating Code Quality..."
echo "==============================="

# Check if frontend uses config.js
if grep -q "from '../config'" /workspaces/mlops/frontend/src/components/Login.js; then
    pass "Frontend components use config.js"
else
    warn "Frontend should use config.js for environment variables"
fi

# Check if auth service has JWT implementation
if grep -q "jsonwebtoken" /workspaces/mlops/auth-service/server.js; then
    pass "Auth service implements JWT"
else
    fail "Auth service should implement JWT"
fi

# Check if backend has token verification
if grep -q "verifyToken" /workspaces/mlops/backend/server.js; then
    pass "Backend has token verification middleware"
else
    fail "Backend should have token verification"
fi

echo ""
echo "=================================="
echo "Validation Summary"
echo "=================================="
echo ""
pass "All critical components are present and properly configured"
echo ""
info "Project Structure: ✓"
info "Frontend Service: ✓"
info "Backend Service: ✓"
info "Auth Service: ✓"
info "Database Config: ✓"
info "Docker Setup: ✓"
info "Kubernetes Manifests: ✓"
info "Replica Configuration: 3 replicas for each service ✓"
info "NodePort Configuration: Frontend (30000), Auth (30001), Backend (30002) ✓"
info "Documentation: ✓"
info "Automation Scripts: ✓"
echo ""
pass "The project is ready for deployment!"
echo ""
echo "Next Steps:"
echo "1. Test with Docker Compose: docker-compose up -d"
echo "2. Deploy to Kubernetes: ./deploy-k8s.sh"
echo "3. Record video demonstration using VIDEO_DEMO_SCRIPT.md"
echo ""
