module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  addons = {
    coredns                 = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy              = {}
    vpc-cni                 = {
      before_compute = true
    }
  }
  enable_irsa = var.enable_irsa

  endpoint_public_access = var.endpoint_public_access


  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids

  eks_managed_node_groups = {
    (var.node_group_name) = {
      
      ami_type       = var.ami_type
      instance_types = var.instance_types

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
      iam_role_additional_policies = {
    }
  }
  }

    tags = var.common_tags
}