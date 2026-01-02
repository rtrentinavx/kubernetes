############################################
# Generate Admin Password for Weave GitOps
############################################
resource "random_password" "weave_admin_password" {
  length  = var.weave_admin_password_length
  special = true
}

############################################
# Kubernetes Namespace for Flux
############################################
resource "kubernetes_namespace_v1" "flux_system" {
  metadata {
    name = var.flux_namespace
  }
}

############################################
# Kubernetes Namespace for Weave GitOps
############################################
resource "kubernetes_namespace_v1" "weave_gitops" {
  metadata {
    name = var.weave_namespace
  }
}

############################################
# Kubernetes Secret for GitHub Token (Flux)
############################################
resource "kubernetes_secret_v1" "flux_github_secret" {
  metadata {
    name      = "flux-system"
    namespace = kubernetes_namespace_v1.flux_system.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = base64encode("git")
    password = base64encode(var.github_token)
  }

  depends_on = [kubernetes_namespace_v1.flux_system]
}

############################################
# Kubernetes Secret for Weave GitOps Cluster User Auth
############################################
resource "kubernetes_secret_v1" "weave_cluster_user_auth" {
  metadata {
    name      = "cluster-user-auth"
    namespace = kubernetes_namespace_v1.weave_gitops.metadata[0].name
  }

  type = "Opaque"

  # Store plain values - Kubernetes will base64 encode automatically
  data = {
    username = "admin"
    password = random_password.weave_admin_password.bcrypt_hash
  }

  depends_on = [kubernetes_namespace_v1.weave_gitops]
}

############################################
# Deploy Flux v2
############################################
resource "helm_release" "flux" {
  name             = "flux2"
  namespace        = kubernetes_namespace_v1.flux_system.metadata[0].name
  repository       = "oci://ghcr.io/fluxcd-community/charts"
  chart            = "flux2"
  version          = var.flux_chart_version
  create_namespace = false
  wait             = true
  wait_for_jobs    = true
  timeout          = 900

  values = [yamlencode({
    namespace = kubernetes_namespace_v1.flux_system.metadata[0].name

    # Deploy to default node pool only (not tainted spot nodes)
    nodeSelector = {
      "cloud.google.com/gke-nodepool" = "np-default-71ce"
    }

    # Source Controller
    source-controller = {
      resources = {
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "64Mi"
        }
      }
    }

    # Kustomize Controller
    kustomize-controller = {
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
        requests = {
          cpu    = "100m"
          memory = "64Mi"
        }
      }
    }

    # Helm Controller
    helm-controller = {
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "1Gi"
        }
        requests = {
          cpu    = "100m"
          memory = "64Mi"
        }
      }
    }

    # Notification Controller
    notification-controller = {
      enabled = var.enable_notifications
      resources = {
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "64Mi"
        }
      }
    }

    # Image Controller
    image-controller = {
      enabled = false
    }

    # Image Reflector Controller
    image-reflector-controller = {
      enabled = false
    }
  })]

  depends_on = [
    kubernetes_namespace_v1.flux_system,
    kubernetes_secret_v1.flux_github_secret
  ]
}

############################################
# Deploy Weave GitOps (UI for Flux)
############################################
resource "helm_release" "weave_gitops" {
  name             = "weave-gitops"
  namespace        = kubernetes_namespace_v1.weave_gitops.metadata[0].name
  repository       = "oci://ghcr.io/weaveworks/charts"
  chart            = "weave-gitops"
  version          = var.weave_chart_version
  create_namespace = false
  wait             = true
  wait_for_jobs    = true
  timeout          = 900

  values = [yamlencode({
    namespace = kubernetes_namespace_v1.weave_gitops.metadata[0].name

    # Deploy to default node pool only (not tainted spot nodes)
    nodeSelector = {
      "cloud.google.com/gke-nodepool" = "np-default-71ce"
    }

    serviceAccount = {
      create = true
      name   = "weave-gitops"
    }

    rbac = {
      create = true
    }

    # Service configuration
    service = {
      type = "LoadBalancer"
    }

    # Expose on External Network Load Balancer (similar to ArgoCD)
    serviceAnnotations = {
      "cloud.google.com/load-balancer-type" = "Network"
    }

    # Resources
    resources = {
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "64Mi"
      }
    }

    # RBAC for reading Flux resources
    rbacVerbsOverride = {
      helm = [
        "list",
        "get",
        "watch"
      ]
      kustomizations = [
        "list",
        "get",
        "watch"
      ]
      gitrepositories = [
        "list",
        "get",
        "watch"
      ]
      helmrepositories = [
        "list",
        "get",
        "watch"
      ]
      events = [
        "list",
        "get",
        "watch"
      ]
      suspendables = [
        "list",
        "get",
        "patch",
        "update"
      ]
    }
  })]

  depends_on = [
    kubernetes_namespace_v1.weave_gitops
  ]
}

############################################
# Create LoadBalancer Service for Weave GitOps
############################################
resource "kubernetes_service_v1" "weave_gitops_lb" {
  metadata {
    name      = "weave-gitops-lb"
    namespace = kubernetes_namespace_v1.weave_gitops.metadata[0].name
  }

  spec {
    type = "LoadBalancer"

    selector = {
      "app.kubernetes.io/name" = "weave-gitops"
    }

    port {
      name        = "http"
      port        = 9001
      target_port = 9001
      protocol    = "TCP"
    }

    session_affinity = "None"
  }

  depends_on = [helm_release.weave_gitops]
}

############################################
# Wait for Flux CRDs to be installed
############################################
resource "time_sleep" "wait_for_flux_crds" {
  create_duration = "180s"
  depends_on      = [helm_release.flux]
}

# Wait for GitRepository CRD to be available
resource "time_sleep" "wait_for_git_repo_crd" {
  create_duration = "60s"
  depends_on      = [time_sleep.wait_for_flux_crds]
}

# Wait for Kustomization CRD to be available
resource "time_sleep" "wait_for_kustomization_crd" {
  create_duration = "60s"
  depends_on      = [time_sleep.wait_for_git_repo_crd]
}

############################################
# Create Flux GitRepository Source and Kustomization using kubectl
############################################
resource "null_resource" "flux_git_resources" {
  provisioner "local-exec" {
    command = <<-EOT
      sleep 30
      kubectl apply -f - <<EOF
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: ${var.github_owner}-${var.github_repo}
  namespace: ${kubernetes_namespace_v1.flux_system.metadata[0].name}
spec:
  interval: 1m
  url: https://github.com/${var.github_owner}/${var.github_repo}.git
  ref:
    branch: ${var.gitops_repo_branch}
  secretRef:
    name: flux-system
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: ${var.github_owner}-${var.github_repo}-kustomization
  namespace: ${kubernetes_namespace_v1.flux_system.metadata[0].name}
spec:
  interval: 10m
  path: ${var.gitops_repo_path}
  prune: true
  wait: true
  sourceRef:
    kind: GitRepository
    name: ${var.github_owner}-${var.github_repo}
EOF
    EOT
  }

  depends_on = [time_sleep.wait_for_kustomization_crd]
}
