# Lab 10: Network Security and Policies

## Duration: 45 minutes

## Objectives
- Explore existing Security Groups configuration
- Work with pre-installed Calico Network Policies
- Create namespace-specific policies to allow/deny traffic
- Test inter-Pod communication with different policies
- Implement namespace-scoped deny policies and selective allow rules

## Prerequisites
- Lab 9 completed (RBAC implementation)
- kubectl configured to use your namespace
- Calico network policy engine installed

## Instructions

### Step 1: Clean Up Previous Resources
```bash
kubectl delete deployment --all
kubectl delete svc --all
kubectl delete pod --all
kubectl get all
```

### Step 2: Deploy Test Applications
Deploy multiple applications to test network connectivity:

```bash
# Deploy frontend application
sed 's/userX/user1/g' frontend-app.yaml > my-frontend-app.yaml
kubectl apply -f my-frontend-app.yaml

# Deploy backend application
sed 's/userX/user1/g' backend-app.yaml > my-backend-app.yaml
kubectl apply -f my-backend-app.yaml

# Deploy database application
sed 's/userX/user1/g' database-app.yaml > my-database-app.yaml
kubectl apply -f my-database-app.yaml

# Create services
sed 's/userX/user1/g' network-services.yaml > my-network-services.yaml
kubectl apply -f my-network-services.yaml
```

### Step 3: Test Default Network Connectivity
Verify all pods can communicate before applying policies:

```bash
# Test frontend to backend connectivity
kubectl exec deployment/user1-frontend -- curl -s http://user1-backend-service:8080/health

# Test backend to database connectivity
kubectl exec deployment/user1-backend -- curl -s http://user1-database-service:5432/health

# Test direct database access from frontend (should work without policies)
kubectl exec deployment/user1-frontend -- curl -s http://user1-database-service:5432/health
```

### Step 4: Create Deny-All Network Policy
Implement a default deny policy:

```bash
# Apply deny-all policy
sed 's/userX/user1/g' deny-all-policy.yaml > my-deny-all-policy.yaml
kubectl apply -f my-deny-all-policy.yaml

# Test connectivity (should fail)
kubectl exec deployment/user1-frontend -- timeout 5 curl http://user1-backend-service:8080/health || echo "Connection blocked as expected"
```

### Step 5: Allow Frontend to Backend Communication
Create selective allow policies:

```bash
# Allow frontend to backend
sed 's/userX/user1/g' allow-frontend-backend.yaml > my-allow-frontend-backend.yaml
kubectl apply -f my-allow-frontend-backend.yaml

# Test frontend to backend (should work)
kubectl exec deployment/user1-frontend -- curl -s http://user1-backend-service:8080/health

# Test frontend to database (should still be blocked)
kubectl exec deployment/user1-frontend -- timeout 5 curl http://user1-database-service:5432/health || echo "Direct DB access blocked"
```

### Step 6: Allow Backend to Database Communication
```bash
# Allow backend to database
sed 's/userX/user1/g' allow-backend-database.yaml > my-allow-backend-database.yaml
kubectl apply -f my-allow-backend-database.yaml

# Test complete flow
kubectl exec deployment/user1-frontend -- curl -s http://user1-backend-service:8080/data
```

### Step 7: Implement Namespace Isolation
Create policies for namespace-level isolation:

```bash
# Deploy test pod in different namespace (requires permissions)
kubectl create namespace test-isolation --dry-run=client -o yaml | kubectl apply -f -

# Apply namespace isolation policy
sed 's/userX/user1/g' namespace-isolation.yaml > my-namespace-isolation.yaml
kubectl apply -f my-namespace-isolation.yaml
```

### Step 8: Test Egress Policies
Control outbound traffic:

```bash
# Apply egress restrictions
sed 's/userX/user1/g' egress-policy.yaml > my-egress-policy.yaml
kubectl apply -f my-egress-policy.yaml

# Test external access (should be restricted)
kubectl exec deployment/user1-frontend -- timeout 5 curl http://google.com || echo "External access blocked"
```

## Key Concepts Learned
- **Network Policies**: Controlling pod-to-pod communication
- **Calico Implementation**: Using Calico for network security
- **Default Deny**: Implementing zero-trust networking
- **Selective Allow**: Permitting specific communication flows
- **Namespace Isolation**: Preventing cross-namespace traffic
- **Egress Control**: Managing outbound network access

## Clean Up
```bash
kubectl delete networkpolicy --all
kubectl delete deployment --all
kubectl delete svc --all
```

---

**Remember**: Network policies provide defense in depth for your Kubernetes applications!