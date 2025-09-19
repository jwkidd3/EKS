# Lab 12: Stateful Applications

## Duration: 45 minutes

## Objectives
- Deploy StatefulSets for applications requiring persistent identity
- Use pre-configured Amazon EBS CSI driver for persistent volumes
- Practice scaling stateful applications
- Implement backup and restore procedures for stateful data

## Prerequisites
- Lab 11 completed (node management)
- kubectl configured to use your namespace
- Amazon EBS CSI driver installed

## Instructions

### Step 1: Clean Up Previous Resources
```bash
kubectl delete deployment --all
kubectl delete svc --all
kubectl get all
```

### Step 2: Create Storage Class and PV Claims
Set up persistent storage:

```bash
# Create storage class
sed 's/userX/user1/g' storage-class.yaml > my-storage-class.yaml
kubectl apply -f my-storage-class.yaml

# Create persistent volume claims
sed 's/userX/user1/g' pvc-templates.yaml > my-pvc-templates.yaml
kubectl apply -f my-pvc-templates.yaml

# Check PVC status
kubectl get pvc
kubectl describe pvc user1-data-pvc
```

### Step 3: Deploy Database StatefulSet
Deploy a stateful database application:

```bash
# Deploy PostgreSQL StatefulSet
sed 's/userX/user1/g' postgres-statefulset.yaml > my-postgres-statefulset.yaml
kubectl apply -f my-postgres-statefulset.yaml

# Create headless service
sed 's/userX/user1/g' postgres-service.yaml > my-postgres-service.yaml
kubectl apply -f my-postgres-service.yaml

# Monitor StatefulSet deployment
kubectl get statefulset
kubectl get pods -l app=postgres
```

### Step 4: Test Database Persistence
Verify data persistence across pod restarts:

```bash
# Connect to database and create test data
kubectl exec user1-postgres-0 -- psql -U postgres -c "CREATE DATABASE testdb;"
kubectl exec user1-postgres-0 -- psql -U postgres -d testdb -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50));"
kubectl exec user1-postgres-0 -- psql -U postgres -d testdb -c "INSERT INTO users (name) VALUES ('user1 test');"

# Delete pod and verify data persists
kubectl delete pod user1-postgres-0
kubectl wait --for=condition=ready pod user1-postgres-0 --timeout=300s

# Verify data persistence
kubectl exec user1-postgres-0 -- psql -U postgres -d testdb -c "SELECT * FROM users;"
```

### Step 5: Scale StatefulSet
Practice scaling stateful applications:

```bash
# Scale up StatefulSet
kubectl scale statefulset user1-postgres --replicas=3

# Monitor scaling process
kubectl get pods -l app=postgres -w

# Check persistent volumes
kubectl get pv
kubectl get pvc
```

### Step 6: Deploy Application with StatefulSet
Deploy a complete stateful application:

```bash
# Deploy Redis cluster
sed 's/userX/user1/g' redis-cluster.yaml > my-redis-cluster.yaml
kubectl apply -f my-redis-cluster.yaml

# Create Redis service
sed 's/userX/user1/g' redis-cluster-service.yaml > my-redis-cluster-service.yaml
kubectl apply -f my-redis-cluster-service.yaml

# Test Redis cluster
kubectl exec user1-redis-0 -- redis-cli set key1 "value from redis-0"
kubectl exec user1-redis-1 -- redis-cli get key1
```

### Step 7: Implement Data Backup
Create backup procedures for stateful data:

```bash
# Create backup job
sed 's/userX/user1/g' backup-job.yaml > my-backup-job.yaml
kubectl apply -f my-backup-job.yaml

# Monitor backup job
kubectl get jobs
kubectl logs job/user1-backup-job
```

### Step 8: Test Data Recovery
Practice restoring from backups:

```bash
# Simulate data loss
kubectl exec user1-postgres-0 -- psql -U postgres -d testdb -c "DROP TABLE users;"

# Restore from backup
sed 's/userX/user1/g' restore-job.yaml > my-restore-job.yaml
kubectl apply -f my-restore-job.yaml

# Verify restoration
kubectl exec user1-postgres-0 -- psql -U postgres -d testdb -c "SELECT * FROM users;"
```

### Step 9: Monitor Stateful Applications
Set up monitoring for stateful workloads:

```bash
# Check resource usage
kubectl top pods
kubectl describe statefulset user1-postgres

# Monitor storage usage
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage
```

## Key Concepts Learned
- **StatefulSets**: Managing stateful applications
- **Persistent Volumes**: Durable storage for pods
- **Storage Classes**: Dynamic volume provisioning
- **Scaling Stateful Apps**: Challenges and considerations
- **Data Backup/Restore**: Protecting stateful data
- **Headless Services**: Service discovery for StatefulSets

## Clean Up
```bash
kubectl delete statefulset --all
kubectl delete pvc --all
kubectl delete job --all
kubectl delete svc --all
```

---

**Remember**: Stateful applications require careful planning for data persistence and scaling!