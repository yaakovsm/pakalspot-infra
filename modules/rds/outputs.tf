output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.db.db_instance_endpoint
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = module.db.db_instance_identifier
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.db.db_instance_arn
}

output "db_instance_port" {
  description = "The port on which the DB accepts connections"
  value       = module.db.db_instance_port
}

output "db_master_username" {
  description = "The master username for the database"
  value       = module.db.db_instance_username
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = module.db.db_instance_address
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "db_instance_master_user_secret_arn" {
  description = "ARN of the secret in AWS Secrets Manager that contains the master user password"
  value       = module.db.db_instance_master_user_secret_arn
}
