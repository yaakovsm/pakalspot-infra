output "route53_record_name" {
  description = "The name of the Route 53 record"
  value       = var.enable_route53_record ? aws_route53_record.main[0].name : null
}

output "route53_record_fqdn" {
  description = "The FQDN of the Route 53 record"
  value       = var.enable_route53_record ? aws_route53_record.main[0].fqdn : null
}

output "alb_dns_name" {
  description = "The DNS name of the ALB that the Route 53 record points to"
  value       = var.enable_route53_record && local.has_alb_data ? local.alb_data.dns_name : null
}

output "alb_arn" {
  description = "The ARN of the ALB that the Route 53 record points to"
  value       = local.alb_arn
}

