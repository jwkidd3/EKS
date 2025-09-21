#!/bin/bash
# delete-cluster.sh

echo "Force deleting EKS training cluster (no graceful draining)..."

# Force delete the cluster (faster, no pod eviction attempts)
eksctl delete cluster --name training-cluster --region us-east-2 --force --disable-nodegroup-eviction

# Clean up any remaining EBS volumes (optional)
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/training-cluster,Values=owned" --query 'Volumes[*].VolumeId' --output text | xargs -r aws ec2 delete-volume --volume-id

echo "Cluster deletion completed!"