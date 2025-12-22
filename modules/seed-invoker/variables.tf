variable "cloudfront_domain" {
  description = "CloudFront distribution domain name (e.g., d1356pm1pxuqc3.cloudfront.net)"
  type        = string
  default     = "d1356pm1pxuqc3.cloudfront.net"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "backend_base_url" {
  description = "Base URL of the backend service (App Runner)"
  type        = string
}
