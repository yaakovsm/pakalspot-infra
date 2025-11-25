# VPC variables
variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
}
variable "aws_profile" {
  description = "The AWS profile to use"
  type        = string
}
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "availability_zones" {
  description = "The availability zones"
  type        = list(string)
}
variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}
variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}
variable "database_subnets" {
  type    = list(string)
  default = ["10.0.21.0/24", "10.0.22.0/24"]
}
variable "enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = true
}
variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

# EKS variables
variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "pakalspot-cluster"
}
variable "kubernetes_version" {
  description = "The version of the Kubernetes cluster"
  type        = string
  default     = "1.29"
}
variable "enable_irsa" {
  description = "Enable IRSA"
  type        = bool
  default     = true
}
variable "endpoint_public_access" {
  description = "Enable public access to the endpoint"
  type        = bool
  default     = true
}
variable "enable_cluster_creator_admin_permissions" {
  description = "Enable cluster creator admin permissions"
  type        = bool
  default     = true
}

#node group variables
variable "node_group_name" {
  description = "The name of the node group"
  type        = string
  default     = "pakalspot-node-group"
}
variable "ami_type" {
  description = "The type of the AMI"
  type        = string
  default     = "AL2_x86_64"
}
variable "instance_types" {
  description = "The instance types"
  type        = list(string)
  default     = ["t3.small"]
}
variable "min_size" {
  description = "The minimum size of the node group"
  type        = number
  default     = 2
}
variable "max_size" {
  description = "The maximum size of the node group"
  type        = number
  default     = 4
}
variable "desired_size" {
  description = "The desired size of the node group"
  type        = number
  default     = 2
}

# External Secrets Operator variables
variable "external_secrets_version" {
  description = "The version of the External Secrets Operator"
  type        = string
  default     = "v0.9.20"
}
variable "external_secrets_namespace" {
  description = "The namespace of the External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

# RDS variables
variable "db_name" {
  description = "The name of the database"
  type        = string
  default     = "pakalspot-db"
}
variable "db_family" {
  description = "The family of the database"
  type        = string
  default     = "postgres14"
}
variable "db_username" {
  description = "The username of the database"
  type        = string
  default     = "pakalspot"
}
variable "db_password" {
  description = "The password of the database"
  type        = string
  default     = "pakalspot"
}
variable "db_port" {
  description = "The port of the database"
  type        = number
  default     = 5432
}
variable "db_host" {
  description = "The host of the database"
  type        = string
  default     = "localhost"
}
variable "db_engine" {
  description = "The engine of the database"
  type        = string
  default     = "postgres"
}
variable "db_engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "14"
}
variable "db_instance_class" {
  description = "The instance class of the database"
  type        = string
  default     = "db.t3.small"
}
variable "allocated_storage" {
  description = "The allocated storage of the database"
  type        = number
  default     = 20
}
variable "max_allocated_storage" {
  description = "The maximum allocated storage of the database"
  type        = number
  default     = 100
}
variable "backup_retention_period" {
  description = "The backup retention period of the database"
  type        = number
  default     = 7
}
variable "parameters" {
  description = "The parameters of the database"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "options" {
  description = "The options of the database"
  type = list(object({
    option_name = string
    option_settings = list(object({
      name  = string
      value = string
    }))
  }))
  default = []
}
variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = true
}
variable "deletion_protection" {
  description = "Deletion protection"
  type        = bool
  default     = true
}
# S3 variables
variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "pakalspot-photos-dev"
}
# ArgoCD variables
variable "argocd_version" {
  description = "The version of the ArgoCD Helm chart"
  type        = string
  default     = "2.11.0"
}
variable "argocd_namespace" {
  description = "The namespace of the ArgoCD"
  type        = string
  default     = "argocd"
}
variable "argocd_insecure" {
  description = "The insecure mode of the ArgoCD"
  type        = bool
  default     = true
}
variable "argocd_service_type" {
  description = "The service type of the ArgoCD"
  type        = string
  default     = "LoadBalancer"
}
variable "argocd_controller_replicas" {
  description = "The number of controller replicas of the ArgoCD"
  type        = number
  default     = 1
}
# API Gateway variables
variable "enable_api_gateway" {
  description = "Enable API Gateway (requires NLB to exist first)"
  type        = bool
  default     = false
}
variable "api_gateway_nlb_name" {
  description = "Name of the NLB created by backend service (e.g., k8s-pakalspot-dev-backend-xxxxx)"
  type        = string
  default     = ""
}

variable "wait_for_helm_releases" {
  description = "Whether to wait for Helm releases to be ready (set to false for faster dev deployments)"
  type        = bool
  default     = false
}

variable "helm_timeout" {
  description = "Timeout in seconds for Helm releases (reduced for dev)"
  type        = number
  default     = 300
}

variable "wait_for_kubectl_manifests" {
  description = "Whether to wait for kubectl manifests to be ready (set to false for faster dev deployments)"
  type        = bool
  default     = false
}

variable "cluster_wait_duration" {
  description = "Duration to wait for EKS cluster to be ready before deploying Helm releases (reduced for dev)"
  type        = string
  default     = "10s"
}