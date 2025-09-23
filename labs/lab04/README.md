# Lab 4: Deployments and ReplicaSets

## Duration: 45 minutes

## Objectives
- Create and manage Deployments and ReplicaSets
- Scale applications horizontally
- Perform rolling updates and rollbacks
- Understand the deployment hierarchy

## Prerequisites
- Lab 3 completed (Services)
- kubectl configured to use your namespace

## Instructions

### Step 1: Create Basic Deployment
Start with a simple deployment:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete pod --all

# Create a basic deployment
sed 's/userX/user1/g' basic-deployment.yaml > my-basic-deployment.yaml
kubectl apply -f my-basic-deployment.yaml

# Check the deployment and its components
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl describe deployment user1-nginx-deployment
```

### Step 2: Understand Deployment Hierarchy
Explore how Deployments manage ReplicaSets and Pods:

```bash
# Check ReplicaSet details
kubectl get rs -o wide
kubectl describe rs $(kubectl get rs -o name | head -1)

# Check pod ownership and labels
kubectl get pods --show-labels
kubectl get pods -o yaml | grep -A 5 ownerReferences

# Test self-healing: delete a pod and watch replacement
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo "Deleting pod: $POD_NAME"
kubectl delete pod $POD_NAME
kubectl get pods -w
# Press Ctrl+C after new pod is running
```

### Step 3: Scale Deployments
Practice horizontal scaling:

```bash
# Scale up to 5 replicas
kubectl scale deployment user1-nginx-deployment --replicas=5
kubectl rollout status deployment/user1-nginx-deployment
kubectl get pods

# Scale down to 2 replicas
kubectl scale deployment user1-nginx-deployment --replicas=2
kubectl get pods

# Use declarative scaling
kubectl patch deployment user1-nginx-deployment -p '{"spec":{"replicas":4}}'
kubectl get deployment user1-nginx-deployment
```

### Step 4: Rolling Updates
Perform zero-downtime application updates:

```bash
# Check current image version
kubectl describe deployment user1-nginx-deployment | grep Image

# Update to a new image version
kubectl set image deployment/user1-nginx-deployment nginx=nginx:1.22

# Watch the rolling update process
kubectl rollout status deployment/user1-nginx-deployment
kubectl get pods -w
# Press Ctrl+C after update completes

# Verify the new image and ReplicaSet behavior
kubectl describe deployment user1-nginx-deployment | grep Image
kubectl get rs  # Notice old ReplicaSet with 0 replicas
```

### Step 5: Rollbacks and History
Manage deployment versions:

```bash
# Check rollout history
kubectl rollout history deployment/user1-nginx-deployment

# Make another update to create more history
kubectl set image deployment/user1-nginx-deployment nginx=nginx:1.23
kubectl rollout status deployment/user1-nginx-deployment

# Check updated history
kubectl rollout history deployment/user1-nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/user1-nginx-deployment
kubectl rollout status deployment/user1-nginx-deployment

# Verify rollback worked
kubectl describe deployment user1-nginx-deployment | grep Image

# Rollback to specific revision
kubectl rollout undo deployment/user1-nginx-deployment --to-revision=1
kubectl rollout status deployment/user1-nginx-deployment
```

### Step 6: Monitoring and Troubleshooting
Practice deployment monitoring:

```bash
# Check deployment status and events
kubectl describe deployment user1-nginx-deployment
kubectl get events --field-selector involvedObject.name=user1-nginx-deployment

# Check ReplicaSet status
kubectl describe rs $(kubectl get rs -l app=nginx -o name | head -1)

# Monitor ongoing deployments
kubectl get deployments -w
# Press Ctrl+C to stop

# Force restart deployment
kubectl rollout restart deployment/user1-nginx-deployment
kubectl rollout status deployment/user1-nginx-deployment
```

## Verification Steps

```bash
# 1. Verify deployment exists and is ready
kubectl get deployment user1-nginx-deployment

# 2. Check ReplicaSet is managing pods
kubectl get rs -l app=nginx

# 3. Verify rollout history exists
kubectl rollout history deployment/user1-nginx-deployment

# 4. Confirm pods are running
kubectl get pods -l app=nginx
```

## Key Takeaways
- Deployments provide declarative management of application replicas
- ReplicaSets ensure desired number of pods are always running
- Rolling updates enable zero-downtime application updates
- Rollbacks provide quick recovery from failed deployments
- Kubernetes automatically manages the deployment lifecycle

## Cleanup
```bash
kubectl delete deployment user1-nginx-deployment
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!