output "service_url" {
  description = "Public HTTPS URL of the App Runner service"
  value       = aws_apprunner_service.backend.service_url
}

output "service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.backend.arn
}

output "service_id" {
  description = "ID of the App Runner service"
  value       = aws_apprunner_service.backend.id
}

output "instance_role_arn" {
  description = "ARN of the IAM instance role (needed for S3 bucket policy)"
  value       = aws_iam_role.app_runner.arn
}

output "vpc_connector_arn" {
  description = "ARN of the VPC connector"
  value       = aws_apprunner_vpc_connector.app_runner.arn
}

output "security_group_id" {
  description = "ID of the security group (needed for RDS module)"
  value       = var.vpc_connector_security_group_id
}


