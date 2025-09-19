# Lab 11: Node Management and Workload Placement

## Duration: 45 minutes

## Objectives
- Use NodeSelector to assign Pods to specific nodes
- Configure Node Affinity rules for advanced placement
- Implement Anti-Affinity to spread Pods across nodes
- Test workload placement with different node configurations
- Use taints and tolerations for specialized workloads

## Prerequisites
- Lab 10 completed (network policies)
- kubectl configured to use your namespace
- Understanding of node concepts

## Instructions

### Step 1: Explore Node Information
```bash
# List all nodes and their labels
kubectl get nodes --show-labels

# Describe a specific node
kubectl describe node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# Check node capacity and usage
kubectl top nodes
```

### Step 2: Add Custom Labels to Nodes
```bash
# Add custom labels for workload placement
kubectl label node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') workload-type=frontend
kubectl label node $(kubectl get nodes -o jsonpath='{.items[1].metadata.name}') workload-type=backend

# Verify labels
kubectl get nodes -L workload-type
```

### Step 3: Deploy with NodeSelector
Deploy applications using node selectors:

```bash
# Deploy frontend app to frontend nodes
sed 's/userX/user1/g' frontend-nodeselected.yaml > my-frontend-nodeselected.yaml
kubectl apply -f my-frontend-nodeselected.yaml

# Deploy backend app to backend nodes
sed 's/userX/user1/g' backend-nodeselected.yaml > my-backend-nodeselected.yaml
kubectl apply -f my-backend-nodeselected.yaml

# Verify placement
kubectl get pods -o wide
```

### Step 4: Configure Node Affinity
Create advanced node placement rules:

```bash
# Deploy with preferred node affinity
sed 's/userX/user1/g' preferred-affinity.yaml > my-preferred-affinity.yaml
kubectl apply -f my-preferred-affinity.yaml

# Deploy with required node affinity
sed 's/userX/user1/g' required-affinity.yaml > my-required-affinity.yaml
kubectl apply -f my-required-affinity.yaml
```

### Step 5: Implement Pod Anti-Affinity
Spread pods across nodes for high availability:

```bash
# Deploy with anti-affinity rules
sed 's/userX/user1/g' anti-affinity-deployment.yaml > my-anti-affinity-deployment.yaml
kubectl apply -f my-anti-affinity-deployment.yaml

# Scale up to see distribution
kubectl scale deployment user1-distributed-app --replicas=4
kubectl get pods -o wide
```

### Step 6: Use Taints and Tolerations
Create specialized node workloads:

```bash
# Taint a node for special workloads (requires permissions)
kubectl taint node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') special=gpu:NoSchedule

# Deploy workload with toleration
sed 's/userX/user1/g' toleration-workload.yaml > my-toleration-workload.yaml
kubectl apply -f my-toleration-workload.yaml

# Verify placement on tainted node
kubectl get pods -o wide
```

### Step 7: Test Resource-Based Placement
Deploy workloads based on node resources:

```bash
# Deploy high-memory workload
sed 's/userX/user1/g' high-memory-app.yaml > my-high-memory-app.yaml
kubectl apply -f my-high-memory-app.yaml

# Deploy high-CPU workload
sed 's/userX/user1/g' high-cpu-app.yaml > my-high-cpu-app.yaml
kubectl apply -f my-high-cpu-app.yaml
```

## Key Concepts Learned
- **NodeSelector**: Simple node-based scheduling
- **Node Affinity**: Advanced node selection rules
- **Pod Anti-Affinity**: Spreading workloads for HA
- **Taints and Tolerations**: Dedicated node scheduling
- **Resource-Based Placement**: Scheduling based on node capacity

## Clean Up
```bash
kubectl delete deployment --all
kubectl label nodes --all workload-type-
kubectl taint nodes --all special-
```

---

**Remember**: Proper workload placement improves performance and availability!