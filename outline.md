# 3-Day Amazon EKS Training Outline

## Day 1: Foundations and Basic Operations

### Module 1: Kubernetes and EKS Fundamentals
- What is Kubernetes? Core concepts and architecture
- Understanding clusters, master nodes, and worker nodes
- Introduction to Kubernetes objects: Pods, Services, Deployments, ReplicaSets
- Namespaces for resource organization
- Amazon EKS overview and benefits of managed Kubernetes

### Lab 1: Exploring the Shared EKS Cluster
- Connect to the shared EKS cluster using kubectl
- Explore existing cluster components and namespaces
- Create your personal namespace for isolation
- Verify cluster access and basic kubectl commands

### Lab 2: Working with Pods and Basic Objects
- Create your first Pod in your namespace
- Explore Pod lifecycle and states
- View Pod logs and execute commands inside containers
- Create and manage basic Kubernetes objects

### Lab 3: Services and Application Exposure
- Create different Service types (ClusterIP, NodePort, LoadBalancer)
- Test service connectivity between Pods
- Understand service discovery and DNS resolution
- Practice service troubleshooting techniques

### Lab 4: Deployments and ReplicaSets
- Create Deployments to manage Pod replicas
- Scale applications up and down
- Perform rolling updates and rollbacks
- Monitor deployment status and history

---

## Day 2: Application Deployment and Management

### Lab 5: Deploying Microservices to EKS
- Deploy NodeJS backend API with database connectivity
- Deploy Crystal backend API with different configurations
- Create frontend application connecting to backend services
- Test end-to-end application functionality
- Scale individual microservices independently

### Module 2: Package Management with Helm
- Introduction to Helm as Kubernetes package manager
- Understanding Helm charts, templates, and values
- Working with public Helm repositories

### Lab 6: Application Deployment with Helm
- Search and explore available Helm charts
- Deploy applications using existing Helm charts
- Customize deployments using values files
- Upgrade and rollback Helm releases
- Create a simple custom Helm chart

### Lab 7: Application Health and Monitoring
- Configure Liveness Probes for automatic Pod restarts
- Set up Readiness Probes for traffic management
- Test probe behavior with intentionally broken applications
- Monitor application health through Kubernetes events
- Troubleshoot and fix unhealthy applications

### Lab 8: Autoscaling Deep Dive
- Deploy kube-ops-view for visual cluster monitoring
- Configure Horizontal Pod Autoscaler (HPA) based on CPU metrics
- Generate load to trigger autoscaling events
- Observe HPA behavior and scaling decisions
- Configure memory-based autoscaling
- Test autoscaling with different workload patterns

---

## Day 3: Security, Networking, and Advanced Operations

### Module 3: Security and Access Control
- RBAC (Role-Based Access Control) fundamentals
- Understanding users, roles, and role bindings
- AWS IAM integration with Kubernetes RBAC
- Security best practices for shared clusters

### Lab 9: Implementing RBAC
- Create service accounts for applications
- Define roles with specific permissions
- Create role bindings for users and service accounts
- Test access controls with different user contexts
- Troubleshoot permission issues

### Lab 10: Network Security and Policies
- Explore existing Security Groups configuration
- Implement Network Policies with Calico
- Create policies to allow/deny traffic between namespaces
- Test inter-Pod communication with different policies
- Implement default deny policies and selective allow rules

### Lab 11: Advanced Service Exposure
- Deploy and configure Ingress controllers
- Create Ingress rules for HTTP and HTTPS traffic
- Implement path-based and host-based routing
- Configure SSL termination at the load balancer
- Test external access to applications through different exposure methods

### Lab 12: Node Management and Workload Placement
- Use NodeSelector to assign Pods to specific nodes
- Configure Node Affinity rules for advanced placement
- Implement Anti-Affinity to spread Pods across nodes
- Test workload placement with different node configurations
- Use taints and tolerations for specialized workloads

### Lab 13: Stateful Applications
- Deploy StatefulSets for applications requiring persistent identity
- Configure persistent volumes with Amazon EBS
- Practice scaling stateful applications
- Implement backup and restore procedures for stateful data

### Lab 14: Troubleshooting and Monitoring
- Use kubectl for advanced debugging techniques
- Analyze Pod, Service, and Ingress logs
- Monitor resource usage and performance metrics
- Practice common troubleshooting scenarios
- Implement basic monitoring with built-in Kubernetes tools

### Lab 15: Advanced Deployment Patterns
- Implement blue-green deployments
- Practice canary deployments with traffic splitting
- Configure resource limits and requests
- Test Pod disruption budgets
- Clean up resources and optimize namespace usage

### Wrap-up and Next Steps
- Key concepts review and Q&A
- Production readiness checklist
- Overview of advanced topics for continued learning:
  - Spot Instances and cost optimization
  - Serverless containers with EKS Fargate
  - CI/CD integration with CodePipeline
  - Monitoring with Prometheus and Grafana
  - Service Mesh with Istio/App Mesh
  - GitOps workflows
- Resources for continued learning and certification paths

---

## Prerequisites
- Basic understanding of containerization and Docker
- AWS account access (for viewing resources)
- Familiarity with command line interface
- Basic networking concepts

## What Participants Will Learn
- Navigate and manage applications in production EKS clusters
- Deploy and scale containerized applications effectively
- Implement security best practices and access controls
- Configure networking and service exposure patterns
- Troubleshoot common EKS operational issues
- Apply autoscaling strategies and advanced deployment patterns

## Shared Cluster Environment
- Each participant will work in their own isolated namespace
- Pre-configured cluster with necessary add-ons and tools
- Shared node groups for realistic multi-tenant experience
- Pre-installed monitoring and visualization tools
- Sample applications and configurations provided

## Materials Needed
- Laptop with administrative privileges
- kubectl configured for the shared cluster
- Code editor (VS Code recommended)
- Access to provided sample applications and configurations