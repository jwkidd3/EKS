# Lab 5: ConfigMaps and Secrets

## Duration: 45 minutes

## Objectives
- Create ConfigMaps from files and command line
- Create different types of Secrets
- Use ConfigMaps and Secrets in pods via environment variables and volume mounts
- Update configurations and observe rolling updates
- Practice real-world configuration management scenarios

## Prerequisites
- Lab 4 completed (deployments)
- kubectl configured to use your namespace

## Instructions

### Step 1: Clean Up and Prepare
Start with a clean environment:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete configmap --all
kubectl delete secret --all

# Verify clean state
kubectl get all,configmap,secret
```

### Step 2: Create ConfigMap from Command Line
Create application configuration using kubectl:

```bash
# Create ConfigMap with application settings
kubectl create configmap user1-app-config \
  --from-literal=database_url=postgresql://db:5432/myapp \
  --from-literal=log_level=info \
  --from-literal=max_connections=100 \
  --from-literal=debug_mode=false

# Verify ConfigMap creation
kubectl get configmap user1-app-config -o yaml
kubectl describe configmap user1-app-config
```

### Step 3: Create ConfigMap from File
Create a configuration file and ConfigMap:

```bash
# Create application properties file
cat > app.properties << EOF
# Application Settings
app.name=MyKubernetesApp
app.version=1.0.0
app.port=8080
app.environment=production

# Feature Flags
feature.new_ui=true
feature.analytics=false
feature.beta_features=disabled

# Cache Settings
cache.ttl=3600
cache.max_size=1000
EOF

# Create ConfigMap from file
kubectl create configmap user1-app-props --from-file=app.properties

# View the file-based ConfigMap
kubectl get configmap user1-app-props -o yaml
```

### Step 4: Create Generic Secret
Create secrets for sensitive data:

```bash
# Create database credentials secret
kubectl create secret generic user1-db-secret \
  --from-literal=username=appuser \
  --from-literal=password=supersecretpassword \
  --from-literal=root-password=adminpassword123

# Create API keys secret
kubectl create secret generic user1-api-keys \
  --from-literal=github_token=ghp_xxxxxxxxxxxxxxxxxxxx \
  --from-literal=stripe_key=sk_test_xxxxxxxxxxxxxxxxxxxx \
  --from-literal=jwt_secret=my-super-secret-jwt-key

# Verify secrets (note: data is base64 encoded)
kubectl get secret user1-db-secret -o yaml
kubectl describe secret user1-db-secret
```

### Step 5: Create TLS Secret
Create a TLS secret for HTTPS:

```bash
# Generate a self-signed certificate (for demo purposes)
openssl req -x509 -newkey rsa:2048 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=user1-app.example.com"

# Create TLS secret
kubectl create secret tls user1-tls-secret --cert=tls.crt --key=tls.key

# View TLS secret
kubectl describe secret user1-tls-secret

# Clean up certificate files
rm tls.key tls.crt
```

### Step 6: Deploy Application Using ConfigMaps and Secrets
Create a deployment that uses both ConfigMaps and Secrets:

```bash
# Apply the web application deployment
sed 's/userX/user1/g' web-app-deployment.yaml > my-web-app-deployment.yaml
kubectl apply -f my-web-app-deployment.yaml

# Check deployment status
kubectl get deployment user1-web-app
kubectl get pods -l app=web-app

# Wait for pods to be ready
kubectl wait --for=condition=Ready pod -l app=web-app --timeout=60s
```

### Step 7: Verify Configuration Loading
Test that the application loaded the configuration correctly:

```bash
# Get pod name
POD_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')

# Check environment variables from ConfigMap
kubectl exec $POD_NAME -- env | grep -E "(DATABASE_URL|LOG_LEVEL|MAX_CONNECTIONS|DEBUG_MODE)"

# Check environment variables from Secret
kubectl exec $POD_NAME -- env | grep -E "(DB_USERNAME|DB_PASSWORD)"

# Check mounted configuration file
kubectl exec $POD_NAME -- cat /etc/config/app.properties

# Check mounted secrets
kubectl exec $POD_NAME -- ls -la /etc/secrets/
kubectl exec $POD_NAME -- cat /etc/secrets/github_token
```

### Step 8: Update Configuration and Observe Rolling Update
Modify configuration and watch Kubernetes update the application:

```bash
# Update the ConfigMap with new values
kubectl patch configmap user1-app-config --patch '{"data":{"log_level":"debug","debug_mode":"true","max_connections":"200"}}'

# Update the properties file ConfigMap
cat > new-app.properties << EOF
# Application Settings
app.name=MyKubernetesApp
app.version=2.0.0
app.port=8080
app.environment=production

# Feature Flags
feature.new_ui=true
feature.analytics=true
feature.beta_features=enabled

# Cache Settings
cache.ttl=7200
cache.max_size=2000
EOF

kubectl create configmap user1-app-props --from-file=app.properties=new-app.properties --dry-run=client -o yaml | kubectl replace -f -

# Trigger rolling update by updating deployment annotation
kubectl patch deployment user1-web-app -p '{"spec":{"template":{"metadata":{"annotations":{"configUpdate":"'$(date)'"}}}}}'

# Watch the rolling update
kubectl rollout status deployment/user1-web-app

# Verify new configuration is loaded
POD_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- env | grep -E "(LOG_LEVEL|DEBUG_MODE|MAX_CONNECTIONS)"
kubectl exec $POD_NAME -- grep "app.version" /etc/config/app.properties
```

### Step 9: ConfigMap and Secret Management
Practice common management tasks:

```bash
# View all ConfigMaps and Secrets
kubectl get configmap,secret

# Edit a ConfigMap directly
kubectl edit configmap user1-app-config

# Create a ConfigMap from multiple files
mkdir config-files
echo "upstream backend { server backend1:8080; server backend2:8080; }" > config-files/nginx.conf
echo "worker_processes auto;" > config-files/nginx-main.conf
kubectl create configmap user1-nginx-config --from-file=config-files/

# View the multi-file ConfigMap
kubectl describe configmap user1-nginx-config

# Clean up
rm -rf config-files new-app.properties app.properties
```

### Step 10: Troubleshooting Configuration Issues
Practice common troubleshooting scenarios:

```bash
# Check if pod is getting the right configuration
kubectl describe pod $POD_NAME | grep -A 10 -B 5 -E "(Environment|Mounts)"

# Check for configuration-related events
kubectl get events --field-selector involvedObject.name=$POD_NAME

# Verify ConfigMap and Secret references in deployment
kubectl describe deployment user1-web-app | grep -A 5 -B 5 -E "(ConfigMap|Secret)"

# Test configuration changes without restarting pods (for volume mounts)
kubectl exec $POD_NAME -- ls -la /etc/config/
kubectl exec $POD_NAME -- watch -n 1 cat /etc/config/app.properties
```

## Verification Steps

Run these commands to verify your setup:

```bash
# 1. Verify ConfigMaps exist and have correct data
kubectl get configmap user1-app-config user1-app-props -o name

# 2. Verify Secrets exist
kubectl get secret user1-db-secret user1-api-keys user1-tls-secret -o name

# 3. Verify deployment is using configurations
kubectl get deployment user1-web-app -o yaml | grep -E "(configMap|secret)"

# 4. Check pod is running with configurations
kubectl get pods -l app=web-app
POD_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- env | grep -c -E "(DATABASE_URL|DB_USERNAME)" || echo "Environment variables not found"
```

## Key Takeaways
- ConfigMaps store non-sensitive configuration data
- Secrets store sensitive data and are base64 encoded
- Both can be used as environment variables or mounted as files
- Updating ConfigMaps requires pod restart unless mounted as volumes
- TLS secrets have specific format requirements
- Always verify configuration is loaded correctly in your applications

## Cleanup
```bash
kubectl delete deployment user1-web-app
kubectl delete configmap user1-app-config user1-app-props user1-nginx-config
kubectl delete secret user1-db-secret user1-api-keys user1-tls-secret
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!