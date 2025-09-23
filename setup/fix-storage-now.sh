#!/bin/bash
# fix-storage-now.sh - Fix storage on existing cluster

set -e

echo "=== FIXING STORAGE ON EXISTING CLUSTER ==="

# 1. Delete any pending PVCs
kubectl delete pvc --all --ignore-not-found=true

# 2. Delete existing EBS CSI addon if it exists
eksctl delete addon --name aws-ebs-csi-driver --cluster training-cluster --region us-east-2 || true

# 3. Create EBS CSI service account with proper IAM role
echo "Creating EBS CSI service account with IAM..."
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster training-cluster \
  --region us-east-2 \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/Amazon_EBS_CSI_DriverPolicy \
  --approve \
  --override-existing-serviceaccounts

# 4. Install EBS CSI addon with the service account
echo "Installing EBS CSI driver addon..."
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster training-cluster \
  --region us-east-2 \
  --service-account-role-arn $(aws iam get-role --role-name eksctl-training-cluster-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa-Role1 --query 'Role.Arn' --output text 2>/dev/null || echo "auto") \
  --force

# 5. Wait for driver to be ready
echo "Waiting for EBS CSI driver to be ready..."
sleep 30
kubectl wait --for=condition=Ready pod -l app=ebs-csi-controller -n kube-system --timeout=120s

# 6. Recreate storage classes
echo "Recreating storage classes..."
kubectl delete storageclass gp3 gp3-immediate fast-ssd --ignore-not-found=true

kubectl apply -f storage-classes.yaml

# 7. Test immediate storage
echo "Testing immediate storage..."
kubectl apply -f test-storage.yaml

# 8. Check result
sleep 5
kubectl get pvc,pv
kubectl describe pvc test-storage-pvc

echo ""
echo "=== STORAGE FIX COMPLETE ==="
echo "If PVC is still pending, check:"
echo "kubectl logs -n kube-system -l app=ebs-csi-controller"