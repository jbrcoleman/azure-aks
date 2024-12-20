resource "azurerm_resource_group" "main" {
  name     = "kubernetes-autoscaling-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "autoscaling-aks-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "autoscalek8s"
  oidc_issuer_enabled = true

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    //type       = "VirtualMachineScaleSets"
    //auto_scaling_enabled = true
    //min_count  = 1
    //max_count  = 5
  }

  identity {
    type = "SystemAssigned"
  }
}

# First, create an Azure User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "karpenter" {
  name                = "karpenter-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
}

# Create Azure AD application for Workload Identity
resource "azuread_application" "karpenter" {
  display_name = "karpenter-workload-identity"
}

# Create Service Principal for the application
resource "azuread_service_principal" "karpenter" {
  client_id = azuread_application.karpenter.client_id
}

# Create federated identity credential
resource "azuread_application_federated_identity_credential" "karpenter" {
  application_id = azuread_application.karpenter.id
  display_name   = "karpenter-federated-credential"
  description    = "Federated credential for Karpenter"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject        = "system:serviceaccount:karpenter:karpenter"
}

# Assign required Azure roles to the managed identity
resource "azurerm_role_assignment" "karpenter_vm_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_user_assigned_identity.karpenter.principal_id
}

# # Install Karpenter Helm chart
# resource "helm_release" "karpenter" {
#   name       = "karpenter"
#   repository = "https://charts.karpenter.sh"
#   namespace  = "karpenter"
#   chart      = "karpenter"
#   version    = "0.16.3"
#   create_namespace = true

#   set {
#     name  = "serviceAccount.annotations.azure\\.workload\\.identity/client-id"
#     value = azuread_application.karpenter.client_id
#   }

#   set {
#     name  = "serviceAccount.annotations.azure\\.workload\\.identity/tenant-id"
#     value = data.azurerm_client_config.current.tenant_id
#   }

#   set {
#     name  = "settings.clusterName"
#     value = "autoscaling-aks-cluster"
#   }

#   set {
#     name  = "settings.clusterEndpoint"
#     value = azurerm_kubernetes_cluster.main.kube_config.0.host
#   }
# }

# Install Prometheus Helm chart
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "prometheus"
  version    = "67.4.0"
  create_namespace = true

  values =[file("${path.module}/kubernetes/prometheus-grafana.yaml")]

}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

# Install Istio base
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  timeout = 120
  cleanup_on_fail = true
  force_update    = true
  
  depends_on = [kubernetes_namespace.istio_system]
}

# Install Istio discovery (istiod)
resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  timeout = 120
  cleanup_on_fail = true
  force_update    = true

  set {
    name  = "pilot.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "pilot.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "pilot.resources.limits.memory"
    value = "2048Mi"
  }

  set {
    name  = "pilot.resources.limits.cpu"
    value = "1000m"
  }

  depends_on = [helm_release.istio_base]
}

# Install Istio ingress gateway
resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name

  timeout = 120
  cleanup_on_fail = true
  force_update    = true

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.limits.memory"
    value = "1024Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "2000m"
  }

  depends_on = [helm_release.istiod]
}

