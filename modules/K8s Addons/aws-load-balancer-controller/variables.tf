variable "alb_controller_version" {
  description = "Version of AWS Load Balancer Controller"
  type        = string
  default     = "1.8.1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
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