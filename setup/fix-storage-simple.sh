#!/bin/bash
# fix-storage-simple.sh - Fix storage without OIDC requirements

set -e

echo "=== FIXING STORAGE WITHOUT OIDC ==="

# 1. Enable OIDC on existing cluster
echo "Enabling OIDC on cluster..."
eksctl utils associate-iam-oidc-provider --cluster training-cluster --region us-east-2 --approve

# 2. Install EBS CSI driver manually (no service account needed)
echo "Installing EBS CSI driver manually..."
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.24"

# 3. Wait for driver to start
echo "Waiting for EBS CSI driver..."
sleep 30
kubectl wait --for=condition=Ready pod -l app=ebs-csi-controller -n kube-system --timeout=120s

# 4. Delete any pending PVCs and recreate storage classes
kubectl delete pvc --all --ignore-not-found=true
kubectl delete storageclass gp3 gp3-immediate fast-ssd --ignore-not-found=true

# 5. Create simple storage classes
kubectl apply -f - << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-immediate
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
volumeBindingMode: Immediate
reclaimPolicy: Delete
EOF

# 6. Test immediate storage
kubectl apply -f - << 'EOF'
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
EOF

# 7. Check result
sleep 10
kubectl get pvc,pv
echo "=== DONE ==="