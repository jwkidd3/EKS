# Lab 7: Resource Management and Autoscaling

## Duration: 45 minutes

## Objectives
- Configure resource requests and limits for containers
- Create and manage ResourceQuotas at namespace level
- Set up Horizontal Pod Autoscaler (HPA)
- Monitor resource usage and scaling behavior
- Practice resource constraint troubleshooting

## Prerequisites
- Lab 6 completed (Persistent Volumes)
- kubectl configured to use your namespace
- Metrics Server installed on cluster

## Instructions

### Step 1: Clean Up and Check Current Resources
Start fresh and examine current resource usage:

```bash
# Clean up previous resources
kubectl delete statefulset --all
kubectl delete deployment --all
kubectl delete pod --all
kubectl delete pvc --all

# Check current resource usage in namespace
kubectl describe namespace $(kubectl config view --minify -o jsonpath='{..namespace}')
kubectl top nodes
kubectl top pods -A
```

### Step 2: Create Resource Quota for Namespace
Set resource limits for your namespace:

```bash
# Create namespace resource quota
sed 's/userX/user1/g' namespace-quota.yaml > my-namespace-quota.yaml
kubectl apply -f my-namespace-quota.yaml

# Verify quota is applied
kubectl describe quota user1-resource-quota
kubectl get quota user1-resource-quota -o yaml
```

### Step 3: Deploy Application with Resource Requests and Limits
Create a deployment with proper resource management:

```bash
# Deploy application with resource specifications
sed 's/userX/user1/g' resource-app-deployment.yaml > my-resource-app-deployment.yaml
kubectl apply -f my-resource-app-deployment.yaml

# Check resource allocation
kubectl describe deployment user1-resource-app
kubectl get pods -l app=resource-app
kubectl describe pod -l app=resource-app
```

### Step 4: Monitor Resource Usage
Observe how resources are being used:

```bash
# Check resource usage in your namespace
kubectl top pods
kubectl describe quota user1-resource-quota

# View detailed resource information
kubectl get pods -l app=resource-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].resources}{"\n"}{end}'

# Monitor node resource allocation
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Step 5: Test Resource Limits
Create a pod that exceeds limits to see what happens:

```bash
# Deploy memory-intensive pod
sed 's/userX/user1/g' memory-test-pod.yaml > my-memory-test-pod.yaml
kubectl apply -f my-memory-test-pod.yaml

# Watch the pod behavior
kubectl get pod user1-memory-test -w
# Press Ctrl+C after observing behavior

# Check events to see what happened
kubectl describe pod user1-memory-test
kubectl get events --field-selector involvedObject.name=user1-memory-test
```

### Step 6: Create Horizontal Pod Autoscaler
Set up HPA to automatically scale based on CPU usage:

```bash
# Create HPA for the resource app
kubectl autoscale deployment user1-resource-app --cpu-percent=50 --min=2 --max=8

# Or apply the HPA yaml file
sed 's/userX/user1/g' hpa.yaml > my-hpa.yaml
kubectl apply -f my-hpa.yaml

# Check HPA status
kubectl get hpa user1-resource-app-hpa
kubectl describe hpa user1-resource-app-hpa
```

### Step 7: Generate Load to Trigger Autoscaling
Create load on the application to trigger scaling:

```bash
# Create load generator pod
sed 's/userX/user1/g' load-generator.yaml > my-load-generator.yaml
kubectl apply -f my-load-generator.yaml

# Wait for load generator to be ready
kubectl wait --for=condition=Ready pod/user1-load-generator --timeout=60s

# Start generating load
kubectl exec user1-load-generator -- sh -c 'while true; do wget -q -O- http://user1-resource-app:80/; done' &

# Monitor CPU usage and scaling in another terminal
kubectl top pods
kubectl get hpa user1-resource-app-hpa -w
# Press Ctrl+C after observing scaling
```

### Step 8: Monitor Autoscaling Behavior
Watch how HPA scales the deployment:

```bash
# Check current replica count
kubectl get deployment user1-resource-app

# Monitor HPA metrics
kubectl describe hpa user1-resource-app-hpa

# View HPA events
kubectl get events --field-selector involvedObject.name=user1-resource-app-hpa

# Check pod distribution across nodes
kubectl get pods -l app=resource-app -o wide
```

### Step 9: Test Resource Quota Limits
Try to exceed namespace resource quotas:

```bash
# Try to create more resources than quota allows
sed 's/userX/user1/g' quota-test-deployment.yaml > my-quota-test-deployment.yaml
kubectl apply -f my-quota-test-deployment.yaml

# Check if deployment succeeded
kubectl get deployment user1-quota-test
kubectl describe deployment user1-quota-test

# Check quota usage
kubectl describe quota user1-resource-quota

# View quota-related events
kubectl get events --field-selector reason=FailedCreate
```

### Step 10: Resource Troubleshooting and Optimization
Practice troubleshooting resource issues:

```bash
# Stop the load generator
kubectl exec user1-load-generator -- pkill wget

# Watch HPA scale down
kubectl get hpa user1-resource-app-hpa -w
# Press Ctrl+C after scale-down begins

# Check resource efficiency
kubectl top pods
kubectl describe quota user1-resource-quota

# View HPA scaling history
kubectl describe hpa user1-resource-app-hpa

# Check for resource pressure on nodes
kubectl describe nodes | grep -A 10 -B 5 "Conditions"

# Analyze resource requests vs limits
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, requests: .spec.containers[].resources.requests, limits: .spec.containers[].resources.limits}'
```

## Verification Steps

Run these commands to verify your resource management setup:

```bash
# 1. Verify ResourceQuota is active
kubectl get quota user1-resource-quota -o jsonpath='{.status.used}'

# 2. Verify HPA is functioning
kubectl get hpa user1-resource-app-hpa -o jsonpath='{.status.currentReplicas}'

# 3. Check resource requests are set
kubectl get pods -l app=resource-app -o jsonpath='{.items[0].spec.containers[0].resources}'

# 4. Verify scaling worked
kubectl get deployment user1-resource-app -o jsonpath='{.status.replicas}'

# 5. Check quota usage
kubectl describe quota user1-resource-quota | grep -A 5 "Used"
```

## Key Takeaways
- Resource requests guarantee minimum resources, limits set maximum usage
- ResourceQuotas prevent resource overconsumption at namespace level
- HPA automatically scales applications based on CPU/memory metrics
- Proper resource management prevents resource starvation and improves stability
- Monitoring resource usage is crucial for optimization
- Resource constraints can cause scheduling failures

## Cleanup
```bash
kubectl delete deployment user1-resource-app user1-quota-test
kubectl delete pod user1-memory-test user1-load-generator
kubectl delete hpa user1-resource-app-hpa
kubectl delete quota user1-resource-quota
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!