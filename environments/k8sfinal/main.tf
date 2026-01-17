module "networking" {
  source             = "../../modules/network"
  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  database_subnets   = var.database_subnets
  enable_nat_gateway = var.enable_nat_gateway
  cluster_name       = var.cluster_name
  common_tags        = var.common_tags
}

module "eks" {
  source                                   = "../../modules/eks"
  cluster_name                             = var.cluster_name
  kubernetes_version                       = var.kubernetes_version
  enable_irsa                              = var.enable_irsa
  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  vpc_id             = module.networking.vpc_id
  subnet_ids         = module.networking.subnet_ids
  private_subnet_ids = module.networking.private_subnets

  node_group_name = var.node_group_name
  ami_type        = var.ami_type
  instance_types  = var.instance_types
  min_size        = var.min_size
  max_size        = var.max_size
  desired_size    = var.desired_size
  capacity_type   = var.capacity_type
  disk_size       = var.disk_size

  common_tags = var.common_tags
}

# Wait for EKS cluster to be fully ready before deploying Helm releases
resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]

  create_duration = var.cluster_wait_duration
}

module "eso-irsa" {
  source            = "../../modules/eso-irsa"
  oidc_provider_arn = module.eks.oidc_provider_arn
  common_tags       = var.common_tags

  depends_on = [module.eks]
}

module "aws-load-balancer-controller" {
  source = "../../modules/K8s Addons/aws-load-balancer-controller"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  vpc_id            = module.networking.vpc_id
  common_tags       = var.common_tags

  wait_for_helm = var.wait_for_helm_releases
  helm_timeout  = var.helm_timeout

  depends_on = [module.eks, time_sleep.wait_for_cluster]
}

module "external-secrets" {
  source = "../../modules/K8s Addons/external-secrets"

  external_secrets_version   = var.external_secrets_version
  external_secrets_namespace = var.external_secrets_namespace
  external_secrets_role_arn  = module.eso-irsa.external_secrets_role_arn

  common_tags = var.common_tags

  wait_for_helm = var.wait_for_helm_releases
  helm_timeout  = var.helm_timeout

  depends_on = [module.eks, module.eso-irsa, time_sleep.wait_for_cluster, module.aws-load-balancer-controller]
}

module "rds" {
  source                  = "../../modules/rds"
  db_name                 = var.db_name
  family                  = var.db_family
  db_username             = var.db_username
  instance_class          = var.db_instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection
  parameters              = var.parameters
  options                 = var.options

  vpc_id                     = module.networking.vpc_id
  vpc_cidr                   = module.networking.vpc_cidr_block
  database_subnet_group_name = module.networking.database_subnet_group_name
  eks_security_group_id      = module.eks.cluster_security_group_id
  eks_node_security_group_id = module.eks.node_security_group_id

  common_tags = var.common_tags

  depends_on = [module.eks, module.networking]
}

module "s3" {
  source                   = "../../modules/s3"
  s3_bucket_name           = var.s3_bucket_name
  backend_s3_principal_arn = module.eks.node_group_iam_role_arn
  common_tags              = var.common_tags

  depends_on = [module.networking, module.eks]
}

data "aws_iam_policy_document" "pakalspot_photos_nodegroup" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
    ]
    resources = [
      "${module.s3.bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3.bucket_arn,
    ]
  }
}

resource "aws_iam_policy" "pakalspot_photos_nodegroup" {
  name        = "pakalspot-photos-nodegroup"
  description = "Allow nodegroup to read/write to pakalspot-photos"
  policy      = data.aws_iam_policy_document.pakalspot_photos_nodegroup.json

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "nodegroup_pakalspot_photos" {
  role       = module.eks.node_group_iam_role_name
  policy_arn = aws_iam_policy.pakalspot_photos_nodegroup.arn
}

module "app-backend-irsa" {
  source            = "../../modules/app-backend-irsa"
  oidc_provider_arn = module.eks.oidc_provider_arn
  s3_bucket_arn     = module.s3.bucket_arn

  namespace            = "pakalspot-k8sfinal"
  service_account_name = "pakalspot-backend"

  common_tags = var.common_tags

  depends_on = [module.eks, module.s3]
}

module "argocd" {
  source = "../../modules/K8s Addons/argocd"

  argocd_version             = var.argocd_version
  argocd_namespace           = var.argocd_namespace
  argocd_insecure            = var.argocd_insecure
  argocd_service_type        = var.argocd_service_type
  argocd_controller_replicas = var.argocd_controller_replicas

  cluster_name = var.cluster_name
  common_tags  = var.common_tags

  wait_for_helm = var.wait_for_helm_releases
  helm_timeout  = var.helm_timeout

  depends_on = [
    module.eks,
    module.aws-load-balancer-controller
  ]
}

module "observability" {
  source = "../../modules/K8s Addons/observability"

  aws_region  = var.aws_region
  common_tags = var.common_tags

  wait_for_helm    = var.wait_for_helm_releases
  helm_timeout     = var.helm_timeout
  wait_for_kubectl = var.wait_for_kubectl_manifests

  depends_on = [
    module.eks,
    module.external-secrets
  ]
}

module "api-gateway" {
  count  = var.enable_api_gateway ? 1 : 0
  source = "../../modules/api-gateway"

  api_name = "pakalspot-api-${var.vpc_name}"
  nlb_name = var.api_gateway_nlb_name

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnets

  stage_name  = "k8sfinal"
  common_tags = var.common_tags

  depends_on = [module.networking, module.eks]
}

# Data source to find the Route53 hosted zone for pakalspot.com
# This is used for ACM certificate DNS validation records only
# NOTE: Route53 A records pointing to ALB are managed manually, not by Terraform
data "aws_route53_zone" "pakalspot" {
  count = var.enable_acm_certificate && var.route53_hosted_zone_id == "" ? 1 : 0
  name  = var.route53_domain_name
}

# Use the provided zone ID if available, otherwise use the data source
# This is only used for ACM certificate validation records
locals {
  route53_zone_id = var.enable_acm_certificate ? (
    var.route53_hosted_zone_id != "" ? var.route53_hosted_zone_id : (
      length(data.aws_route53_zone.pakalspot) > 0 ? data.aws_route53_zone.pakalspot[0].zone_id : ""
    )
  ) : ""
}

# Data source to reference existing ACM certificate (if provided)
data "aws_acm_certificate" "existing" {
  count = var.enable_acm_certificate && var.existing_acm_certificate_arn != "" ? 1 : 0
  arn   = var.existing_acm_certificate_arn
}

# ACM Certificate Module (only if not using existing certificate)
# Creates ACM certificate for pakalspot.com with DNS validation via Route53
# This only creates DNS validation CNAME records, not the main A record
# NOTE: Route53 A records pointing to ALB must be created manually
module "acm" {
  count  = var.enable_acm_certificate && var.existing_acm_certificate_arn == "" && local.route53_zone_id != "" ? 1 : 0
  source = "../../modules/acm"

  domain_name               = var.route53_domain_name
  hosted_zone_id            = local.route53_zone_id
  subject_alternative_names = var.acm_subject_alternative_names
  common_tags               = var.common_tags
}

# Local to get certificate ARN (either from existing or newly created)
locals {
  acm_certificate_arn = var.enable_acm_certificate ? (
    var.existing_acm_certificate_arn != "" ? var.existing_acm_certificate_arn : (
      length(module.acm) > 0 ? module.acm[0].certificate_arn : ""
    )
  ) : ""
}

# Route53 Module
# Automatically creates A record pointing to ALB
# This replaces manual Route53 record creation
module "route53" {
  count  = var.enable_acm_certificate && local.route53_zone_id != "" ? 1 : 0
  source = "../../modules/route53"

  hosted_zone_id        = local.route53_zone_id
  domain_name          = var.route53_domain_name
  cluster_name         = var.cluster_name
  enable_route53_record = true
  # alb_name and alb_arn are optional - module will auto-detect ALB by cluster tags
  # The module will find ALB created by Kubernetes ingress with tag: elbv2.k8s.aws/cluster
  common_tags          = var.common_tags

  depends_on = [
    module.eks,
    module.aws-load-balancer-controller
    # Note: ALB will be created by Kubernetes ingress after deployment
    # Route53 record will be created once ALB exists (may require second terraform apply)
  ]
}
