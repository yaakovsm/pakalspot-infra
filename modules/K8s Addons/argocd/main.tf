# Cleanup resource - deletes ArgoCD Applications BEFORE destroying ArgoCD itself
# This ensures finalizers are removed while the controller is still running
resource "null_resource" "argocd_cleanup" {
  triggers = {
    namespace = var.argocd_namespace
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Delete all ArgoCD Applications first (while ArgoCD controller is still running)
      kubectl delete applications.argoproj.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s || true
      
      # Delete all ApplicationSets
      kubectl delete applicationsets.argoproj.io -n ${self.triggers.namespace} --all --ignore-not-found=true --timeout=60s || true
      
      # Wait a bit for finalizers to be processed
      sleep 10
    EOT
  }

  depends_on = [helm_release.argocd]
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_version

  namespace        = var.argocd_namespace
  create_namespace = true

  wait    = var.wait_for_helm
  timeout = var.helm_timeout

  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = var.argocd_insecure
        }
      }

      server = {
        service = {
          type = var.argocd_service_type
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"   = "external"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
      }

      controller = {
        replicas = var.argocd_controller_replicas
      }
    })
  ]
}
