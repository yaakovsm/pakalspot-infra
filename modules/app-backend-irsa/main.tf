# IAM Policy Document for Backend App S3 Access
data "aws_iam_policy_document" "backend_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${var.s3_bucket_arn}/photos/*"
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
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["photos/*"]
    }
  }
}

# IAM Policy
resource "aws_iam_policy" "backend_s3" {
  name        = "pakalspot-backend-s3-policy"
  description = "Policy for PakalSpot backend to access S3 photos bucket"
  policy      = data.aws_iam_policy_document.backend_s3.json

  tags = var.common_tags
}

# IAM Role for Service Account (IRSA)
module "backend_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "pakalspot-backend-s3"

  role_policy_arns = {
    policy = aws_iam_policy.backend_s3.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.namespace}:${var.service_account_name}"]
    }
  }

  tags = var.common_tags
}

# Output the IAM role ARN
output "backend_role_arn" {
  description = "IAM role ARN for PakalSpot backend service account"
  value       = module.backend_irsa.iam_role_arn
}

