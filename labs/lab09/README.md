# Lab 9: Implementing RBAC

## Duration: 45 minutes

## Objectives
- Create service accounts for applications
- Define roles with specific permissions
- Create role bindings for users and service accounts
- Test access controls with different user contexts
- Troubleshoot permission issues

## Prerequisites
- Lab 8 completed (autoscaling)
- kubectl configured to use your namespace
- Understanding of Kubernetes security concepts

## Instructions

### Step 1: Clean Up Previous Resources
Start with a clean environment:

```bash
# Clean up previous lab resources
kubectl delete deployment --all
kubectl delete svc --all
kubectl delete hpa --all
kubectl delete pod --all
kubectl get all

# Verify namespace is clean
kubectl get pods
```

### Step 2: Create Service Accounts
Create service accounts for different application roles:

```bash
# Create service accounts
sed 's/userX/user1/g' service-accounts.yaml > my-service-accounts.yaml
kubectl apply -f my-service-accounts.yaml

# Verify service accounts were created
kubectl get serviceaccounts
kubectl describe serviceaccount user1-app-reader
kubectl describe serviceaccount user1-app-manager
kubectl describe serviceaccount user1-admin
```

### Step 3: Create Roles with Specific Permissions
Define roles with different permission levels:

```bash
# Create roles with different permission levels
sed 's/userX/user1/g' roles.yaml > my-roles.yaml
kubectl apply -f my-roles.yaml

# Verify roles were created
kubectl get roles
kubectl describe role user1-pod-reader
kubectl describe role user1-pod-manager
kubectl describe role user1-namespace-admin
```

### Step 4: Create RoleBindings
Bind service accounts to roles:

```bash
# Create role bindings
sed 's/userX/user1/g' role-bindings.yaml > my-role-bindings.yaml
kubectl apply -f my-role-bindings.yaml

# Verify role bindings
kubectl get rolebindings
kubectl describe rolebinding user1-read-pods
kubectl describe rolebinding user1-manage-pods
kubectl describe rolebinding user1-admin-namespace
```

### Step 5: Deploy Applications with Service Accounts
Deploy applications using the created service accounts:

```bash
# Deploy application with reader service account
sed 's/userX/user1/g' app-with-reader-sa.yaml > my-app-with-reader-sa.yaml
kubectl apply -f my-app-with-reader-sa.yaml

# Deploy application with manager service account
sed 's/userX/user1/g' app-with-manager-sa.yaml > my-app-with-manager-sa.yaml
kubectl apply -f my-app-with-manager-sa.yaml

# Deploy application with admin service account
sed 's/userX/user1/g' app-with-admin-sa.yaml > my-app-with-admin-sa.yaml
kubectl apply -f my-app-with-admin-sa.yaml

# Verify deployments
kubectl get deployments
kubectl get pods
```

### Step 6: Test Service Account Permissions
Test what each service account can do:

```bash
# Test reader service account permissions
kubectl exec deployment/user1-reader-app -- sh -c '
echo "Testing reader permissions..."
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Should work - reading pods
curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods

echo "Reader test completed"
'

# Test manager service account permissions
kubectl exec deployment/user1-manager-app -- sh -c '
echo "Testing manager permissions..."
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Should work - reading pods
curl -s -H "Authorization: Bearer $TOKEN" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods

echo "Manager test completed"
'
```

### Step 7: Test Permission Failures
Verify that restrictions work as expected:

```bash
# Create test pod to verify permissions
sed 's/userX/user1/g' rbac-test-pod.yaml > my-rbac-test-pod.yaml
kubectl apply -f my-rbac-test-pod.yaml

# Test unauthorized access (should fail)
kubectl exec user1-rbac-test -- sh -c '
echo "Testing unauthorized access..."
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# This should fail - no permissions to read pods
curl -s -H "Authorization: Bearer $TOKEN" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  https://kubernetes.default.svc/api/v1/namespaces/user1-namespace/pods
'
```

### Step 8: Create ClusterRole for Cross-Namespace Access
Create cluster-wide permissions:

```bash
# Create cluster role and binding (requires cluster admin)
sed 's/userX/user1/g' cluster-rbac.yaml > my-cluster-rbac.yaml
kubectl apply -f my-cluster-rbac.yaml

# Verify cluster role
kubectl get clusterrole user1-cluster-reader
kubectl describe clusterrole user1-cluster-reader

# Verify cluster role binding
kubectl get clusterrolebinding user1-cluster-read-binding
kubectl describe clusterrolebinding user1-cluster-read-binding
```

### Step 9: Test kubectl Access with Service Account
Test kubectl access using service account tokens:

```bash
# Extract service account token
SA_TOKEN=$(kubectl get secret $(kubectl get serviceaccount user1-app-reader -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)

# Get cluster info
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Test kubectl with service account token
kubectl --token="$SA_TOKEN" --server="$CLUSTER_SERVER" --insecure-skip-tls-verify=true get pods

# Test operations that should fail
echo "Testing operations that should fail..."
kubectl --token="$SA_TOKEN" --server="$CLUSTER_SERVER" --insecure-skip-tls-verify=true delete pod --all || echo "Delete failed as expected"
```

### Step 10: Implement Least Privilege Access
Create a minimal permission service account:

```bash
# Create minimal permissions service account
sed 's/userX/user1/g' minimal-rbac.yaml > my-minimal-rbac.yaml
kubectl apply -f my-minimal-rbac.yaml

# Deploy app with minimal permissions
sed 's/userX/user1/g' app-minimal-permissions.yaml > my-app-minimal-permissions.yaml
kubectl apply -f my-app-minimal-permissions.yaml

# Test minimal permissions
kubectl exec deployment/user1-minimal-app -- sh -c '
echo "Testing minimal permissions..."
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

# Should only work for reading specific ConfigMaps
curl -s -H "Authorization: Bearer $TOKEN" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/configmaps/user1-app-config
'
```

### Step 11: Create Custom Roles for Specific Resources
Create roles for specific resource management:

```bash
# Create custom roles for different resources
sed 's/userX/user1/g' custom-resource-roles.yaml > my-custom-resource-roles.yaml
kubectl apply -f my-custom-resource-roles.yaml

# Verify custom roles
kubectl get roles
kubectl describe role user1-configmap-manager
kubectl describe role user1-service-manager
```

### Step 12: Test RBAC with Real Applications
Deploy applications that actually use the RBAC permissions:

```bash
# Deploy an application that reads ConfigMaps
sed 's/userX/user1/g' configmap-reader-app.yaml > my-configmap-reader-app.yaml
kubectl apply -f my-configmap-reader-app.yaml

# Create a ConfigMap for the app to read
sed 's/userX/user1/g' app-configmap.yaml > my-app-configmap.yaml
kubectl apply -f my-app-configmap.yaml

# Test the application's ability to read ConfigMaps
kubectl exec deployment/user1-configmap-reader -- curl -s http://localhost:3000/config
```

### Step 13: Audit and Monitor RBAC Usage
Monitor RBAC activity and troubleshoot issues:

```bash
# Check current permissions for a service account
kubectl auth can-i --list --as=system:serviceaccount:user1-namespace:user1-app-reader

# Test specific permissions
kubectl auth can-i get pods --as=system:serviceaccount:user1-namespace:user1-app-reader
kubectl auth can-i create pods --as=system:serviceaccount:user1-namespace:user1-app-reader
kubectl auth can-i delete pods --as=system:serviceaccount:user1-namespace:user1-app-reader

# Check what a service account can do in current namespace
kubectl auth can-i --list --as=system:serviceaccount:user1-namespace:user1-app-manager
```

### Step 14: Troubleshoot RBAC Issues
Practice identifying and fixing RBAC problems:

```bash
# Deploy application with missing permissions
sed 's/userX/user1/g' broken-rbac-app.yaml > my-broken-rbac-app.yaml
kubectl apply -f my-broken-rbac-app.yaml

# Check why the application might fail
kubectl logs deployment/user1-broken-app
kubectl describe pod $(kubectl get pods -l app=broken-app -o jsonpath='{.items[0].metadata.name}')

# Fix the RBAC issue
sed 's/userX/user1/g' fix-rbac.yaml > my-fix-rbac.yaml
kubectl apply -f my-fix-rbac.yaml

# Verify the fix
kubectl logs deployment/user1-broken-app
```

### Step 15: Clean Up Service Accounts and Roles
Practice proper RBAC cleanup:

```bash
# List all RBAC resources in namespace
kubectl get serviceaccounts
kubectl get roles
kubectl get rolebindings

# Check cluster-wide resources (if you have permissions)
kubectl get clusterroles | grep user1
kubectl get clusterrolebindings | grep user1

# Clean up specific resources
kubectl delete rolebinding user1-read-pods
kubectl delete role user1-pod-reader
kubectl delete serviceaccount user1-app-reader
```

## Verification Steps

### Verify Your RBAC Implementation
Run these commands to verify everything is working:

```bash
# 1. Check all service accounts are created
kubectl get serviceaccounts

# 2. Verify roles have correct permissions
kubectl get roles
kubectl describe role user1-pod-manager

# 3. Check role bindings are correct
kubectl get rolebindings
kubectl describe rolebinding user1-manage-pods

# 4. Test service account permissions
kubectl auth can-i get pods --as=system:serviceaccount:user1-namespace:user1-app-reader

# 5. Verify applications are using correct service accounts
kubectl get pods -o custom-columns=NAME:.metadata.name,SERVICE_ACCOUNT:.spec.serviceAccountName
```

## Clean Up
Remove all RBAC resources:

```bash
# Delete all deployments
kubectl delete deployment --all

# Delete all services
kubectl delete svc --all

# Delete all role bindings
kubectl delete rolebinding --all

# Delete all roles
kubectl delete role --all

# Delete service accounts (except default)
kubectl delete serviceaccount --all --field-selector metadata.name!=default

# Delete cluster roles and bindings (if you have permissions)
kubectl delete clusterrolebinding user1-cluster-read-binding
kubectl delete clusterrole user1-cluster-reader
```

## Troubleshooting

### Common Issues
1. **Permission denied errors**: Check role permissions and bindings
2. **Service account not found**: Verify service account creation
3. **Token not working**: Check service account token extraction
4. **Cross-namespace access fails**: Use ClusterRole instead of Role

### Useful Commands
```bash
# Debug RBAC permissions
kubectl auth can-i <verb> <resource> --as=<user/serviceaccount>
kubectl describe role <role-name>
kubectl describe rolebinding <binding-name>

# Check service account details
kubectl get serviceaccount <sa-name> -o yaml
kubectl describe secret <sa-token-secret>

# View RBAC audit logs (if enabled)
kubectl get events --field-selector reason=Forbidden
```

## Key Concepts Learned
- **Service Accounts**: Application identities in Kubernetes
- **Roles**: Sets of permissions for resources
- **RoleBindings**: Connecting service accounts/users to roles
- **ClusterRoles**: Cluster-wide permissions
- **Least Privilege**: Granting minimal necessary permissions
- **Permission Testing**: Verifying RBAC configurations
- **RBAC Troubleshooting**: Identifying and fixing permission issues
- **API Server Authentication**: How service accounts authenticate to the API

## Next Steps
In the next lab, you'll learn about network security and policies to control traffic flow between pods and services in your EKS cluster.

---

**Remember**: Always follow the principle of least privilege when implementing RBAC in production environments!