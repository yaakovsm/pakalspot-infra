output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.seed_invoker.function_name
}

output "ssm_flag_param_name" {
  description = "Name of the SSM parameter storing the seeded flag"
  value       = aws_ssm_parameter.seeded_flag.name
}

output "ssm_api_key_param_name" {
  description = "Name of the SSM parameter storing the admin seed API key (read-only data source)"
  value       = data.aws_ssm_parameter.admin_seed_api_key.name
}
