output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

# Comment out for first apply - will enable after IRSA modules are uncommented
# output "backend_irsa_role_arn" {
#   description = "IAM role ARN for backend service account (for IRSA)"
#   value       = module.app-backend-irsa.backend_role_arn
# }

output "s3_bucket_name" {
  description = "S3 bucket name for photos"
  value       = module.s3.bucket_name
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "acm_pakalspot_cert_arn" {
  description = "The ARN of the ACM certificate (existing or newly created). Use this ARN in the ALB Ingress annotation alb.ingress.kubernetes.io/certificate-arn"
  value       = var.enable_acm_certificate ? local.acm_certificate_arn : null
}

output "route53_record_fqdn" {
  description = "The FQDN of the Route53 record pointing to ALB"
  value       = length(module.route53) > 0 ? module.route53[0].route53_record_fqdn : null
}

output "alb_dns_name" {
  description = "The DNS name of the ALB (for reference)"
  value       = length(module.route53) > 0 ? module.route53[0].alb_dns_name : null
}

output "node_group_name" {
  description = "The actual AWS nodegroup name (with random suffix)"
  value       = module.eks.node_group_name
}

output "route53_hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  value       = local.route53_zone_id != "" ? local.route53_zone_id : null
}

# Add alias for consistency with checklist
output "route53_alb_dns_name" {
  description = "Alias for alb_dns_name (for compatibility with verification checklist)"
  value       = length(module.route53) > 0 ? module.route53[0].alb_dns_name : null
}