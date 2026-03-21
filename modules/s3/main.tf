module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.9.0"

  bucket = var.s3_bucket_name

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  # Block all public access
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false

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

data "aws_iam_policy_document" "pakalspot_photos_bucket" {
  # Allow backend read/write access (if backend_s3_principal_arn is provided)
  dynamic "statement" {
    for_each = var.backend_s3_principal_arn != null ? [1] : []
    content {
      sid = "AllowBackendRW"

      principals {
        type        = "AWS"
        identifiers = [var.backend_s3_principal_arn]
      }

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
      ]

      resources = [
        "${module.s3_bucket.s3_bucket_arn}/*",
      ]
    }
  }

  # Allow public read-only access over HTTPS
  statement {
    sid = "AllowPublicReadOnlyOverTLS"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
}

resource "aws_s3_bucket_policy" "pakalspot_photos_bucket" {
  count  = var.create_bucket_policy ? 1 : 0
  bucket = module.s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.pakalspot_photos_bucket.json
  depends_on = [module.s3_bucket]
}
