module "networking" {
  source             = "../../modules/network"
  vpc_name           = var.vpc_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  database_subnets   = var.database_subnets
  enable_nat_gateway = var.enable_nat_gateway
  common_tags        = var.common_tags
}

module "eks" {
  source                                   = "../../modules/eks"
  cluster_name                             = var.cluster_name
  kubernetes_version                       = var.kubernetes_version
  enable_irsa                              = var.enable_irsa
  endpoint_public_access                   = var.endpoint_public_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.subnet_ids

  node_group_name = var.node_group_name
  ami_type        = var.ami_type
  instance_types  = var.instance_types
  min_size        = var.min_size
  max_size        = var.max_size
  desired_size    = var.desired_size

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

  common_tags = var.common_tags

  depends_on = [module.eks, module.networking]
}

module "s3" {
  source         = "../../modules/s3"
  s3_bucket_name = var.s3_bucket_name
  common_tags    = var.common_tags

  depends_on = [module.networking]
}

module "app-backend-irsa" {
  source            = "../../modules/app-backend-irsa"
  oidc_provider_arn = module.eks.oidc_provider_arn
  s3_bucket_arn     = module.s3.bucket_arn

  namespace            = "pakalspot-dev"
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

  stage_name  = "dev"
  common_tags = var.common_tags

  depends_on = [module.networking, module.eks]
}
