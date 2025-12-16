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
  sensitive   = true
  default     = null
}
variable "db_port" {
  description = "The port of the database"
  type        = number
  default     = 5432
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
variable "multi_az" {
  description = "Enable Multi-AZ deployment for RDS (default: false for dev)"
  type        = bool
  default     = false
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
variable "frontend_s3_bucket_name" {
  description = "The name of the S3 bucket for frontend static site"
  type        = string
}
variable "photos_s3_bucket_name" {
  description = "The name of the S3 bucket for photos"
  type        = string
  default     = "pakalspot-photos-dev"
}

# App Runner variables
variable "app_runner_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 8000
}
variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}
variable "app_runner_service_name" {
  description = "Name of the App Runner service"
  type        = string
  default     = "pakalspot-backend"
}
variable "app_runner_cpu" {
  description = "CPU allocation for App Runner service (e.g., '0.25 vCPU', '0.5 vCPU', '1 vCPU')"
  type        = string
  default     = "0.25 vCPU"
}
variable "app_runner_memory" {
  description = "Memory allocation for App Runner service (e.g., '0.5 GB', '1 GB', '2 GB')"
  type        = string
  default     = "0.5 GB"
}
variable "app_runner_min_instances" {
  description = "Minimum number of instances for App Runner auto-scaling"
  type        = number
  default     = 1
}
variable "app_runner_max_instances" {
  description = "Maximum number of instances for App Runner auto-scaling"
  type        = number
  default     = 5
}



# CloudFront variables
variable "cloudfront_price_class" {
  description = "Price class for CloudFront distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}
variable "cloudfront_comment" {
  description = "Comment for CloudFront distribution"
  type        = string
  default     = "PakalSpot Frontend Distribution"
}

# Route53 and ACM variables
variable "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID for pakalspot.com"
  type        = string
  default     = "Z0034741Q8NP4KS4CM1B"
}

variable "route53_domain_name" {
  description = "Domain name for Route53 record (e.g., pakalspot.com)"
  type        = string
  default     = "pakalspot.com"
}

variable "acm_certificate_arn" {
  description = "ARN of existing ACM certificate for pakalspot.com (must be in us-east-1 for CloudFront)"
  type        = string
  default     = "arn:aws:acm:us-east-1:182399725157:certificate/20ec8b78-356a-4150-a932-82253340f753"
}

variable "enable_route53_record" {
  description = "Enable Route53 record update to point to CloudFront"
  type        = bool
  default     = true
}

variable "cloudfront_aliases" {
  description = "List of custom domain aliases for CloudFront (e.g., [\"pakalspot.com\"])"
  type        = list(string)
  default     = ["pakalspot.com"]
}
