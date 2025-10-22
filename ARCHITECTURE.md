# MLOps Microservices Application - Architecture Overview

## System Architecture

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                         Internet/User                           │
└────────────────────────────┬───────────────────────────────────┘
                             │
                             │ HTTP/HTTPS
                             ▼
┌────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (Minikube)                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              Frontend Service (NodePort)                │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │   │
│  │  │ Frontend │  │ Frontend │  │ Frontend │            │   │
│  │  │  Pod 1   │  │  Pod 2   │  │  Pod 3   │            │   │
│  │  │  React   │  │  React   │  │  React   │            │   │
│  │  │  Nginx   │  │  Nginx   │  │  Nginx   │            │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘            │   │
│  │       └────────┬─────┴──────┬──────┘                  │   │
│  │                │            │                          │   │
│  │         Port 80│            │Port 30000 (NodePort)    │   │
│  └────────────────┼────────────┼──────────────────────────┘   │
│                   │            │                               │
│  ┌────────────────▼────────────▼──────────────────────────┐   │
│  │           Internal Service Mesh (ClusterIP)             │   │
│  │                                                          │   │
│  │  ┌──────────────────────┐  ┌──────────────────────┐   │   │
│  │  │  Auth Service        │  │  Backend Service     │   │   │
│  │  │  ┌────────────────┐  │  │  ┌────────────────┐ │   │   │
│  │  │  │ Auth Pod 1     │  │  │  │ Backend Pod 1  │ │   │   │
│  │  │  │ Node.js/Express│  │  │  │ Node.js/Express│ │   │   │
│  │  │  │ JWT Auth       │  │  │  │ User APIs      │ │   │   │
│  │  │  └────────────────┘  │  │  └────────────────┘ │   │   │
│  │  │  ┌────────────────┐  │  │  ┌────────────────┐ │   │   │
│  │  │  │ Auth Pod 2     │  │  │  │ Backend Pod 2  │ │   │   │
│  │  │  └────────────────┘  │  │  └────────────────┘ │   │   │
│  │  │  ┌────────────────┐  │  │  ┌────────────────┐ │   │   │
│  │  │  │ Auth Pod 3     │  │  │  │ Backend Pod 3  │ │   │   │
│  │  │  └────────────────┘  │  │  └────────────────┘ │   │   │
│  │  │  Port: 5001         │  │  │  Port: 5000      │ │   │   │
│  │  └──────────┬───────────┘  └──────────┬──────────┘   │   │
│  │             │                          │               │   │
│  │             └────────────┬─────────────┘               │   │
│  │                          │                             │   │
│  │  ┌───────────────────────▼──────────────────────┐     │   │
│  │  │         Database Service (ClusterIP)         │     │   │
│  │  │  ┌────────────────────────────────────┐      │     │   │
│  │  │  │      MongoDB Pod                   │      │     │   │
│  │  │  │      - Database: mlops             │      │     │   │
│  │  │  │      - Collection: users           │      │     │   │
│  │  │  │      - Persistent Volume           │      │     │   │
│  │  │  │      Port: 27017                   │      │     │   │
│  │  │  └────────────────────────────────────┘      │     │   │
│  │  └──────────────────────────────────────────────┘     │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Kubernetes Resources                        │   │
│  │  - ConfigMaps (MongoDB init script)                     │   │
│  │  - Secrets (JWT tokens)                                 │   │
│  │  - PersistentVolumeClaim (MongoDB data)                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Frontend Service
- **Technology**: React 18.2.0, Nginx
- **Replicas**: 3 pods
- **Port**: 80 (internal), 30000 (NodePort for external access)
- **Responsibilities**:
  - User interface rendering
  - Client-side routing
  - Authentication state management
  - API communication
- **Components**:
  - Login page
  - Signup page
  - Forgot Password page
  - Reset Password page
  - Dashboard

### 2. Authentication Service
- **Technology**: Node.js 18, Express.js
- **Replicas**: 3 pods
- **Port**: 5001 (ClusterIP - internal only)
- **Responsibilities**:
  - User registration (Signup)
  - User authentication (Login)
  - JWT token generation and validation
  - Password reset workflow
  - Token verification for other services
- **Key Features**:
  - Password hashing with bcrypt
  - JWT token management
  - Email-based password recovery
  - Secure token verification endpoint

### 3. Backend Service
- **Technology**: Node.js 18, Express.js
- **Replicas**: 3 pods
- **Port**: 5000 (ClusterIP - internal only)
- **Responsibilities**:
  - User profile management
  - Protected API endpoints
  - Business logic execution
  - Inter-service communication
- **Key Features**:
  - Token verification with auth service
  - User profile CRUD operations
  - Middleware for authentication

### 4. Database Service
- **Technology**: MongoDB 7.0
- **Replicas**: 1 pod (single instance)
- **Port**: 27017 (ClusterIP - internal only)
- **Storage**: PersistentVolumeClaim (5Gi)
- **Responsibilities**:
  - Data persistence
  - User data storage
  - Index management
- **Collections**:
  - users (with unique email index)

## Data Flow

### 1. User Registration Flow
```
User → Frontend → Auth Service → MongoDB
                       ↓
                  JWT Token
                       ↓
                   Frontend (Store token)
                       ↓
                   Dashboard
```

### 2. User Login Flow
```
User → Frontend → Auth Service → MongoDB (Verify credentials)
                       ↓
                  JWT Token
                       ↓
                   Frontend (Store token)
                       ↓
                   Dashboard
```

### 3. Protected API Call Flow
```
User → Frontend (with JWT) → Backend Service → Auth Service (Verify token)
                                   ↓                    ↓
                              MongoDB          JWT Valid/Invalid
                                   ↓                    ↓
                              User Data ←────────── Backend
                                   ↓
                              Frontend
```

### 4. Password Reset Flow
```
User → Frontend → Auth Service → Generate Reset Token
                       ↓
                  Store in MongoDB
                       ↓
              Send Email (with token link)
                       ↓
User clicks link → Frontend → Auth Service → Verify token
                                   ↓
                              Update Password
                                   ↓
                              MongoDB
```

## Network Communication

### Service-to-Service Communication
- **Frontend → Auth Service**: HTTP REST API calls for authentication
- **Frontend → Backend Service**: HTTP REST API calls for user data
- **Backend → Auth Service**: HTTP calls for token verification
- **Auth Service → MongoDB**: MongoDB protocol for data operations
- **Backend → MongoDB**: MongoDB protocol for data operations

### Service Discovery
- Kubernetes DNS for service discovery
- Service names used as hostnames:
  - `mongodb-service:27017`
  - `auth-service:5001`
  - `backend-service:5000`

## Security Architecture

### 1. Authentication & Authorization
- JWT-based token authentication
- Tokens expire after 24 hours
- Passwords hashed with bcrypt (10 rounds)
- Protected routes require valid JWT

### 2. Network Security
- Internal services (ClusterIP) not exposed externally
- Only frontend exposed via NodePort
- Service-to-service communication within cluster
- Environment-based secrets

### 3. Data Security
- Passwords never stored in plain text
- JWT secrets stored in Kubernetes Secrets
- Database credentials managed securely
- Reset tokens hashed before storage

## Scalability Features

### Horizontal Scaling
- **Frontend**: 3 replicas with load balancing
- **Backend**: 3 replicas with load balancing
- **Auth Service**: 3 replicas with load balancing
- Session affinity for consistent user experience

### Resource Management
- CPU and memory limits defined
- Resource requests for guaranteed allocation
- Health checks for automatic recovery

### High Availability
- Multiple replicas prevent single point of failure
- Readiness probes ensure traffic to healthy pods
- Liveness probes restart unhealthy pods
- PersistentVolume for database data durability

## Monitoring & Health Checks

### Health Endpoints
- **Backend**: `GET /health`
- **Auth Service**: `GET /health`
- **Frontend**: `GET /` (HTTP 200)

### Kubernetes Probes
- **Liveness Probes**: Restart unhealthy containers
- **Readiness Probes**: Control traffic routing
- **Startup Probes**: Allow slow-starting containers

### Logging
- Container logs via kubectl
- Centralized logging (configurable)
- Application-level logging to stdout/stderr

## Deployment Strategies

### Blue-Green Deployment
- Deploy new version alongside old
- Switch traffic when ready
- Rollback if issues detected

### Rolling Updates
- Default Kubernetes strategy
- Gradual pod replacement
- Zero-downtime deployments

### Canary Deployment
- Route small percentage to new version
- Monitor metrics
- Gradually increase traffic

## Resource Requirements

### Development (Minikube)
- **CPU**: 4 cores minimum
- **Memory**: 8GB minimum
- **Storage**: 20GB minimum

### Production (Recommended)
- **CPU**: 8+ cores
- **Memory**: 16GB+
- **Storage**: 100GB+ with SSD
- **Network**: High bandwidth, low latency

## Technology Stack Summary

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Frontend Framework | React | 18.2.0 | UI Development |
| Frontend Server | Nginx | Alpine | Static file serving |
| Backend Runtime | Node.js | 18 | Server-side JavaScript |
| Backend Framework | Express | 4.18.2 | Web framework |
| Database | MongoDB | 7.0 | Data persistence |
| Authentication | JWT | 9.0.2 | Token-based auth |
| Password Hashing | bcryptjs | 2.4.3 | Secure password storage |
| Container Runtime | Docker | Latest | Containerization |
| Orchestration | Kubernetes | Latest | Container orchestration |
| Local K8s | Minikube | Latest | Local development |

## Best Practices Implemented

1. **Microservices Pattern**: Separate services for different concerns
2. **Containerization**: All services containerized with Docker
3. **Orchestration**: Kubernetes for deployment and scaling
4. **Health Checks**: Comprehensive liveness and readiness probes
5. **Security**: JWT tokens, password hashing, secrets management
6. **Scalability**: Multiple replicas with load balancing
7. **Persistence**: PersistentVolumes for database
8. **Configuration**: ConfigMaps and Secrets for configuration
9. **Documentation**: Comprehensive README and guides
10. **Automation**: Deployment scripts for easy setup

## Future Enhancements

- [ ] Implement HTTPS/TLS
- [ ] Add API Gateway (Kong/Nginx Ingress)
- [ ] Implement rate limiting
- [ ] Add monitoring (Prometheus + Grafana)
- [ ] Implement logging aggregation (ELK stack)
- [ ] Add distributed tracing (Jaeger)
- [ ] Implement CI/CD pipeline
- [ ] Add horizontal pod autoscaling
- [ ] Implement service mesh (Istio)
- [ ] Add backup and disaster recovery
- [ ] Implement caching (Redis)
- [ ] Add message queue (RabbitMQ/Kafka)
