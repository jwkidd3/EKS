#!/bin/bash
# fix-access.sh - Add cluster creator to access and then grant broad access

echo "Adding cluster creator to access..."

# Get current user ARN
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
echo "Adding user: $USER_ARN"

# Add cluster creator to the cluster (this requires eksctl)
eksctl create iamidentitymapping \
  --cluster training-cluster \
  --region us-east-2 \
  --arn "$USER_ARN" \
  --group system:masters \
  --username cluster-admin

echo "Cluster creator added. Now updating kubeconfig..."
aws eks update-kubeconfig --region us-east-2 --name training-cluster

echo "Testing access..."
kubectl get nodes

echo "Now granting access to all users..."
kubectl create clusterrolebinding authenticated-users \
  --clusterrole=cluster-admin \
  --group=system:authenticated

kubectl create clusterrolebinding anonymous-users \
  --clusterrole=cluster-admin \
  --user=system:anonymous

echo "Access granted to all users!"