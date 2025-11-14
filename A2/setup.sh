#!/bin/bash

###############################################################################
# NASA APOD ETL Pipeline - Setup and Deployment Script
# 
# This script automates the setup and deployment of the complete MLOps pipeline
# including Airflow, PostgreSQL, DVC, and Git configuration.
#
# Author: MLOps Team
# Date: November 13, 2025
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
print_header "Checking Prerequisites"

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi
print_success "Docker is installed"

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi
print_success "Docker Compose is installed"

if ! command -v git &> /dev/null; then
    print_warning "Git is not installed. Some features may not work."
else
    print_success "Git is installed"
fi

# Navigate to project directory
print_header "Setting Up Project Directory"
cd "$(dirname "$0")"
PROJECT_DIR=$(pwd)
echo "Project directory: $PROJECT_DIR"

# Create necessary directories
print_header "Creating Directory Structure"
mkdir -p dags logs plugins data dvc-remote postgres-init
print_success "Directories created"

# Check if .env file exists
print_header "Configuring Environment Variables"
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        print_success "Created .env file from .env.example"
        print_warning "Please review and update .env file with your configuration"
    else
        print_error ".env.example not found. Creating default .env file..."
        cat > .env << EOF
AIRFLOW_UID=$(id -u)
AIRFLOW_GID=0
AIRFLOW_PROJ_DIR=.
_AIRFLOW_WWW_USER_USERNAME=admin
_AIRFLOW_WWW_USER_PASSWORD=admin
POSTGRES_USER=airflow
POSTGRES_PASSWORD=airflow
POSTGRES_DB=airflow
EOF
        print_success "Created default .env file"
    fi
else
    print_success ".env file already exists"
fi

# Set proper permissions
print_header "Setting Permissions"
chmod -R 755 dags logs plugins data dvc-remote
print_success "Permissions set"

# Stop any running containers
print_header "Cleaning Up Previous Containers"
if docker-compose ps | grep -q "Up"; then
    print_warning "Stopping existing containers..."
    docker-compose down
    print_success "Containers stopped"
else
    print_success "No running containers found"
fi

# Build Docker images
print_header "Building Docker Images"
docker-compose build --no-cache
print_success "Docker images built successfully"

# Start PostgreSQL first
print_header "Starting PostgreSQL Database"
docker-compose up -d postgres
print_success "PostgreSQL started"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
sleep 15

# Check PostgreSQL health
if docker-compose exec -T postgres pg_isready -U airflow > /dev/null 2>&1; then
    print_success "PostgreSQL is ready"
else
    print_error "PostgreSQL is not responding. Please check logs."
    docker-compose logs postgres
    exit 1
fi

# Initialize Airflow
print_header "Initializing Airflow"
docker-compose up airflow-init
print_success "Airflow initialized"

# Start all services
print_header "Starting All Services"
docker-compose up -d
print_success "All services started"

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 20

# Check service status
print_header "Checking Service Status"
docker-compose ps

# Initialize Git repository
print_header "Initializing Git Repository"
if [ ! -d .git ]; then
    git init
    git config user.name "MLOps Pipeline"
    git config user.email "mlops@example.com"
    print_success "Git repository initialized"
else
    print_success "Git repository already exists"
fi

# Initialize DVC
print_header "Initializing DVC"
docker-compose exec -T airflow-webserver bash -c "
    cd /opt/airflow && \
    if [ ! -d .dvc ]; then
        dvc init --no-scm && \
        dvc remote add -d local /opt/airflow/dvc-remote && \
        dvc config core.autostage true && \
        echo 'DVC initialized successfully'
    else
        echo 'DVC already initialized'
    fi
" || print_warning "DVC initialization will be completed on first DAG run"

# Display access information
print_header "Deployment Complete!"
echo ""
echo "Access Information:"
echo "==================="
echo "Airflow Web UI: http://localhost:8080"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "PostgreSQL:"
echo "Host: localhost"
echo "Port: 5432"
echo "Database: airflow"
echo "Username: airflow"
echo "Password: airflow"
echo ""
echo "Useful Commands:"
echo "================"
echo "View logs:           docker-compose logs -f"
echo "Stop services:       docker-compose down"
echo "Restart services:    docker-compose restart"
echo "View DAG status:     docker-compose exec airflow-webserver airflow dags list"
echo "Trigger DAG:         docker-compose exec airflow-webserver airflow dags trigger nasa_apod_etl_pipeline"
echo ""
print_success "Setup completed successfully!"
echo ""
print_warning "Please wait 1-2 minutes for all services to fully start before accessing the web UI"
