# ============================================================================
# Data Sources
# ============================================================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Read existing admin seed API key from SSM (must exist, not created by Terraform)
data "aws_ssm_parameter" "admin_seed_api_key" {
  name = "/pakalspot/seed/admin_seed_api_key"
}

# ============================================================================
# SSM Parameter for Seeding Flag
# ============================================================================
resource "aws_ssm_parameter" "seeded_flag" {
  name        = "/pakalspot/seed/seeded"
  description = "Flag indicating whether the database has been seeded"
  type        = "String"
  value       = "false"

  tags = merge(
    var.common_tags,
    {
      Name = "pakalspot-seed-flag"
    }
  )
}

# ============================================================================
# Lambda Function Archive
# ============================================================================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/seed-invoker/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# ============================================================================
# IAM Role for Lambda
# ============================================================================
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "seed_invoker" {
  name               = "pakalspot-seed-invoker-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name = "pakalspot-seed-invoker-lambda-role"
    }
  )
}

# Attach basic Lambda execution role (for CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.seed_invoker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM policy for SSM access
data "aws_iam_policy_document" "lambda_ssm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      aws_ssm_parameter.seeded_flag.arn,
      data.aws_ssm_parameter.admin_seed_api_key.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:PutParameter"
    ]
    resources = [
      aws_ssm_parameter.seeded_flag.arn
    ]
  }
}

resource "aws_iam_role_policy" "lambda_ssm" {
  name   = "pakalspot-seed-invoker-ssm-policy"
  role   = aws_iam_role.seed_invoker.id
  policy = data.aws_iam_policy_document.lambda_ssm_policy.json
}

# ============================================================================
# Lambda Function
# ============================================================================
resource "aws_lambda_function" "seed_invoker" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "pakalspot-seed-invoker"
  role             = aws_iam_role.seed_invoker.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      BACKEND_BASE_URL = "https://${var.backend_base_url}"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "pakalspot-seed-invoker"
    }
  )
}

# ============================================================================
# Invoke Lambda after Apply
# ============================================================================
resource "null_resource" "invoke_seed_lambda" {
  triggers = {
    cloudfront_domain = var.cloudfront_domain
    lambda_code_hash  = aws_lambda_function.seed_invoker.source_code_hash
    ssm_flag_param    = aws_ssm_parameter.seeded_flag.id
    ssm_api_key_param = data.aws_ssm_parameter.admin_seed_api_key.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.seed_invoker.function_name} \
        --region ${var.aws_region} \
        /tmp/seed-result.json && \
      cat /tmp/seed-result.json && \
      echo ""
    EOT
  }

  depends_on = [
    aws_lambda_function.seed_invoker,
    aws_ssm_parameter.seeded_flag,
    data.aws_ssm_parameter.admin_seed_api_key
  ]
}
