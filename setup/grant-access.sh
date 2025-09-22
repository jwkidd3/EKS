#!/bin/bash
# grant-access.sh - Grant access to all authenticated AWS users

echo "Granting cluster access to all authenticated AWS users..."

# First update kubeconfig as cluster creator
aws eks update-kubeconfig --region us-east-2 --name training-cluster

# Create ClusterRoleBinding for all authenticated users
kubectl create clusterrolebinding authenticated-users \
  --clusterrole=cluster-admin \
  --group=system:authenticated

# Also create one for anonymous users (backup)
kubectl create clusterrolebinding anonymous-users \
  --clusterrole=cluster-admin \
  --user=system:anonymous

echo "Access granted! All AWS users can now access the cluster with:"
echo "aws eks update-kubeconfig --region us-east-2 --name training-cluster"