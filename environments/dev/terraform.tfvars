# ============================================================================
# Lean AWS Architecture - Dev Environment Configuration
# ============================================================================
# This file contains actual values for the dev environment.
# DO NOT commit sensitive values to version control.
# ============================================================================

# AWS Configuration
aws_region  = "us-east-1"
aws_profile = "tf-user"

# VPC/Networking Configuration
vpc_name           = "pakalspot-dev"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnets   = ["10.0.21.0/24", "10.0.22.0/24"]
enable_nat_gateway = true

# RDS PostgreSQL Configuration
db_name                 = "pakalspotdb"
db_family               = "postgres14"
db_username             = "pakalspot"
db_instance_class       = "db.t3.small"
allocated_storage       = 20
max_allocated_storage   = 100
backup_retention_period = 7
skip_final_snapshot     = true
deletion_protection     = false
multi_az                = false # Single-AZ for dev (cost-effective)

# RDS Parameters (optional)
parameters = [
  {
    name  = "log_statement"
    value = "all"
  },
  {
    name  = "log_min_duration_statement"
    value = "0"
  }
]

# S3 Bucket Configuration
frontend_s3_bucket_name = "pakalspot-web-dev"
photos_s3_bucket_name   = "pakalspot-photos"

# App Runner Configuration
# ECR Image URI format: <account-id>.dkr.ecr.<region>.amazonaws.com/<repository>:<tag>
# Note: Must include the tag (e.g., :latest, :dev-bfb77c1, etc.)
ecr_repository_url       = "182399725157.dkr.ecr.us-east-1.amazonaws.com/pakalspot-backend:dev-363db3f"
app_runner_service_name  = "pakalspot-backend"
app_runner_cpu           = "0.25 vCPU"
app_runner_memory        = "0.5 GB"
app_runner_min_instances = 1
app_runner_max_instances = 5

# CloudFront Configuration
cloudfront_price_class = "PriceClass_100" # Options: PriceClass_All, PriceClass_200, PriceClass_100
cloudfront_comment     = "PakalSpot Frontend Distribution"

# Route53 and ACM Configuration
route53_hosted_zone_id = "Z0034741Q8NP4KS4CM1B"
route53_domain_name    = "pakalspot.com"
enable_route53_record  = true
acm_certificate_arn    = "arn:aws:acm:us-east-1:182399725157:certificate/20ec8b78-356a-4150-a932-82253340f753"
cloudfront_aliases     = ["pakalspot.com"]

# Common Tags
common_tags = {
  Environment = "dev"
  Terraform   = "true"
  ManagedBy   = "terraform"
  Project     = "pakalspot"
}
