# ============================================================================
# Lean AWS Architecture Outputs
# ============================================================================

# RDS Outputs

output "db_instance_endpoint" {
  description = "RDS endpoint for the backend"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = module.rds.db_instance_identifier
}

# S3 Bucket Outputs
output "frontend_s3_bucket_name" {
  description = "S3 bucket name for frontend static site"
  value       = module.s3_frontend.bucket_name
}

output "frontend_s3_bucket_arn" {
  description = "S3 bucket ARN for frontend static site"
  value       = module.s3_frontend.bucket_arn
}

output "photos_s3_bucket_name" {
  description = "S3 bucket name for photos"
  value       = module.s3_photos.bucket_name
}

output "photos_s3_bucket_arn" {
  description = "S3 bucket ARN for photos"
  value       = module.s3_photos.bucket_arn
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront_frontend.distribution_id
}

output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL (HTTPS)"
  value       = module.cloudfront_frontend.distribution_url
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront_frontend.distribution_domain_name
}

# App Runner Outputs
output "app_runner_service_url" {
  description = "App Runner service URL"
  value       = module.app_runner.service_url
}

output "app_runner_service_arn" {
  description = "App Runner service ARN"
  value       = module.app_runner.service_arn
}

output "app_runner_service_id" {
  description = "App Runner service ID"
  value       = module.app_runner.service_id
}

output "app_runner_iam_role_arn" {
  description = "App Runner IAM role ARN (for instance access to AWS resources)"
  value       = module.app_runner.instance_role_arn
}

# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnets
}

# RDS Outputs (backward compatibility)
output "rds_endpoint" {
  description = "RDS endpoint (alias for db_instance_endpoint)"
  value       = module.rds.db_instance_endpoint
}

# Secrets Manager Output
output "database_url_secret_arn" {
  description = "ARN of the Secrets Manager secret containing app configuration (uses existing /pakalspot/backend secret)"
  value       = data.aws_secretsmanager_secret.app_config.arn
}

# Route53 Outputs
output "route53_record_fqdn" {
  description = "Fully qualified domain name of the Route53 record"
  value       = module.route53_cloudfront.route53_record_fqdn
}

# ACM Certificate Output
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate used for CloudFront"
  value       = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
}
