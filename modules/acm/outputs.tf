output "certificate_arn" {
  description = "The ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.pakalspot.certificate_arn
}

output "certificate_domain" {
  description = "The primary domain name of the certificate"
  value       = aws_acm_certificate.pakalspot.domain_name
}

output "certificate_status" {
  description = "The status of the certificate"
  value       = aws_acm_certificate.pakalspot.status
}

