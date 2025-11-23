# IAM Policy Document for External Secrets
data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:*:*:secret:/pakalspot/frontend*",
      "arn:aws:secretsmanager:*:*:secret:/pakalspot/backend*"
    ]
  }

  # ListSecrets doesn't support resource-level restrictions
  # This is required for External Secrets to discover secrets
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }
}

# IAM Policy
resource "aws_iam_policy" "external_secrets" {
  name        = "external-secrets-policy"
  description = "Policy for External Secrets Operator to access AWS Secrets Manager"
  policy      = data.aws_iam_policy_document.external_secrets.json

  tags = var.common_tags
}

# IAM Role for Service Account (IRSA)
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "external-secrets-operator"

  role_policy_arns = {
    policy = aws_iam_policy.external_secrets.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = var.common_tags
}

#Output the IAM role ARN
output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = module.external_secrets_irsa.iam_role_arn
}