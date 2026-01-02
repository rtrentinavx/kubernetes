############################################
# Reserve Static External IP for Argo CD LB
############################################
resource "google_compute_address" "argocd_lb_ip" {
  name    = "argocd-lb-ip"
  region  = var.region
  project = var.project
}

############################################
# Kubernetes Namespace for Argo CD
############################################
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

############################################
# Argo CD via Helm with GKE External Network LB
############################################
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  wait    = true
  timeout = 600

  # Values: publish argocd-server via External Network LB, pin static IP, preserve client IP
  values = [yamlencode({
    crds = { install = true }

    server = {
      service = {
        type                  = "LoadBalancer"
        loadBalancerIP        = google_compute_address.argocd_lb_ip.address
        externalTrafficPolicy = "Local"
        annotations = {
          "cloud.google.com/load-balancer-type" = "Network"
        }
        # If you don’t need HTTP/80, set `enabled=false` for http
        ports = {
          http  = { enabled = true, port = 80 }
          https = { enabled = true, port = 443 }
        }
      }
    }

    applicationSet = { enabled = true }
  })]

  depends_on = [
    kubernetes_namespace_v1.argocd,
    google_compute_address.argocd_lb_ip
  ]
}

############################################
# Argo CD Root Application (Bootstrap)
############################################
resource "kubernetes_manifest" "argocd_root_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.root_app_name
      namespace = kubernetes_namespace_v1.argocd.metadata[0].name
      annotations = {
        "argocd.argoproj.io/sync-wave" = "0"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_revision
        path           = var.gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true",
          "RespectIgnoreDifferences=true"
        ]
      }
    }
  }

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }

  depends_on = [helm_release.argocd]
}