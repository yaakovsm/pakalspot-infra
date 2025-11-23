aws_region                               = "us-east-1"
aws_profile                              = "tf-user"
vpc_name                                 = "pakalspot-dev"
vpc_cidr                                 = "10.0.0.0/16"
availability_zones                       = ["us-east-1a", "us-east-1b"]
public_subnets                           = ["10.0.101.0/24", "10.0.102.0/24"]
private_subnets                          = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnets                         = ["10.0.21.0/24", "10.0.22.0/24"]
enable_nat_gateway                       = true
cluster_name                             = "pakalspot-cluster"
kubernetes_version                       = "1.30"
enable_irsa                              = true
endpoint_public_access                   = true
enable_cluster_creator_admin_permissions = true
node_group_name                          = "pakalspot-node-group"
ami_type                                 = "AL2_x86_64"
instance_types                           = ["t3.small"]
min_size                                 = 1
max_size                                 = 4
desired_size                             = 2
external_secrets_version                 = "0.9.20"
external_secrets_namespace               = "external-secrets"
argocd_version                           = "2.11.0"
argocd_namespace                         = "argocd"
argocd_insecure                          = true
argocd_service_type                      = "LoadBalancer"
argocd_controller_replicas               = 1
s3_bucket_name                           = "pakalspot-photos"
db_name                                  = "pakalspot-db"
db_family                                = "postgres14"
db_username                              = "pakalspot"
db_port                                  = 5432
db_engine                                = "postgres"
db_engine_version                        = "14"
db_instance_class                        = "db.t3.small"
allocated_storage                        = 20
max_allocated_storage                    = 100
backup_retention_period                  = 7
skip_final_snapshot                      = true
deletion_protection                      = true
parameters = [
  {
    name  = "character_set_server"
    value = "utf8mb4"
  }
]
options = [
  {
    option_name = "POSTGRES_AUDIT_PLUGIN"
    option_settings = [
      {
        name  = "SERVER_AUDIT_EVENTS"
        value = "CONNECT"
      }
    ]
  }
]

common_tags = {
  Environment = "dev"
  Terraform   = "true"
  managed_by  = "terraform"
}