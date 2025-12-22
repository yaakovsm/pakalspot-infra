resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for CloudFront"
}

data "aws_iam_policy_document" "s3_frontend_policy" {
  statement {
    sid    = "AllowCloudFrontOAIReadFrontend"
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

data "aws_iam_policy_document" "s3_init_photos_policy" {
  statement {
    sid    = "AllowCloudFrontOAIReadInitPhotos"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.frontend.iam_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["${var.init_photos_bucket_arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "init_photos" {
  for_each = var.init_photos_bucket_id != null ? { enabled = true } : {}

  bucket = var.init_photos_bucket_id
  policy = data.aws_iam_policy_document.s3_init_photos_policy.json

  depends_on = [aws_cloudfront_origin_access_identity.frontend]
}

resource "aws_cloudfront_distribution" "frontend" {
  comment             = var.cloudfront_comment
  enabled             = true
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.cloudfront_price_class
  default_root_object = var.default_root_object

  aliases = length(var.aliases) > 0 ? var.aliases : null

  origin {
    domain_name = var.s3_bucket_regional_domain_name
    origin_id   = "S3-${var.s3_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  dynamic "origin" {
    for_each = var.init_photos_bucket_regional_domain_name != null ? [1] : []
    content {
      domain_name = var.init_photos_bucket_regional_domain_name
      origin_id   = "S3-${var.init_photos_bucket_name}"

      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
      }
    }
  }

  dynamic "origin" {
    for_each = var.enable_api_proxy && var.app_runner_service_url != null ? [1] : []
    content {
      domain_name = replace(replace(var.app_runner_service_url, "https://", ""), "/", "")
      origin_id   = "AppRunner-API"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
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

  ordered_cache_behavior {
    path_pattern     = "/photos/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.init_photos_bucket_name}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.enable_api_proxy && var.app_runner_service_url != null ? [1] : []
    content {
      path_pattern     = "/api/*"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "AppRunner-API"
      compress         = true

      forwarded_values {
        query_string = true
        headers = [
          "Origin",
          "Access-Control-Request-Method",
          "Access-Control-Request-Headers",
          "Authorization",
          "Content-Type",
          "Accept"
        ]
        cookies {
          forward = "none"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn != null ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != null ? "TLSv1.2_2021" : null
    cloudfront_default_certificate = var.acm_certificate_arn == null ? true : false
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  tags = var.common_tags
}
