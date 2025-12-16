variable "app_runner_service_name" {
  description = "Name of the App Runner service"
  type        = string
  default     = "pakalspot-backend"
}

variable "ecr_repository_url" {
  description = "ECR repository URL"
  type        = string
}

variable "app_runner_cpu" {
  description = "CPU of the App Runner service"
  type        = string
  default     = "0.25 vCPU"
}

variable "app_runner_memory" {
  description = "Memory for App Runner instance"
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
  default     = 10
}

variable "app_runner_port" {
  description = "Port on which the application listens"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Path for health check endpoint"
  type        = string
  default     = "/health"
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks before considering healthy"
  type        = number
  default     = 1
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks before considering unhealthy"
  type        = number
  default     = 5
}

variable "health_check_interval" {
  description = "Interval between health checks in seconds"
  type        = number
  default     = 10
}

variable "health_check_timeout" {
  description = "Timeout for health checks in seconds"
  type        = number
  default     = 5
}

variable "auto_deployments_enabled" {
  description = "Enable automatic deployments from source"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for security group and VPC connector"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for VPC connector"
  type        = list(string)
}

variable "secrets_manager_secret_arn" {
  description = "ARN of Secrets Manager secret containing application configuration"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of S3 bucket for photos (for IAM policy)"
  type        = string
}
variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "rds_master_secret_arn" { type = string }

variable "vpc_connector_security_group_id" {
  description = "Security group ID for App Runner VPC connector (created at environment level to avoid circular dependencies)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}