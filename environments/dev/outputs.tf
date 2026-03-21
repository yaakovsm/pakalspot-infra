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
  description = "The ARN of the validated ACM certificate for pakalspot.com. Use this ARN in the ALB Ingress annotation alb.ingress.kubernetes.io/certificate-arn"
  value       = var.enable_acm_certificate && local.route53_zone_id != "" && length(module.acm) > 0 ? module.acm[0].certificate_arn : null
}