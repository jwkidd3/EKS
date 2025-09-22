#!/bin/bash
# add-user-access.sh - Add current AWS user to EKS cluster access

echo "Adding current AWS user to EKS cluster access..."

# Get current AWS user ARN
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
echo "Current user ARN: $USER_ARN"

# Add user to cluster access
eksctl create iamidentitymapping \
  --cluster training-cluster \
  --region us-east-2 \
  --arn "$USER_ARN" \
  --group system:masters \
  --username admin

echo "User access added to cluster!"
echo "Now run: kubectl get nodes"