#!/bin/bash
# test-storage-cleanup.sh - Clean up storage test resources

echo "Cleaning up storage test resources..."

# Delete test PVC (this will also delete the associated PV)
kubectl delete pvc test-storage-pvc --ignore-not-found=true

echo "Storage test cleanup completed!"
echo "Run 'kubectl get pv,pvc' to verify cleanup"