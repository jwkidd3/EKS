# EKS Training Setup

This directory contains all the configuration files and setup scripts needed to deploy the EKS training environment.

## Files

### Configuration Files
- **`eks-training-cluster.yaml`** - EKS cluster configuration
- **`storage-classes.yaml`** - Storage class definitions (gp3, fast-ssd, gp3-immediate)
- **`namespace-quota-template.yaml`** - Resource quota and limit templates
- **`test-storage.yaml`** - Storage validation test

### Setup Scripts
- **`add-user-access.sh`** - Add current AWS user to cluster access
- **`update-cluster.sh`** - Update existing cluster configuration
- **`cleanup-training.sh`** - Clean up training resources between sessions
- **`delete-cluster.sh`** - Complete cluster deletion script
- **`test-storage-cleanup.sh`** - Clean up storage test resources

### Documentation
- **`environment-setup.md`** - Comprehensive setup guide and instructions

## Quick Start

### For New Cluster:
1. **Create the cluster:**
   ```bash
   cd setup
   eksctl create cluster -f eks-training-cluster.yaml
   ```

### For Existing Cluster:
1. **Add user access:**
   ```bash
   cd setup
   ./add-user-access.sh
   ```

2. **Apply storage classes:**
   ```bash
   kubectl apply -f storage-classes.yaml
   ```

3. **Test immediate storage creation (optional):**
   ```bash
   # Create PVC with immediate binding
   kubectl apply -f test-storage.yaml

   # Verify PVC bound immediately (should show "Bound" status)
   kubectl get pvc,pv

   # Check storage class binding mode
   kubectl describe pvc test-storage-pvc

   # Clean up test resources
   ./test-storage-cleanup.sh
   ```

4. **Follow the complete setup guide in `environment-setup.md`**

## Cleanup

- **Daily cleanup:** `./cleanup-training.sh`
- **Full deletion:** `./delete-cluster.sh` (force deletes - no graceful draining)

## Capacity

This setup creates a **2-node cluster** optimized for training with proper resource isolation using username prefixes (user1, user2, etc.).