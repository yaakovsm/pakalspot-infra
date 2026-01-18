# Data source to find ALB by exact name (if provided)
data "aws_lb" "alb_by_name" {
  count = var.enable_route53_record && var.alb_name != "" && var.alb_arn == "" ? 1 : 0
  name  = var.alb_name
}

# Data source to find ALB by tags
# Kubernetes ALB controller tags ALBs with elbv2.k8s.aws/cluster tag
data "aws_lbs" "alb_list" {
  count = var.enable_route53_record && var.alb_arn == "" && var.alb_name == "" ? 1 : 0
  tags = {
    "elbv2.k8s.aws/cluster" = var.cluster_name
  }
}

# Data source to get ALB by ARN (if provided directly)
data "aws_lb" "alb_by_arn" {
  count = var.enable_route53_record && var.alb_arn != "" ? 1 : 0
  arn   = var.alb_arn
}

# Filter to find the ALB that matches our criteria
# If alb_name is provided, use it directly. Otherwise, find ALB by tags.
locals {
  # Convert set of ARNs to list and get first one
  # data.aws_lbs returns a set, so we need to convert to list to index
  alb_arns_list = var.enable_route53_record && var.alb_arn == "" && var.alb_name == "" && length(data.aws_lbs.alb_list) > 0 ? tolist(data.aws_lbs.alb_list[0].arns) : []

  # Determine ALB ARN based on provided inputs
  alb_arn = var.enable_route53_record ? (
    var.alb_arn != "" ? var.alb_arn : (
      var.alb_name != "" ? try(data.aws_lb.alb_by_name[0].arn, null) : (
        length(local.alb_arns_list) > 0 ? local.alb_arns_list[0] : null
      )
    )
  ) : null

  # Get ALB data from the appropriate data source
  # Priority: alb_arn > alb_name > tag lookup
  alb_data = var.enable_route53_record ? (
    var.alb_arn != "" && length(data.aws_lb.alb_by_arn) > 0 ? data.aws_lb.alb_by_arn[0] : (
      var.alb_name != "" && length(data.aws_lb.alb_by_name) > 0 ? data.aws_lb.alb_by_name[0] : (
        length(data.aws_lb.alb_by_arn_from_tags) > 0 && length(local.alb_arns_list) > 0 ? try(data.aws_lb.alb_by_arn_from_tags["main"], null) : null
      )
    )
  ) : null

  # Determine if we have valid ALB data
  has_alb_data = local.alb_data != null
}

# Data source to get ALB by ARN from tag lookup
# Use for_each with a static key to avoid computed key issues
# The ARN value is computed, but the key is static, which Terraform allows
# Note: If alb_arns_list is empty, try() will return empty string and data source may fail
# This is acceptable - the Route53 record won't be created if ALB doesn't exist yet
# User can apply in stages: first create ALB via ingress, then apply Route53 module
data "aws_lb" "alb_by_arn_from_tags" {
  for_each = var.enable_route53_record && var.alb_arn == "" && var.alb_name == "" ? toset(["main"]) : toset([])
  arn      = try(local.alb_arns_list[0], "")
}

# Route 53 record pointing to ALB
# Note: This resource requires ALB to exist
# Use static for_each key to allow planning, but apply will fail if ALB doesn't exist (expected)
# Solution: Apply in stages - first create infrastructure + deploy app (creates ALB), then apply again
resource "aws_route53_record" "main" {
  for_each = var.enable_route53_record ? { "main" = true } : {}
  zone_id  = var.hosted_zone_id
  name     = var.domain_name
  type     = "A"

  # Alias block is required for A records pointing to ALB
  # Use try() to handle missing ALB data gracefully - will fail during apply if ALB doesn't exist
  # This is expected behavior - user should create ALB first, then apply Route53
  alias {
    name                   = try(local.alb_data.dns_name, "")
    zone_id                = try(local.alb_data.zone_id, "")
    evaluate_target_health = true
  }
}
