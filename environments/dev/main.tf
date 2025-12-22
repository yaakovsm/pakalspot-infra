# ============================================================================
# Lean AWS Architecture - Dev Environment
# ============================================================================
# This configuration provisions a lean, cost-effective AWS architecture
# suitable for MVP deployment without EKS/Kubernetes.
# 
# Architecture:
# - VPC with public/private/database subnets
# - RDS PostgreSQL (Single-AZ)
# - S3 buckets: frontend (static site) + photos (public with versioning)
# - App Runner for backend service
# - CloudFront for frontend CDN
#
# Note: EKS/Kubernetes configuration is preserved in the k8sfinal branch.
# ============================================================================

# ============================================================================
# Networking
# ============================================================================
module "networking" {
  source             = "../../modules/network"
  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  database_subnets   = var.database_subnets
  enable_nat_gateway = var.enable_nat_gateway
  cluster_name       = "" # Empty for lean architecture (no K8s tags)
  common_tags        = var.common_tags
}
# ============================================================================
# App Runner VPC Connector Security Group
# ============================================================================
resource "aws_security_group" "apprunner_vpc_connector" {
  name        = "${var.app_runner_service_name}-vpc-connector-sg"
  description = "SG for App Runner VPC connector (egress + allow DB access via RDS SG rule)"
  vpc_id      = module.networking.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.app_runner_service_name}-vpc-connector-sg"
  })
}

# ============================================================================
# S3 Buckets
# ============================================================================

# Frontend S3 bucket for static site hosting
module "s3_frontend" {
  source                   = "../../modules/s3"
  s3_bucket_name           = var.frontend_s3_bucket_name
  backend_s3_principal_arn = null  # Frontend bucket doesn't need backend access
  create_bucket_policy     = false # CloudFront OAI will handle access via CloudFront module
  common_tags              = var.common_tags
}

# Photos S3 bucket (public read, backend write via IAM)
module "s3_photos" {
  source                   = "../../modules/s3"
  s3_bucket_name           = var.photos_s3_bucket_name
  backend_s3_principal_arn = null # App Runner IAM role handles S3 access via IAM policy
  create_bucket_policy     = true # Keep public read policy
  common_tags              = var.common_tags
}
data "aws_s3_bucket" "init_photos" {
  bucket = "pakalspot-init-photos"
}

# ============================================================================
# RDS PostgreSQL Database
# ============================================================================
module "rds" {
  source                     = "../../modules/rds"
  db_name                    = var.db_name
  family                     = var.db_family
  db_username                = var.db_username
  instance_class             = var.db_instance_class
  allocated_storage          = var.allocated_storage
  max_allocated_storage      = var.max_allocated_storage
  backup_retention_period    = var.backup_retention_period
  skip_final_snapshot        = var.skip_final_snapshot
  deletion_protection        = var.deletion_protection
  multi_az                   = var.multi_az
  parameters                 = var.parameters
  options                    = var.options
  allowed_security_group_ids = [aws_security_group.apprunner_vpc_connector.id]
  vpc_id                     = module.networking.vpc_id
  vpc_cidr                   = module.networking.vpc_cidr_block
  database_subnet_group_name = module.networking.database_subnet_group_name
  common_tags                = var.common_tags

  depends_on = [
    module.networking,
  ]
}

# ============================================================================
# Secrets Manager
# ============================================================================
# Use existing secret at /pakalspot/backend (created/managed separately)
# This secret contains: DB_URL, JWT_SECRET, S3_BUCKET, AWS_REGION, S3_ACCESS_KEY, S3_SECRET_KEY, SECRET_KEY
data "aws_secretsmanager_secret" "app_config" {
  name = "/pakalspot/backend"
}

# ============================================================================
# App Runner Service
# ============================================================================
module "app_runner" {
  source = "../../modules/app-runner"

  app_runner_service_name          = var.app_runner_service_name
  ecr_repository_url               = var.ecr_repository_url
  app_runner_cpu                   = var.app_runner_cpu
  app_runner_memory                = var.app_runner_memory
  app_runner_min_instances         = var.app_runner_min_instances
  app_runner_max_instances         = var.app_runner_max_instances
  app_runner_port                  = var.app_runner_port
  health_check_path                = "/health"
  health_check_healthy_threshold   = 1
  health_check_unhealthy_threshold = 5
  health_check_interval            = 10
  health_check_timeout             = 5
  auto_deployments_enabled         = false

  vpc_id                     = module.networking.vpc_id
  private_subnets            = module.networking.private_subnets
  secrets_manager_secret_arn = data.aws_secretsmanager_secret.app_config.arn
  s3_bucket_arn              = module.s3_photos.bucket_arn
  db_host                    = module.rds.db_instance_address
  db_name                    = var.db_name
  db_user                    = var.db_username

  rds_master_secret_arn           = module.rds.db_instance_master_user_secret_arn
  vpc_connector_security_group_id = aws_security_group.apprunner_vpc_connector.id
  common_tags                     = var.common_tags

  depends_on = [
    module.networking,
    module.s3_photos,
    data.aws_secretsmanager_secret.app_config
  ]
}


# ============================================================================
# CloudFront Distribution for Frontend
# ============================================================================
module "cloudfront_frontend" {
  source = "../../modules/cloudfront-frontend"

  s3_bucket_name                 = module.s3_frontend.bucket_name
  s3_bucket_id                   = module.s3_frontend.bucket_id
  s3_bucket_arn                  = module.s3_frontend.bucket_arn
  s3_bucket_regional_domain_name = module.s3_frontend.bucket_regional_domain_name

  init_photos_bucket_name                 = data.aws_s3_bucket.init_photos.bucket
  init_photos_bucket_id                   = data.aws_s3_bucket.init_photos.id
  init_photos_bucket_arn                  = data.aws_s3_bucket.init_photos.arn
  init_photos_bucket_regional_domain_name = data.aws_s3_bucket.init_photos.bucket_regional_domain_name


  cloudfront_comment     = var.cloudfront_comment
  cloudfront_price_class = var.cloudfront_price_class
  default_root_object    = "index.html"
  min_ttl                = 0
  default_ttl            = 3600
  max_ttl                = 86400
  is_ipv6_enabled        = true

  # Custom domain configuration
  aliases             = length(var.cloudfront_aliases) > 0 ? var.cloudfront_aliases : []
  acm_certificate_arn = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null

  # API proxy configuration
  app_runner_service_url = module.app_runner.service_url
  enable_api_proxy       = true

  common_tags = var.common_tags

  depends_on = [module.s3_frontend, module.app_runner]
}

# ============================================================================
# Route53 Record for CloudFront Distribution
# ============================================================================
# Updates existing Route53 A record to point to CloudFront distribution
module "route53_cloudfront" {
  source = "../../modules/route53-cloudfront"

  hosted_zone_id                         = var.route53_hosted_zone_id
  domain_name                            = var.route53_domain_name
  cloudfront_distribution_domain_name    = module.cloudfront_frontend.distribution_domain_name
  cloudfront_distribution_hosted_zone_id = "Z2FDTNDATAQYW2"
  enable_route53_record                  = var.enable_route53_record

  common_tags = var.common_tags

  depends_on = [module.cloudfront_frontend]
}

# ============================================================================
# Seed Invoker Lambda
# ============================================================================
# Lambda function that performs one-time seeding of the backend via CloudFront
module "seed_invoker" {
  source = "../../modules/seed-invoker"

  cloudfront_domain = var.cloudfront_domain
  backend_base_url  = module.app_runner.service_url
  aws_region        = var.aws_region
  common_tags       = var.common_tags

  depends_on = [
    module.cloudfront_frontend,
    module.app_runner
  ]
}
