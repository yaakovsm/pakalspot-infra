variable "argocd_version" {
  description = "Version of ArgoCD"
  type        = string
  default     = "7.3.0"
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_insecure" {
  description = "Disable internal TLS for ArgoCD server"
  type        = bool
  default     = true
}

variable "argocd_service_type" {
  description = "Service type for ArgoCD server"
  type        = string
  default     = "LoadBalancer"
}

variable "argocd_controller_replicas" {
  description = "Number of ArgoCD controller replicas"
  type        = number
  default     = 1
}


variable "cluster_name" {
  description = "Name of the EKS cluster (for dependency tracking)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}