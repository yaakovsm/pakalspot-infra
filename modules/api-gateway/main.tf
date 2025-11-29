# Data source to find NLB by name (if nlb_arn is not provided)
# Kubernetes services create NLBs with predictable names: k8s-<namespace>-<svcname>-<hash>
data "aws_lb" "backend_nlb" {
  count = var.nlb_arn == "" && var.nlb_name != "" ? 1 : 0
  name  = var.nlb_name
}

# Use provided ARN or lookup result
locals {
  nlb_arn      = var.nlb_arn != "" ? var.nlb_arn : (var.nlb_name != "" && length(data.aws_lb.backend_nlb) > 0 ? data.aws_lb.backend_nlb[0].arn : "")
  nlb_dns_name = var.nlb_arn != "" ? null : (var.nlb_name != "" && length(data.aws_lb.backend_nlb) > 0 ? data.aws_lb.backend_nlb[0].dns_name : null)
  # For integration URI, we need DNS name
  # If NLB name is provided but not found yet, use a placeholder that can be updated later
  integration_uri = local.nlb_dns_name != null ? "http://${local.nlb_dns_name}" : (var.nlb_name != "" ? "http://${var.nlb_name}.elb.us-east-1.amazonaws.com" : "http://placeholder.nlb.amazonaws.com")
}

# Security group for VPC Link (if not provided)
resource "aws_security_group" "vpc_link" {
  count       = length(var.security_group_ids) == 0 ? 1 : 0
  name        = "${var.api_name}-vpc-link-sg"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.api_name}-vpc-link-sg"
    }
  )
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

# VPC Link for API Gateway
resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.api_name}-vpc-link"
  security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : [aws_security_group.vpc_link[0].id]
  subnet_ids         = var.subnet_ids

  tags = var.common_tags
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"
  description   = "API Gateway for PakalSpot application"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }

  tags = var.common_tags
}

# Integration with NLB
# Note: If NLB doesn't exist yet, integration_uri will use a placeholder
# After NLB is created, update this resource with the correct DNS name
resource "aws_apigatewayv2_integration" "backend" {
  api_id = aws_apigatewayv2_api.main.id

  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = local.integration_uri

  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.main.id
  payload_format_version = "1.0"

  # Allow updates to integration_uri when NLB is created
  lifecycle {
    ignore_changes = [integration_uri]
  }
}

# Route for /api/*
resource "aws_apigatewayv2_route" "api" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /api/{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

# Default route (optional - for health checks)
resource "aws_apigatewayv2_route" "api_root" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /api"

  target = "integrations/${aws_apigatewayv2_integration.backend.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.stage_name
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.common_tags
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 7

  tags = var.common_tags
}

