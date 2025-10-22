# Quick Reference Commands - MLOps Microservices Application

## 🎯 Essential Commands

### Validation
```bash
# Run complete project validation
./validate-project.sh
```

### Docker Compose Deployment
```bash
# Start all services
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Clean reset
docker-compose down -v
```

### Kubernetes Deployment
```bash
# Deploy everything (automated)
./deploy-k8s.sh

# Deploy manually
minikube start --cpus=4 --memory=8192
eval $(minikube docker-env)
docker build -t mlops-frontend:latest ./frontend
docker build -t mlops-backend:latest ./backend
docker build -t mlops-auth-service:latest ./auth-service
kubectl apply -f k8s/

# Access application
minikube service frontend-service

# Or get URL
minikube service frontend-service --url

# Cleanup
./cleanup-k8s.sh
```

### Monitoring & Debugging
```bash
# Check all pods
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments

# View logs
kubectl logs -l app=frontend
kubectl logs -l app=backend
kubectl logs -l app=auth-service
kubectl logs -l app=mongodb

# Describe pod
kubectl describe pod <pod-name>

# Execute into pod
kubectl exec -it <pod-name> -- sh
```

### Health Checks
```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Check all services
curl http://$MINIKUBE_IP:30000     # Frontend
curl http://$MINIKUBE_IP:30001/health  # Auth Service
curl http://$MINIKUBE_IP:30002/health  # Backend Service
```

### Scaling
```bash
# Scale up
kubectl scale deployment frontend --replicas=5
kubectl scale deployment backend --replicas=5
kubectl scale deployment auth-service --replicas=5

# Scale down
kubectl scale deployment frontend --replicas=3
kubectl scale deployment backend --replicas=3
kubectl scale deployment auth-service --replicas=3
```

### Updates
```bash
# Rebuild and update frontend
eval $(minikube docker-env)
docker build -t mlops-frontend:latest ./frontend
kubectl rollout restart deployment frontend
kubectl rollout status deployment frontend

# Same for backend
docker build -t mlops-backend:latest ./backend
kubectl rollout restart deployment backend

# Same for auth-service
docker build -t mlops-auth-service:latest ./auth-service
kubectl rollout restart deployment auth-service
```

## 📚 Documentation Files

- `README.md` - Main comprehensive guide
- `QUICKSTART.md` - Quick start guide
- `ARCHITECTURE.md` - Architecture details
- `TESTING.md` - Testing guide
- `PROJECT_SUMMARY.md` - Assignment compliance
- `VIDEO_DEMO_SCRIPT.md` - Demo recording guide
- `FILE_INDEX.md` - Complete file listing
- `FINAL_VERIFICATION.md` - Final verification checklist

## 🎬 Recording Demo

Follow the step-by-step guide in `VIDEO_DEMO_SCRIPT.md`

## 🔍 Troubleshooting

### Pods not starting
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Image not found
```bash
eval $(minikube docker-env)
docker images | grep mlops
# Rebuild if missing
docker build -t mlops-frontend:latest ./frontend
```

### Service not accessible
```bash
kubectl get services
minikube service list
minikube service frontend-service --url
```

### MongoDB connection issues
```bash
kubectl get pods -l app=mongodb
kubectl logs -l app=mongodb
kubectl exec -it <mongodb-pod> -- mongosh mlops
```

## 🎯 Quick Testing Flow

1. **Deploy:**
   ```bash
   ./deploy-k8s.sh
   ```

2. **Access:**
   ```bash
   minikube service frontend-service
   ```

3. **Test Signup:**
   - Navigate to application
   - Click "Sign Up"
   - Create account

4. **Test Login:**
   - Logout
   - Login with credentials

5. **Verify Pods:**
   ```bash
   kubectl get pods
   # Should show 10 pods (3+3+3+1)
   ```

6. **Check Logs:**
   ```bash
   kubectl logs -l app=backend --tail=20
   kubectl logs -l app=auth-service --tail=20
   ```

7. **Cleanup:**
   ```bash
   ./cleanup-k8s.sh
   ```

## 📋 Service Ports

### Docker Compose
- Frontend: http://localhost:3000
- Backend: http://localhost:5000
- Auth Service: http://localhost:5001
- MongoDB: localhost:27017

### Kubernetes (NodePort)
- Frontend: http://\<minikube-ip\>:30000
- Auth Service: http://\<minikube-ip\>:30001
- Backend: http://\<minikube-ip\>:30002

## ✅ Pre-Submission Checklist

- [ ] Run `./validate-project.sh` - all checks pass
- [ ] Deploy with `./deploy-k8s.sh` - successful
- [ ] Access frontend - working
- [ ] Test signup - successful
- [ ] Test login - successful
- [ ] Verify 3 replicas: `kubectl get pods`
- [ ] Check documentation - complete
- [ ] Record video demo - ready

---

**All commands tested and verified on:** October 22, 2025
