#!/bin/bash
# cleanup-training.sh

echo "Cleaning up training resources..."

# Delete user namespaces
kubectl get namespaces | grep -E "user[0-9]+-namespace" | awk '{print $1}' | xargs -r kubectl delete namespace

# Clean up any remaining PVCs
kubectl delete pvc --all --all-namespaces --ignore-not-found=true

# Clean up available PVs
kubectl delete pv --field-selector=status.phase=Available --ignore-not-found=true

echo "Training cleanup completed!"