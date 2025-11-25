variable "cluster_name" {
    description = "The name of the cluster"
    type = string
    default = "pakalspot-cluster"
}

variable "kubernetes_version" {
    description = "The version of the Kubernetes cluster"
    type = string
    default = "1.29"
}
variable "enable_irsa" {
    description = "Enable IRSA"
    type = bool
    default = true
}
variable "endpoint_public_access" {
    description = "Enable public access to the endpoint"
    type = bool
    default = true
}
variable "enable_cluster_creator_admin_permissions" {
    description = "Enable cluster creator admin permissions"
    type = bool
    default = true
}
variable "vpc_id" {
    description = "The ID of the VPC"
    type = string
}
variable "subnet_ids" {
    description = "The IDs of the subnets"
    type = list(string)
}
variable "private_subnet_ids" {
    description = "The IDs of the private subnets"
    type = list(string)
}
variable "node_group_name" {
    description = "The name of the node group"
    type = string
    default = "pakalspot-node-group"
}
variable "ami_type" {
    description = "The type of the AMI"
    type = string
    default = "AL2_x86_64"
}
variable "instance_types" {
    description = "The instance types"
    type = list(string)
    default = ["t3.small"]
}
variable "min_size" {
    description = "The minimum size of the node group"
    type = number
    default = 2
}
variable "max_size" {
    description = "The maximum size of the node group"
    type = number
    default = 4
}
variable "desired_size" {
    description = "The desired size of the node group"
    type = number
    default = 2
}
variable "common_tags" {
    description = "Common tags"
    type = map(string)
    default = {}
}
variable "capacity_type" {
    description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
    type = string
    default = "ON_DEMAND"
}
variable "disk_size" {
    description = "Disk size in GiB for worker nodes"
    type = number
    default = 20
}
variable "update_config" {
    description = "Configuration block for node group updates"
    type = object({
        max_unavailable_percentage = optional(number)
        max_unavailable            = optional(number)
    })
    default = {
        max_unavailable = 1
    }
}