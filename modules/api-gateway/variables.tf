variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "pakalspot-api"
}

variable "nlb_arn" {
  description = "ARN of the NLB created by Kubernetes service (can be empty initially, use data source)"
  type        = string
  default     = ""
}

variable "nlb_name" {
  description = "Name of the NLB to look up (if nlb_arn is not provided)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for VPC Link"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for VPC Link (private subnets)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for VPC Link"
  type        = list(string)
  default     = []
}

variable "stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

