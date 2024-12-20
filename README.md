# Cloud-Native Web Application with Azure, Kubernetes, and Advanced Scaling

## Project Overview

This project demonstrates a comprehensive cloud-native application architecture leveraging Microsoft Azure, Terraform, Kubernetes (AKS), and advanced cloud-native technologies. The solution provides a scalable, secure, and monitored web application infrastructure with intelligent resource management.

### Key Technologies

- **Cloud Platform**: Microsoft Azure
- **Infrastructure as Code**: Terraform
- **Container Orchestration**: Kubernetes (AKS)
- **Autoscaling**: Karpenter and Nodepool (NAP)
- **Monitoring**: Prometheus
- **Service Mesh**: Istio
- **Visualization**: Grafana
- **Web Application**: Python Flask

## Architecture Components

### 1. Infrastructure Provisioning
- **Terraform** manages the entire cloud infrastructure
- Automates creation of Azure Kubernetes Service (AKS) cluster
- Configures network security and access controls
- Defines repeatable, version-controlled infrastructure

### 2. Kubernetes Cluster
- **AKS Cluster** with auto-scaling capabilities
- Managed Kubernetes service with system-assigned identity
- Supports dynamic node provisioning and scaling
- Configured for high availability and performance

### 3. Application Deployment
- **Containerized Web Application**
  - Python Flask-based microservice
  - Docker containerization
  - Kubernetes deployment with resource limits
- **IP-Restricted Access**
  - Network Security Group (NSG) controls ingress
  - Allows access only from specified IP addresses

### 4. Monitoring and Observability
- **Prometheus**
  - Metrics collection and monitoring
  - 15-second scrape interval
  - Persistent storage for historical data
- **Grafana**
  - Dashboarding and visualization
  - Exposes metrics in user-friendly interfaces

### 5. Autoscaling Strategy
- **Karpenter** provides intelligent node scaling
  - Automatically provisions and deprovisions nodes
  - Adjusts infrastructure based on actual workload
  - Optimizes cloud resource utilization and costs

## Prerequisites

Before getting started, ensure you have:
- Azure account with sufficient permissions
- Azure CLI installed
- Terraform CLI
- Docker
- kubectl
- Helm

## Setup and Deployment

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/azure-kubernetes-webapp.git
cd azure-kubernetes-webapp
```

### 2. Configure Azure Credentials
```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 3. Configure Terraform Variables
Edit `terraform/variables.tf`:
- Set `location` to your preferred Azure region
- Update `allowed_ip` with your specific IP address

### 4. Initialize Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Configure Kubernetes Context
```bash
az aks get-credentials \
  --resource-group kubernetes-autoscaling-rg \
  --name autoscaling-aks-cluster
```

### 6. Deploy Application and Tools
```bash
# Build and push web application container
docker build -t restricted-webapp ../webapp
docker push yourregistry.azurecr.io/restricted-webapp:latest

# Deploy Kubernetes resources
kubectl apply -f ../kubernetes/web-app-deployment.yaml

# Deploy Karpenter
walkthrough: https://learn.microsoft.com/en-gb/azure/aks/node-autoprovision?tabs=azure-cli

# Install Prometheus and Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/prometheus \
  -f ../kubernetes/prometheus-grafana-values.yaml
```

## Security Considerations

- Use Azure Key Vault for secret management
- Implement network policies
- Regularly update and rotate IP allowlists
- Enable Azure AD integration for advanced authentication

## Monitoring and Maintenance

- Check Grafana dashboards for cluster performance
- Monitor Prometheus metrics
- Set up alerts for resource constraints
- Regularly update Kubernetes and container images

## Cost Optimization

- Use Karpenter for intelligent scaling
- Set appropriate resource requests and limits
- Leverage Azure's cost management tools
- Implement auto-shutdown for non-production environments

## Troubleshooting

- Check Kubernetes events: `kubectl get events`
- View pod logs: `kubectl logs <pod-name>`
- Verify network security group rules
- Ensure container registry access

## Future Improvements

- Implement CI/CD pipelines
- Add more sophisticated health checks
- Enhance monitoring with custom dashboards
- Implement advanced authentication
