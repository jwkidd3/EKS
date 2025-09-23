#!/bin/bash
# complete-cluster-setup.sh - Complete EKS cluster setup with working storage

set -e

echo "=== COMPLETE EKS CLUSTER SETUP ==="

# 1. Delete existing cluster if it exists
echo "Cleaning up any existing cluster..."
eksctl delete cluster --name training-cluster --region us-east-2 --force --disable-nodegroup-eviction || true

# 2. Create cluster with proper IAM service accounts
echo "Creating new cluster with EBS CSI driver..."
eksctl create cluster \
  --name training-cluster \
  --region us-east-2 \
  --nodes 2 \
  --node-type m5.large \
  --managed \
  --with-oidc

# 3. Create EBS CSI service account with IAM role
echo "Setting up EBS CSI driver IAM..."
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster training-cluster \
  --region us-east-2 \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/Amazon_EBS_CSI_DriverPolicy \
  --approve

# 4. Install EBS CSI driver
echo "Installing EBS CSI driver..."
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster training-cluster \
  --region us-east-2 \
  --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/eksctl-training-cluster-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa-Role1 \
  --force

# 5. Wait for EBS CSI driver to be ready
echo "Waiting for EBS CSI driver..."
kubectl wait --for=condition=Ready pod -l app=ebs-csi-controller -n kube-system --timeout=300s

# 6. Create storage classes
echo "Creating storage classes..."
kubectl apply -f - << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-immediate
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: Immediate
reclaimPolicy: Delete
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: io2
  iops: "4000"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# 7. Create Cloud9 IAM role and add to cluster
echo "Setting up Cloud9 access..."
aws iam create-role --role-name Cloud9-EKS-Role --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }
  ]
}' || true

aws iam attach-role-policy --role-name Cloud9-EKS-Role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy || true
aws iam attach-role-policy --role-name Cloud9-EKS-Role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy || true

aws iam create-instance-profile --instance-profile-name Cloud9-EKS-Profile || true
aws iam add-role-to-instance-profile --instance-profile-name Cloud9-EKS-Profile --role-name Cloud9-EKS-Role || true

eksctl create iamidentitymapping \
  --cluster training-cluster \
  --region us-east-2 \
  --arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/Cloud9-EKS-Role \
  --group system:masters \
  --username cloud9-user

# 8. Grant access to all authenticated users
echo "Granting access to all authenticated AWS users..."
kubectl create clusterrolebinding all-access \
  --clusterrole=cluster-admin \
  --group=system:authenticated

# 9. Test immediate storage
echo "Testing immediate storage binding..."
kubectl apply -f - << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-immediate-storage
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp3-immediate
  resources:
    requests:
      storage: 1Gi
EOF

# 10. Wait and verify
sleep 10
kubectl get pvc test-immediate-storage
kubectl get pv

echo ""
echo "=== SETUP COMPLETE ==="
echo "Cluster: training-cluster"
echo "Region: us-east-2"
echo "Nodes: $(kubectl get nodes --no-headers | wc -l)"
echo "Storage Classes: $(kubectl get sc --no-headers | wc -l)"
echo ""
echo "Students should:"
echo "1. Attach Cloud9-EKS-Profile to their EC2 instance"
echo "2. Run: aws eks update-kubeconfig --region us-east-2 --name training-cluster"
echo "3. Run: kubectl get nodes"
echo ""
echo "If PVC is still Pending, check logs:"
echo "kubectl logs -n kube-system deployment/ebs-csi-controller"