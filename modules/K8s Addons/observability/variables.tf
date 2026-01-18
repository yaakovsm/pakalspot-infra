variable "aws_region" {
  description = "AWS region for Secrets Manager"
  type        = string
  default     = "us-east-1"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "wait_for_helm" {
  description = "Whether to wait for Helm releases to be ready"
  type        = bool
  default     = true
}

variable "helm_timeout" {
  description = "Timeout in seconds for Helm releases"
  type        = number
  default     = 600
}

variable "wait_for_kubectl" {
  description = "Whether to wait for kubectl manifests to be ready"
  type        = bool
  default     = true
}

variable "target_namespace" {
  description = "Kubernetes namespace where the application is deployed (e.g., pakalspot-dev, pakalspot-k8sfinal)"
  type        = string
  default     = "pakalspot-dev"
}