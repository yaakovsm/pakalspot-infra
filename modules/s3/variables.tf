variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}
variable "cors_allowed_origins" {
  description = "Allowed origins for CORS (use specific domains in production)"
  type        = list(string)
  default     = ["*"]
}

variable "backend_s3_principal_arn" {
  type        = string
  description = "IAM ARN (user/role) that can read/write to pakalspot-photos"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}