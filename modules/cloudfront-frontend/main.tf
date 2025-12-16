# ============================================================================
# CloudFront Origin Access Identity (OAI)
# ============================================================================
# OAI allows CloudFront to access private S3 bucket
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for ${var.s3_bucket_name}"
}

# ============================================================================
# S3 Bucket Policy for CloudFront OAI
# ============================================================================
# Policy document allowing CloudFront OAI to access S3 bucket
data "aws_iam_policy_document" "s3_frontend_policy" {
  statement {
    sid    = "AllowCloudFrontOAI"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.frontend.iam_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${var.s3_bucket_arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_frontend_policy.json

  depends_on = [aws_cloudfront_origin_access_identity.frontend]
}

# ============================================================================
# CloudFront Distribution
# ============================================================================
# CDN distribution for frontend static site
resource "aws_cloudfront_distribution" "frontend" {
  comment             = var.cloudfront_comment
  enabled             = true
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.cloudfront_price_class
  default_root_object = var.default_root_object

  # Custom domain aliases (if provided)
  aliases = length(var.aliases) > 0 ? var.aliases : null

  origin {
    domain_name = var.s3_bucket_regional_domain_name
    origin_id   = "S3-${var.s3_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_bucket_name}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn != null ? var.acm_certificate_arn : null
    ssl_support_method       = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version  = var.acm_certificate_arn != null ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.acm_certificate_arn == null ? true : false
  }

  tags = var.common_tags
}

