variable "s3_bucket_name" {
  description = "Name of the S3 bucket (used for origin ID)"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID of the S3 bucket (for bucket policy)"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket (for bucket policy)"
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (for CloudFront origin)"
  type        = string
}

variable "cloudfront_comment" {
  description = "Comment for CloudFront distribution"
  type        = string
}

variable "cloudfront_price_class" {
  description = "Price class for CloudFront distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "Default root object for CloudFront distribution"
  type        = string
  default     = "index.html"
}

variable "min_ttl" {
  description = "Minimum TTL for caching in seconds"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for caching in seconds"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL for caching in seconds"
  type        = number
  default     = 86400
}

variable "is_ipv6_enabled" {
  description = "Enable IPv6 for CloudFront distribution"
  type        = bool
  default     = true
}

variable "aliases" {
  description = "List of custom domain aliases (e.g., [\"pakalspot.com\", \"www.pakalspot.com\"])"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain (must be in us-east-1 for CloudFront)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}