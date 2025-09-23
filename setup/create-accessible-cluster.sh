#!/bin/bash
# create-accessible-cluster.sh - Create cluster and configure access

echo "Creating accessible EKS cluster..."

# Create cluster with explicit creator mapping
eksctl create cluster \
  --name training-cluster \
  --region us-east-2 \
  --nodes 2 \
  --node-type m5.large \
  --managed \
  --with-oidc \
  --set-kubeconfig-context=false

# Explicitly add current user as cluster admin
echo "Adding cluster creator as admin..."
eksctl create iamidentitymapping \
  --cluster training-cluster \
  --region us-east-2 \
  --arn $(aws sts get-caller-identity --query Arn --output text) \
  --group system:masters \
  --username cluster-admin

# Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region us-east-2 --name training-cluster

# Test access
echo "Testing access..."
kubectl get nodes

# Grant access to all authenticated users
echo "Granting access to all AWS users..."
kubectl create clusterrolebinding authenticated-cluster-admin \
  --clusterrole=cluster-admin \
  --group=system:authenticated

echo ""
echo "Cluster is now accessible!"
echo "Any AWS user can now run:"
echo "  aws eks update-kubeconfig --region us-east-2 --name training-cluster"
echo "  kubectl get nodes"