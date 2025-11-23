module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  database_subnets = var.database_subnets

  create_database_subnet_group = true
  create_database_subnet_route_table = true

  enable_nat_gateway = var.enable_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  database_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.common_tags
}