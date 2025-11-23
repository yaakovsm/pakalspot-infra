
resource "helm_release" "prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "79.1.0"

  namespace        = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values.yaml")
  ]

  wait = true
  timeout = 600
}

resource "null_resource" "cleanup_pvcs" {
  triggers = {
    release_name = helm_release.prometheus_stack.name
    namespace    = helm_release.prometheus_stack.namespace
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl delete pvc -n ${self.triggers.namespace} --all --ignore-not-found=true || true
    EOT
  }

  depends_on = [helm_release.prometheus_stack]
}


# ClusterSecretStore for monitoring - allows cross-namespace ServiceAccount reference
# Using unique name to avoid conflicts with interview app's aws-secretstore ClusterSecretStore
resource "kubectl_manifest" "monitoring_secretstore" {
  yaml_body = <<-YAML
    apiVersion: external-secrets.io/v1beta1
    kind: ClusterSecretStore
    metadata:
      name: aws-secretstore-monitoring
    spec:
      provider:
        aws:
          service: SecretsManager
          region: ${var.aws_region}
          auth:
            jwt:
              serviceAccountRef:
                name: external-secrets
                namespace: external-secrets
  YAML

  depends_on = [helm_release.prometheus_stack]
  wait = true
  server_side_apply = false
}

# ExternalSecret to pull Gmail password
resource "kubectl_manifest" "gmail_secret" {
  yaml_body = <<-YAML
    apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    metadata:
      name: gmail-auth
      namespace: monitoring
    spec:
      refreshInterval: 1h
      secretStoreRef:
        name: aws-secretstore-monitoring
        kind: ClusterSecretStore
      target:
        name: gmail-auth
        creationPolicy: Owner
      data:
      - secretKey: password
        remoteRef:
          key: monitoring-gmail-auth
          property: password
  YAML

  depends_on = [kubectl_manifest.monitoring_secretstore]
  wait = true
  server_side_apply = false
}

# PrometheusRule
resource "kubectl_manifest" "alert_rules" {
  yaml_body = file("${path.module}/alert-rules.yaml")
  
  depends_on = [
    helm_release.prometheus_stack  # Only needs Helm release - CRDs come from it
  ]
  
  wait = true
  server_side_apply = false
}

# AlertmanagerConfig
resource "kubectl_manifest" "alertmanager_config" {
  yaml_body = file("${path.module}/alertmanager-config.yaml")
  
  depends_on = [
    helm_release.prometheus_stack,
    kubectl_manifest.gmail_secret,
    kubectl_manifest.alert_rules
  ]
  
  wait = true
  server_side_apply = false
}

# Grafana Dashboard ConfigMap
# The Grafana sidecar will automatically discover and load this dashboard
resource "kubernetes_config_map" "grafana_dashboard" {
  metadata {
    name      = "pakalspot-dashboard"
    namespace = "monitoring"
    
    labels = {
      grafana_dashboard = "1"
    }
    
    annotations = {
      grafana_folder = "pakalspot"
    }
  }

  data = {
    "pakalspot-dashboard.json" = file("${path.module}/dashboard.json")
  }

  depends_on = [helm_release.prometheus_stack]
}