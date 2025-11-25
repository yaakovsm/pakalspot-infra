variable "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator IRSA"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "external_secrets_version" {
  description = "Version of External Secrets Operator"
  type        = string
  default     = "v0.9.20"
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
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