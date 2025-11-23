terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22"
    }
    # Comment out for first apply - will enable after cluster exists
    # kubernetes = {
    #   source  = "hashicorp/kubernetes"
    #   version = "2.38.0"
    # }
    # helm = {
    #   source  = "hashicorp/helm"
    #   version = "3.0.0"
    # }
    # kubectl = {
    #   source  = "gavinbunney/kubectl"
    #   version = "1.19.0"
    # }
  }
}
provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# Comment out for first apply - will enable after cluster exists
# data "aws_eks_cluster" "eks" {
#   name = module.eks.cluster_name
# }
# data "aws_eks_cluster_auth" "eks" {
#   name = module.eks.cluster_name
# }
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }
# provider "helm" {
#   kubernetes = {
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }
# provider "kubectl" {
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }