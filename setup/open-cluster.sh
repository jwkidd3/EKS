#!/bin/bash
# open-cluster.sh - Open cluster for direct kubectl access

echo "Making cluster publicly accessible without AWS auth..."

# Get cluster endpoint
ENDPOINT=$(aws eks describe-cluster --name training-cluster --region us-east-2 --query 'cluster.endpoint' --output text)
echo "Cluster endpoint: $ENDPOINT"

# Get cluster CA certificate
CA_DATA=$(aws eks describe-cluster --name training-cluster --region us-east-2 --query 'cluster.certificateAuthority.data' --output text)

# Create public kubeconfig file that students can use
cat << EOF > public-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_DATA
    server: $ENDPOINT
  name: training-cluster
contexts:
- context:
    cluster: training-cluster
  name: training-cluster
current-context: training-cluster
users: []
EOF

echo "Created public-kubeconfig.yaml"
echo ""
echo "Students can now use:"
echo "export KUBECONFIG=./public-kubeconfig.yaml"
echo "kubectl get nodes"
echo ""
echo "Share the public-kubeconfig.yaml file with students"