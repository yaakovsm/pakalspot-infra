module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.9.0"

  bucket = var.s3_bucket_name
  
  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Enable versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption with SSE-S3
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
      bucket_key_enabled = false
    }
  }

  # CORS configuration
  cors_rule = [
    {
      allowed_methods = ["GET", "PUT", "POST", "HEAD"]
      allowed_origins = var.cors_allowed_origins
      allowed_headers = ["*"]
      expose_headers  = ["ETag", "Content-Length"]
      max_age_seconds = 3000
    }
  ]

  tags = var.common_tags
}