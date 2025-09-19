# EKS Training Course - Lab Overview

## Day 1: Foundations and Basic Operations (4 Labs)

### Lab 1: Exploring the Shared EKS Cluster
- **Duration**: ~30 minutes
- **Objectives**:
  - Connect to shared EKS cluster using kubectl
  - Explore existing cluster components and namespaces
  - Create personal namespace for isolation (userX-namespace)
  - Verify cluster access and basic kubectl commands

### Lab 2: Working with Pods and Basic Objects
- **Duration**: ~45 minutes
- **Objectives**:
  - Create first Pod in personal namespace
  - Explore Pod lifecycle and states
  - View Pod logs and execute commands inside containers
  - Create and manage basic Kubernetes objects

### Lab 3: Services and Application Exposure
- **Duration**: ~45 minutes
- **Objectives**:
  - Create different Service types (ClusterIP, NodePort, LoadBalancer)
  - Test service connectivity between Pods
  - Understand service discovery and DNS resolution
  - Practice service troubleshooting techniques

### Lab 4: Deployments and ReplicaSets
- **Duration**: ~45 minutes
- **Objectives**:
  - Create Deployments to manage Pod replicas
  - Scale applications up and down
  - Perform rolling updates and rollbacks
  - Monitor deployment status and history

---

## Day 2: Application Deployment and Management (4 Labs)

### Lab 5: Deploying Microservices to EKS
- **Duration**: ~45 minutes
- **Objectives**:
  - Deploy NodeJS backend API with database connectivity
  - Deploy Crystal backend API with different configurations
  - Create frontend application connecting to backend services
  - Test end-to-end application functionality
  - Scale individual microservices independently

### Lab 6: Application Deployment with Helm
- **Duration**: ~45 minutes
- **Objectives**:
  - Search and explore available Helm charts
  - Deploy applications using existing Helm charts
  - Customize deployments using values files
  - Upgrade and rollback Helm releases
  - Create a simple custom Helm chart

### Lab 7: Application Health and Monitoring
- **Duration**: ~45 minutes
- **Objectives**:
  - Configure Liveness Probes for automatic Pod restarts
  - Set up Readiness Probes for traffic management
  - Test probe behavior with intentionally broken applications
  - Monitor application health through Kubernetes events
  - Troubleshoot and fix unhealthy applications

### Lab 8: Autoscaling Deep Dive
- **Duration**: ~45 minutes
- **Objectives**:
  - Explore pre-installed kube-ops-view for visual cluster monitoring
  - Configure Horizontal Pod Autoscaler (HPA) based on CPU metrics
  - Generate load to trigger autoscaling events
  - Observe HPA behavior and scaling decisions
  - Configure memory-based autoscaling
  - Test autoscaling with different workload patterns

---

## Day 3: Security, Networking, and Advanced Operations (5 Labs)

### Lab 9: Implementing RBAC
- **Duration**: ~45 minutes
- **Objectives**:
  - Create service accounts for applications
  - Define roles with specific permissions
  - Create role bindings for users and service accounts
  - Test access controls with different user contexts
  - Troubleshoot permission issues

### Lab 10: Network Security and Policies
- **Duration**: ~45 minutes
- **Objectives**:
  - Explore existing Security Groups configuration
  - Work with pre-installed Calico Network Policies
  - Create namespace-specific policies to allow/deny traffic
  - Test inter-Pod communication with different policies
  - Implement namespace-scoped deny policies and selective allow rules

### Lab 11: Node Management and Workload Placement
- **Duration**: ~45 minutes
- **Objectives**:
  - Use NodeSelector to assign Pods to specific nodes
  - Configure Node Affinity rules for advanced placement
  - Implement Anti-Affinity to spread Pods across nodes
  - Test workload placement with different node configurations
  - Use taints and tolerations for specialized workloads

### Lab 12: Stateful Applications
- **Duration**: ~45 minutes
- **Objectives**:
  - Deploy StatefulSets for applications requiring persistent identity
  - Use pre-configured Amazon EBS CSI driver for persistent volumes
  - Practice scaling stateful applications
  - Implement backup and restore procedures for stateful data

### Lab 13: Troubleshooting and Advanced Deployment Patterns
- **Duration**: ~45 minutes
- **Objectives**:
  - Use kubectl for advanced debugging techniques
  - Analyze Pod, Service, and Ingress logs
  - Monitor resource usage and performance metrics
  - Implement blue-green deployments
  - Practice canary deployments with traffic splitting
  - Configure resource limits and requests
  - Clean up resources and optimize namespace usage

---

## Lab Structure Notes
- All labs use personal namespaces (userX-namespace format)
- All resources prefixed with student username (userX-*)
- Pre-built YAML files provided for editing
- Shared EKS cluster environment
- Focus on practical, hands-on experience

**Total Labs**: 13 labs across 3 days
**Lab Distribution**: Day 1 (4), Day 2 (4), Day 3 (5)