# Lab 13: Monitoring and Troubleshooting

## Duration: 45 minutes

## Objectives
- Use kubectl for debugging and troubleshooting techniques
- Analyze pod, service, and application logs
- Monitor resource usage and performance metrics
- Practice common troubleshooting scenarios
- Debug network connectivity issues
- Optimize resource usage and cleanup

## Prerequisites
- All previous labs completed
- kubectl configured to use your namespace
- Understanding of Kubernetes troubleshooting

## Instructions

### Step 1: Deploy Applications for Troubleshooting
Set up applications with common issues:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete service --all
kubectl delete pod --all

# Deploy application with resource issues
sed 's/userX/user1/g' problematic-app.yaml > my-problematic-app.yaml
kubectl apply -f my-problematic-app.yaml

# Deploy application with configuration problems
sed 's/userX/user1/g' broken-config-app.yaml > my-broken-config-app.yaml
kubectl apply -f my-broken-config-app.yaml

# Check initial status
kubectl get pods -l owner=user1
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Step 2: Basic Troubleshooting Techniques
Practice fundamental debugging commands:

```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces | grep -v Running

# Examine problematic pods
kubectl get pods -l app=problematic
kubectl describe pod $(kubectl get pods -l app=problematic -o jsonpath='{.items[0].metadata.name}')
kubectl logs $(kubectl get pods -l app=problematic -o jsonpath='{.items[0].metadata.name}')

# Check for previous container crashes
kubectl logs $(kubectl get pods -l app=problematic -o jsonpath='{.items[0].metadata.name}') --previous

# Review cluster events
kubectl get events --field-selector involvedObject.kind=Pod
kubectl get events --field-selector type=Warning
```

### Step 3: Resource Usage Analysis
Monitor and analyze resource consumption:

```bash
# Check current resource usage
kubectl top nodes
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory

# Examine node resource allocation
kubectl describe nodes | grep -A 5 "Allocated resources"

# Deploy resource-monitoring application
sed 's/userX/user1/g' resource-limited-app.yaml > my-resource-limited-app.yaml
kubectl apply -f my-resource-limited-app.yaml

# Monitor resource usage over time
kubectl top pods -l owner=user1
```

### Step 4: Network Connectivity Troubleshooting
Debug common network issues:

```bash
# Deploy test applications with services
sed 's/userX/user1/g' performance-app.yaml > my-performance-app.yaml
kubectl apply -f my-performance-app.yaml

# Create debug pod for network testing
kubectl run user1-debug --image=nicolaka/netshoot --command -- sleep 3600

# Test DNS resolution
kubectl exec user1-debug -- nslookup kubernetes.default
kubectl exec user1-debug -- nslookup user1-performance-service

# Test service connectivity
kubectl exec user1-debug -- nc -zv user1-performance-service 80
kubectl exec user1-debug -- curl -I user1-performance-service

# Check service endpoints
kubectl get endpoints user1-performance-service
kubectl describe endpoints user1-performance-service
```

### Step 5: Application Performance Debugging
Analyze application performance issues:

```bash
# Generate load for testing
sed 's/userX/user1/g' load-test.yaml > my-load-test.yaml
kubectl apply -f my-load-test.yaml

# Monitor performance during load
kubectl top pods -l app=performance --watch
# Press Ctrl+C after observing metrics

# Check application logs under load
kubectl logs -l app=performance --tail=50
kubectl logs -f deployment/user1-performance-app &

# Stop log streaming
kill %1

# Examine application internals
kubectl exec deployment/user1-performance-app -- ps aux
kubectl exec deployment/user1-performance-app -- free -h
```

### Step 6: Storage and Configuration Issues
Debug persistent volume and configuration problems:

```bash
# Check persistent volume claims
kubectl get pvc
kubectl describe pvc $(kubectl get pvc -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "no-pvc")

# Examine ConfigMaps and Secrets
kubectl get configmaps
kubectl get secrets
kubectl describe configmap $(kubectl get cm -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "no-cm")

# Test configuration loading
kubectl get pods -l app=broken-config
kubectl logs -l app=broken-config
```

### Step 7: Resource Quota and Limits Troubleshooting
Debug resource constraint issues:

```bash
# Create resource quota for testing
sed 's/userX/user1/g' namespace-quota.yaml > my-namespace-quota.yaml
kubectl apply -f my-namespace-quota.yaml

# Check current resource usage against quotas
kubectl describe quota user1-resource-quota
kubectl describe limitranges

# Attempt to deploy resource-intensive application
sed 's/userX/user1/g' optimized-app.yaml > my-optimized-app.yaml
kubectl apply -f my-optimized-app.yaml

# Debug quota violations
kubectl get events | grep quota
kubectl describe pod $(kubectl get pods -l app=optimized -o jsonpath='{.items[0].metadata.name}')
```

### Step 8: Log Analysis and Event Monitoring
Practice comprehensive log analysis:

```bash
# Aggregate logs from application pods
kubectl logs -l owner=user1 --tail=50

# Stream logs in real-time
kubectl logs -f deployment/user1-performance-app &

# Export logs for analysis
kubectl logs deployment/user1-performance-app > user1-performance-logs.txt

# Stop log streaming
kill %1

# Analyze events by type
kubectl get events --field-selector type=Warning
kubectl get events --field-selector type=Normal --sort-by=.metadata.creationTimestamp
```

### Step 9: Troubleshooting Summary and Best Practices
Review troubleshooting techniques:

```bash
# Check overall namespace health
kubectl get all -l owner=user1
kubectl top pods -l owner=user1

# Review resource consumption patterns
kubectl describe quota user1-resource-quota
kubectl top nodes

# Clean up debug resources
kubectl delete pod user1-debug
kubectl delete job user1-load-test

# Verify cleanup
kubectl get pods -l owner=user1
```

### Step 10: Final Cleanup and Documentation
Document findings and clean up:

```bash
# Document current resource usage
kubectl get all > user1-resource-summary.txt
kubectl top pods >> user1-resource-summary.txt

# Clean up test applications
kubectl delete deployment user1-problematic-app user1-broken-config-app user1-performance-app
kubectl delete quota user1-resource-quota

# Verify namespace is clean
kubectl get all
echo "Troubleshooting lab completed successfully!"
```

## Verification Steps

```bash
# 1. Check troubleshooting skills were practiced
kubectl get events --sort-by=.metadata.creationTimestamp | head -10

# 2. Verify resource monitoring works
kubectl top nodes
kubectl top pods

# 3. Confirm debugging commands work
kubectl logs --help | head -5
kubectl describe --help | head -5

# 4. Test network troubleshooting knowledge
kubectl run test-debug --image=nicolaka/netshoot --rm -it --command -- nslookup kubernetes.default

# 5. Verify cleanup was successful
kubectl get all -l owner=user1
```

## Key Takeaways
- kubectl describe and logs are essential for debugging
- Events provide valuable troubleshooting information
- Resource monitoring helps identify performance issues
- Network connectivity problems can be debugged systematically
- Proper resource limits prevent application issues
- Regular cleanup keeps namespaces organized
- Troubleshooting is a systematic process of elimination

## Cleanup
```bash
kubectl delete deployment user1-problematic-app user1-broken-config-app user1-performance-app user1-resource-limited-app user1-optimized-app
kubectl delete quota user1-resource-quota
kubectl delete pod user1-debug --ignore-not-found=true
kubectl delete job user1-load-test --ignore-not-found=true
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
13. **Monitoring and Troubleshooting** - Debugging and operational practices

You now have hands-on experience with essential EKS and Kubernetes concepts!

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!