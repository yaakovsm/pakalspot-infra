variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for photos"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the backend service account"
  type        = string
  default     = "pakalspot-dev"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
  default     = "pakalspot-backend"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

