output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}
output "node_security_group_id" {
  description = "Security group ID attached to the EKS node group (for pod traffic)"
  value       = module.eks.node_security_group_id
}
output "node_group_iam_role_arn" {
  description = "IAM role ARN for the EKS node group"
  value       = module.eks.eks_managed_node_groups[var.node_group_name].iam_role_arn
}
output "node_group_iam_role_name" {
  description = "IAM role name for the EKS node group"
  value       = module.eks.eks_managed_node_groups[var.node_group_name].iam_role_name
}