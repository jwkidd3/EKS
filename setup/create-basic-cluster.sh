#!/bin/bash
# create-basic-cluster.sh - Create basic 2-node cluster

echo "Creating basic 2-node EKS cluster in us-east-2..."

eksctl create cluster \
  --name training-cluster \
  --region us-east-2 \
  --nodes 2 \
  --node-type m5.large \
  --managed

echo "Cluster created successfully!"