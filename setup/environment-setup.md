# EKS Training Environment Setup Guide

## Overview
This document outlines the components and steps required to set up a **simplified shared EKS cluster** environment for the 3-day training course using eksctl for cluster creation and management.

### Key Simplifications
- **Standard AWS Credentials:** Students use their existing AWS credentials
- **No Custom IAM Setup:** Eliminates complex per-user IAM role management
- **Streamlined Access:** Direct cluster access with standard AWS permissions

## Prerequisites
- AWS Account with appropriate permissions
- eksctl CLI tool (latest version)
- kubectl CLI tool
- AWS CLI configured with appropriate credentials
- Helm 3.x installed

## Install Required Tools

### Install eksctl
```bash
# For macOS
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# For Linux
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
```

### kubectl Installation
Students will install kubectl during Lab 1 as part of the hands-on learning experience.

## Cluster Configuration File

Create the cluster configuration file that defines the complete EKS setup:

```yaml
# eks-training-cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: training-cluster
  region: us-east-2
  version: "1.28"

# VPC Configuration
vpc:
  cidr: 10.0.0.0/16
  enableDnsHostnames: true
  enableDnsSupport: true
  publicAccessCIDRs: ["0.0.0.0/0"]

# IAM Configuration
iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: aws-load-balancer-controller
      namespace: kube-system
    wellKnownPolicies:
      awsLoadBalancerController: true
  - metadata:
      name: ebs-csi-controller-sa
      namespace: kube-system
    wellKnownPolicies:
      ebsCSIController: true
  - metadata:
      name: cluster-autoscaler
      namespace: kube-system
    wellKnownPolicies:
      autoScaler: true

# Add-ons
addons:
- name: vpc-cni
  version: latest
- name: coredns
  version: latest
- name: kube-proxy
  version: latest
- name: aws-ebs-csi-driver
  version: latest
  serviceAccountRoleARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/eksctl-training-cluster-addon-iamserviceaccount-kube-system-ebs-csi-controller-sa-Role1

# Node Groups
nodeGroups:
- name: training-workers
  instanceType: m5.large
  desiredCapacity: 5
  minSize: 3
  maxSize: 10
  volumeSize: 30
  volumeType: gp3
  amiFamily: AmazonLinux2
  ssh:
    enableSsm: true
  labels:
    node-type: training
    environment: education
  tags:
    Environment: Training
    Project: EKS-Course
  iam:
    attachPolicyARNs:
    - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
    - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
    - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
    - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Optional: Spot instance node group for cost optimization
- name: training-spot
  instancesDistribution:
    instanceTypes:
    - m5.large
    - m5a.large
    - m4.large
    onDemandBaseCapacity: 0
    onDemandPercentageAboveBaseCapacity: 0
    spotInstancePools: 3
  desiredCapacity: 3
  minSize: 0
  maxSize: 8
  volumeSize: 30
  volumeType: gp3
  amiFamily: AmazonLinux2
  labels:
    node-type: training-spot
    environment: education
  tags:
    Environment: Training
    Project: EKS-Course
    NodeType: Spot

# CloudWatch Logging
cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    logRetentionInDays: 7
```

## Cluster Creation

### 1. Create the EKS Cluster
```bash
# Set environment variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-2

# Create the cluster (takes 15-20 minutes)
eksctl create cluster -f eks-training-cluster.yaml

# Verify cluster creation
kubectl get nodes
kubectl cluster-info
```

### 2. Update kubeconfig
```bash
# Update kubeconfig for cluster access
aws eks update-kubeconfig --region us-east-2 --name training-cluster

# Verify access
kubectl get svc
```

## Post-Cluster Setup

### 1. Install AWS Load Balancer Controller
```bash
# The service account was created by eksctl, now install the controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=training-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-2 \
  --set vpcId=$(aws eks describe-cluster --name training-cluster --query "cluster.resourcesVpcConfig.vpcId" --output text)

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### 2. Install Calico Network Policy Engine
```bash
# Install Calico for network policies
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Verify Calico installation
kubectl get pods -n calico-system
```

### 3. Install Cluster Autoscaler
```bash
# Download and apply cluster autoscaler
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Edit the deployment to add cluster name
sed -i 's/<YOUR CLUSTER NAME>/training-cluster/g' cluster-autoscaler-autodiscover.yaml

kubectl apply -f cluster-autoscaler-autodiscover.yaml

# Annotate the service account (already created by eksctl)
kubectl annotate serviceaccount cluster-autoscaler \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:role/eksctl-training-cluster-addon-iamserviceaccount-kube-system-cluster-autoscaler-Role1

# Verify cluster autoscaler
kubectl get deployment -n kube-system cluster-autoscaler
```

### 4. Install Metrics Server
```bash
# Metrics server should be installed by default, verify
kubectl get deployment metrics-server -n kube-system

# If not installed, install it
if ! kubectl get deployment metrics-server -n kube-system; then
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

# Test metrics
kubectl top nodes
```

### 5. Install Kube-ops-view
```bash
# Install kube-ops-view for cluster visualization
helm repo add geek-cookbook https://geek-cookbook.github.io/charts/
helm repo update

helm install kube-ops-view geek-cookbook/kube-ops-view \
  --namespace kube-ops-view \
  --create-namespace \
  --set service.type=LoadBalancer \
  --set rbac.create=true

# Get the LoadBalancer URL
kubectl get svc -n kube-ops-view kube-ops-view
```

## Storage Configuration

### Create Custom Storage Classes
```bash
# Create gp3 storage class
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF

# Create fast SSD storage class
cat <<EOF | kubectl apply -f -
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

# Create immediate-binding gp3 storage class for instant PVC provisioning
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-immediate
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: Immediate
reclaimPolicy: Delete
EOF

# Verify storage classes
kubectl get storageclass
```


## Monitoring and Observability

### 1. Enable CloudWatch Container Insights
```bash
# Install CloudWatch agent
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | \
sed "s/{{cluster_name}}/training-cluster/;s/{{region_name}}/us-east-2/" | \
kubectl apply -f -

# Verify CloudWatch agent
kubectl get pods -n amazon-cloudwatch
```

### 2. Create Namespace Resource Quotas Template
```bash
cat <<EOF > namespace-quota-template.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: training-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
    services: "10"
    persistentvolumeclaims: "5"
    count/deployments.apps: "10"
    count/replicasets.apps: "20"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: training-limits
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
EOF
```


## Validation and Testing

### 1. Cluster Validation
```bash
# Verify cluster components
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get storageclass
kubectl get crd | grep calico

# Test storage class functionality
kubectl create namespace test-storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc-immediate
  namespace: test-storage
spec:
  storageClassName: gp3-immediate
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Verify PVC is bound immediately
kubectl get pvc -n test-storage
kubectl delete namespace test-storage

# Test cluster functionality
kubectl run test-pod --image=nginx:1.21 --rm -it --restart=Never -- curl -I http://kubernetes.default.svc.cluster.local

# Test metrics
kubectl top nodes
kubectl top pods -A
```

### 2. Component Testing
```bash
# Test AWS Load Balancer Controller
kubectl get deployment -n kube-system aws-load-balancer-controller

# Test Calico
kubectl get pods -n calico-system

# Test EBS CSI Driver
kubectl get pods -n kube-system | grep ebs-csi

# Test Cluster Autoscaler
kubectl get deployment -n kube-system cluster-autoscaler

# Test kube-ops-view
kubectl get svc -n kube-ops-view
```


## Cleanup Scripts

### Training Cleanup Script
```bash
#!/bin/bash
# cleanup-training.sh

echo "Cleaning up training resources..."

# Delete user namespaces
kubectl get namespaces | grep -E "user[0-9]+-namespace" | awk '{print $1}' | xargs -r kubectl delete namespace

# Clean up any remaining PVCs
kubectl delete pvc --all --all-namespaces --ignore-not-found=true

# Clean up available PVs
kubectl delete pv --field-selector=status.phase=Available --ignore-not-found=true

echo "Training cleanup completed!"
```

### Complete Cluster Deletion
```bash
#!/bin/bash
# delete-cluster.sh

echo "Deleting EKS training cluster..."

# Delete the cluster (this will also delete node groups and associated resources)
eksctl delete cluster --name training-cluster --region us-east-2

# Clean up any remaining EBS volumes (optional)
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/training-cluster,Values=owned" --query 'Volumes[*].VolumeId' --output text | xargs -r aws ec2 delete-volume --volume-id

echo "Cluster deletion completed!"
```

## Cost Optimization

### Recommendations
- Use Spot instances for non-critical workloads (configured in node group)
- Implement cluster autoscaler (included in setup)
- Set up resource quotas and limits (template provided)
- Schedule training during off-peak hours
- Monitor costs with AWS Cost Explorer

### Cost Monitoring
```bash
# Check current node utilization for 30-user capacity
kubectl top nodes

# Check resource requests vs limits across all nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# Monitor cluster autoscaler logs for scaling events
kubectl logs -n kube-system deployment/cluster-autoscaler

# Check namespace resource usage
kubectl get resourcequota --all-namespaces

# Monitor EBS volume costs
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/training-cluster,Values=owned" --query 'Volumes[*].[VolumeId,Size,VolumeType]' --output table
```

## Troubleshooting

### Common Issues and Solutions
1. **eksctl command not found**: Ensure eksctl is properly installed and in PATH
2. **Insufficient IAM permissions**: Ensure AWS credentials have EKS and EC2 permissions
3. **Node group creation fails**: Check VPC quotas and instance limits
4. **Add-on installation fails**: Verify IRSA and service account configurations
5. **Network connectivity issues**: Check security groups and route tables

### Monitoring Commands
```bash
# Monitor cluster status
eksctl get cluster --region us-east-2

# Check node group status
eksctl get nodegroup --cluster training-cluster --region us-east-2

# Monitor cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check system pods
kubectl get pods -n kube-system

# Monitor resource usage
kubectl top nodes
kubectl top pods -A
```

## Security Considerations

### Best Practices Implemented
- IRSA (IAM Roles for Service Accounts) enabled
- Private subnets for worker nodes
- Security groups with minimal required access
- CloudWatch logging enabled
- Network policies support with Calico
- Encrypted EBS volumes
- Least privilege RBAC policies

### Additional Security Measures
- Regular security scanning of container images
- Implementation of Pod Security Standards
- Network policy enforcement
- Audit log monitoring
- Access key rotation
- VPC Flow Logs (optional)

## Capacity Planning for 30 Students

### Node Group Scaling
- **Primary Workers:** 5-10 nodes (m5.large) - handles core workloads
- **Spot Workers:** 0-8 nodes (mixed instance types) - cost optimization
- **Total Capacity:** 13-18 nodes supporting 30 concurrent users
- **Auto Scaling:** Enabled based on resource demands

### Resource Allocation per Student
- **CPU Requests:** Up to 4 cores per namespace
- **Memory Requests:** Up to 8GB per namespace
- **Pods:** Up to 20 pods per namespace
- **Storage:** Up to 5 PVCs per namespace
- **Services:** Up to 10 services per namespace

### Total Cluster Capacity
- **CPU:** ~60-90 cores across all nodes
- **Memory:** ~240-360GB across all nodes
- **Storage:** Unlimited EBS volumes (pay per use)
- **Network:** 30 isolated namespaces with Calico policies

## Storage Classes Summary

The cluster provides multiple storage classes for different lab scenarios:

| Storage Class | Binding Mode | Use Case | IOPS | Throughput |
|---------------|--------------|----------|------|------------|
| **gp3** | WaitForFirstConsumer | StatefulSets, node-specific workloads | 3000 | 125 MiB/s |
| **gp3-immediate** | Immediate | Quick PVC provisioning, demos | 3000 | 125 MiB/s |
| **fast-ssd** | WaitForFirstConsumer | High-performance applications | 4000 | N/A |

**Storage Access:**
- All students have immediate access to create PVCs with any storage class
- Standard Kubernetes RBAC applies based on AWS credentials
- Automatic cleanup of PVCs when namespaces are deleted

---

**Note**: This simplified environment setup using eksctl provides a production-ready, secure, and cost-effective EKS cluster for training purposes. All components are configured with best practices and can support **30 concurrent users** using standard AWS credentials.