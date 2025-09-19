# Lab 7: Application Health and Monitoring

## Duration: 45 minutes

## Objectives
- Configure Liveness Probes for automatic Pod restarts
- Set up Readiness Probes for traffic management
- Test probe behavior with intentionally broken applications
- Monitor application health through Kubernetes events
- Troubleshoot and fix unhealthy applications

## Prerequisites
- Lab 6 completed (Helm deployments)
- kubectl configured to use your namespace
- Understanding of basic Kubernetes concepts

## Instructions

### Step 1: Clean Up Previous Resources
Start with a clean environment:

```bash
# Clean up previous lab resources
kubectl delete deployment --all
kubectl delete svc --all
kubectl delete configmap --all
helm uninstall --all
kubectl get all

# Verify namespace is clean
kubectl get pods
```

### Step 2: Deploy Application with Basic Health Checks
Deploy an application with initial health probe configuration:

```bash
# Deploy application with basic health checks
sed 's/userX/user1/g' app-with-health-checks.yaml > my-app-with-health-checks.yaml
kubectl apply -f my-app-with-health-checks.yaml

# Check deployment status
kubectl get deployments
kubectl get pods -w

# Check pod details to see probe configuration
kubectl describe pod $(kubectl get pods -l app=health-demo -o jsonpath='{.items[0].metadata.name}')
```

### Step 3: Configure Liveness Probes
Create deployments with various liveness probe configurations:

```bash
# Deploy app with HTTP liveness probe
sed 's/userX/user1/g' liveness-http-probe.yaml > my-liveness-http-probe.yaml
kubectl apply -f my-liveness-http-probe.yaml

# Deploy app with command-based liveness probe
sed 's/userX/user1/g' liveness-exec-probe.yaml > my-liveness-exec-probe.yaml
kubectl apply -f my-liveness-exec-probe.yaml

# Deploy app with TCP liveness probe
sed 's/userX/user1/g' liveness-tcp-probe.yaml > my-liveness-tcp-probe.yaml
kubectl apply -f my-liveness-tcp-probe.yaml

# Check all deployments
kubectl get deployments
kubectl get pods
```

### Step 4: Configure Readiness Probes
Set up readiness probes for traffic management:

```bash
# Deploy app with readiness probe
sed 's/userX/user1/g' readiness-probe.yaml > my-readiness-probe.yaml
kubectl apply -f my-readiness-probe.yaml

# Create service to test traffic routing
sed 's/userX/user1/g' health-service.yaml > my-health-service.yaml
kubectl apply -f my-health-service.yaml

# Check service endpoints
kubectl get svc
kubectl get endpoints
kubectl describe endpoints user1-health-service
```

### Step 5: Test Probe Behavior with Healthy Applications
Test how probes work with functioning applications:

```bash
# Create test pod for connectivity testing
sed 's/userX/user1/g' health-test-pod.yaml > my-health-test-pod.yaml
kubectl apply -f my-health-test-pod.yaml

# Test health endpoints from test pod
kubectl exec user1-health-test -- curl -s http://user1-health-service/health
kubectl exec user1-health-test -- curl -s http://user1-health-service/ready

# Monitor pod status
kubectl get pods -l app=readiness-demo -o wide
kubectl describe pod $(kubectl get pods -l app=readiness-demo -o jsonpath='{.items[0].metadata.name}') | grep -A 10 Conditions
```

### Step 6: Simulate Application Failures
Create applications that will fail health checks:

```bash
# Deploy app that fails liveness checks
sed 's/userX/user1/g' failing-liveness.yaml > my-failing-liveness.yaml
kubectl apply -f my-failing-liveness.yaml

# Deploy app that fails readiness checks
sed 's/userX/user1/g' failing-readiness.yaml > my-failing-readiness.yaml
kubectl apply -f my-failing-readiness.yaml

# Watch pod behavior
kubectl get pods -l app=failing-liveness -w &
kubectl get pods -l app=failing-readiness -w &

# Stop watching after observing restarts
sleep 60
kill %1 %2
```

### Step 7: Monitor Kubernetes Events
Learn to monitor application health through events:

```bash
# Watch events in real-time
kubectl get events --sort-by=.metadata.creationTimestamp

# Filter events for specific applications
kubectl get events --field-selector involvedObject.name=user1-failing-liveness

# Get events for the entire namespace
kubectl get events --all-namespaces | grep user1-namespace

# Describe problematic pods to see detailed events
kubectl describe pod $(kubectl get pods -l app=failing-liveness -o jsonpath='{.items[0].metadata.name}')
```

### Step 8: Configure Startup Probes for Slow-Starting Applications
Handle applications that take time to start:

```bash
# Deploy slow-starting application with startup probe
sed 's/userX/user1/g' startup-probe.yaml > my-startup-probe.yaml
kubectl apply -f my-startup-probe.yaml

# Monitor startup behavior
kubectl get pods -l app=slow-start -w &

# Check probe configuration
kubectl describe pod $(kubectl get pods -l app=slow-start -o jsonpath='{.items[0].metadata.name}') | grep -A 20 "Liveness\|Readiness\|Startup"

# Stop watching
sleep 120
kill %1
```

### Step 9: Implement Multi-Container Pod Health Checks
Deploy pods with multiple containers and health checks:

```bash
# Deploy multi-container pod with health checks
sed 's/userX/user1/g' multi-container-health.yaml > my-multi-container-health.yaml
kubectl apply -f my-multi-container-health.yaml

# Check status of all containers in the pod
kubectl get pods -l app=multi-container
kubectl describe pod $(kubectl get pods -l app=multi-container -o jsonpath='{.items[0].metadata.name}')

# Test both containers' health endpoints
kubectl exec user1-health-test -- curl -s http://user1-multi-service:8080/health
kubectl exec user1-health-test -- curl -s http://user1-multi-service:9090/health
```

### Step 10: Configure Probe Timing and Thresholds
Fine-tune probe configurations for optimal behavior:

```bash
# Deploy app with custom probe timing
sed 's/userX/user1/g' custom-probe-timing.yaml > my-custom-probe-timing.yaml
kubectl apply -f my-custom-probe-timing.yaml

# Monitor probe behavior with custom timing
kubectl get pods -l app=custom-timing -w &

# Check probe status in pod events
kubectl describe pod $(kubectl get pods -l app=custom-timing -o jsonpath='{.items[0].metadata.name}') | grep -A 10 Events

# Stop watching
sleep 60
kill %1
```

### Step 11: Implement Health Check Best Practices
Deploy applications following health check best practices:

```bash
# Deploy application with comprehensive health checks
sed 's/userX/user1/g' best-practices-health.yaml > my-best-practices-health.yaml
kubectl apply -f my-best-practices-health.yaml

# Create a comprehensive service
sed 's/userX/user1/g' best-practices-service.yaml > my-best-practices-service.yaml
kubectl apply -f my-best-practices-service.yaml

# Test the comprehensive health system
kubectl exec user1-health-test -- curl -s http://user1-best-practices-service/health/live
kubectl exec user1-health-test -- curl -s http://user1-best-practices-service/health/ready
kubectl exec user1-health-test -- curl -s http://user1-best-practices-service/metrics
```

### Step 12: Create Health Check Dashboard
Monitor application health in a centralized way:

```bash
# Deploy health monitoring dashboard
sed 's/userX/user1/g' health-dashboard.yaml > my-health-dashboard.yaml
kubectl apply -f my-health-dashboard.yaml

# Expose dashboard via service
sed 's/userX/user1/g' dashboard-service.yaml > my-dashboard-service.yaml
kubectl apply -f my-dashboard-service.yaml

# Check dashboard functionality
kubectl get svc user1-health-dashboard
kubectl exec user1-health-test -- curl -s http://user1-health-dashboard/
```

### Step 13: Troubleshoot and Fix Unhealthy Applications
Practice fixing applications with health check issues:

```bash
# Identify failing applications
kubectl get pods --field-selector=status.phase=Failed
kubectl get pods | grep -E "(CrashLoopBackOff|Error|Pending)"

# Get detailed information about failing pods
FAILING_POD=$(kubectl get pods -l app=failing-liveness -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $FAILING_POD
kubectl logs $FAILING_POD --previous

# Fix the failing application by updating configuration
sed 's/userX/user1/g' fixed-application.yaml > my-fixed-application.yaml
kubectl apply -f my-fixed-application.yaml

# Verify the fix
kubectl get pods -l app=fixed-app
kubectl describe pod $(kubectl get pods -l app=fixed-app -o jsonpath='{.items[0].metadata.name}')
```

### Step 14: Load Testing with Health Checks
Test how health checks behave under load:

```bash
# Create load generator
sed 's/userX/user1/g' load-generator.yaml > my-load-generator.yaml
kubectl apply -f my-load-generator.yaml

# Monitor application health during load
kubectl exec user1-load-generator -- sh -c '
for i in $(seq 1 100); do
  curl -s http://user1-best-practices-service/health/ready
  sleep 0.1
done'

# Check pod resource usage and health status
kubectl top pods
kubectl get pods -l app=best-practices
```

## Verification Steps

### Verify Your Health Check Configuration
Run these commands to verify everything is working:

```bash
# 1. Check all deployments are running
kubectl get deployments

# 2. Verify pods are healthy
kubectl get pods
kubectl get pods --field-selector=status.phase=Running

# 3. Check service endpoints include only ready pods
kubectl get endpoints

# 4. Test health endpoints
kubectl exec user1-health-test -- curl -s http://user1-health-service/health

# 5. Verify probe configurations
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.containers[0].livenessProbe.httpGet.path}{"\n"}{end}'
```

## Clean Up
Remove all health check resources:

```bash
# Delete all deployments
kubectl delete deployment --all

# Delete all services
kubectl delete svc --all

# Delete all pods
kubectl delete pod --all

# Delete all configmaps
kubectl delete configmap --all
```

## Troubleshooting

### Common Issues
1. **Probes failing immediately**: Check initialDelaySeconds configuration
2. **Pods stuck in CrashLoopBackOff**: Review liveness probe configuration
3. **Service not routing traffic**: Check readiness probe status
4. **False positive failures**: Adjust failure and success thresholds

### Useful Commands
```bash
# Debug health check failures
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl get events --sort-by=.metadata.creationTimestamp

# Check probe configuration
kubectl get pod <pod-name> -o yaml | grep -A 10 "livenessProbe\|readinessProbe"

# Monitor probe status
kubectl get pods -w
kubectl describe pod <pod-name> | grep -A 10 Conditions
```

## Key Concepts Learned
- **Liveness Probes**: Automatic restart of unhealthy containers
- **Readiness Probes**: Traffic management based on application readiness
- **Startup Probes**: Handling slow-starting applications
- **Probe Types**: HTTP, TCP, and exec probes
- **Probe Timing**: Configuration of delays, timeouts, and thresholds
- **Multi-Container Health**: Managing health in complex pods
- **Event Monitoring**: Using Kubernetes events for troubleshooting
- **Best Practices**: Implementing comprehensive health check strategies

## Next Steps
In the next lab, you'll learn about autoscaling based on metrics and how to handle dynamic workload changes in your EKS cluster.

---

**Remember**: Proper health checks are essential for application reliability and automatic recovery in Kubernetes!