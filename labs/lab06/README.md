# Lab 6: Persistent Volumes and Storage

## Duration: 45 minutes

## Objectives
- Create and manage PersistentVolumes and PersistentVolumeClaims
- Use different storage classes and binding modes
- Deploy stateful applications with persistent storage
- Practice storage expansion and backup scenarios
- Understand storage lifecycle and data persistence

## Prerequisites
- Lab 5 completed (ConfigMaps and Secrets)
- kubectl configured to use your namespace
- EBS CSI driver installed on cluster

## Instructions

### Step 1: Clean Up and Explore Storage Classes
Start fresh and examine available storage options:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete pvc --all
kubectl delete configmap --all
kubectl delete secret --all

# Explore available storage classes
kubectl get storageclass
kubectl describe storageclass gp3
kubectl describe storageclass gp3-immediate
kubectl describe storageclass fast-ssd
```

### Step 2: Create Basic PersistentVolumeClaim
Create a simple PVC with immediate binding:

```bash
# Create immediate-binding PVC
sed 's/userX/user1/g' basic-pvc.yaml > my-basic-pvc.yaml
kubectl apply -f my-basic-pvc.yaml

# Check PVC status - should bind immediately
kubectl get pvc user1-basic-storage
kubectl get pv

# Examine the created PV details
PV_NAME=$(kubectl get pvc user1-basic-storage -o jsonpath='{.spec.volumeName}')
kubectl describe pv $PV_NAME
```

### Step 3: Deploy Application with Persistent Storage
Deploy a simple file-writing application:

```bash
# Deploy pod with persistent storage
sed 's/userX/user1/g' storage-writer-pod.yaml > my-storage-writer-pod.yaml
kubectl apply -f my-storage-writer-pod.yaml

# Wait for pod to be ready
kubectl wait --for=condition=Ready pod/user1-storage-writer --timeout=60s

# Write some data to persistent storage
kubectl exec user1-storage-writer -- sh -c 'echo "Hello from Kubernetes $(date)" >> /data/application.log'
kubectl exec user1-storage-writer -- sh -c 'echo "User: user1" >> /data/application.log'
kubectl exec user1-storage-writer -- sh -c 'echo "Pod: $(hostname)" >> /data/application.log'

# Verify data was written
kubectl exec user1-storage-writer -- cat /data/application.log
kubectl exec user1-storage-writer -- ls -la /data/
```

### Step 4: Test Data Persistence
Delete and recreate the pod to verify data persists:

```bash
# Delete the pod
kubectl delete pod user1-storage-writer

# Recreate the pod
kubectl apply -f my-storage-writer-pod.yaml
kubectl wait --for=condition=Ready pod/user1-storage-writer --timeout=60s

# Verify old data is still there
kubectl exec user1-storage-writer -- cat /data/application.log

# Add more data from the new pod
kubectl exec user1-storage-writer -- sh -c 'echo "Data persisted! New pod: $(hostname)" >> /data/application.log'
kubectl exec user1-storage-writer -- cat /data/application.log
```

### Step 5: Create StatefulSet with Persistent Storage
Deploy a StatefulSet for more advanced storage scenarios:

```bash
# Create StatefulSet with persistent storage
sed 's/userX/user1/g' data-statefulset.yaml > my-data-statefulset.yaml
kubectl apply -f my-data-statefulset.yaml

# Watch StatefulSet pods come up
kubectl get statefulset user1-data-app -w
# Press Ctrl+C after pods are ready

# Check the automatically created PVCs
kubectl get pvc | grep user1-data-app
kubectl get pv

# Verify each pod has its own storage
kubectl exec user1-data-app-0 -- sh -c 'echo "Pod 0 data $(date)" > /data/pod0.txt'
kubectl exec user1-data-app-1 -- sh -c 'echo "Pod 1 data $(date)" > /data/pod1.txt'

# Check data isolation
kubectl exec user1-data-app-0 -- ls -la /data/
kubectl exec user1-data-app-1 -- ls -la /data/
```

### Step 6: Scale StatefulSet and Observe Storage
Scale the StatefulSet and see how storage behaves:

```bash
# Scale up the StatefulSet
kubectl scale statefulset user1-data-app --replicas=3

# Watch new pod creation
kubectl get pods -l app=data-app -w
# Press Ctrl+C after new pod is ready

# Check that new pod gets its own PVC
kubectl get pvc | grep user1-data-app
kubectl exec user1-data-app-2 -- sh -c 'echo "Pod 2 data $(date)" > /data/pod2.txt'

# Scale down
kubectl scale statefulset user1-data-app --replicas=2

# Verify PVCs are retained even after scaling down
kubectl get pvc | grep user1-data-app
kubectl get pods -l app=data-app

# Scale back up and verify data persistence
kubectl scale statefulset user1-data-app --replicas=3
kubectl wait --for=condition=Ready pod/user1-data-app-2 --timeout=60s
kubectl exec user1-data-app-2 -- cat /data/pod2.txt
```

### Step 7: Storage Expansion
Practice expanding PVC size:

```bash
# Check current size
kubectl get pvc user1-basic-storage -o jsonpath='{.spec.resources.requests.storage}'

# Expand the PVC (requires allowVolumeExpansion: true in storage class)
kubectl patch pvc user1-basic-storage -p '{"spec":{"resources":{"requests":{"storage":"3Gi"}}}}'

# Monitor expansion progress
kubectl describe pvc user1-basic-storage

# Verify expansion in pod
kubectl exec user1-storage-writer -- df -h /data
```

### Step 8: Different Storage Classes
Create PVCs with different storage classes:

```bash
# Create fast SSD PVC
sed 's/userX/user1/g' fast-storage-pvc.yaml > my-fast-storage-pvc.yaml
kubectl apply -f my-fast-storage-pvc.yaml

# Create waiting-for-consumer PVC
sed 's/userX/user1/g' delayed-pvc.yaml > my-delayed-pvc.yaml
kubectl apply -f my-delayed-pvc.yaml

# Check PVC statuses
kubectl get pvc

# Note: delayed PVC should be Pending until bound to a pod
# Deploy pod to bind the delayed PVC
sed 's/userX/user1/g' delayed-storage-pod.yaml > my-delayed-storage-pod.yaml
kubectl apply -f my-delayed-storage-pod.yaml

# Now check PVC status again
kubectl get pvc user1-delayed-storage
```

### Step 9: Storage Backup Simulation
Practice creating "backups" by copying data:

```bash
# Create a backup pod with access to existing PVC
sed 's/userX/user1/g' backup-pod.yaml > my-backup-pod.yaml
kubectl apply -f my-backup-pod.yaml
kubectl wait --for=condition=Ready pod/user1-backup-pod --timeout=60s

# Create backup of data
kubectl exec user1-backup-pod -- sh -c 'tar czf /backup/app-data-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .'
kubectl exec user1-backup-pod -- ls -la /backup/

# Simulate data corruption
kubectl exec user1-storage-writer -- sh -c 'rm -f /data/application.log'
kubectl exec user1-storage-writer -- ls -la /data/

# Restore from backup
BACKUP_FILE=$(kubectl exec user1-backup-pod -- ls /backup/ | grep tar.gz | head -1)
kubectl exec user1-backup-pod -- sh -c "tar xzf /backup/$BACKUP_FILE -C /data/"
kubectl exec user1-storage-writer -- cat /data/application.log
```

### Step 10: Storage Troubleshooting
Practice common storage troubleshooting scenarios:

```bash
# Check PVC events
kubectl describe pvc user1-basic-storage

# Check PV events
PV_NAME=$(kubectl get pvc user1-basic-storage -o jsonpath='{.spec.volumeName}')
kubectl describe pv $PV_NAME

# Check storage class details
kubectl describe storageclass gp3-immediate

# Monitor storage-related events
kubectl get events --field-selector reason=VolumeMount
kubectl get events --field-selector reason=VolumeMountMismatches

# Check EBS volumes in AWS (if curious)
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/training-cluster,Values=owned" --query 'Volumes[*].[VolumeId,Size,State,VolumeType]' --output table

# View storage usage in pods
kubectl exec user1-storage-writer -- df -h
kubectl exec user1-data-app-0 -- du -sh /data/*
```

## Verification Steps

Run these commands to verify your storage setup:

```bash
# 1. Verify PVCs are bound
kubectl get pvc | grep user1 | grep Bound

# 2. Verify PVs exist
kubectl get pv | grep user1

# 3. Verify StatefulSet storage
kubectl get pvc | grep user1-data-app | wc -l  # Should show 3 PVCs

# 4. Verify data persistence
kubectl exec user1-storage-writer -- cat /data/application.log | wc -l  # Should show multiple lines

# 5. Check storage expansion worked
kubectl get pvc user1-basic-storage -o jsonpath='{.spec.resources.requests.storage}'  # Should show 3Gi
```

## Key Takeaways
- PVCs abstract storage requests from specific implementations
- StatefulSets automatically create PVCs for each pod replica
- Data persists across pod restarts and deletions
- Storage classes define different types of storage with varying performance
- PVC expansion is supported but requires storage class configuration
- Backup strategies are important for persistent data
- Storage troubleshooting involves checking PVC, PV, and storage class events

## Cleanup
```bash
kubectl delete statefulset user1-data-app
kubectl delete pod user1-storage-writer user1-backup-pod user1-delayed-storage-pod
kubectl delete pvc user1-basic-storage user1-fast-storage user1-delayed-storage
kubectl delete pvc -l app=data-app  # Clean up StatefulSet PVCs
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!