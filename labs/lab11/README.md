# Lab 11: StatefulSets and Headless Services

## Duration: 45 minutes

## Objectives
- Deploy and manage StatefulSets for stateful applications
- Configure headless services for stable network identities
- Manage persistent volume claims with StatefulSets
- Practice StatefulSet scaling and updates
- Troubleshoot StatefulSet deployment issues

## Prerequisites
- Lab 10 completed (Network Policies and Security)
- kubectl configured to use your namespace
- Understanding of persistent volumes

## Instructions

### Step 1: Clean Up and Create Headless Service
Start by creating a headless service for StatefulSet:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete networkpolicy --all
kubectl delete pod --all

# Create headless service for database cluster
sed 's/userX/user1/g' database-headless-service.yaml > my-database-headless-service.yaml
kubectl apply -f my-database-headless-service.yaml

# Verify headless service (no ClusterIP)
kubectl get svc user1-database-headless
kubectl describe svc user1-database-headless
```

### Step 2: Deploy Basic StatefulSet
Create a simple StatefulSet with persistent storage:

```bash
# Deploy database StatefulSet
sed 's/userX/user1/g' database-statefulset.yaml > my-database-statefulset.yaml
kubectl apply -f my-database-statefulset.yaml

# Watch pods being created in order
kubectl get pods -l app=database -w
# Press Ctrl+C after all pods are running

# Verify StatefulSet and persistent volumes
kubectl get statefulset user1-database
kubectl get pvc -l app=database
kubectl get pods -l app=database -o wide
```

### Step 3: Test Stable Network Identities
Verify DNS resolution for StatefulSet pods:

```bash
# Create debug pod for DNS testing
kubectl run debug-pod --image=nicolaka/netshoot --command -- sleep 3600

# Test DNS resolution for StatefulSet pods
kubectl exec -it debug-pod -- nslookup user1-database-0.user1-database-headless
kubectl exec -it debug-pod -- nslookup user1-database-1.user1-database-headless
kubectl exec -it debug-pod -- nslookup user1-database-2.user1-database-headless

# Test connectivity to specific pod
kubectl exec -it debug-pod -- nc -zv user1-database-0.user1-database-headless 5432
kubectl exec -it debug-pod -- nc -zv user1-database-1.user1-database-headless 5432

# Check pod hostnames
kubectl exec user1-database-0 -- hostname
kubectl exec user1-database-1 -- hostname
```

### Step 4: Scale StatefulSet
Practice scaling StatefulSets up and down:

```bash
# Scale up StatefulSet (pods created in order)
kubectl scale statefulset user1-database --replicas=5
kubectl get pods -l app=database -w
# Press Ctrl+C after scaling completes

# Verify new PVCs are created
kubectl get pvc -l app=database

# Scale down StatefulSet (pods deleted in reverse order)
kubectl scale statefulset user1-database --replicas=3
kubectl get pods -l app=database -w
# Press Ctrl+C after scaling completes

# Note: PVCs are retained even after scaling down
kubectl get pvc -l app=database
```

### Step 5: Persistent Volume Management
Explore how StatefulSets manage persistent storage:

```bash
# Check persistent volume details
kubectl get pv
kubectl describe pvc data-user1-database-0

# Write data to specific pod's volume
kubectl exec user1-database-0 -- sh -c 'echo "data-from-pod-0" > /data/test-file.txt'
kubectl exec user1-database-1 -- sh -c 'echo "data-from-pod-1" > /data/test-file.txt'

# Verify data persistence
kubectl exec user1-database-0 -- cat /data/test-file.txt
kubectl exec user1-database-1 -- cat /data/test-file.txt

# Delete a pod to test persistence
kubectl delete pod user1-database-0
kubectl wait --for=condition=Ready pod/user1-database-0 --timeout=120s

# Verify data survives pod recreation
kubectl exec user1-database-0 -- cat /data/test-file.txt
```

### Step 6: StatefulSet Rolling Updates
Perform controlled updates to StatefulSet:

```bash
# Check current image version
kubectl describe statefulset user1-database | grep Image

# Update StatefulSet image with rolling update
kubectl patch statefulset user1-database -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","image":"postgres:14-alpine"}]}}}}'

# Watch rolling update progress
kubectl rollout status statefulset/user1-database
kubectl get pods -l app=database -w
# Press Ctrl+C after update completes

# Verify update strategy
kubectl describe statefulset user1-database | grep -A 5 "Update Strategy"

# Check rollout history
kubectl rollout history statefulset/user1-database
```

### Step 7: Web Application StatefulSet
Deploy a web application requiring persistent sessions:

```bash
# Deploy web app StatefulSet
sed 's/userX/user1/g' webapp-statefulset.yaml > my-webapp-statefulset.yaml
kubectl apply -f my-webapp-statefulset.yaml

# Create LoadBalancer service for web app
sed 's/userX/user1/g' webapp-service.yaml > my-webapp-service.yaml
kubectl apply -f my-webapp-service.yaml

# Check web application pods and service
kubectl get pods -l app=webapp
kubectl get svc user1-webapp-service

# Test session affinity (if configured)
kubectl exec debug-pod -- curl -s user1-webapp-service/session
```

### Step 8: StatefulSet Troubleshooting
Practice diagnosing common StatefulSet issues:

```bash
# Check StatefulSet events and status
kubectl describe statefulset user1-database
kubectl get events --field-selector involvedObject.name=user1-database

# Verify pod creation order
kubectl get pods -l app=database --sort-by=.metadata.creationTimestamp

# Check PVC binding issues
kubectl get pvc -l app=database
kubectl describe pvc data-user1-database-0

# Test headless service resolution
kubectl exec debug-pod -- dig user1-database-headless

# Check for resource constraints
kubectl describe node | grep -A 5 "Allocated resources"
```

### Step 9: StatefulSet Backup Simulation
Simulate backup procedures for StatefulSet data:

```bash
# Create backup job that accesses StatefulSet volumes
sed 's/userX/user1/g' backup-job.yaml > my-backup-job.yaml
kubectl apply -f my-backup-job.yaml

# Monitor backup job
kubectl get job user1-database-backup
kubectl logs -l job-name=user1-database-backup

# Verify backup data (example)
kubectl exec user1-database-0 -- ls -la /data/backups/

# Test restore procedure
kubectl exec user1-database-0 -- sh -c 'echo "restored-data" > /data/restored-file.txt'
kubectl exec user1-database-0 -- cat /data/restored-file.txt
```

### Step 10: StatefulSet Maintenance
Practice StatefulSet maintenance operations:

```bash
# Pause StatefulSet updates
kubectl patch statefulset user1-database -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# Update only newer pods (partition-based update)
kubectl patch statefulset user1-database -p '{"spec":{"template":{"spec":{"containers":[{"name":"postgres","image":"postgres:15-alpine"}]}}}}'

# Check which pods get updated
kubectl get pods -l app=database -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image

# Resume normal updates
kubectl patch statefulset user1-database -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'

# Force delete StatefulSet (if needed)
kubectl delete statefulset user1-database --cascade=orphan
kubectl delete pod user1-database-0 user1-database-1 user1-database-2 --force
```

## Verification Steps

```bash
# 1. Verify StatefulSet is running
kubectl get statefulset | grep user1

# 2. Check pod naming and order
kubectl get pods -l app=database --sort-by=.metadata.name

# 3. Verify persistent volumes are bound
kubectl get pvc -l app=database | grep Bound

# 4. Test stable network identities
kubectl exec debug-pod -- nslookup user1-database-0.user1-database-headless

# 5. Confirm data persistence after pod restart
kubectl delete pod user1-database-0
kubectl wait --for=condition=Ready pod/user1-database-0 --timeout=120s
kubectl exec user1-database-0 -- ls -la /data/
```

## Key Takeaways
- StatefulSets provide stable, unique network identifiers for pods
- Headless services enable direct pod-to-pod communication
- Persistent volume claims are automatically created and managed
- Pods are created and deleted in order (0, 1, 2... and reverse)
- Rolling updates happen in reverse pod order for safety
- PVCs persist even when StatefulSet scales down
- Partition-based updates allow gradual rollouts

## Cleanup
```bash
kubectl delete statefulset user1-database user1-webapp
kubectl delete service user1-database-headless user1-webapp-service
kubectl delete job user1-database-backup
kubectl delete pod debug-pod
kubectl delete pvc --all
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!