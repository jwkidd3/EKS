# Lab 2: Working with Pods and Basic Objects

## Duration: 45 minutes

## Objectives
- Create your first Pod in your personal namespace
- Explore Pod lifecycle and states
- View Pod logs and execute commands inside containers
- Create and manage basic Kubernetes objects

## Prerequisites
- Lab 1 completed (namespace created and configured)
- kubectl configured to use your namespace

## Instructions

> **📋 SHARED CLUSTER NOTICE:** Throughout this lab, you'll use `sed` commands to replace `userX` with your assigned username (user1, user2, etc.) in YAML files. This ensures your resources are properly named and isolated from other students in the shared EKS cluster.

### Step 1: Verify Your Environment
Before starting, ensure you're in the correct namespace:

```bash
# Check current namespace
kubectl config view --minify | grep namespace

# If not set, set it to your namespace
kubectl config set-context --current --namespace=userX-namespace

# Verify you can create pods
kubectl auth can-i create pods
```

### Step 2: Create Your First Pod
Let's start with a simple nginx Pod customized for your user:

```bash
# SHARED CLUSTER: Customize Pod with Your Username
# This command replaces 'userX' with your assigned username in the YAML file
#
# What gets renamed:
# - Pod name: userX-simple-nginx → user1-simple-nginx
# - Namespace: userX-namespace → user1-namespace
# - Labels: owner: userX → owner: user1
#
# Replace 'user1' with YOUR assigned username (user1, user2, user3, etc.)
sed 's/userX/user1/g' simple-pod.yaml > my-simple-pod.yaml

# Create the pod
kubectl apply -f my-simple-pod.yaml

# Check if the pod was created
kubectl get pods

# Get more detailed information
kubectl get pods -o wide
```

### Step 3: Explore Pod Lifecycle
Watch your Pod go through different states:

```bash
# Watch the pod status in real-time
kubectl get pods -w

# In another terminal, check the pod events
kubectl describe pod user1-simple-nginx

# Check pod logs
kubectl logs user1-simple-nginx
```

### Step 4: Interact with Your Pod
Let's execute commands inside the running container:

```bash
# Execute a command in the pod
kubectl exec user1-simple-nginx -- ls /

# Get an interactive shell
kubectl exec -it user1-simple-nginx -- /bin/bash

# Inside the container, try these commands:
# ps aux
# cat /etc/os-release
# curl localhost:80
# exit
```

### Step 5: Create a Multi-Container Pod
Now let's create a Pod with multiple containers:

```bash
# Edit the multi-container pod YAML
sed 's/userX/user1/g' multi-container-pod.yaml > my-multi-container-pod.yaml

# Create the multi-container pod
kubectl apply -f my-multi-container-pod.yaml

# Check the pod status
kubectl get pods

# Check logs from specific containers
kubectl logs user1-multi-container -c nginx-container
kubectl logs user1-multi-container -c busybox-container
```

### Step 6: Understanding Pod States
Create a pod with a problem to see different states:

```bash
# Create a pod with an invalid image
sed 's/userX/user1/g' problematic-pod.yaml > my-problematic-pod.yaml
kubectl apply -f my-problematic-pod.yaml

# Watch the pod status
kubectl get pods
kubectl describe pod user1-problematic-nginx

# Check the events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Step 7: Working with Pod Labels and Annotations
Let's add labels and annotations to your pods:

```bash
# Add labels to your pod
kubectl label pod user1-simple-nginx environment=training
kubectl label pod user1-simple-nginx tier=frontend

# Add annotations
kubectl annotate pod user1-simple-nginx description="My first training pod"

# View labels and annotations
kubectl get pods --show-labels
kubectl describe pod user1-simple-nginx | grep -A 5 "Labels\|Annotations"
```

### Step 8: Using Selectors
Practice using label selectors:

```bash
# Get pods with specific labels
kubectl get pods -l environment=training
kubectl get pods -l tier=frontend

# Use multiple label selectors
kubectl get pods -l environment=training,tier=frontend

# Show all pods with labels
kubectl get pods --show-labels
```

### Step 9: Pod Resource Monitoring
Check resource usage of your pods:

```bash
# Check resource usage (requires metrics server)
kubectl top pod

# Get detailed resource information
kubectl describe pod user1-simple-nginx | grep -A 10 "Requests\|Limits"

# Check node allocation
kubectl describe node | grep -A 5 "Allocated resources"
```

### Step 10: Creating Pods with Resource Limits
Create a pod with resource constraints:

```bash
# Edit the resource-limited pod YAML
sed 's/userX/user1/g' resource-pod.yaml > my-resource-pod.yaml

# Create the pod
kubectl apply -f my-resource-pod.yaml

# Check the pod details
kubectl describe pod user1-resource-nginx | grep -A 10 "Limits\|Requests"
```

### Step 11: Pod Networking
Explore pod networking:

```bash
# Get pod IP addresses
kubectl get pods -o wide

# Test connectivity between pods (from multi-container pod)
kubectl exec user1-multi-container -c busybox-container -- ping -c 3 <SIMPLE_POD_IP>

# Check DNS resolution
kubectl exec user1-multi-container -c busybox-container -- nslookup kubernetes.default
```

### Step 12: Environment Variables and ConfigMaps
Work with environment variables:

```bash
# Create a simple configmap
kubectl create configmap user1-config --from-literal=app.name=myapp --from-literal=app.version=1.0

# Create a pod that uses the configmap
sed 's/userX/user1/g' configmap-pod.yaml > my-configmap-pod.yaml
kubectl apply -f my-configmap-pod.yaml

# Check environment variables in the pod
kubectl exec user1-configmap-nginx -- env | grep APP_
```

## Verification Steps

### Verify Your Work
Run these commands to check your progress:

```bash
# 1. List all your pods
kubectl get pods

# 2. Check pod states
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# 3. Verify labels
kubectl get pods --show-labels

# 4. Check resource usage
kubectl top pod

# 5. Verify configmap
kubectl get configmap
```

## Clean Up (Optional)
If you want to clean up some resources:

```bash
# Delete specific pods
kubectl delete pod user1-problematic-nginx

# Delete all pods with a specific label
kubectl delete pods -l environment=training

# Or delete all pods (be careful!)
kubectl delete pods --all
```

## Troubleshooting

### Common Issues
1. **Pod stuck in Pending**: Check node resources and scheduling constraints
2. **Pod in CrashLoopBackOff**: Check logs and container image
3. **Cannot exec into pod**: Ensure pod is running and container has shell
4. **Permission denied**: Verify you're in the correct namespace

### Useful Commands
```bash
# Debug pod issues
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Force delete stuck pods
kubectl delete pod <pod-name> --force --grace-period=0
```

## Key Concepts Learned
- **Pod Lifecycle**: Pending → Running → Succeeded/Failed
- **Multi-container Pods**: Containers share network and storage
- **Labels and Selectors**: Organize and query resources
- **Resource Limits**: Control CPU and memory usage
- **Environment Variables**: Configure applications
- **Pod Networking**: Each pod gets unique IP address

## Next Steps
In the next lab, you'll learn about Services and how to expose your applications for network access.

---

**Remember**: Always prefix your resources with your username to avoid conflicts!