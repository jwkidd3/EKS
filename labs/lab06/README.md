# Lab 6: Application Deployment with Helm

## Duration: 45 minutes

## Objectives
- Search and explore available Helm charts
- Deploy applications using existing Helm charts
- Customize deployments using values files
- Upgrade and rollback Helm releases
- Create a simple custom Helm chart

## Prerequisites
- Lab 5 completed (microservices deployment)
- kubectl configured to use your namespace
- Helm 3.x installed

## Instructions

### Step 1: Clean Up Previous Resources
Start with a clean environment:

```bash
# Clean up previous lab resources
kubectl delete deployment --all
kubectl delete svc --all
kubectl delete configmap --all
kubectl get all

# Verify namespace is clean
kubectl get pods
```

### Step 2: Initialize Helm and Add Repositories
Set up Helm repositories for chart discovery:

```bash
# Add popular Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update repository information
helm repo update

# List available repositories
helm repo list

# Search for available charts
helm search repo redis
helm search repo nginx
helm search repo mysql
```

### Step 3: Deploy Redis Using Bitnami Chart
Deploy Redis using a pre-built Helm chart:

```bash
# Search for Redis charts
helm search repo redis --versions

# Show chart information
helm show chart bitnami/redis
helm show values bitnami/redis > redis-values.yaml

# Install Redis with custom values
helm install user1-redis bitnami/redis \
  --namespace user1-namespace \
  --set auth.enabled=false \
  --set replica.replicaCount=1 \
  --set master.persistence.enabled=false \
  --set replica.persistence.enabled=false

# Check the deployment
helm list -n user1-namespace
kubectl get pods -l app.kubernetes.io/name=redis
```

### Step 4: Create Custom Values File
Create a custom values file for more complex configuration:

```bash
# Create custom values for MySQL
sed 's/userX/user1/g' mysql-values.yaml > my-mysql-values.yaml

# Deploy MySQL with custom values
helm install user1-mysql bitnami/mysql \
  --namespace user1-namespace \
  --values my-mysql-values.yaml

# Check MySQL deployment
kubectl get pods -l app.kubernetes.io/name=mysql
kubectl get pvc -l app.kubernetes.io/name=mysql
```

### Step 5: Deploy Web Application Using Helm
Deploy a web application that connects to the databases:

```bash
# Deploy nginx web server
helm install user1-nginx bitnami/nginx \
  --namespace user1-namespace \
  --set service.type=LoadBalancer \
  --set replicaCount=2

# Check web server deployment
kubectl get pods -l app.kubernetes.io/name=nginx
kubectl get svc -l app.kubernetes.io/name=nginx
```

### Step 6: Monitor and Manage Helm Releases
Learn to manage Helm releases:

```bash
# List all releases in namespace
helm list -n user1-namespace

# Get release status
helm status user1-redis -n user1-namespace
helm status user1-mysql -n user1-namespace

# Get release history
helm history user1-redis -n user1-namespace

# Get release values
helm get values user1-redis -n user1-namespace
helm get manifest user1-redis -n user1-namespace
```

### Step 7: Upgrade Helm Releases
Practice upgrading releases with new configurations:

```bash
# Upgrade Redis with different configuration
helm upgrade user1-redis bitnami/redis \
  --namespace user1-namespace \
  --set auth.enabled=false \
  --set replica.replicaCount=2 \
  --set master.persistence.enabled=false \
  --set replica.persistence.enabled=false

# Check upgrade status
helm history user1-redis -n user1-namespace
kubectl get pods -l app.kubernetes.io/name=redis

# Upgrade nginx with more replicas
helm upgrade user1-nginx bitnami/nginx \
  --namespace user1-namespace \
  --set replicaCount=3 \
  --set service.type=LoadBalancer

# Verify the upgrade
kubectl get pods -l app.kubernetes.io/name=nginx
```

### Step 8: Create a Custom Helm Chart
Create your own Helm chart for the microservices from Lab 5:

```bash
# Create a new Helm chart
helm create user1-microservices

# Examine the generated structure
ls -la user1-microservices/
tree user1-microservices/

# Edit the chart files
sed 's/userX/user1/g' Chart.yaml > user1-microservices/Chart.yaml
sed 's/userX/user1/g' values.yaml > user1-microservices/values.yaml
```

### Step 9: Customize the Helm Chart Templates
Modify the chart templates for your microservices:

```bash
# Replace the default templates with your microservices
cp microservices-deployment.yaml user1-microservices/templates/
cp microservices-service.yaml user1-microservices/templates/
cp microservices-configmap.yaml user1-microservices/templates/

# Remove default files if needed
rm user1-microservices/templates/deployment.yaml
rm user1-microservices/templates/service.yaml

# Validate the chart
helm lint user1-microservices/
```

### Step 10: Install Your Custom Chart
Deploy your custom chart:

```bash
# Install the custom chart
helm install user1-app user1-microservices/ \
  --namespace user1-namespace \
  --values user1-microservices/values.yaml

# Check the deployment
helm list -n user1-namespace
kubectl get pods -l app.kubernetes.io/managed-by=Helm

# Test the application
kubectl get svc
```

### Step 11: Test Application Connectivity
Verify that Helm-deployed applications work together:

```bash
# Create a test pod for connectivity testing
sed 's/userX/user1/g' helm-test-pod.yaml > my-helm-test-pod.yaml
kubectl apply -f my-helm-test-pod.yaml

# Test Redis connectivity
kubectl exec user1-helm-test -- redis-cli -h user1-redis-master ping

# Test MySQL connectivity
kubectl exec user1-helm-test -- mysql -h user1-mysql -u root -ppassword -e "SHOW DATABASES;"

# Test web server
kubectl exec user1-helm-test -- curl -s http://user1-nginx/
```

### Step 12: Practice Rollbacks
Learn to rollback releases when issues occur:

```bash
# Simulate a bad upgrade (invalid configuration)
helm upgrade user1-nginx bitnami/nginx \
  --namespace user1-namespace \
  --set replicaCount=10 \
  --set resources.requests.memory=10Gi

# Check if pods are pending due to resource constraints
kubectl get pods -l app.kubernetes.io/name=nginx

# Rollback to previous version
helm rollback user1-nginx 1 -n user1-namespace

# Verify rollback
helm history user1-nginx -n user1-namespace
kubectl get pods -l app.kubernetes.io/name=nginx
```

### Step 13: Package and Share Your Chart
Learn to package charts for distribution:

```bash
# Package your custom chart
helm package user1-microservices/

# Verify the package
ls -la user1-microservices-*.tgz

# Install from the package
helm install user1-packaged-app user1-microservices-*.tgz \
  --namespace user1-namespace \
  --set fullnameOverride=user1-packaged

# Check the installation
helm list -n user1-namespace
```

## Verification Steps

### Verify Your Helm Deployments
Run these commands to verify everything is working:

```bash
# 1. Check all Helm releases
helm list -n user1-namespace

# 2. Verify all pods are running
kubectl get pods

# 3. Check services created by Helm
kubectl get svc -l app.kubernetes.io/managed-by=Helm

# 4. Test connectivity between Helm-deployed services
kubectl exec user1-helm-test -- curl -s http://user1-nginx/

# 5. Verify persistent volumes (if any)
kubectl get pvc
```

## Clean Up
Remove Helm releases and clean up:

```bash
# Uninstall all Helm releases
helm uninstall user1-redis -n user1-namespace
helm uninstall user1-mysql -n user1-namespace
helm uninstall user1-nginx -n user1-namespace
helm uninstall user1-app -n user1-namespace
helm uninstall user1-packaged-app -n user1-namespace

# Delete custom charts and packages
rm -rf user1-microservices/
rm -f user1-microservices-*.tgz

# Clean up test resources
kubectl delete pod user1-helm-test
```

## Troubleshooting

### Common Issues
1. **Chart not found**: Ensure repositories are added and updated
2. **Values not applied**: Check YAML syntax and indentation
3. **Release failed**: Use `helm status` and `kubectl describe` to debug
4. **Permission denied**: Verify namespace access and RBAC permissions

### Useful Commands
```bash
# Debug Helm releases
helm get all <release-name> -n <namespace>
helm get hooks <release-name> -n <namespace>

# Template validation
helm template <chart> --debug

# Dry run installation
helm install <release> <chart> --dry-run --debug
```

## Key Concepts Learned
- **Helm Repositories**: Adding and managing chart repositories
- **Chart Discovery**: Searching for and exploring available charts
- **Values Customization**: Using values files to customize deployments
- **Release Management**: Installing, upgrading, and rolling back releases
- **Chart Creation**: Building custom Helm charts for applications
- **Package Management**: Packaging and distributing Helm charts
- **Troubleshooting**: Debugging Helm deployments and releases

## Next Steps
In the next lab, you'll learn how to implement health checks and monitoring for your applications to ensure they're running properly and can recover from failures.

---

**Remember**: Helm simplifies application deployment and management, but understanding the underlying Kubernetes resources is still important!