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
variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}
variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
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
variable "backend_s3_principal_arn" {
  description = "IAM ARN (user/role) that can read/write to pakalspot-photos"
  type        = string
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

# Route 53 variables
# NOTE: Route53 A records pointing to ALB are managed manually, not by Terraform
# These variables are only used for ACM certificate DNS validation records
variable "route53_hosted_zone_id" {
  description = "The Route 53 hosted zone ID for pakalspot.com. Required for ACM certificate DNS validation. Leave empty to auto-lookup by domain name."
  type        = string
  default     = ""
}

variable "route53_domain_name" {
  description = "The domain name for ACM certificate (e.g., pakalspot.com). Also used to lookup Route53 zone if zone_id is not provided."
  type        = string
  default     = "pakalspot.com"
}

variable "enable_acm_certificate" {
  description = "Whether to create ACM certificate with DNS validation via Route53. Route53 A records must be created manually."
  type        = bool
  default     = false
}

variable "acm_subject_alternative_names" {
  description = "List of subject alternative names (SANs) for the ACM certificate (e.g., ['www.pakalspot.com']). Leave empty for just the primary domain."
  type        = list(string)
  default     = []
}