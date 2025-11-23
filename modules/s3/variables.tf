variable "s3_bucket_name" {
    description = "The name of the S3 bucket"
    type = string
}
variable "cors_allowed_origins" {
    description = "Allowed origins for CORS (use specific domains in production)"
    type = list(string)
    default = ["*"]
}
variable "common_tags" {
    description = "Common tags"
    type = map(string)
    default = {}
}