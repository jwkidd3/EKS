#!/bin/bash
# create-iam-role.sh - Creates the EKS Training IAM Role

set -e

echo "Creating EKS Training IAM Role..."

# Get AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Substitute environment variables in the policy template
envsubst < eks-training-role-policy.json > eks-training-role-policy-final.json

echo "Creating IAM role: EKS-Training-Role"

# Create the role
aws iam create-role \
  --role-name EKS-Training-Role \
  --assume-role-policy-document file://eks-training-role-policy-final.json \
  --description "Role for EKS training environment access from Cloud9"

# Attach necessary policies
echo "Attaching policies to role..."

aws iam attach-role-policy \
  --role-name EKS-Training-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam attach-role-policy \
  --role-name EKS-Training-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

echo "IAM role EKS-Training-Role created successfully!"
echo "Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/EKS-Training-Role"

# Clean up temporary file
rm -f eks-training-role-policy-final.json

echo "Setup complete!"