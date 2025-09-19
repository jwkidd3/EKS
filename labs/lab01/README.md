# Lab 1: Exploring the Shared EKS Cluster

## Duration: 30 minutes

## Objectives
- Install and configure kubectl for cluster access
- Connect to shared EKS cluster in us-east-1
- Explore existing cluster components and namespaces
- Create personal namespace for isolation (userX-namespace)
- Verify cluster access and basic kubectl commands

## Prerequisites
- Access to AWS Cloud9 environment with provided credentials
- Your assigned username (user1, user2, etc.)

## Instructions

### Step 1: Install Required Tools

#### Install kubectl
**For macOS:**
```bash
# Using Homebrew
brew install kubectl

# Verify installation
kubectl version --client
```

**For Linux:**
```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

**For Windows:**
```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or download from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

#### Verify AWS CLI (pre-installed in Cloud9)
```bash
# AWS CLI is pre-installed in Cloud9 - just verify it's working
aws --version

# Verify your AWS identity
aws sts get-caller-identity
```

### Step 2: Verify AWS Access
Your AWS credentials are already configured in Cloud9:

```bash
# Verify AWS configuration
aws sts get-caller-identity

# Check current region
aws configure get region
```

**Expected Output**: You should see your AWS account ID, user ARN, and user ID.

### Step 3: Connect to the Shared EKS Cluster
Update your kubeconfig to connect to the training cluster:

```bash
# Update kubeconfig for the training cluster
aws eks update-kubeconfig --region us-east-1 --name training-cluster

# Verify the context was added
kubectl config get-contexts

# Verify connection to the cluster
kubectl cluster-info
```

**Expected Output**: You should see cluster information showing the EKS cluster endpoint.

### Step 4: Verify Cluster Access
Test your connection to the EKS cluster:

```bash
# Check cluster connection
kubectl cluster-info

# View cluster nodes
kubectl get nodes

# Check your current context
kubectl config current-context
```

**Expected Output**: You should see cluster information and a list of worker nodes.

### Step 5: Explore Existing Namespaces
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
Create your personal namespace using the provided YAML file. Edit the namespace name to include your username:

```bash
# Edit the namespace YAML file
# Replace 'userX' with your actual username (e.g., user1, user2)
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
aws eks update-kubeconfig --region us-east-1 --name training-cluster

# View available clusters (read-only)
aws eks list-clusters --region us-east-1
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