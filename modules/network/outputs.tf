output "vpc_id" {
    value = module.vpc.vpc_id
}
output "vpc_cidr_block" {
    value = module.vpc.vpc_cidr_block
}
output "public_subnets" {
    value = module.vpc.public_subnets
}

output "private_subnets" {
    value = module.vpc.private_subnets
}
output "database_subnets" {
    value = module.vpc.database_subnets
}
output "database_subnet_group_name" {
    value = module.vpc.database_subnet_group_name
}
output "igw_id" {
    value = module.vpc.igw_id
}
output "natgw_ids" {
    value = module.vpc.natgw_ids
}
output "subnet_ids" {
    description = "All subnet IDs (public + private) for EKS"
    value = concat(module.vpc.public_subnets, module.vpc.private_subnets)
}