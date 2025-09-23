# Lab 8: Health Checks and Probes

## Duration: 45 minutes

## Objectives
- Configure liveness, readiness, and startup probes
- Understand probe types and their use cases
- Practice troubleshooting application health issues
- Monitor probe behavior and failure recovery

## Prerequisites
- Lab 7 completed (Resource Management)
- kubectl configured to use your namespace

## Instructions

### Step 1: Clean Up and Deploy Unhealthy Application
Start with an application that has health issues:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete pod --all

# Deploy application without health checks
sed 's/userX/user1/g' unhealthy-app.yaml > my-unhealthy-app.yaml
kubectl apply -f my-unhealthy-app.yaml

# Check application status
kubectl get pods -l app=unhealthy-app
kubectl describe pod $(kubectl get pods -l app=unhealthy-app -o jsonpath='{.items[0].metadata.name}')
```

### Step 2: Add Readiness Probe
Configure readiness probe to prevent traffic to unready pods:

```bash
# Deploy app with readiness probe
sed 's/userX/user1/g' readiness-app.yaml > my-readiness-app.yaml
kubectl apply -f my-readiness-app.yaml

# Watch pods become ready
kubectl get pods -l app=readiness-app -w
# Press Ctrl+C after pods are ready

# Check readiness probe configuration
kubectl describe pod $(kubectl get pods -l app=readiness-app -o jsonpath='{.items[0].metadata.name}') | grep -A 5 "Readiness"

# Test readiness behavior
kubectl get pods -l app=readiness-app -o wide
```

### Step 3: Add Liveness Probe
Configure liveness probe to restart unhealthy containers:

```bash
# Deploy app with liveness probe
sed 's/userX/user1/g' liveness-app.yaml > my-liveness-app.yaml
kubectl apply -f my-liveness-app.yaml

# Check liveness probe configuration
kubectl describe pod $(kubectl get pods -l app=liveness-app -o jsonpath='{.items[0].metadata.name}') | grep -A 5 "Liveness"

# Monitor pod health over time
kubectl get pods -l app=liveness-app -w
# Press Ctrl+C after observing for a few minutes
```

### Step 4: Simulate Application Failure
Test how probes handle application failures:

```bash
# Create app that will become unhealthy
sed 's/userX/user1/g' failing-app.yaml > my-failing-app.yaml
kubectl apply -f my-failing-app.yaml

# Wait for app to be ready
kubectl wait --for=condition=Ready pod -l app=failing-app --timeout=60s

# Simulate app failure by creating failure condition
POD_NAME=$(kubectl get pods -l app=failing-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- touch /tmp/unhealthy

# Watch liveness probe detect failure and restart container
kubectl get pods -l app=failing-app -w
# Press Ctrl+C after seeing restart

# Check restart count and events
kubectl describe pod $POD_NAME | grep -E "(Restart Count|Events)" -A 10
```

### Step 5: Configure Startup Probe
Handle slow-starting applications with startup probes:

```bash
# Deploy slow-starting app with startup probe
sed 's/userX/user1/g' startup-app.yaml > my-startup-app.yaml
kubectl apply -f my-startup-app.yaml

# Monitor startup process
kubectl get pods -l app=startup-app -w
# Press Ctrl+C after pod is ready

# Check probe configurations
kubectl describe pod $(kubectl get pods -l app=startup-app -o jsonpath='{.items[0].metadata.name}') | grep -A 5 -E "(Startup|Liveness|Readiness)"

# View startup events
kubectl get events --field-selector involvedObject.name=$(kubectl get pods -l app=startup-app -o jsonpath='{.items[0].metadata.name}')
```

### Step 6: Different Probe Types
Test HTTP, TCP, and command-based probes:

```bash
# Deploy app with HTTP probe
sed 's/userX/user1/g' http-probe-app.yaml > my-http-probe-app.yaml
kubectl apply -f my-http-probe-app.yaml

# Deploy app with TCP probe
sed 's/userX/user1/g' tcp-probe-app.yaml > my-tcp-probe-app.yaml
kubectl apply -f my-tcp-probe-app.yaml

# Deploy app with command probe
sed 's/userX/user1/g' exec-probe-app.yaml > my-exec-probe-app.yaml
kubectl apply -f my-exec-probe-app.yaml

# Check all probe types
kubectl get pods | grep probe
kubectl describe pod $(kubectl get pods -l app=http-probe -o jsonpath='{.items[0].metadata.name}') | grep -A 3 "Http Get"
kubectl describe pod $(kubectl get pods -l app=tcp-probe -o jsonpath='{.items[0].metadata.name}') | grep -A 3 "TCP Socket"
kubectl describe pod $(kubectl get pods -l app=exec-probe -o jsonpath='{.items[0].metadata.name}') | grep -A 3 "Exec"
```

### Step 7: Service Integration with Readiness
See how readiness probes affect service traffic:

```bash
# Create service for readiness app
sed 's/userX/user1/g' health-service.yaml > my-health-service.yaml
kubectl apply -f my-health-service.yaml

# Check service endpoints
kubectl get endpoints user1-health-service
kubectl describe endpoints user1-health-service

# Scale up readiness app
kubectl scale deployment user1-readiness-app --replicas=3
kubectl get pods -l app=readiness-app

# Make one pod unready and check endpoints
POD_NAME=$(kubectl get pods -l app=readiness-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- touch /tmp/not-ready

# Check that unhealthy pod is removed from endpoints
kubectl get endpoints user1-health-service
kubectl describe endpoints user1-health-service
```

### Step 8: Probe Troubleshooting
Practice diagnosing probe failures:

```bash
# Create deployment with broken probes
sed 's/userX/user1/g' broken-probe-app.yaml > my-broken-probe-app.yaml
kubectl apply -f my-broken-probe-app.yaml

# Diagnose probe failures
kubectl get pods -l app=broken-probe
kubectl describe pod $(kubectl get pods -l app=broken-probe -o jsonpath='{.items[0].metadata.name}') | grep -A 10 "Events"

# Check container logs for probe-related errors
kubectl logs $(kubectl get pods -l app=broken-probe -o jsonpath='{.items[0].metadata.name}')

# Fix the probe and redeploy
kubectl patch deployment user1-broken-probe-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","readinessProbe":{"httpGet":{"path":"/","port":80}}}]}}}}'
kubectl rollout status deployment/user1-broken-probe-app
```

## Verification Steps

```bash
# 1. Verify probes are configured
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].livenessProbe.httpGet.path}{"\n"}{end}'

# 2. Check readiness probe affects service endpoints
kubectl get endpoints | grep user1

# 3. Verify probe failure recovery
kubectl describe pod $(kubectl get pods -l app=failing-app -o jsonpath='{.items[0].metadata.name}') | grep "Restart Count"

# 4. Confirm different probe types work
kubectl get pods | grep probe | grep Running
```

## Key Takeaways
- Readiness probes control traffic routing to pods
- Liveness probes restart unhealthy containers
- Startup probes protect slow-starting applications
- Probe types: HTTP, TCP, and exec commands
- Proper timing prevents false positive failures
- Service endpoints automatically exclude unready pods
- Probe failures generate events for troubleshooting

## Cleanup
```bash
kubectl delete deployment user1-unhealthy-app user1-readiness-app user1-liveness-app user1-failing-app user1-startup-app user1-http-probe-app user1-tcp-probe-app user1-exec-probe-app user1-broken-probe-app
kubectl delete service user1-health-service
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!