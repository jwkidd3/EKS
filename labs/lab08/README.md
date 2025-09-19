# Lab 8: Autoscaling Deep Dive

## Duration: 45 minutes

## Objectives
- Explore pre-installed kube-ops-view for visual cluster monitoring
- Configure Horizontal Pod Autoscaler (HPA) based on CPU metrics
- Generate load to trigger autoscaling events
- Observe HPA behavior and scaling decisions
- Configure memory-based autoscaling
- Test autoscaling with different workload patterns

## Prerequisites
- Lab 7 completed (health checks and monitoring)
- kubectl configured to use your namespace
- Metrics Server installed in cluster
- Understanding of resource requests and limits

## Instructions

### Step 1: Clean Up Previous Resources
Start with a clean environment:

```bash
# Clean up previous lab resources
kubectl delete deployment --all
kubectl delete svc --all
kubectl delete pod --all
kubectl get all

# Verify namespace is clean
kubectl get pods
```

### Step 2: Access Kube-ops-view for Visual Monitoring
Explore the pre-installed cluster visualization tool:

```bash
# Check if kube-ops-view is running
kubectl get pods -n kube-ops-view
kubectl get svc -n kube-ops-view

# Get the LoadBalancer URL for kube-ops-view
kubectl get svc -n kube-ops-view kube-ops-view

# Note: Open the external URL in your browser to visualize the cluster
# You'll use this throughout the lab to observe scaling behavior
```

### Step 3: Deploy Application with Resource Requests
Deploy an application with defined resource requests (required for HPA):

```bash
# Deploy CPU-intensive application
sed 's/userX/user1/g' cpu-app.yaml > my-cpu-app.yaml
kubectl apply -f my-cpu-app.yaml

# Verify deployment and check resource requests
kubectl get deployment user1-cpu-app
kubectl describe deployment user1-cpu-app
kubectl top pods -l app=cpu-app
```

### Step 4: Create Horizontal Pod Autoscaler (HPA)
Configure HPA based on CPU utilization:

```bash
# Create HPA for CPU-based scaling
sed 's/userX/user1/g' cpu-hpa.yaml > my-cpu-hpa.yaml
kubectl apply -f my-cpu-hpa.yaml

# Check HPA status
kubectl get hpa
kubectl describe hpa user1-cpu-hpa

# Monitor HPA in real-time
kubectl get hpa -w &

# Stop watching after verification
sleep 30
kill %1
```

### Step 5: Create Service for Load Testing
Expose the application for load testing:

```bash
# Create service for the CPU app
sed 's/userX/user1/g' cpu-app-service.yaml > my-cpu-app-service.yaml
kubectl apply -f my-cpu-app-service.yaml

# Verify service
kubectl get svc user1-cpu-app-service
kubectl describe svc user1-cpu-app-service
```

### Step 6: Generate CPU Load to Trigger Scaling
Create load to trigger HPA scaling:

```bash
# Deploy load generator
sed 's/userX/user1/g' load-generator-cpu.yaml > my-load-generator-cpu.yaml
kubectl apply -f my-load-generator-cpu.yaml

# Check load generator is running
kubectl get pods -l app=load-generator

# Start generating load
kubectl exec user1-load-generator -- sh -c '
echo "Starting CPU load test..."
for i in $(seq 1 10); do
  echo "Load test iteration $i"
  curl -s http://user1-cpu-app-service/cpu-load &
done
wait
'

# Monitor the scaling in real-time
kubectl get hpa user1-cpu-hpa -w &
kubectl get pods -l app=cpu-app -w &

# Let it run for 5 minutes to observe scaling
sleep 300
kill %1 %2
```

### Step 7: Observe HPA Scaling Behavior
Monitor and analyze the scaling behavior:

```bash
# Check current HPA status
kubectl get hpa user1-cpu-hpa
kubectl describe hpa user1-cpu-hpa

# Check current pod count
kubectl get pods -l app=cpu-app

# View HPA events
kubectl describe hpa user1-cpu-hpa | grep Events -A 10

# Check pod resource utilization
kubectl top pods -l app=cpu-app
```

### Step 8: Configure Memory-Based HPA
Create HPA that scales based on memory usage:

```bash
# Deploy memory-intensive application
sed 's/userX/user1/g' memory-app.yaml > my-memory-app.yaml
kubectl apply -f my-memory-app.yaml

# Create memory-based HPA
sed 's/userX/user1/g' memory-hpa.yaml > my-memory-hpa.yaml
kubectl apply -f my-memory-hpa.yaml

# Create service for memory app
sed 's/userX/user1/g' memory-app-service.yaml > my-memory-app-service.yaml
kubectl apply -f my-memory-app-service.yaml

# Check memory HPA
kubectl get hpa user1-memory-hpa
kubectl describe hpa user1-memory-hpa
```

### Step 9: Test Memory-Based Scaling
Generate memory load to trigger memory-based scaling:

```bash
# Generate memory load
kubectl exec user1-load-generator -- sh -c '
echo "Starting memory load test..."
for i in $(seq 1 5); do
  echo "Memory load test iteration $i"
  curl -s http://user1-memory-app-service/memory-load &
done
wait
'

# Monitor memory-based scaling
kubectl get hpa user1-memory-hpa -w &
kubectl get pods -l app=memory-app -w &

# Monitor for 3 minutes
sleep 180
kill %1 %2

# Check memory utilization
kubectl top pods -l app=memory-app
```

### Step 10: Configure Multi-Metric HPA
Create HPA that scales based on multiple metrics:

```bash
# Deploy application that can stress both CPU and memory
sed 's/userX/user1/g' multi-metric-app.yaml > my-multi-metric-app.yaml
kubectl apply -f my-multi-metric-app.yaml

# Create multi-metric HPA
sed 's/userX/user1/g' multi-metric-hpa.yaml > my-multi-metric-hpa.yaml
kubectl apply -f my-multi-metric-hpa.yaml

# Create service for multi-metric app
sed 's/userX/user1/g' multi-metric-service.yaml > my-multi-metric-service.yaml
kubectl apply -f my-multi-metric-service.yaml

# Check multi-metric HPA
kubectl get hpa user1-multi-metric-hpa
kubectl describe hpa user1-multi-metric-hpa
```

### Step 11: Test Multi-Metric Scaling
Test scaling behavior with multiple metrics:

```bash
# Generate mixed load (CPU and memory)
kubectl exec user1-load-generator -- sh -c '
echo "Starting mixed load test..."
for i in $(seq 1 8); do
  curl -s http://user1-multi-metric-service/cpu-load &
  curl -s http://user1-multi-metric-service/memory-load &
done
wait
'

# Monitor multi-metric scaling
kubectl get hpa user1-multi-metric-hpa -w &
kubectl get pods -l app=multi-metric-app -w &

# Monitor for 4 minutes
sleep 240
kill %1 %2

# Check resource utilization
kubectl top pods -l app=multi-metric-app
```

### Step 12: Test Scale-Down Behavior
Observe how HPA scales down after load decreases:

```bash
# Stop all load generation
kubectl delete pod user1-load-generator

# Create a new load generator for controlled testing
kubectl apply -f my-load-generator-cpu.yaml

# Generate moderate load for 2 minutes
kubectl exec user1-load-generator -- sh -c '
for i in $(seq 1 4); do
  curl -s http://user1-cpu-app-service/cpu-load &
done
wait
'

# Wait for scale-up
sleep 120

# Stop load generation (no more requests)
echo "Load stopped - observing scale-down behavior"

# Monitor scale-down (takes 5+ minutes by default)
kubectl get hpa -w &
kubectl get pods -l app=cpu-app -w &

# Monitor for 8 minutes to see scale-down
sleep 480
kill %1 %2
```

### Step 13: Configure Custom HPA Behavior
Create HPA with custom scaling behavior:

```bash
# Deploy app with custom HPA behavior
sed 's/userX/user1/g' custom-hpa-behavior.yaml > my-custom-hpa-behavior.yaml
kubectl apply -f my-custom-hpa-behavior.yaml

# Check custom HPA configuration
kubectl describe hpa user1-custom-behavior-hpa

# Test custom scaling behavior
kubectl exec user1-load-generator -- sh -c '
for i in $(seq 1 6); do
  curl -s http://user1-cpu-app-service/cpu-load &
done
wait
'

# Monitor custom scaling behavior
kubectl get hpa user1-custom-behavior-hpa -w &
kubectl get pods -l app=cpu-app -w &

sleep 240
kill %1 %2
```

### Step 14: Monitor HPA Metrics and Events
Analyze HPA metrics and decision-making process:

```bash
# Get detailed HPA metrics
kubectl describe hpa user1-cpu-hpa
kubectl describe hpa user1-memory-hpa
kubectl describe hpa user1-multi-metric-hpa

# Check HPA events
kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler

# Get current scaling status
kubectl get hpa
kubectl top pods

# Check HPA conditions and status
kubectl get hpa -o wide
kubectl get hpa user1-cpu-hpa -o yaml | grep -A 20 status
```

### Step 15: Test Resource Limit Impact on HPA
Understand how resource limits affect scaling:

```bash
# Deploy app with low resource limits
sed 's/userX/user1/g' limited-resources-app.yaml > my-limited-resources-app.yaml
kubectl apply -f my-limited-resources-app.yaml

# Create HPA for limited resources app
sed 's/userX/user1/g' limited-resources-hpa.yaml > my-limited-resources-hpa.yaml
kubectl apply -f my-limited-resources-hpa.yaml

# Create service
sed 's/userX/user1/g' limited-resources-service.yaml > my-limited-resources-service.yaml
kubectl apply -f my-limited-resources-service.yaml

# Generate load and observe behavior with limited resources
kubectl exec user1-load-generator -- sh -c '
for i in $(seq 1 8); do
  curl -s http://user1-limited-service/cpu-load &
done
wait
'

# Monitor resource-limited scaling
kubectl get hpa user1-limited-hpa -w &
kubectl top pods -l app=limited-resources --use-protocol-buffers &

sleep 180
kill %1 %2
```

## Verification Steps

### Verify Your Autoscaling Configuration
Run these commands to verify everything is working:

```bash
# 1. Check all HPA configurations
kubectl get hpa

# 2. Verify metrics are available
kubectl top nodes
kubectl top pods

# 3. Check application resource usage
kubectl describe deployment user1-cpu-app | grep -A 5 "Limits\|Requests"

# 4. Verify HPA is making scaling decisions
kubectl describe hpa user1-cpu-hpa | tail -20

# 5. Check current pod counts match HPA target
kubectl get pods -l app=cpu-app --no-headers | wc -l
```

## Clean Up
Remove all autoscaling resources:

```bash
# Delete all HPAs
kubectl delete hpa --all

# Delete all deployments
kubectl delete deployment --all

# Delete all services
kubectl delete svc --all

# Delete test pods
kubectl delete pod --all
```

## Troubleshooting

### Common Issues
1. **HPA shows "unknown" metrics**: Check if Metrics Server is running
2. **No scaling occurs**: Verify resource requests are defined
3. **Scaling too aggressive**: Adjust scale-up/scale-down policies
4. **Pods stuck pending**: Check cluster resource availability

### Useful Commands
```bash
# Debug HPA issues
kubectl describe hpa <hpa-name>
kubectl get events --sort-by=.metadata.creationTimestamp

# Check metrics availability
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# Monitor resource usage
kubectl top pods --sort-by=cpu
kubectl top pods --sort-by=memory
```

## Key Concepts Learned
- **Horizontal Pod Autoscaler (HPA)**: Automatic scaling based on metrics
- **CPU-based Scaling**: Scaling based on CPU utilization
- **Memory-based Scaling**: Scaling based on memory usage
- **Multi-metric Scaling**: Using multiple metrics for scaling decisions
- **Scaling Behavior**: Customizing scale-up and scale-down policies
- **Resource Requirements**: Impact of requests and limits on scaling
- **Metrics Server**: Source of metrics for HPA decisions
- **Load Testing**: Generating load to trigger scaling events

## Next Steps
In the next lab, you'll learn about implementing Role-Based Access Control (RBAC) to secure your applications and control access to Kubernetes resources.

---

**Remember**: Proper resource requests and limits are essential for effective autoscaling in Kubernetes!