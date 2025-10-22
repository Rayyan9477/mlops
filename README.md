# MLOps Microservices Application

A full-stack microservices application with frontend, backend, authentication service, and database, demonstrating a scalable, modular deployment structure using Docker and Kubernetes.

## 📋 Table of Contents

- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Local Development with Docker Compose](#local-development-with-docker-compose)
- [Kubernetes Deployment on Minikube](#kubernetes-deployment-on-minikube)
- [Access Instructions](#access-instructions)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

## 🏗 Architecture

### Microservices Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         User/Browser                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Frontend Service (React)                  │
│                    - Login/Signup/Forgot Password            │
│                    - Dashboard                               │
│                    - Port: 3000 (Dev) / 80 (Prod)           │
└──────────────────┬───────────────────┬──────────────────────┘
                   │                   │
         ┌─────────▼─────────┐  ┌──────▼──────────┐
         │  Auth Service     │  │  Backend Service │
         │  (Node.js/Express)│  │  (Node.js/Express)│
         │  - Signup         │  │  - User Profile   │
         │  - Login          │  │  - Protected APIs │
         │  - Forgot Password│  │  - Token Verify   │
         │  - JWT Auth       │  │  Port: 5000       │
         │  Port: 5001       │  │                   │
         └─────────┬─────────┘  └──────┬───────────┘
                   │                   │
                   └─────────┬─────────┘
                             │
                   ┌─────────▼─────────┐
                   │  MongoDB Database  │
                   │  - User Collection │
                   │  Port: 27017       │
                   └────────────────────┘
```

### Component Communication

- **Frontend → Auth Service**: User authentication (signup, login, forgot password)
- **Frontend → Backend Service**: Protected API calls for user data
- **Backend Service → Auth Service**: Token verification
- **Auth Service → MongoDB**: User authentication data storage
- **Backend Service → MongoDB**: User profile data retrieval

## 🛠 Technology Stack

### Frontend
- **React** 18.2.0 - UI framework
- **React Router** - Client-side routing
- **Axios** - HTTP client
- **Nginx** - Production web server

### Backend Services
- **Node.js** 18 - Runtime environment
- **Express.js** - Web framework
- **Mongoose** - MongoDB ODM
- **JWT** - Token-based authentication
- **bcryptjs** - Password hashing

### Database
- **MongoDB** 7.0 - NoSQL database

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration
- **Kubernetes** - Container orchestration
- **Minikube** - Local Kubernetes cluster

## ✨ Features

### Authentication Module
- ✅ User Signup with email validation
- ✅ User Login with JWT token generation
- ✅ Forgot Password functionality
- ✅ Password Reset with secure tokens
- ✅ Token-based authentication
- ✅ Protected routes

### User Management
- ✅ User profile retrieval
- ✅ Profile updates
- ✅ User listing

### Infrastructure
- ✅ Microservices architecture
- ✅ Docker containerization
- ✅ Kubernetes deployment with 3 replicas per service
- ✅ Health checks and monitoring
- ✅ Persistent data storage
- ✅ Load balancing

## 📁 Project Structure

```
mlops/
├── frontend/                    # React frontend service
│   ├── public/
│   ├── src/
│   │   ├── components/         # React components
│   │   │   ├── Login.js
│   │   │   ├── Signup.js
│   │   │   ├── ForgotPassword.js
│   │   │   ├── ResetPassword.js
│   │   │   └── Dashboard.js
│   │   ├── App.js
│   │   └── index.js
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── backend/                     # Backend API service
│   ├── server.js
│   ├── Dockerfile
│   ├── package.json
│   └── .env
│
├── auth-service/               # Authentication service
│   ├── server.js
│   ├── Dockerfile
│   ├── package.json
│   └── .env
│
├── database/                   # Database configurations
│   ├── init-mongo.js
│   └── README.md
│
├── k8s/                        # Kubernetes manifests
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── mongodb-pvc.yaml
│   ├── mongodb-configmap.yaml
│   ├── auth-service-deployment.yaml
│   ├── auth-service-service.yaml
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── secrets.yaml
│
├── docker-compose.yml          # Docker Compose configuration
└── README.md                   # This file
```

## 📦 Prerequisites

### Required Software

1. **Docker** (version 20.x or higher)
   ```bash
   docker --version
   ```

2. **Docker Compose** (version 2.x or higher)
   ```bash
   docker-compose --version
   ```

3. **Minikube** (for Kubernetes deployment)
   ```bash
   minikube version
   ```

4. **kubectl** (Kubernetes CLI)
   ```bash
   kubectl version --client
   ```

### Installation Guides

- **Docker**: https://docs.docker.com/get-docker/
- **Minikube**: https://minikube.sigs.k8s.io/docs/start/
- **kubectl**: https://kubernetes.io/docs/tasks/tools/

## 🚀 Local Development with Docker Compose

### Step 1: Clone the Repository

```bash
cd /path/to/your/workspace
```

### Step 2: Build and Start Services

```bash
# Build and start all services in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f
```

### Step 3: Verify Services

```bash
# Check service status
docker-compose ps

# Check health endpoints
curl http://localhost:5000/health  # Backend
curl http://localhost:5001/health  # Auth Service
```

### Step 4: Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **Auth Service**: http://localhost:5001

### Step 5: Stop Services

```bash
# Stop services
docker-compose down

# Stop and remove volumes (clean reset)
docker-compose down -v
```

## ☸️ Kubernetes Deployment on Minikube

### Step 1: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Verify Minikube is running
minikube status
```

### Step 2: Enable Minikube Docker Environment

```bash
# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Verify you're using Minikube's Docker
docker ps
```

### Step 3: Build Docker Images

```bash
# Build all images in Minikube's Docker environment
docker build -t mlops-frontend:latest ./frontend
docker build -t mlops-backend:latest ./backend
docker build -t mlops-auth-service:latest ./auth-service

# Verify images
docker images | grep mlops
```

### Step 4: Deploy to Kubernetes

```bash
# Create namespace (optional)
kubectl create namespace mlops

# Deploy MongoDB with dependencies
kubectl apply -f k8s/mongodb-pvc.yaml
kubectl apply -f k8s/mongodb-configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml

# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=120s

# Deploy Auth Service
kubectl apply -f k8s/auth-service-deployment.yaml
kubectl apply -f k8s/auth-service-service.yaml

# Wait for Auth Service
kubectl wait --for=condition=ready pod -l app=auth-service --timeout=120s

# Deploy Backend Service
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# Wait for Backend
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s

# Deploy Frontend Service
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Wait for Frontend
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s
```

### Step 5: Verify Deployment

```bash
# Check all pods (should see 3 replicas for each service except MongoDB)
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments

# View logs for specific service
kubectl logs -l app=frontend --tail=50
kubectl logs -l app=backend --tail=50
kubectl logs -l app=auth-service --tail=50
```

### Step 6: Access the Application

```bash
# Get the Minikube IP
minikube ip

# Get the NodePort for frontend service
kubectl get service frontend-service

# Access the application
# URL format: http://<minikube-ip>:30000
minikube service frontend-service --url
```

Or open directly in browser:
```bash
minikube service frontend-service
```

### Step 7: Monitor and Debug

```bash
# View all resources
kubectl get all

# Describe a pod for debugging
kubectl describe pod <pod-name>

# View logs for a specific pod
kubectl logs <pod-name>

# Execute commands in a pod
kubectl exec -it <pod-name> -- sh

# Port forward for local testing
kubectl port-forward service/frontend-service 8080:80
kubectl port-forward service/backend-service 5000:5000
kubectl port-forward service/auth-service 5001:5001
```

### Step 8: Scale Deployments (Optional)

```bash
# Scale a deployment
kubectl scale deployment frontend --replicas=5
kubectl scale deployment backend --replicas=5
kubectl scale deployment auth-service --replicas=5

# Verify scaling
kubectl get pods
```

### Step 9: Update Deployment

```bash
# After code changes, rebuild image
eval $(minikube docker-env)
docker build -t mlops-frontend:latest ./frontend

# Restart deployment to use new image
kubectl rollout restart deployment frontend

# Check rollout status
kubectl rollout status deployment frontend
```

### Step 10: Clean Up

```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete individually
kubectl delete deployment frontend backend auth-service mongodb
kubectl delete service frontend-service backend-service auth-service mongodb-service
kubectl delete pvc mongodb-pvc
kubectl delete configmap mongodb-init-script
kubectl delete secret app-secrets

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## 🔐 Access Instructions

### Docker Compose Environment

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | React application |
| Backend API | http://localhost:5000 | Backend REST API |
| Auth Service | http://localhost:5001 | Authentication API |
| MongoDB | localhost:27017 | Database (internal) |

### Kubernetes/Minikube Environment

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# All services are exposed via NodePort for easy access
echo "Frontend:     http://$MINIKUBE_IP:30000"
echo "Auth Service: http://$MINIKUBE_IP:30001"
echo "Backend:      http://$MINIKUBE_IP:30002"

# Or use minikube service command for frontend
minikube service frontend-service

# Access services directly via NodePort (no port-forward needed)
curl http://$MINIKUBE_IP:30001/health  # Auth Service
curl http://$MINIKUBE_IP:30002/health  # Backend Service
```

## 📚 API Documentation

### Authentication Service (Port 5001)

#### POST /api/auth/signup
Create a new user account.

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "User created successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### POST /api/auth/login
Authenticate user and get JWT token.

**Request:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### POST /api/auth/forgot-password
Request password reset email.

**Request:**
```json
{
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "message": "If the email exists, a reset link has been sent"
}
```

#### POST /api/auth/reset-password/:token
Reset password using token.

**Request:**
```json
{
  "password": "newpassword123"
}
```

**Response:**
```json
{
  "message": "Password reset successful"
}
```

#### POST /api/auth/verify
Verify JWT token (used by backend service).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Token is valid",
  "user": {
    "id": "user_id",
    "email": "john@example.com",
    "name": "John Doe"
  }
}
```

### Backend Service (Port 5000)

#### GET /api/users/profile
Get current user profile (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "email": "john@example.com",
  "name": "John Doe",
  "createdAt": "2025-10-22T10:00:00.000Z",
  "updatedAt": "2025-10-22T10:00:00.000Z"
}
```

#### PUT /api/users/profile
Update user profile (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "John Updated"
}
```

**Response:**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "email": "john@example.com",
    "name": "John Updated",
    "updatedAt": "2025-10-22T11:00:00.000Z"
  }
}
```

#### GET /api/users
Get all users (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "email": "john@example.com",
    "name": "John Doe",
    "createdAt": "2025-10-22T10:00:00.000Z"
  }
]
```

## 🐛 Troubleshooting

### Docker Compose Issues

**Problem: Container fails to start**
```bash
# Check logs
docker-compose logs <service-name>

# Restart specific service
docker-compose restart <service-name>

# Rebuild and restart
docker-compose up -d --build <service-name>
```

**Problem: Port already in use**
```bash
# Find process using port
sudo lsof -i :3000  # or :5000, :5001

# Kill process or change port in docker-compose.yml
```

**Problem: Cannot connect to MongoDB**
```bash
# Check MongoDB is running
docker-compose ps mongodb

# Check MongoDB logs
docker-compose logs mongodb

# Restart MongoDB
docker-compose restart mongodb
```

### Kubernetes/Minikube Issues

**Problem: Pods not starting**
```bash
# Describe pod to see events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check if image is available
docker images | grep mlops
```

**Problem: ImagePullBackOff error**
```bash
# Make sure you're using Minikube's Docker daemon
eval $(minikube docker-env)

# Rebuild images
docker build -t mlops-frontend:latest ./frontend
docker build -t mlops-backend:latest ./backend
docker build -t mlops-auth-service:latest ./auth-service

# Verify images are in Minikube
docker images | grep mlops

# Update deployment
kubectl rollout restart deployment <deployment-name>
```

**Problem: Service not accessible**
```bash
# Check service
kubectl get service <service-name>

# Get Minikube service URL
minikube service <service-name> --url

# Use port forwarding
kubectl port-forward service/<service-name> <local-port>:<service-port>
```

**Problem: Pods crashing**
```bash
# Check pod status
kubectl get pods

# View detailed pod information
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check previous logs if pod restarted
kubectl logs <pod-name> --previous
```

**Problem: MongoDB connection issues**
```bash
# Check MongoDB pod is ready
kubectl get pod -l app=mongodb

# Test MongoDB connection from another pod
kubectl run -it --rm debug --image=mongo:7.0 --restart=Never -- mongosh mongodb://mongodb-service:27017/mlops

# Check service DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mongodb-service
```

**Problem: Environment variables not set**
```bash
# Check secrets
kubectl get secrets
kubectl describe secret app-secrets

# Check environment in pod
kubectl exec <pod-name> -- env
```

### General Debugging

**Check resource usage:**
```bash
# Docker
docker stats

# Kubernetes
kubectl top nodes
kubectl top pods
```

**Network issues:**
```bash
# Docker network
docker network ls
docker network inspect mlops_mlops-network

# Kubernetes network
kubectl get networkpolicies
kubectl describe service <service-name>
```

**Database issues:**
```bash
# Connect to MongoDB (Docker)
docker-compose exec mongodb mongosh mlops

# Connect to MongoDB (Kubernetes)
kubectl exec -it <mongodb-pod> -- mongosh mlops

# Check collections
db.users.find()
```

## 📝 Additional Notes

### Security Considerations
- Change JWT secret in production (`secrets.yaml`)
- Use proper email credentials for forgot password
- Implement rate limiting
- Add HTTPS/TLS certificates
- Use Kubernetes secrets for sensitive data

### Performance Optimization
- Adjust replica counts based on load
- Configure resource limits appropriately
- Use horizontal pod autoscaling
- Implement caching strategies
- Optimize database queries

### Monitoring
- Add logging aggregation (ELK stack)
- Implement metrics collection (Prometheus)
- Set up dashboards (Grafana)
- Configure alerts

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the ISC License.

## 👨‍💻 Author

MLOps Assignment Project

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review logs using provided commands
- Check Kubernetes events: `kubectl get events --sort-by='.lastTimestamp'`

---

**Happy Coding! 🚀**
