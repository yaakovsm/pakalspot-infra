variable "db_name" {
  description = "The name of the database"
  type        = string
}
variable "family" {
  description = "The family of the database"
  type        = string
}
variable "db_username" {
  description = "The username of the database"
  type        = string
}
variable "instance_class" {
  description = "The instance class of the database"
  type        = string
}
variable "allocated_storage" {
  description = "The allocated storage of the database"
  type        = number
  default     = 20
}
variable "max_allocated_storage" {
  description = "The maximum allocated storage of the database"
  type        = number
}
variable "backup_retention_period" {
  description = "The backup retention period of the database"
  type        = number
  default     = 1
}
variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = true
}
variable "deletion_protection" {
  description = "Deletion protection"
  type        = bool
  default     = true
}
variable "parameters" {
  description = "The parameters of the database"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "options" {
  description = "The options of the database"
  type = list(object({
    option_name = string
    option_settings = list(object({
      name  = string
      value = string
    }))
  }))
  default = []
}
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}
variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}
variable "database_subnet_group_name" {
  description = "Database subnet group name"
  type        = string
}
variable "eks_security_group_id" {
  description = "EKS cluster security group ID to allow database access"
  type        = string
}
variable "eks_node_security_group_id" {
  description = "EKS node group security group ID to allow database access from pods"
  type        = string
}
variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}