# Lab 12: Ingress and Load Balancing

## Duration: 45 minutes

## Objectives
- Deploy and configure Kubernetes Ingress controllers
- Create Ingress rules for HTTP and HTTPS traffic routing
- Implement path-based and host-based routing
- Configure SSL/TLS termination at the Ingress
- Practice load balancing scenarios with multiple backends

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

### Step 4: Configure Host-Based Routing
Set up virtual hosts with different domain names:

```bash
# Deploy host-based ingress
sed 's/userX/user1/g' host-based-ingress.yaml > my-host-based-ingress.yaml
kubectl apply -f my-host-based-ingress.yaml

# Verify ingress rules
kubectl get ingress user1-host-ingress -o yaml
kubectl describe ingress user1-host-ingress

# Test host-based routing
kubectl exec -it test-client -- curl -H "Host: user1-frontend.example.com" user1-frontend-service/
kubectl exec -it test-client -- curl -H "Host: user1-api.example.com" user1-api-service/health
kubectl exec -it test-client -- curl -H "Host: user1-admin.example.com" user1-admin-service/
```

### Step 5: SSL/TLS Termination
Configure HTTPS with SSL certificates:

```bash
# Create TLS secret for HTTPS
sed 's/userX/user1/g' tls-secret.yaml > my-tls-secret.yaml
kubectl apply -f my-tls-secret.yaml

# Deploy HTTPS-enabled ingress
sed 's/userX/user1/g' https-ingress.yaml > my-https-ingress.yaml
kubectl apply -f my-https-ingress.yaml

# Verify TLS configuration
kubectl describe ingress user1-https-ingress
kubectl get secret user1-tls-secret

# Test HTTPS endpoint (internal testing)
kubectl exec -it test-client -- curl -k -H "Host: user1-secure.example.com" https://user1-frontend-service/
```

### Step 6: Advanced Load Balancing
Configure load balancing with multiple replicas:

```bash
# Scale backend services for load balancing
kubectl scale deployment user1-frontend --replicas=3
kubectl scale deployment user1-api-backend --replicas=2
kubectl scale deployment user1-admin --replicas=2

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app=frontend --timeout=120s
kubectl wait --for=condition=Ready pod -l app=api-backend --timeout=120s

# Deploy load balancer ingress with session affinity
sed 's/userX/user1/g' loadbalancer-ingress.yaml > my-loadbalancer-ingress.yaml
kubectl apply -f my-loadbalancer-ingress.yaml

# Test load balancing
for i in {1..10}; do
  kubectl exec -it test-client -- curl -H "Host: user1-lb.example.com" user1-frontend-service/ | grep -o "Pod: user1-frontend-[^<]*"
  sleep 1
done
```

### Step 7: Ingress with Rewrite Rules
Implement URL rewriting and redirection:

```bash
# Deploy ingress with URL rewriting
sed 's/userX/user1/g' rewrite-ingress.yaml > my-rewrite-ingress.yaml
kubectl apply -f my-rewrite-ingress.yaml

# Test URL rewriting
kubectl exec -it test-client -- curl -H "Host: user1-rewrite.example.com" user1-frontend-service/old-path
kubectl exec -it test-client -- curl -v -H "Host: user1-rewrite.example.com" user1-frontend-service/redirect-me

# Check ingress annotations
kubectl get ingress user1-rewrite-ingress -o yaml | grep -A 5 annotations
```

### Step 8: Ingress Monitoring and Troubleshooting
Practice diagnosing ingress issues:

```bash
# Check ingress controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=ingress-nginx --tail=50

# Verify ingress backend endpoints
kubectl get endpoints user1-frontend-service user1-api-service user1-admin-service

# Check ingress controller status
kubectl get pods -n kube-system -l app.kubernetes.io/name=ingress-nginx

# Test connectivity to individual services
kubectl exec -it test-client -- nc -zv user1-frontend-service 80
kubectl exec -it test-client -- nc -zv user1-api-service 8080
kubectl exec -it test-client -- nc -zv user1-admin-service 80

# Debug ingress events
kubectl get events --field-selector involvedObject.kind=Ingress
```

### Step 9: Multiple Ingress Classes
Work with different ingress classes and controllers:

```bash
# Deploy ingress with specific class
sed 's/userX/user1/g' class-specific-ingress.yaml > my-class-specific-ingress.yaml
kubectl apply -f my-class-specific-ingress.yaml

# List available ingress classes
kubectl get ingressclass

# Check ingress class assignment
kubectl get ingress user1-class-ingress -o yaml | grep -A 2 ingressClassName

# Verify controller handling the ingress
kubectl describe ingress user1-class-ingress | grep -A 5 "Events"
```

### Step 10: Ingress Performance and Scaling
Test ingress performance under load:

```bash
# Create load testing job
sed 's/userX/user1/g' load-test-job.yaml > my-load-test-job.yaml
kubectl apply -f my-load-test-job.yaml

# Monitor load test progress
kubectl logs -f job/user1-load-test

# Check ingress performance metrics (if available)
kubectl top pods -l app.kubernetes.io/name=ingress-nginx -n kube-system

# Scale ingress controller (if supported)
kubectl get deployment -n kube-system -l app.kubernetes.io/name=ingress-nginx

# Clean up load test
kubectl delete job user1-load-test
```

## Verification Steps

```bash
# 1. Verify ingress resources are created
kubectl get ingress | grep user1

# 2. Check external IP assignment
kubectl get ingress user1-basic-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 3. Test path-based routing
kubectl exec -it test-client -- curl -H "Host: user1-app.example.com" user1-frontend-service/api/health

# 4. Verify TLS configuration
kubectl get secret user1-tls-secret
kubectl describe ingress user1-https-ingress | grep -A 3 "TLS"

# 5. Confirm load balancing across replicas
kubectl get pods -l app=frontend -o wide
```

## Key Takeaways
- Ingress provides HTTP/HTTPS routing to services
- Path-based routing directs traffic based on URL paths
- Host-based routing uses different hostnames for routing
- TLS termination can be handled at the Ingress layer
- Session affinity controls load balancing behavior
- Ingress controllers implement the routing rules
- Multiple ingress classes support different controllers

## Cleanup
```bash
kubectl delete deployment user1-frontend user1-api-backend user1-admin
kubectl delete service user1-frontend-service user1-api-service user1-admin-service
kubectl delete ingress --all
kubectl delete secret user1-tls-secret
kubectl delete pod test-client
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!