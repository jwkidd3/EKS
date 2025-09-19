
All projects
EKS





EKS Multi-User Cluster Configuration
Last message 2 months ago
EKS Training Lab Guide Redesign
Last message 3 months ago
EKS Course Lab Guide
Last message 3 months ago
Amazon EKS Training Presentation
Last message 3 months ago
EKS Training Outline Design
Last message 3 months ago
Instructions
Add instructions to tailor Claude’s responses

Files
1% of project capacity used

outline
82 lines

text



Labs
29 lines

text



3-Day Amazon EKS Training Outline.md
171 lines

md



content
82 lines

text



content
4.02 KB •82 lines
•
Formatting may be inconsistent from source

Kubernetes Basics
What is Kubernetes?
Open-source system for automating deployment, scaling, and management of containerized applications
Clusters consist of masters that control worker nodes
Kubernetes (k8s) Objects
Building blocks for deploying and managing applications in Kubernetes
Pods: Smallest deployable unit (typically one or more containers and shared storage)
Services: Expose applications running on Pods (e.g., LoadBalancer, NodePort, ClusterIP, ExternalName)
Deployments: Manage Pod creation and rollout (use ReplicaSets to ensure desired number of replicas)
ReplicaSets: Ensure desired number of Pod replicas are running
Namespaces: Organize Kubernetes objects (virtual clusters within a physical cluster)
Amazon EKS
Managed Kubernetes service on AWS
Simplifies deploying and managing Kubernetes clusters
Provides control plane and worker nodes
EKS Cluster Creation Workflow
Steps involved in creating an EKS cluster
What happens during cluster creation
EKS Architecture
Control Plane vs. Worker Nodes
High-level overview of communication between control plane and worker nodes
Workshop Hands-on Labs
Integrate hands-on labs throughout the modules for practical experience
Setting up EKS, managing environments and applications, configuring networking, monitoring, and security features
Deploying Microservices to EKS
Deploy NodeJS and Crystal backend APIs with sample applications
Explore Service Types (LoadBalancer, NodePort, etc.)
Scale backend and frontend services
Clean up deployed applications
Helm
Introduction to Helm (package manager for Kubernetes)
Deploy applications using Helm charts
Update chart repositories, search for charts, and install applications
Roll back deployments and clean up resources
Health Checks
Configure Liveness and Readiness Probes for Pods
Liveness Probes: Restart unhealthy Pods
Readiness Probes: Indicate Pod readiness for traffic
Autoscaling
Kube-ops-view for cluster monitoring
Configure Horizontal Pod Autoscaler (HPA) to autoscale applications based on metrics
Configure Cluster Autoscaler (CA) to autoscale worker nodes based on cluster needs
Clean up autoscaling resources
RBAC (Role-Based Access Control)
Define roles and bindings to manage Kubernetes access
Create users, map IAM users to Kubernetes users, and assign roles for access control
Clean up RBAC resources
Security Groups and Network Policies
Prerequisite: Security group creation and RDS configuration
Network Policies with Calico to control network traffic between Pods
Implement security policies (allow/deny specific traffic)
Clean up Calico resources
Exposing Services
Service types (LoadBalancer, NodePort, etc.) for exposing applications
Ingress controllers for routing external traffic to services
Clean up exposed services
Node Management
NodeSelector for assigning Pods to specific nodes
Affinity and Anti-Affinity for controlling Pod placement across nodes
Advanced Topics (Optional)
Using Spot Instances with EKS for cost-effective cluster management
Advanced VPC Networking with EKS (Secondary CIDRs)
Stateful containers using StatefulSets and Amazon EBS CSI Driver
Deploying Microservices to EKS Fargate serverless platform
Deploying Stateful Microservices with Amazon FSx or EFS
Resource Management with Metrics Server, Pod CPU/Memory Management, Resource Quotas, and Pod Priority/Preemption
CI/CD with CodePipeline
Logging with Amazon OpenSearch Service, Fluent Bit, and OpenSearch Dashboards
Monitoring with Prometheus, Grafana, and Pixie
Tracing with X-Ray
GitOps with Weave Flux or ArgoCD
Custom Resource Definitions (CRDs)
CIS EKS Benchmark Assessment with kube-bench
Open Policy Agent (OPA) for policy-based control
Patching/Upgrading EKS Clusters
Service Mesh
Introduction to Service Mesh (managing communication between microservices)
Deploy applications with Istio or AWS App Mesh for service mesh functionality
Traffic management, monitoring, and visualization of service communication
Batch Processing and Machine Learning
Batch Processing with Argo Workflows for managing long-running tasks
Machine Learning with Kubeflow for deploying and managing ML pipelines