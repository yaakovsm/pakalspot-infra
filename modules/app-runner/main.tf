# ============================================================================
# Data Sources
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# IAM Roles for App Runner
# ============================================================================
# Two roles are needed:
#   1. Access role: Allows App Runner to pull images from ECR
#   2. Instance role: Allows App Runner service to access AWS resources (Secrets Manager, S3)

# Access Role - for pulling images from ECR
data "aws_iam_policy_document" "app_runner_access_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app_runner_access" {
  name               = "pakalspot-app-runner-access"
  assume_role_policy = data.aws_iam_policy_document.app_runner_access_trust.json

  tags = merge(
    var.common_tags,
    {
      Name = "pakalspot-app-runner-access"
    }
  )
}

# Policy for ECR access - Use AWS-managed policy
resource "aws_iam_role_policy_attachment" "app_runner_ecr" {
  role       = aws_iam_role.app_runner_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# Instance Role - for accessing AWS resources from the service
# Note: Instance role must be assumable by tasks.apprunner.amazonaws.com (not build.apprunner.amazonaws.com)
data "aws_iam_policy_document" "app_runner_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app_runner" {
  name               = "${var.app_runner_service_name}-role"
  assume_role_policy = data.aws_iam_policy_document.app_runner_trust.json

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_runner_service_name}-role"
    }
  )
}

# Policy for Secrets Manager access
# Use wildcard pattern to handle secret version suffixes automatically
data "aws_iam_policy_document" "app_runner_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:/pakalspot/backend-*",
      var.rds_master_secret_arn
    ]
  }
}


resource "aws_iam_policy" "app_runner_secrets" {
  name        = "${var.app_runner_service_name}-secrets"
  description = "Allow App Runner to read secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.app_runner_secrets.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "app_runner_secrets" {
  role       = aws_iam_role.app_runner.name
  policy_arn = aws_iam_policy.app_runner_secrets.arn
}

# Policy for S3 access (photos bucket + optional init seed bucket)
data "aws_iam_policy_document" "app_runner_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${var.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      var.s3_bucket_arn
    ]
  }

  dynamic "statement" {
    for_each = var.init_seed_bucket_arn != "" ? [1] : []
    content {
      sid    = "InitSeedRead"
      effect = "Allow"
      actions = [
        "s3:GetObject",
      ]
      resources = [
        "${var.init_seed_bucket_arn}/*",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.init_seed_bucket_arn != "" ? [1] : []
    content {
      sid    = "InitSeedList"
      effect = "Allow"
      actions = [
        "s3:ListBucket",
      ]
      resources = [
        var.init_seed_bucket_arn,
      ]
    }
  }
}

resource "aws_iam_policy" "app_runner_s3" {
  name        = "${var.app_runner_service_name}-s3"
  description = "Allow App Runner to access photos S3 bucket"
  policy      = data.aws_iam_policy_document.app_runner_s3.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "app_runner_s3" {
  role       = aws_iam_role.app_runner.name
  policy_arn = aws_iam_policy.app_runner_s3.arn
}

# ============================================================================
# Security Group for App Runner VPC Connector
# ============================================================================
# Note: Security group is created at environment level to avoid circular dependencies
# This module accepts an existing security group ID via var.vpc_connector_security_group_id
locals {
  # Use the provided security group ID (required, no conditional creation)
  vpc_connector_sg_id = var.vpc_connector_security_group_id
}


# ============================================================================
# App Runner VPC Connector
# ============================================================================
# Enables App Runner to access resources in VPC (e.g., RDS)
resource "aws_apprunner_vpc_connector" "app_runner" {
  vpc_connector_name = "${var.app_runner_service_name}-connector"
  subnets            = var.private_subnets
  security_groups    = [local.vpc_connector_sg_id]

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_runner_service_name}-connector"
    }
  )
}

# ============================================================================
# App Runner Auto-Scaling Configuration
# ============================================================================
resource "aws_apprunner_auto_scaling_configuration_version" "backend" {
  auto_scaling_configuration_name = "${var.app_runner_service_name}-autoscaling"

  max_concurrency = 100
  max_size        = var.app_runner_max_instances
  min_size        = var.app_runner_min_instances

  tags = var.common_tags
}

# ============================================================================
# AWS App Runner Service
# ============================================================================
# Backend service pulling Docker image from ECR
resource "aws_apprunner_service" "backend" {
  service_name = var.app_runner_service_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_access.arn
    }

    image_repository {
      image_identifier      = var.ecr_repository_url
      image_repository_type = "ECR"

      image_configuration {
        port = tostring(var.app_runner_port)
        # ENVIRONMENT=dev so Settings allows missing SECRET_KEY (see app core/settings.py).
        # App Runner requires every runtime_environment_secrets key to exist in the target
        # Secrets Manager JSON — only reference keys present in /pakalspot/backend.
        runtime_environment_variables = {
          DB_HOST            = var.db_host
          DB_NAME            = var.db_name
          DB_USER            = var.db_user
          DB_PORT            = "5432"
          INIT_SEED_BUCKET   = "pakalspot-init-photos"
          INIT_SEED_JSON_KEY = "init_spots.json"
          SEED_ENABLED       = "true"
          ENVIRONMENT        = try(var.common_tags["Environment"], "dev")
        }
        runtime_environment_secrets = {
          DB_PASSWORD = "${var.rds_master_secret_arn}:password::"
          JWT_SECRET  = "${var.secrets_manager_secret_arn}:JWT_SECRET::"
          S3_BUCKET   = "${var.secrets_manager_secret_arn}:S3_BUCKET::"
          AWS_REGION  = "${var.secrets_manager_secret_arn}:AWS_REGION::"
          ADMIN_SEED_API_KEY   = "${var.secrets_manager_secret_arn}:ADMIN_SEED_API_KEY::"
        }
      }
    }

    auto_deployments_enabled = var.auto_deployments_enabled
  }

  instance_configuration {
    cpu               = var.app_runner_cpu
    memory            = var.app_runner_memory
    instance_role_arn = aws_iam_role.app_runner.arn
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.backend.arn

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.app_runner.arn
    }
  }

  health_check_configuration {
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = "HTTP"
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }

  tags = var.common_tags
}
