# ACM Certificate for pakalspot.com with DNS validation
# This module creates an ACM certificate, DNS validation records in Route53,
# and waits for certificate validation to complete.

# ACM Certificate
# Domain: pakalspot.com
# Optional SAN: www.pakalspot.com (if provided)
resource "aws_acm_certificate" "pakalspot" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Add subject alternative names if provided
  subject_alternative_names = var.subject_alternative_names

  # Certificate must be in the same region as the ALB
  # ALB is in us-east-1, so certificate is created there
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name        = "pakalspot-certificate"
      Description = "ACM certificate for ${var.domain_name}"
    }
  )
}

# Route53 DNS validation records
# ACM provides domain_validation_options with the required DNS records
# We create these records in Route53 to validate the certificate
resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.pakalspot.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [
    each.value.record,
  ]

  allow_overwrite = true
}

# Certificate Validation
# This resource waits for the certificate to be validated
# It depends on the DNS validation records being created
resource "aws_acm_certificate_validation" "pakalspot" {
  certificate_arn = aws_acm_certificate.pakalspot.arn

  validation_record_fqdns = [
    for record in aws_route53_record.certificate_validation : record.fqdn
  ]

  timeouts {
    create = "5m"
  }
}

