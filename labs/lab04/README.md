# Lab 4: Deployments and ReplicaSets

## Duration: 45 minutes

## Objectives
- Create Deployments to manage Pod replicas
- Scale applications up and down
- Perform rolling updates and rollbacks
- Monitor deployment status and history

## Prerequisites
- Lab 3 completed (services and pods)
- kubectl configured to use your namespace

## Instructions

### Step 1: Verify Your Environment
Ensure you're in the correct namespace:

```bash
# Check current namespace
kubectl config view --minify | grep namespace

# Clean up any existing deployments from previous labs
kubectl delete deployment --all
kubectl get pods
```

### Step 2: Create Your First Deployment
Create a basic deployment with multiple replicas:

```bash
# Create a basic deployment
sed 's/userX/user1/g' basic-deployment.yaml > my-basic-deployment.yaml
kubectl apply -f my-basic-deployment.yaml

# Check the deployment
kubectl get deployments
kubectl get replicasets
kubectl get pods

# Get detailed information
kubectl describe deployment user1-nginx-deployment
```

### Step 3: Understanding ReplicaSets
Explore the relationship between Deployments and ReplicaSets:

```bash
# Check ReplicaSet details
kubectl get rs
kubectl describe rs $(kubectl get rs -o name | head -1)

# Check how pods are labeled
kubectl get pods --show-labels

# Try to delete a pod and watch it get recreated
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME
kubectl get pods -w
```

### Step 4: Scaling Your Deployment
Practice scaling deployments up and down:

```bash
# Scale up to 5 replicas
kubectl scale deployment user1-nginx-deployment --replicas=5
kubectl get pods
kubectl get deployment user1-nginx-deployment

# Watch the scaling process
kubectl rollout status deployment/user1-nginx-deployment

# Scale down to 2 replicas
kubectl scale deployment user1-nginx-deployment --replicas=2
kubectl get pods
```

### Step 5: Updating Your Deployment
Perform a rolling update by changing the image:

```bash
# Check current image
kubectl describe deployment user1-nginx-deployment | grep Image

# Update to a new image version
kubectl set image deployment/user1-nginx-deployment nginx=nginx:1.22

# Watch the rolling update
kubectl rollout status deployment/user1-nginx-deployment
kubectl get pods -w

# Check the new image
kubectl describe deployment user1-nginx-deployment | grep Image
```

### Step 6: Deployment History and Rollbacks
Explore deployment history and perform rollbacks:

```bash
# Check rollout history
kubectl rollout history deployment/user1-nginx-deployment

# Make another change to create more history
kubectl set image deployment/user1-nginx-deployment nginx=nginx:1.23
kubectl rollout status deployment/user1-nginx-deployment

# Check history again
kubectl rollout history deployment/user1-nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/user1-nginx-deployment
kubectl rollout status deployment/user1-nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/user1-nginx-deployment --to-revision=1
kubectl rollout status deployment/user1-nginx-deployment
```

### Step 7: Advanced Deployment Configuration
Create a deployment with advanced configuration:

```bash
# Create an advanced deployment
sed 's/userX/user1/g' advanced-deployment.yaml > my-advanced-deployment.yaml
kubectl apply -f my-advanced-deployment.yaml

# Check the deployment strategy
kubectl describe deployment user1-advanced-nginx | grep -A 10 "StrategyType"

# Monitor the deployment
kubectl get deployment user1-advanced-nginx
kubectl get pods -l app=advanced-nginx
```

### Step 8: Rolling Update Strategies
Test different update strategies:

```bash
# Update with specific strategy parameters
kubectl patch deployment user1-advanced-nginx -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"50%","maxUnavailable":"25%"}}}}'

# Trigger an update
kubectl set image deployment/user1-advanced-nginx nginx=nginx:1.24

# Watch the update process
kubectl get pods -l app=advanced-nginx -w
```

### Step 9: Deployment Pausing and Resuming
Practice pausing and resuming deployments:

```bash
# Pause a deployment
kubectl rollout pause deployment/user1-advanced-nginx

# Make multiple changes while paused
kubectl set image deployment/user1-advanced-nginx nginx=nginx:1.25
kubectl set env deployment/user1-advanced-nginx DEMO=paused-update

# Check that no rollout occurred
kubectl get pods -l app=advanced-nginx

# Resume the deployment
kubectl rollout resume deployment/user1-advanced-nginx
kubectl rollout status deployment/user1-advanced-nginx
```

### Step 10: Deployment with Resource Limits
Create a deployment with resource constraints:

```bash
# Create resource-limited deployment
sed 's/userX/user1/g' resource-deployment.yaml > my-resource-deployment.yaml
kubectl apply -f my-resource-deployment.yaml

# Check resource allocation
kubectl describe deployment user1-resource-nginx
kubectl top pods -l app=resource-nginx
```

### Step 11: Deployment Readiness and Health Checks
Work with readiness and liveness probes:

```bash
# Create deployment with health checks
sed 's/userX/user1/g' health-deployment.yaml > my-health-deployment.yaml
kubectl apply -f my-health-deployment.yaml

# Monitor pod readiness
kubectl get pods -l app=health-nginx
kubectl describe pod $(kubectl get pods -l app=health-nginx -o jsonpath='{.items[0].metadata.name}')

# Check deployment status
kubectl get deployment user1-health-nginx
```

### Step 12: Blue-Green Deployment Simulation
Simulate a blue-green deployment pattern:

```bash
# Create blue deployment
sed 's/userX/user1/g' blue-deployment.yaml > my-blue-deployment.yaml
kubectl apply -f my-blue-deployment.yaml

# Create service pointing to blue
sed 's/userX/user1/g' blue-green-service.yaml > my-blue-green-service.yaml
kubectl apply -f my-blue-green-service.yaml

# Test current version
kubectl get svc user1-blue-green-service
kubectl get pods -l version=blue

# Create green deployment
sed 's/userX/user1/g' green-deployment.yaml > my-green-deployment.yaml
kubectl apply -f my-green-deployment.yaml

# Switch service to green (simulate blue-green switch)
kubectl patch service user1-blue-green-service -p '{"spec":{"selector":{"version":"green"}}}'

# Verify the switch
kubectl get pods -l version=green
```

## Verification Steps

### Verify Your Deployments
Run these commands to check your work:

```bash
# 1. List all deployments
kubectl get deployments

# 2. Check deployment status
kubectl get deployments -o wide

# 3. Verify ReplicaSets
kubectl get rs

# 4. Check rollout history
kubectl rollout history deployment/user1-nginx-deployment

# 5. Verify resource usage
kubectl top pods
```

## Clean Up (Optional)
Remove deployments if needed:

```bash
# Delete specific deployments
kubectl delete deployment user1-resource-nginx

# Delete all deployments
kubectl delete deployment --all
```

## Troubleshooting

### Common Issues
1. **Deployment stuck in progress**: Check pod events and resource limits
2. **Pods not ready**: Verify readiness probes and application startup
3. **Rollback fails**: Check deployment history and revision numbers
4. **Scaling issues**: Verify resource quotas and node capacity

### Useful Commands
```bash
# Debug deployment issues
kubectl describe deployment <deployment-name>
kubectl rollout status deployment/<deployment-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Force restart deployment
kubectl rollout restart deployment/<deployment-name>
```

## Key Concepts Learned
- **Deployments**: Declarative way to manage pods and ReplicaSets
- **ReplicaSets**: Ensure desired number of pod replicas
- **Rolling Updates**: Zero-downtime application updates
- **Rollbacks**: Revert to previous deployment versions
- **Scaling**: Horizontal scaling of application instances
- **Deployment Strategies**: Control update behavior
- **Blue-Green Deployments**: Alternative deployment pattern

## Next Steps
In the next lab, you'll deploy complete microservices applications with multiple components working together.

---

**Remember**: Always use your username prefix and monitor deployment status during updates!