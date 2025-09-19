# Lab 5: Deploying Microservices to EKS

## Duration: 45 minutes

## Objectives
- Deploy NodeJS backend API with database connectivity
- Deploy Crystal backend API with different configurations
- Create frontend application connecting to backend services
- Test end-to-end application functionality
- Scale individual microservices independently

## Prerequisites
- Lab 4 completed (deployments and services)
- kubectl configured to use your namespace

## Instructions

### Step 1: Clean Up Previous Resources
Start with a clean environment:

```bash
# Clean up previous lab resources
kubectl delete deployment --all
kubectl delete svc --all
kubectl get all

# Verify namespace is clean
kubectl get pods
```

### Step 2: Deploy Database Layer
Start by deploying a Redis database for the microservices:

```bash
# Deploy Redis database
sed 's/userX/user1/g' redis-deployment.yaml > my-redis-deployment.yaml
sed 's/userX/user1/g' redis-service.yaml > my-redis-service.yaml

kubectl apply -f my-redis-deployment.yaml
kubectl apply -f my-redis-service.yaml

# Verify Redis is running
kubectl get pods -l app=redis
kubectl get svc user1-redis-service
```

### Step 3: Deploy NodeJS Backend API
Deploy the NodeJS backend service:

```bash
# Deploy NodeJS backend
sed 's/userX/user1/g' nodejs-backend.yaml > my-nodejs-backend.yaml
kubectl apply -f my-nodejs-backend.yaml

# Check deployment status
kubectl get deployment user1-nodejs-backend
kubectl get pods -l app=nodejs-backend

# Check logs to ensure it's connecting to Redis
kubectl logs -l app=nodejs-backend
```

### Step 4: Deploy Crystal Backend API
Deploy the Crystal backend with different configuration:

```bash
# Deploy Crystal backend
sed 's/userX/user1/g' crystal-backend.yaml > my-crystal-backend.yaml
kubectl apply -f my-crystal-backend.yaml

# Check deployment status
kubectl get deployment user1-crystal-backend
kubectl get pods -l app=crystal-backend

# Verify both backends are running
kubectl get deployments
```

### Step 5: Create ConfigMap for Frontend
Create configuration for the frontend application:

```bash
# Create ConfigMap for frontend configuration
sed 's/userX/user1/g' frontend-config.yaml > my-frontend-config.yaml
kubectl apply -f my-frontend-config.yaml

# Verify ConfigMap
kubectl get configmap user1-frontend-config
kubectl describe configmap user1-frontend-config
```

### Step 6: Deploy Frontend Application
Deploy the frontend that connects to both backends:

```bash
# Deploy frontend application
sed 's/userX/user1/g' frontend-deployment.yaml > my-frontend-deployment.yaml
kubectl apply -f my-frontend-deployment.yaml

# Check frontend deployment
kubectl get deployment user1-frontend
kubectl get pods -l app=frontend

# Check frontend logs
kubectl logs -l app=frontend
```

### Step 7: Create Services for All Components
Create services to expose each component:

```bash
# Create NodeJS backend service
sed 's/userX/user1/g' nodejs-service.yaml > my-nodejs-service.yaml
kubectl apply -f my-nodejs-service.yaml

# Create Crystal backend service
sed 's/userX/user1/g' crystal-service.yaml > my-crystal-service.yaml
kubectl apply -f my-crystal-service.yaml

# Create frontend service (LoadBalancer)
sed 's/userX/user1/g' frontend-service.yaml > my-frontend-service.yaml
kubectl apply -f my-frontend-service.yaml

# Check all services
kubectl get svc
```

### Step 8: Test Service Connectivity
Test connectivity between services:

```bash
# Create a test pod for internal testing
sed 's/userX/user1/g' test-connectivity.yaml > my-test-connectivity.yaml
kubectl apply -f my-test-connectivity.yaml

# Test Redis connectivity
kubectl exec user1-connectivity-test -- redis-cli -h user1-redis-service ping

# Test NodeJS backend
kubectl exec user1-connectivity-test -- curl -s http://user1-nodejs-service:3000/health

# Test Crystal backend
kubectl exec user1-connectivity-test -- curl -s http://user1-crystal-service:3000/health

# Test frontend
kubectl exec user1-connectivity-test -- curl -s http://user1-frontend-service:80/
```

### Step 9: Test End-to-End Functionality
Test the complete application flow:

```bash
# Test data flow through NodeJS backend
kubectl exec user1-connectivity-test -- curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"key":"test","value":"hello"}' \
  http://user1-nodejs-service:3000/data

# Retrieve data through NodeJS
kubectl exec user1-connectivity-test -- curl -s http://user1-nodejs-service:3000/data/test

# Test Crystal backend functionality
kubectl exec user1-connectivity-test -- curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"message":"crystal test"}' \
  http://user1-crystal-service:3000/process

# Check external access if LoadBalancer has external IP
kubectl get svc user1-frontend-service
```

### Step 10: Scale Individual Microservices
Practice independent scaling of each service:

```bash
# Scale NodeJS backend (high load service)
kubectl scale deployment user1-nodejs-backend --replicas=3
kubectl get pods -l app=nodejs-backend

# Scale Crystal backend (moderate load)
kubectl scale deployment user1-crystal-backend --replicas=2
kubectl get pods -l app=crystal-backend

# Scale frontend (user-facing)
kubectl scale deployment user1-frontend --replicas=4
kubectl get pods -l app=frontend

# Keep Redis as single instance (stateful)
kubectl get pods -l app=redis

# Check overall resource usage
kubectl top pods
```

### Step 11: Monitor Service Discovery
Verify service discovery is working correctly:

```bash
# Check DNS resolution between services
kubectl exec user1-connectivity-test -- nslookup user1-nodejs-service
kubectl exec user1-connectivity-test -- nslookup user1-crystal-service
kubectl exec user1-connectivity-test -- nslookup user1-redis-service

# Test service discovery from NodeJS pod
NODEJS_POD=$(kubectl get pods -l app=nodejs-backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec $NODEJS_POD -- nslookup user1-redis-service

# Test from Crystal pod
CRYSTAL_POD=$(kubectl get pods -l app=crystal-backend -o jsonpath='{.items[0].metadata.name}')
kubectl exec $CRYSTAL_POD -- nslookup user1-redis-service
```

### Step 12: Load Testing and Monitoring
Generate load and monitor the microservices:

```bash
# Generate load on NodeJS backend
kubectl exec user1-connectivity-test -- sh -c '
for i in $(seq 1 20); do
  curl -X POST -H "Content-Type: application/json" \
    -d "{\"key\":\"load-test-$i\",\"value\":\"test-data-$i\"}" \
    http://user1-nodejs-service:3000/data
  sleep 1
done'

# Check pod resource usage
kubectl top pods

# Check deployment status
kubectl get deployments
kubectl describe deployment user1-nodejs-backend
```

### Step 13: Application Health Monitoring
Monitor the health of all services:

```bash
# Check health endpoints
kubectl exec user1-connectivity-test -- curl -s http://user1-nodejs-service:3000/health
kubectl exec user1-connectivity-test -- curl -s http://user1-crystal-service:3000/health

# Check pod readiness
kubectl get pods
kubectl describe pod $NODEJS_POD | grep -A 5 "Conditions"

# Check service endpoints
kubectl get endpoints
kubectl describe endpoints user1-nodejs-service
```

## Verification Steps

### Verify Your Microservices Deployment
Run these commands to verify everything is working:

```bash
# 1. Check all deployments are running
kubectl get deployments

# 2. Verify all pods are ready
kubectl get pods

# 3. Check all services
kubectl get svc

# 4. Test connectivity
kubectl exec user1-connectivity-test -- curl -s http://user1-frontend-service:80/

# 5. Verify scaling
kubectl get pods -l app=nodejs-backend --no-headers | wc -l
```

## Clean Up (Optional)
Remove microservices if needed:

```bash
# Delete all deployments
kubectl delete deployment --all

# Delete all services
kubectl delete svc --all

# Delete ConfigMaps
kubectl delete configmap --all
```

## Troubleshooting

### Common Issues
1. **Service connectivity fails**: Check service selectors and pod labels
2. **Pods crash on startup**: Check environment variables and dependencies
3. **Database connection issues**: Verify Redis is running and accessible
4. **Load balancer pending**: Wait for AWS to provision the load balancer

### Useful Commands
```bash
# Debug connectivity
kubectl exec <test-pod> -- telnet <service-name> <port>
kubectl describe svc <service-name>
kubectl get endpoints <service-name>

# Check logs
kubectl logs -l app=<app-name>
kubectl logs -f deployment/<deployment-name>
```

## Key Concepts Learned
- **Microservices Architecture**: Deploying multiple interconnected services
- **Service Communication**: How services discover and communicate with each other
- **Database Integration**: Connecting applications to data stores
- **Independent Scaling**: Scaling different services based on their load
- **Configuration Management**: Using ConfigMaps for application configuration
- **End-to-End Testing**: Verifying complete application functionality
- **Load Distribution**: Managing traffic across service replicas

## Next Steps
In the next lab, you'll learn how to use Helm to package and deploy these microservices more efficiently.

---

**Remember**: Monitor resource usage and scale services based on their specific requirements!