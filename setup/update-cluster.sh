#!/bin/bash
# update-cluster.sh - Update existing EKS cluster configuration

echo "Updating existing EKS training cluster..."

# Update cluster endpoint access configuration
echo "Updating cluster endpoint access..."
aws eks modify-cluster --name training-cluster --region us-east-2 \
  --resources-vpc-config endpointConfigPrivate=false,endpointConfigPublic=true

# Wait for cluster to be active
echo "Waiting for cluster update to complete..."
aws eks wait cluster-active --name training-cluster --region us-east-2

# Apply anonymous RBAC configuration
echo "Applying anonymous access configuration..."
kubectl apply -f anonymous-rbac.yaml

# Verify cluster status
echo "Verifying cluster status..."
kubectl get nodes
kubectl cluster-info

echo "Cluster update completed!"