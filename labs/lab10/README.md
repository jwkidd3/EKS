# Lab 10: Network Policies and Security

## Duration: 45 minutes

## Objectives
- Implement network policies for pod-to-pod isolation
- Control ingress and egress traffic between pods
- Create namespace-level network isolation
- Practice network security troubleshooting

## Prerequisites
- Lab 9 completed (Jobs and CronJobs)
- kubectl configured to use your namespace
- Calico network plugin installed (verify with instructor)

## Instructions

### Step 1: Clean Up and Test Initial Connectivity
Start by testing unrestricted pod connectivity:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete job --all
kubectl delete cronjob --all
kubectl delete networkpolicy --all

# Deploy test applications
sed 's/userX/user1/g' frontend-app.yaml > my-frontend-app.yaml
sed 's/userX/user1/g' backend-app.yaml > my-backend-app.yaml
sed 's/userX/user1/g' database-app.yaml > my-database-app.yaml
kubectl apply -f my-frontend-app.yaml -f my-backend-app.yaml -f my-database-app.yaml

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l tier=frontend --timeout=60s
kubectl wait --for=condition=Ready pod -l tier=backend --timeout=60s
kubectl wait --for=condition=Ready pod -l tier=database --timeout=60s

# Test connectivity (should work before policies)
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80
kubectl exec -it $(kubectl get pods -l tier=backend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-database-service 5432
```

### Step 2: Deploy Network Services
Create services for network policy testing:

```bash
# Deploy services
sed 's/userX/user1/g' network-services.yaml > my-network-services.yaml
kubectl apply -f my-network-services.yaml

# Verify services
kubectl get svc -l owner=user1
kubectl describe svc user1-frontend-service user1-backend-service user1-database-service
```

### Step 3: Implement Default Deny Policy
Create a baseline security posture:

```bash
# Apply deny-all network policy
sed 's/userX/user1/g' deny-all-policy.yaml > my-deny-all-policy.yaml
kubectl apply -f my-deny-all-policy.yaml

# Test connectivity (should fail now)
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- timeout 5 nc -zv user1-backend-service 80 || echo "Connection blocked as expected"

# Verify policy is active
kubectl get networkpolicy
kubectl describe networkpolicy user1-deny-all
```

### Step 4: Allow Frontend to Backend Communication
Create specific ingress rules:

```bash
# Allow frontend to reach backend
sed 's/userX/user1/g' allow-frontend-backend.yaml > my-allow-frontend-backend.yaml
kubectl apply -f my-allow-frontend-backend.yaml

# Test frontend to backend (should work)
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80

# Test backend to database (should still fail)
kubectl exec -it $(kubectl get pods -l tier=backend -o jsonpath='{.items[0].metadata.name}') -- timeout 5 nc -zv user1-database-service 5432 || echo "Connection still blocked"

# Check policy details
kubectl describe networkpolicy user1-allow-frontend-backend
```

### Step 5: Allow Backend to Database Communication
Enable database access for backend tier:

```bash
# Allow backend to reach database
sed 's/userX/user1/g' allow-backend-database.yaml > my-allow-backend-database.yaml
kubectl apply -f my-allow-backend-database.yaml

# Test full application flow
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80
kubectl exec -it $(kubectl get pods -l tier=backend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-database-service 5432

# Verify all network policies
kubectl get networkpolicy
kubectl describe networkpolicy user1-allow-backend-database
```

### Step 6: Test Egress Policies
Control outbound traffic from pods:

```bash
# Apply egress restrictions
sed 's/userX/user1/g' egress-policy.yaml > my-egress-policy.yaml
kubectl apply -f my-egress-policy.yaml

# Test external connectivity (should be limited)
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- timeout 5 nc -zv google.com 80 || echo "External access blocked"

# Test internal DNS still works
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nslookup user1-backend-service

# Check egress policy configuration
kubectl describe networkpolicy user1-egress-policy
```

### Step 7: Namespace Isolation
Create namespace-level network segmentation:

```bash
# Create additional namespace for testing
kubectl create namespace user1-isolated

# Apply namespace isolation policy
sed 's/userX/user1/g' namespace-isolation.yaml > my-namespace-isolation.yaml
kubectl apply -f my-namespace-isolation.yaml

# Deploy test pod in isolated namespace
kubectl run test-pod --image=nicolaka/netshoot --namespace=user1-isolated -- sleep 3600

# Test cross-namespace connectivity (should fail)
kubectl exec -n user1-isolated test-pod -- timeout 5 nc -zv user1-backend-service.default.svc.cluster.local 80 || echo "Cross-namespace blocked"

# Check namespace isolation policy
kubectl describe networkpolicy user1-namespace-isolation
```

### Step 8: Network Policy Troubleshooting
Practice debugging network connectivity issues:

```bash
# Check network policy conflicts
kubectl get networkpolicy -o wide
kubectl describe networkpolicy --all

# Verify pod labels match policy selectors
kubectl get pods --show-labels | grep user1

# Check for policy ordering issues
kubectl get networkpolicy -o yaml | grep -A 5 -B 5 "podSelector"

# Test with different pods to isolate issues
kubectl run debug-pod --image=nicolaka/netshoot -- sleep 3600
kubectl exec -it debug-pod -- nc -zv user1-frontend-service 80
```

### Step 9: Policy Performance and Monitoring
Monitor network policy effectiveness:

```bash
# Check Calico policy status (if available)
kubectl get pods -n kube-system -l k8s-app=calico-node

# View network policy events
kubectl get events --field-selector reason=NetworkPolicyEvaluated

# Test policy changes in real-time
kubectl scale deployment user1-frontend --replicas=3
kubectl get pods -l tier=frontend

# Monitor connectivity during scaling
for i in {1..5}; do
  kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80
  sleep 2
done
```

### Step 10: Policy Cleanup and Best Practices
Clean up and review security best practices:

```bash
# Review all active network policies
kubectl get networkpolicy
kubectl get networkpolicy -o yaml > network-policies-backup.yaml

# Test application functionality
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80
kubectl exec -it $(kubectl get pods -l tier=backend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-database-service 5432

# Clean up test resources
kubectl delete networkpolicy user1-deny-all user1-allow-frontend-backend user1-allow-backend-database user1-egress-policy user1-namespace-isolation
kubectl delete namespace user1-isolated
kubectl delete pod debug-pod test-pod --ignore-not-found=true

# Verify connectivity is restored
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80
```

## Verification Steps

```bash
# 1. Verify network policies were created
kubectl get networkpolicy | grep user1

# 2. Check pod connectivity follows policy rules
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- nc -zv user1-backend-service 80

# 3. Confirm egress restrictions work
kubectl apply -f my-egress-policy.yaml
kubectl exec -it $(kubectl get pods -l tier=frontend -o jsonpath='{.items[0].metadata.name}') -- timeout 5 nc -zv google.com 80 || echo "Egress blocked correctly"

# 4. Verify namespace isolation
kubectl get networkpolicy user1-namespace-isolation
```

## Key Takeaways
- Network policies provide micro-segmentation for pod traffic
- Default deny policies create secure baseline configurations
- Ingress rules control incoming traffic to pods
- Egress rules control outgoing traffic from pods
- Namespace isolation prevents cross-namespace communication
- Label selectors determine which pods policies apply to
- Network policies are additive - multiple policies can apply to same pod

## Cleanup
```bash
kubectl delete deployment user1-frontend user1-backend user1-database
kubectl delete service user1-frontend-service user1-backend-service user1-database-service
kubectl delete networkpolicy --all
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!