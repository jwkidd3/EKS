# Lab 12: Ingress and Load Balancing

## Duration: 45 minutes

## Objectives
- Deploy and configure Kubernetes Ingress resources
- Create basic HTTP routing with Ingress
- Implement path-based routing for different services
- Practice basic load balancing with Ingress
- Troubleshoot ingress connectivity issues

## Prerequisites
- Lab 11 completed (StatefulSets and Headless Services)
- kubectl configured to use your namespace
- Understanding of DNS and HTTP routing concepts

## Instructions

### Step 1: Clean Up and Deploy Application Services
Start by creating backend services for Ingress testing:

```bash
# Clean up previous resources
kubectl delete statefulset --all
kubectl delete service --all
kubectl delete pod --all

# Deploy frontend application
sed 's/userX/user1/g' frontend-app.yaml > my-frontend-app.yaml
kubectl apply -f my-frontend-app.yaml

# Deploy API backend application
sed 's/userX/user1/g' api-backend.yaml > my-api-backend.yaml
kubectl apply -f my-api-backend.yaml

# Deploy admin application
sed 's/userX/user1/g' admin-app.yaml > my-admin-app.yaml
kubectl apply -f my-admin-app.yaml

# Verify services are running
kubectl get pods,svc -l owner=user1
```

### Step 2: Create Basic Ingress Resource
Configure basic HTTP routing with Ingress:

```bash
# Deploy basic ingress for frontend
sed 's/userX/user1/g' basic-ingress.yaml > my-basic-ingress.yaml
kubectl apply -f my-basic-ingress.yaml

# Check ingress status and assigned IP
kubectl get ingress user1-basic-ingress
kubectl describe ingress user1-basic-ingress

# Wait for ingress to get an external IP (may take a few minutes)
kubectl get ingress user1-basic-ingress -w
# Press Ctrl+C once external IP is assigned
```

### Step 3: Implement Path-Based Routing
Create advanced routing rules based on URL paths:

```bash
# Deploy path-based ingress
sed 's/userX/user1/g' path-based-ingress.yaml > my-path-based-ingress.yaml
kubectl apply -f my-path-based-ingress.yaml

# Test different paths (requires external access)
INGRESS_IP=$(kubectl get ingress user1-path-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"

# Create test pod to test internal routing
kubectl run test-client --image=nicolaka/netshoot --command -- sleep 3600

# Test routing from inside cluster
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/api/health
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/admin/
```

### Step 4: Test Load Balancing
Scale services and test load distribution:

```bash
# Scale frontend service for load balancing
kubectl scale deployment user1-frontend --replicas=3
kubectl scale deployment user1-api-backend --replicas=2

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app=frontend --timeout=120s
kubectl wait --for=condition=Ready pod -l app=api-backend --timeout=120s

# Test load balancing across replicas
for i in {1..10}; do
  kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/
  sleep 1
done
```

### Step 5: Ingress Troubleshooting
Practice diagnosing ingress issues:

```bash
# Check ingress controller status (if available)
kubectl get pods -n kube-system -l app.kubernetes.io/name=ingress-nginx

# Verify ingress backend endpoints
kubectl get endpoints user1-frontend-service user1-api-service user1-admin-service

# Test connectivity to individual services
kubectl exec -it test-client -- nc -zv user1-frontend-service 80
kubectl exec -it test-client -- nc -zv user1-api-service 8080

# Debug ingress events
kubectl get events --field-selector involvedObject.kind=Ingress
kubectl describe ingress user1-path-ingress
```

### Step 6: Monitor Ingress Status
Check ingress health and configuration:

```bash
# Review all ingress resources
kubectl get ingress
kubectl describe ingress user1-basic-ingress
kubectl describe ingress user1-path-ingress

# Check ingress events
kubectl get events --field-selector involvedObject.kind=Ingress

# Monitor ingress over time
kubectl get ingress -w &
# Press Ctrl+C to stop after a few seconds

# Verify service endpoints behind ingress
kubectl get endpoints user1-frontend-service user1-api-service user1-admin-service
```

### Step 7: Test Ingress Connectivity
Verify ingress routing works correctly:

```bash
# Test basic ingress connectivity
kubectl exec -it test-client -- curl user1-frontend-service/

# Test path-based routing
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/api/health

# Test direct service access vs ingress
kubectl exec -it test-client -- curl user1-api-service:8080/health
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/api/health
```

### Step 8: Ingress Resource Management
Practice managing ingress resources:

```bash
# Update ingress configuration
kubectl patch ingress user1-basic-ingress -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/"}}}'

# Check updated configuration
kubectl describe ingress user1-basic-ingress | grep -A 5 "Annotations"

# List all ingress resources with details
kubectl get ingress -o wide

# Export ingress configuration for backup
kubectl get ingress user1-basic-ingress -o yaml > user1-basic-ingress-backup.yaml
```

### Step 9: Cleanup and Best Practices
Clean up resources and review best practices:

```bash
# Delete test client
kubectl delete pod test-client

# Review ingress resource usage
kubectl get ingress
kubectl get services

# Scale down deployments
kubectl scale deployment user1-frontend --replicas=1
kubectl scale deployment user1-api-backend --replicas=1

# Verify ingress still works with fewer replicas
kubectl run temp-test --image=nicolaka/netshoot --rm -it --command -- curl -H "Host: user1-app.example.com" user1-frontend-service/
```

## Verification Steps

```bash
# 1. Verify ingress resources are created
kubectl get ingress | grep user1

# 2. Check ingress backend services
kubectl get endpoints user1-frontend-service user1-api-service user1-admin-service

# 3. Test basic ingress connectivity
kubectl run verify-test --image=nicolaka/netshoot --rm -it --command -- curl user1-frontend-service/

# 4. Test path-based routing functionality
kubectl run verify-path --image=nicolaka/netshoot --rm -it --command -- curl -H "Host: user1-app.example.com" user1-frontend-service/api/health

# 5. Confirm load balancing works
kubectl get pods -l app=frontend -o wide
kubectl get pods -l app=api-backend -o wide
```

## Key Takeaways
- Ingress provides HTTP routing to Kubernetes services
- Path-based routing directs traffic based on URL paths
- Ingress resources require backend services to function
- Load balancing distributes traffic across multiple pod replicas
- Ingress controllers implement and manage routing rules
- Troubleshooting involves checking services, endpoints, and events

## Cleanup
```bash
kubectl delete deployment user1-frontend user1-api-backend user1-admin
kubectl delete service user1-frontend-service user1-api-service user1-admin-service
kubectl delete ingress user1-basic-ingress user1-path-ingress
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!