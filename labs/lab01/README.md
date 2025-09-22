# Lab 1: Exploring the Shared EKS Cluster

## Duration: 30 minutes

## Objectives
- Configure kubectl for cluster access (kubectl pre-installed in Cloud9)
- Connect to shared EKS cluster in us-east-2
- Explore existing cluster components and namespaces
- Create personal namespace for isolation (userX-namespace)
- Verify cluster access and basic kubectl commands

## Prerequisites
- Access to AWS Cloud9 environment with provided credentials
- Your assigned username (user1, user2, etc.)

## Instructions

### Step 1: Install and Verify Required Tools

#### Install kubectl
```bash
# Install kubectl
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin

# Verify kubectl is available
kubectl version --client
```

### Step 2: Set Up Cluster Access

```bash
# Run the setup script provided by instructor
./student-setup.sh
```

**Expected Output**: You should see "Setup complete!" and a list of 2 worker nodes.

### Step 4: Explore Existing Namespaces
Explore the namespaces that already exist in the cluster:

```bash
# List all namespaces
kubectl get namespaces

# Get detailed information about namespaces
kubectl get namespaces -o wide

# Describe a specific namespace (like kube-system)
kubectl describe namespace kube-system
```

**Questions to Consider:**
- What default namespaces do you see?
- What custom namespaces are already created?

### Step 6: Create Your Personal Namespace
Create your personal namespace using the provided YAML file. You'll need to customize it with your assigned username for resource isolation in the shared cluster:

```bash
# IMPORTANT: Resource Naming for Shared Cluster
# The sed command below replaces 'userX' with your assigned username in ALL resource names
# This ensures isolation between students in the shared EKS cluster
#
# What gets renamed:
# - Namespace: userX-namespace → user1-namespace
# - ResourceQuota: userX-quota → user1-quota
# - LimitRange: userX-limits → user1-limits
# - Labels: owner: userX → owner: user1
#
# Replace 'user1' with YOUR assigned username (user1, user2, user3, etc.)
sed 's/userX/user1/g' namespace.yaml > my-namespace.yaml

# Create your namespace
kubectl apply -f my-namespace.yaml

# Verify your namespace was created
kubectl get namespace user1-namespace
```

### Step 7: Set Your Default Namespace Context
Configure kubectl to use your namespace by default:

```bash
# Set your namespace as the default for this context
kubectl config set-context --current --namespace=user1-namespace

# Verify the context change
kubectl config view --minify | grep namespace
```

### Step 8: Explore Cluster Components
Let's explore what's running in the cluster:

```bash
# Check system pods
kubectl get pods -n kube-system

# Check if there are any pods in your namespace
kubectl get pods

# Look at cluster-wide resources
kubectl get nodes -o wide
kubectl get storageclasses
kubectl get clusterroles | head -10
```

### Step 9: Test Basic kubectl Commands
Practice some basic kubectl commands in your namespace:

```bash
# Get help for kubectl
kubectl help

# Show version information
kubectl version --client

# Get events in your namespace
kubectl get events

# Check resource quotas (if any)
kubectl get resourcequota

# Check if you can see all namespaces
kubectl get pods --all-namespaces | head -10
```

### Step 10: Understanding Your Permissions
Test what you can and cannot do:

```bash
# Test if you can create pods in your namespace
kubectl auth can-i create pods

# Test if you can create namespaces
kubectl auth can-i create namespaces

# Test if you can delete nodes (should be no)
kubectl auth can-i delete nodes

# Get a list of resources you can access
kubectl api-resources --verbs=list --namespaced -o name
```

### Step 11: Explore Pre-installed Add-ons
Check what add-ons are already installed:

```bash
# Check for metrics server
kubectl get pods -n kube-system | grep metrics-server

# Check for AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Check for Calico components
kubectl get pods -n calico-system

# Check for kube-ops-view
kubectl get pods -n kube-ops-view
```

## Verification Steps

### Verify Your Setup
Run these commands to ensure everything is working:

```bash
# 1. Confirm you're in your namespace
kubectl config view --minify | grep namespace

# 2. Confirm you can create resources in your namespace
kubectl auth can-i create pods

# 3. List your namespace
kubectl get namespace | grep user1

# 4. Check for any existing resources in your namespace
kubectl get all
```

## Troubleshooting

### Common Issues
1. **Cannot connect to cluster**: Verify your kubeconfig is correct
2. **Permission denied**: Ensure you're using the correct username
3. **Namespace already exists**: This is okay, just proceed
4. **Wrong namespace context**: Re-run the context setting command

### Helpful Commands
```bash
# Reset namespace context if needed
kubectl config set-context --current --namespace=default

# Check current user
kubectl config view --minify | grep name

# Debug connection issues
kubectl cluster-info dump

# Re-configure cluster access if needed
aws eks update-kubeconfig --region us-east-2 --name training-cluster

# View available clusters (read-only)
aws eks list-clusters --region us-east-2
```

## Key Takeaways
- The EKS cluster is shared among all students
- Each student has their own isolated namespace
- You have specific permissions within your namespace
- Several add-ons are pre-installed for the training labs
- Always work within your assigned namespace to avoid conflicts

## Next Steps
In the next lab, you'll start creating and managing Pods within your personal namespace.

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!