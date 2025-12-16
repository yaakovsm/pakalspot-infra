output "bucket_id" {
  description = "Name (id) of the bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN of the bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "bucket_name" {
  description = "Name of the bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket (for CloudFront origin)"
  value       = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

