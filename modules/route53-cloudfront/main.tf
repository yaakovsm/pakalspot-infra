# ============================================================================
# Route53 Record for CloudFront Distribution
# ============================================================================
# Updates existing Route53 A record to point to CloudFront distribution
# Uses allow_overwrite = true to update the existing record

resource "aws_route53_record" "cloudfront" {
  count   = var.enable_route53_record ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_distribution_domain_name
    zone_id                = var.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = false
  }

  allow_overwrite = true
}

