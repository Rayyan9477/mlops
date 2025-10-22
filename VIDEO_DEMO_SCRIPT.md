# Video Demonstration Script for MLOps Microservices Application

## 🎬 Demo Duration: 5-10 minutes

## 📋 Pre-Demo Checklist
- [ ] Minikube stopped (clean start)
- [ ] Terminal ready
- [ ] Browser ready
- [ ] Screen recording software ready
- [ ] Project directory open

---

## 🎥 SCENE 1: Introduction (30 seconds)

**What to say:**
> "Hello! I'm demonstrating the MLOps Microservices Application for Assignment #2. This is a full-stack application with four microservices: Frontend, Backend, Authentication Service, and Database, all deployed on Kubernetes using Minikube."

**What to show:**
- Show the project directory structure
- Briefly show the README.md file

**Terminal command:**
```bash
cd /workspaces/mlops
ls -la
```

---

## 🎥 SCENE 2: Architecture Overview (45 seconds)

**What to say:**
> "The architecture consists of a React frontend, Node.js backend service, separate authentication service using JWT tokens, and MongoDB database. Each service is containerized with Docker and orchestrated with Kubernetes."

**What to show:**
- Open ARCHITECTURE.md and show the architecture diagram
- Point out the four main services

**Terminal command:**
```bash
cat ARCHITECTURE.md | head -50
```

---

## 🎥 SCENE 3: Starting Minikube (30 seconds)

**What to say:**
> "First, I'll start Minikube with 4 CPUs and 8GB of memory to ensure smooth operation of all services."

**What to show:**
- Terminal showing Minikube starting

**Terminal command:**
```bash
minikube start --cpus=4 --memory=8192 --driver=docker
```

**Wait for Minikube to start completely**

---

## 🎥 SCENE 4: Deploying to Kubernetes (2 minutes)

**What to say:**
> "Now I'll use the automated deployment script which will build Docker images and deploy all services to Kubernetes. This script configures the Docker environment, builds images for frontend, backend, and auth service, then deploys all Kubernetes resources."

**What to show:**
- Terminal executing deployment script
- Show progress messages as they appear

**Terminal command:**
```bash
./deploy-k8s.sh
```

**Narrate key steps:**
- "Building Docker images..."
- "Deploying MongoDB with persistent storage..."
- "Deploying Authentication Service with 3 replicas..."
- "Deploying Backend Service with 3 replicas..."
- "Deploying Frontend Service with 3 replicas..."

---

## 🎥 SCENE 5: Verifying Deployment (1 minute)

**What to say:**
> "Let's verify that all pods are running. As you can see, we have 10 pods total: 3 for frontend, 3 for backend, 3 for auth-service, and 1 for MongoDB. All pods are in Running state with 1/1 containers ready."

**What to show:**
- Pod status showing all pods running
- Service list showing all services

**Terminal commands:**
```bash
# Show all pods with replicas
kubectl get pods

# Show services
kubectl get services

# Show deployments with replica counts
kubectl get deployments
```

**Point out:**
- 3 replicas for frontend ✅
- 3 replicas for backend ✅
- 3 replicas for auth-service ✅
- 1 replica for mongodb ✅

---

## 🎥 SCENE 6: Accessing the Application (30 seconds)

**What to say:**
> "Now let's access the application. The frontend is exposed via NodePort 30000. I'll use minikube service command to open it in the browser."

**What to show:**
- Terminal command to get service URL
- Browser opening the application

**Terminal command:**
```bash
# Get the service URL
minikube service frontend-service --url

# Or open directly in browser
minikube service frontend-service
```

---

## 🎥 SCENE 7: User Signup (1 minute)

**What to say:**
> "The application opens with a beautiful interface. Let me demonstrate the user signup functionality. I'll click on Sign Up and create a new account."

**What to do:**
1. Click "Sign Up" link
2. Fill in the form:
   - Name: "Demo User"
   - Email: "demo@mlops.com"
   - Password: "password123"
   - Confirm Password: "password123"
3. Click "Sign Up" button

**What to say:**
> "After submitting, the authentication service creates the user, stores the hashed password in MongoDB, generates a JWT token, and redirects to the dashboard."

**What to show:**
- Form submission
- Redirect to dashboard
- Dashboard showing user information

---

## 🎥 SCENE 8: Dashboard and Services (45 seconds)

**What to say:**
> "The dashboard displays user information retrieved from the backend service. You can see the service connection status showing all microservices are connected and working."

**What to show:**
- User profile information
- Service status indicators
- Created/Updated timestamps

**Optional - Show in terminal:**
```bash
# Show logs from backend service
kubectl logs -l app=backend --tail=10

# Show logs from auth service
kubectl logs -l app=auth-service --tail=10
```

---

## 🎥 SCENE 9: Logout and Login (1 minute)

**What to say:**
> "Let me logout and demonstrate the login functionality."

**What to do:**
1. Click "Logout" button
2. Redirected to login page
3. Enter credentials:
   - Email: "demo@mlops.com"
   - Password: "password123"
4. Click "Login" button

**What to say:**
> "The authentication service verifies credentials against the database, generates a new JWT token, and grants access to the dashboard."

**What to show:**
- Logout action
- Login form
- Successful login
- Dashboard access

---

## 🎥 SCENE 10: Forgot Password (45 seconds)

**What to say:**
> "Now I'll demonstrate the forgot password functionality."

**What to do:**
1. Logout if logged in
2. Click "Forgot Password" link
3. Enter email: "demo@mlops.com"
4. Click "Send Reset Link"

**What to say:**
> "The auth service generates a secure reset token, stores it in the database with an expiration time, and would send an email in production. The token is hashed for security."

**What to show:**
- Forgot password form
- Success message
- (Optional) Show in MongoDB that reset token was created:

```bash
kubectl exec -it $(kubectl get pod -l app=mongodb -o jsonpath='{.items[0].metadata.name}') -- mongosh mlops --eval "db.users.findOne({email: 'demo@mlops.com'}, {resetPasswordToken: 1, resetPasswordExpires: 1})"
```

---

## 🎥 SCENE 11: Kubernetes Features (1 minute)

**What to say:**
> "Let me show some Kubernetes features. First, the high availability - we have 3 replicas of each service for load balancing and fault tolerance."

**Terminal commands:**
```bash
# Show replica sets
kubectl get replicasets

# Show pod distribution
kubectl get pods -o wide

# Describe frontend service to show replicas
kubectl describe deployment frontend

# Show scaling capability
kubectl scale deployment frontend --replicas=5
kubectl get pods -w
# (Wait a moment to show new pods starting)
kubectl scale deployment frontend --replicas=3
```

**What to say:**
> "As you can see, Kubernetes automatically manages pod replicas, handles load balancing, and maintains the desired state."

---

## 🎥 SCENE 12: Service Health Checks (30 seconds)

**What to say:**
> "All services have health check endpoints. Let me demonstrate."

**Terminal commands:**
```bash
# Port forward to backend
kubectl port-forward service/backend-service 5000:5000 &

# Test health endpoint
curl http://localhost:5000/health

# Port forward to auth service
kubectl port-forward service/auth-service 5001:5001 &

# Test health endpoint
curl http://localhost:5001/health

# Kill port forwards
killall kubectl
```

---

## 🎥 SCENE 13: Database Verification (30 seconds)

**What to say:**
> "Let's verify the data was stored in MongoDB."

**Terminal command:**
```bash
# Connect to MongoDB and show user
kubectl exec -it $(kubectl get pod -l app=mongodb -o jsonpath='{.items[0].metadata.name}') -- mongosh mlops --eval "db.users.find({email: 'demo@mlops.com'}).pretty()"
```

**What to say:**
> "As you can see, the user data is stored with a hashed password, timestamps, and proper indexes."

---

## 🎥 SCENE 14: Docker and Kubernetes Files (45 seconds)

**What to say:**
> "Let me quickly show the Docker and Kubernetes configurations that make this all work."

**What to show:**
```bash
# Show Docker Compose file
cat docker-compose.yml | head -30

# Show a Kubernetes deployment
cat k8s/frontend-deployment.yaml

# Show a Kubernetes service
cat k8s/frontend-service.yaml

# Show the structure
ls -la k8s/
```

**What to say:**
> "We have Docker Compose for local development, individual Dockerfiles for each service, and comprehensive Kubernetes manifests for deployments, services, ConfigMaps, Secrets, and persistent storage."

---

## 🎥 SCENE 15: Conclusion and Cleanup (1 minute)

**What to say:**
> "This completes the demonstration of the MLOps Microservices Application. I've shown:
> - Complete microservices architecture with 4 services
> - User authentication with Signup, Login, and Forgot Password
> - Docker containerization and Kubernetes orchestration
> - 3 replicas for each service as required
> - Frontend exposed via NodePort for external access
> - Database persistence with MongoDB
> - Health checks and monitoring
> - Complete documentation and automation scripts
>
> All assignment requirements have been successfully implemented. Now let me clean up the deployment."

**Terminal command:**
```bash
# Cleanup
./cleanup-k8s.sh
# Answer 'y' to confirm

# Stop Minikube (optional)
minikube stop
```

**What to show:**
- Cleanup script running
- Resources being deleted
- Clean terminal

---

## 📝 Final Screen Text Overlay

Show text on screen:
```
✅ Assignment Requirements Met:
✅ Microservices Architecture (4 services)
✅ User Authentication (Signup, Login, Forgot Password)
✅ Technology Stack (React, Node.js, MongoDB, JWT)
✅ Containerization (Docker + Docker Compose)
✅ Kubernetes Deployment (Minikube)
✅ 3 Replicas per Service
✅ External Access (NodePort)
✅ Complete Documentation

Project Repository: [Your GitHub URL]
Documentation: README.md, ARCHITECTURE.md, QUICKSTART.md
```

---

## 🎬 Recording Tips

1. **Audio Quality:**
   - Use a good microphone
   - Record in a quiet environment
   - Speak clearly and at moderate pace

2. **Screen Recording:**
   - Use 1920x1080 resolution minimum
   - Record at 30 fps
   - Make terminal font size large (16-18pt)
   - Use high contrast terminal theme

3. **Terminal Setup:**
   ```bash
   # Make terminal font larger
   # Use dark theme with bright text
   # Close unnecessary tabs/windows
   ```

4. **Browser Setup:**
   - Close unnecessary tabs
   - Disable notifications
   - Use incognito/private mode for clean demo

5. **Pacing:**
   - Don't rush
   - Pause briefly when showing new screens
   - Wait for animations/transitions to complete

6. **Practice:**
   - Do a complete dry run before recording
   - Time your demo (aim for 8-10 minutes)
   - Have a backup plan if something fails

---

## 🚨 Troubleshooting During Demo

**If pods don't start:**
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**If application doesn't load:**
```bash
minikube service frontend-service --url
# Use the URL directly in browser
```

**If MongoDB connection fails:**
```bash
kubectl get pods
# Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=120s
```

---

## ✅ Post-Recording Checklist

- [ ] Video is clear and audible
- [ ] All 4 microservices demonstrated
- [ ] Authentication features shown (Signup, Login, Forgot Password)
- [ ] 3 replicas verified
- [ ] Kubernetes deployment shown
- [ ] Docker configuration mentioned
- [ ] Video length: 8-12 minutes
- [ ] Export in HD quality (1080p)
- [ ] Upload to required platform

---

**Good luck with your demo! 🎬🚀**
