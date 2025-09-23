#!/bin/bash
# fix-ebs-permissions.sh - Fix EBS permissions NOW

set -e

echo "Fixing EBS permissions..."

# Get worker node role
NODE_ROLE=$(aws iam list-roles --query 'Roles[?contains(RoleName, `NodeInstanceRole`) || contains(RoleName, `eksctl-training-cluster-nodegroup`)].RoleName' --output text)
echo "Node role: $NODE_ROLE"

# Create EBS policy file
cat > /tmp/ebs-policy.json << 'POLICY_END'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:AttachVolume",
                "ec2:DetachVolume",
                "ec2:ModifyVolume",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInstances",
                "ec2:DescribeSnapshots",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumesModifications",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:CreateVolume",
                "ec2:DeleteVolume"
            ],
            "Resource": "*"
        }
    ]
}
POLICY_END

# Create policy
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam create-policy --policy-name EKS-EBS-CSI-Policy --policy-document file:///tmp/ebs-policy.json || true

# Attach policy to node role
aws iam attach-role-policy --role-name $NODE_ROLE --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/EKS-EBS-CSI-Policy

# Delete existing PVC
kubectl delete pvc test-now || true

# Create test PVC file
cat > /tmp/test-pvc.yaml << 'PVC_END'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-now
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp3-immediate
  resources:
    requests:
      storage: 1Gi
PVC_END

# Apply test PVC
kubectl apply -f /tmp/test-pvc.yaml

# Wait and check
sleep 15
kubectl get pvc,pv

echo "Fix complete!"