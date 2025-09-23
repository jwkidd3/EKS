# Lab 13: Troubleshooting and Advanced Deployment Patterns

## Duration: 45 minutes

## Objectives
- Use kubectl for advanced debugging techniques
- Analyze Pod, Service, and Ingress logs
- Monitor resource usage and performance metrics
- Implement blue-green deployments
- Practice canary deployments with traffic splitting
- Configure resource limits and requests
- Clean up resources and optimize namespace usage

## Prerequisites
- All previous labs completed
- kubectl configured to use your namespace
- Understanding of Kubernetes troubleshooting

## Instructions

> **🔧 ADVANCED DEPLOYMENTS & TROUBLESHOOTING:** This lab tests multiple deployment patterns and troubleshooting scenarios. All resources use your username prefix to isolate testing environments and prevent interference with other students' blue-green and canary deployments.

### Step 1: Set Up Problematic Applications
Deploy applications with intentional issues:

```bash
# Clean previous resources
kubectl delete all --all

# Deploy app with resource issues
sed 's/userX/user1/g' problematic-app.yaml > my-problematic-app.yaml
kubectl apply -f my-problematic-app.yaml

# Deploy app with configuration issues
sed 's/userX/user1/g' broken-config-app.yaml > my-broken-config-app.yaml
kubectl apply -f my-broken-config-app.yaml
```

### Step 2: Practice Advanced Debugging
Use various debugging techniques:

```bash
# Check overall cluster health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Debug pod issues
kubectl describe pod $(kubectl get pods -l app=problematic -o jsonpath='{.items[0].metadata.name}')
kubectl logs $(kubectl get pods -l app=problematic -o jsonpath='{.items[0].metadata.name}') --previous

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.kind=Pod

# Resource usage debugging
kubectl top pods
kubectl describe node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
```

### Step 3: Implement Blue-Green Deployment
Practice zero-downtime deployment patterns:

```bash
# Deploy blue version
sed 's/userX/user1/g' blue-green-blue.yaml > my-blue-green-blue.yaml
kubectl apply -f my-blue-green-blue.yaml

# Create service pointing to blue
sed 's/userX/user1/g' blue-green-service.yaml > my-blue-green-service.yaml
kubectl apply -f my-blue-green-service.yaml

# Test blue version
kubectl exec deployment/user1-blue-app -- curl -s http://user1-blue-green-service/version

# Deploy green version
sed 's/userX/user1/g' blue-green-green.yaml > my-blue-green-green.yaml
kubectl apply -f my-blue-green-green.yaml

# Switch traffic to green
kubectl patch service user1-blue-green-service -p '{"spec":{"selector":{"version":"green"}}}'

# Verify switch
kubectl exec deployment/user1-green-app -- curl -s http://user1-blue-green-service/version
```

### Step 4: Implement Canary Deployment
Practice gradual rollouts:

```bash
# Deploy stable version
sed 's/userX/user1/g' canary-stable.yaml > my-canary-stable.yaml
kubectl apply -f my-canary-stable.yaml

# Deploy canary version (10% traffic)
sed 's/userX/user1/g' canary-version.yaml > my-canary-version.yaml
kubectl apply -f my-canary-version.yaml

# Create service for canary testing
sed 's/userX/user1/g' canary-service.yaml > my-canary-service.yaml
kubectl apply -f my-canary-service.yaml

# Test traffic distribution
for i in {1..20}; do
  kubectl exec deployment/user1-canary-stable -- curl -s http://user1-canary-service/version
done
```

### Step 5: Monitor and Optimize Resources
Analyze resource usage and optimize:

```bash
# Check resource utilization
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory

# Analyze resource requests vs usage
kubectl describe nodes | grep -A 5 "Allocated resources"

# Deploy resource-optimized application
sed 's/userX/user1/g' optimized-app.yaml > my-optimized-app.yaml
kubectl apply -f my-optimized-app.yaml
```

### Step 6: Implement Proper Resource Limits
Configure appropriate resource constraints:

```bash
# Deploy app with proper resource limits
sed 's/userX/user1/g' resource-limited-app.yaml > my-resource-limited-app.yaml
kubectl apply -f my-resource-limited-app.yaml

# Create resource quota for namespace
sed 's/userX/user1/g' namespace-quota.yaml > my-namespace-quota.yaml
kubectl apply -f my-namespace-quota.yaml

# Verify quota enforcement
kubectl describe quota user1-resource-quota
```

### Step 7: Advanced Troubleshooting Scenarios
Practice complex debugging:

```bash
# Network connectivity issues
kubectl exec deployment/user1-canary-stable -- nslookup user1-canary-service
kubectl exec deployment/user1-canary-stable -- curl -v http://user1-canary-service

# Performance troubleshooting
kubectl exec deployment/user1-optimized-app -- top -n 1
kubectl exec deployment/user1-optimized-app -- free -h

# Storage issues
kubectl get pv
kubectl get pvc
kubectl describe pvc $(kubectl get pvc -o jsonpath='{.items[0].metadata.name}')
```

### Step 8: Log Analysis and Monitoring
Implement comprehensive logging:

```bash
# Aggregate logs from multiple pods
kubectl logs -l app=canary-stable --tail=50

# Stream logs in real-time
kubectl logs -f deployment/user1-canary-stable &

# Export logs for analysis
kubectl logs deployment/user1-optimized-app > user1-app-logs.txt

# Stop log streaming
kill %1
```

### Step 9: Performance Optimization
Optimize application performance:

```bash
# Deploy performance-tuned application
sed 's/userX/user1/g' performance-app.yaml > my-performance-app.yaml
kubectl apply -f my-performance-app.yaml

# Load test the application
sed 's/userX/user1/g' load-test.yaml > my-load-test.yaml
kubectl apply -f my-load-test.yaml

# Monitor during load test
kubectl top pods -l app=performance
```

### Step 10: Final Cleanup and Optimization
Clean up and optimize namespace usage:

```bash
# List all resources in namespace
kubectl get all
kubectl get pvc
kubectl get secrets
kubectl get configmaps

# Selective cleanup of unused resources
kubectl delete deployment $(kubectl get deployments -o jsonpath='{.items[?(@.status.replicas==0)].metadata.name}')

# Final resource usage check
kubectl describe namespace user1-namespace
kubectl top pods
```

## Verification Steps
Run comprehensive verification:

```bash
# 1. Check all deployments are healthy
kubectl get deployments -o wide

# 2. Verify services are working
kubectl get svc
kubectl get endpoints

# 3. Test application connectivity
kubectl exec deployment/user1-performance-app -- curl -s http://user1-canary-service/health

# 4. Check resource utilization
kubectl top pods --sort-by=cpu

# 5. Verify no failed pods
kubectl get pods | grep -v Running || echo "All pods running successfully"
```

## Key Concepts Learned
- **Advanced Debugging**: Using kubectl for complex troubleshooting
- **Blue-Green Deployments**: Zero-downtime deployment strategy
- **Canary Deployments**: Gradual rollout with traffic splitting
- **Resource Optimization**: Right-sizing applications
- **Performance Monitoring**: Analyzing and improving performance
- **Log Management**: Collecting and analyzing application logs
- **Namespace Management**: Organizing and cleaning up resources

## Final Cleanup
Complete cleanup of all lab resources:

```bash
# Delete all resources in namespace
kubectl delete all --all
kubectl delete pvc --all
kubectl delete secrets --all --field-selector type!=kubernetes.io/service-account-token
kubectl delete configmaps --all
kubectl delete networkpolicies --all
kubectl delete roles --all
kubectl delete rolebindings --all
kubectl delete serviceaccounts --all --field-selector metadata.name!=default

# Verify namespace is clean
kubectl get all
echo "Lab environment cleaned successfully!"
```

## Course Summary
Congratulations! You have completed all 13 labs covering:

1. **Cluster Exploration** - Understanding EKS basics
2. **Pod Management** - Working with basic Kubernetes objects
3. **Service Discovery** - Networking and service exposure
4. **Deployments and ReplicaSets** - Application lifecycle management
5. **ConfigMaps and Secrets** - Configuration management
6. **Persistent Volumes and Storage** - Data persistence
7. **Resource Management and Autoscaling** - Dynamic resource allocation
8. **Health Checks and Probes** - Application monitoring and reliability
9. **Jobs and CronJobs** - Batch processing and scheduled tasks
10. **Network Policies and Security** - Traffic control and isolation
11. **StatefulSets and Headless Services** - Stateful application management
12. **Ingress and Load Balancing** - HTTP/HTTPS traffic routing
13. **Monitoring and Troubleshooting** - Advanced debugging and deployment patterns

You now have hands-on experience with essential EKS and Kubernetes concepts!

---

**Remember**: Practice these concepts in real-world scenarios to master EKS!