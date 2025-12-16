output "route53_record_name" {
  description = "Route53 record name"
  value       = var.enable_route53_record ? aws_route53_record.cloudfront[0].name : null
}

output "route53_record_fqdn" {
  description = "Fully qualified domain name of the Route53 record"
  value       = var.enable_route53_record ? aws_route53_record.cloudfront[0].fqdn : null
}

