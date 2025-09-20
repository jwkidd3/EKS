# Lab 3: Services and Application Exposure

## Duration: 45 minutes

## Objectives
- Create different Service types (ClusterIP, NodePort, LoadBalancer)
- Test service connectivity between Pods
- Understand service discovery and DNS resolution
- Practice service troubleshooting techniques

## Prerequisites
- Lab 2 completed (basic pods created)
- kubectl configured to use your namespace

## Instructions

> **🌐 SERVICE NETWORKING:** This lab creates various service types that expose your applications. Each service name is customized with your username to avoid port conflicts and ensure proper load balancer isolation in the shared cluster.

### Step 1: Prepare Your Environment
First, ensure you have some pods running to expose:

```bash
# Check current namespace
kubectl config view --minify | grep namespace

# Create the nginx deployment for this lab
sed 's/userX/user1/g' nginx-deployment.yaml > my-nginx-deployment.yaml
kubectl apply -f my-nginx-deployment.yaml

# Verify pods are running
kubectl get pods -l app=nginx
```

### Step 2: Create a ClusterIP Service
ClusterIP is the default service type, providing internal cluster access:

```bash
# Create a ClusterIP service
sed 's/userX/user1/g' clusterip-service.yaml > my-clusterip-service.yaml
kubectl apply -f my-clusterip-service.yaml

# Check the service
kubectl get svc
kubectl describe svc user1-nginx-clusterip

# Note the cluster IP and port
kubectl get svc user1-nginx-clusterip -o wide
```

### Step 3: Test ClusterIP Service Connectivity
Test internal connectivity using a test pod:

```bash
# Create a test pod for connectivity testing
sed 's/userX/user1/g' test-pod.yaml > my-test-pod.yaml
kubectl apply -f my-test-pod.yaml

# Wait for test pod to be ready
kubectl wait --for=condition=Ready pod/user1-test-pod --timeout=60s

# Test connectivity using cluster IP
CLUSTER_IP=$(kubectl get svc user1-nginx-clusterip -o jsonpath='{.spec.clusterIP}')
kubectl exec user1-test-pod -- curl -s http://$CLUSTER_IP:80

# Test connectivity using service name (DNS)
kubectl exec user1-test-pod -- curl -s http://user1-nginx-clusterip:80
```

### Step 4: Create a NodePort Service
NodePort exposes the service on each node's IP at a static port:

```bash
# Create a NodePort service
sed 's/userX/user1/g' nodeport-service.yaml > my-nodeport-service.yaml
kubectl apply -f my-nodeport-service.yaml

# Check the NodePort service
kubectl get svc user1-nginx-nodeport
kubectl describe svc user1-nginx-nodeport

# Get the NodePort
NODEPORT=$(kubectl get svc user1-nginx-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODEPORT"
```

### Step 5: Test NodePort Service
Test the NodePort service from within the cluster:

```bash
# Get node internal IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test from test pod
kubectl exec user1-test-pod -- curl -s http://$NODE_IP:$NODEPORT

# Check if external access is available (may not work in all environments)
kubectl get nodes -o wide
```

### Step 6: Create a LoadBalancer Service
LoadBalancer provides external access through cloud provider's load balancer:

```bash
# Create a LoadBalancer service
sed 's/userX/user1/g' loadbalancer-service.yaml > my-loadbalancer-service.yaml
kubectl apply -f my-loadbalancer-service.yaml

# Check the LoadBalancer service (may take a few minutes to get external IP)
kubectl get svc user1-nginx-loadbalancer
kubectl describe svc user1-nginx-loadbalancer

# Wait for external IP (this may take several minutes)
kubectl get svc user1-nginx-loadbalancer -w
```

### Step 7: Service Discovery and DNS
Explore Kubernetes DNS resolution:

```bash
# Test different DNS names from test pod
kubectl exec user1-test-pod -- nslookup user1-nginx-clusterip

# Test full DNS name
kubectl exec user1-test-pod -- nslookup user1-nginx-clusterip.userX-namespace.svc.cluster.local

# Test other namespace services (should fail)
kubectl exec user1-test-pod -- nslookup kubernetes.default

# List all service DNS entries
kubectl exec user1-test-pod -- cat /etc/resolv.conf
```

### Step 8: Service Endpoints
Understand how services map to pod endpoints:

```bash
# Check service endpoints
kubectl get endpoints
kubectl describe endpoints user1-nginx-clusterip

# Compare with pod IPs
kubectl get pods -l app=nginx -o wide

# Scale the deployment and watch endpoints
kubectl scale deployment user1-nginx-deployment --replicas=3
kubectl get endpoints user1-nginx-clusterip -w
```

### Step 9: Service Labels and Selectors
Understand how services find pods:

```bash
# Check service selector
kubectl get svc user1-nginx-clusterip -o yaml | grep -A 5 selector

# Check pod labels
kubectl get pods -l app=nginx --show-labels

# Create a pod with different labels
sed 's/userX/user1/g' different-label-pod.yaml > my-different-label-pod.yaml
kubectl apply -f my-different-label-pod.yaml

# Check endpoints again
kubectl get endpoints user1-nginx-clusterip
```

### Step 10: Troubleshooting Services
Practice common service troubleshooting:

```bash
# Create a service with wrong selector
sed 's/userX/user1/g' wrong-selector-service.yaml > my-wrong-selector-service.yaml
kubectl apply -f my-wrong-selector-service.yaml

# Check why this service has no endpoints
kubectl get endpoints user1-wrong-service
kubectl describe svc user1-wrong-service

# Fix the service
kubectl patch svc user1-wrong-service -p '{"spec":{"selector":{"app":"nginx"}}}'
kubectl get endpoints user1-wrong-service
```

### Step 11: Multi-Port Services
Create a service with multiple ports:

```bash
# Create a multi-port deployment
sed 's/userX/user1/g' multi-port-deployment.yaml > my-multi-port-deployment.yaml
kubectl apply -f my-multi-port-deployment.yaml

# Create a multi-port service
sed 's/userX/user1/g' multi-port-service.yaml > my-multi-port-service.yaml
kubectl apply -f my-multi-port-service.yaml

# Test both ports
kubectl exec user1-test-pod -- curl -s http://user1-multi-port-service:80
kubectl exec user1-test-pod -- curl -s http://user1-multi-port-service:8080/status
```

### Step 12: Service Load Balancing
Test load balancing across multiple pods:

```bash
# Ensure multiple replicas
kubectl scale deployment user1-nginx-deployment --replicas=3
kubectl get pods -l app=nginx

# Test load balancing
for i in {1..10}; do
  kubectl exec user1-test-pod -- curl -s http://user1-nginx-clusterip | grep -o "Server address.*"
done
```

## Verification Steps

### Verify Your Services
Run these commands to check your work:

```bash
# 1. List all services
kubectl get svc

# 2. Check service endpoints
kubectl get endpoints

# 3. Test service connectivity
kubectl exec user1-test-pod -- curl -s http://user1-nginx-clusterip:80

# 4. Check external access (if LoadBalancer has external IP)
EXTERNAL_IP=$(kubectl get svc user1-nginx-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -n "$EXTERNAL_IP" ]; then
  echo "External access: http://$EXTERNAL_IP"
fi
```

## Clean Up (Optional)
Remove services if needed:

```bash
# Delete specific services
kubectl delete svc user1-wrong-service

# Delete all services with your prefix
kubectl delete svc -l owner=user1
```

## Troubleshooting

### Common Issues
1. **Service has no endpoints**: Check if pods have correct labels
2. **Cannot connect to service**: Verify service selector matches pod labels
3. **LoadBalancer stuck in pending**: Check cloud provider configuration
4. **DNS resolution fails**: Verify pod and service are in same namespace

### Useful Commands
```bash
# Debug service issues
kubectl describe svc <service-name>
kubectl get endpoints <service-name>
kubectl logs <pod-name>

# Test connectivity
kubectl exec <test-pod> -- curl -v http://<service-name>:<port>
kubectl exec <test-pod> -- telnet <service-ip> <port>
```

## Key Concepts Learned
- **ClusterIP**: Internal cluster communication
- **NodePort**: External access through node ports
- **LoadBalancer**: External access through cloud load balancer
- **Service Discovery**: DNS-based service resolution
- **Endpoints**: How services map to pod IPs
- **Selectors**: How services find target pods
- **Load Balancing**: Traffic distribution across pods

## Next Steps
In the next lab, you'll learn about Deployments and ReplicaSets for managing multiple pod replicas and updates.

---

**Remember**: Always prefix your resources with your username and work within your namespace!