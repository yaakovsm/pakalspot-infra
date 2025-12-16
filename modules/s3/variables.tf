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
  default     = null
}
variable "create_bucket_policy" {
  type        = bool
  description = "Whether to create bucket policy (set to false if IAM policies handle access)"
  default     = true
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}