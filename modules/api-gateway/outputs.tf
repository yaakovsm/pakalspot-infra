output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.main.id
}

output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "api_gateway_stage_url" {
  description = "API Gateway stage URL"
  value       = "${aws_apigatewayv2_api.main.api_endpoint}/${aws_apigatewayv2_stage.main.name}"
}

output "vpc_link_id" {
  description = "VPC Link ID"
  value       = aws_apigatewayv2_vpc_link.main.id
}

