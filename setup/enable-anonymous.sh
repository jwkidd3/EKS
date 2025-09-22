#!/bin/bash
# enable-anonymous.sh - Enable anonymous access to existing cluster

echo "Enabling anonymous access to cluster..."

# Get cluster endpoint
CLUSTER_ENDPOINT=$(aws eks describe-cluster --name training-cluster --region us-east-2 --query 'cluster.endpoint' --output text)
echo "Cluster endpoint: $CLUSTER_ENDPOINT"

# Create kubeconfig with anonymous access
cat << EOF > ~/.kube/config-anonymous
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: $CLUSTER_ENDPOINT
    insecure-skip-tls-verify: true
  name: training-cluster
contexts:
- context:
    cluster: training-cluster
  name: training-cluster
current-context: training-cluster
EOF

# Use anonymous config
export KUBECONFIG=~/.kube/config-anonymous

# Create anonymous RBAC
kubectl create clusterrolebinding anonymous-admin \
  --clusterrole=cluster-admin \
  --user=system:anonymous

echo "Anonymous access enabled!"
echo "Export KUBECONFIG=~/.kube/config-anonymous to use anonymous access"