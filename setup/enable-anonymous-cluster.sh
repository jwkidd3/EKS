#!/bin/bash
# enable-anonymous-cluster.sh - Configure cluster for anonymous access

echo "Configuring cluster for anonymous access..."

# First, we need to get access to the cluster as the creator
# Add the cluster creator to the aws-auth configmap
eksctl create iamidentitymapping \
  --cluster training-cluster \
  --region us-east-2 \
  --arn $(aws sts get-caller-identity --query Arn --output text) \
  --group system:masters \
  --username cluster-admin

# Update kubeconfig
aws eks update-kubeconfig --region us-east-2 --name training-cluster

# Enable anonymous authentication by modifying the cluster
kubectl patch configmap aws-auth -n kube-system --patch '
data:
  mapRoles: |
    - rolearn: system:anonymous
      username: system:anonymous
      groups:
        - system:masters
'

# Create ClusterRoleBinding for anonymous users
kubectl create clusterrolebinding anonymous-cluster-admin \
  --clusterrole=cluster-admin \
  --user=system:anonymous

echo "Cluster configured for anonymous access!"
echo "Users can now connect with just: kubectl --server=$(aws eks describe-cluster --name training-cluster --region us-east-2 --query 'cluster.endpoint' --output text) --insecure-skip-tls-verify=true get nodes"