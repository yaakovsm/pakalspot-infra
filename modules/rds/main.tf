# Security group for RDS allowing access from allowed security groups
resource "aws_security_group" "rds" {
  name        = "${var.db_name}-sg"
  description = "Security group for RDS PostgreSQL database"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      description     = "PostgreSQL from security group ${ingress.key + 1}"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.db_name}-sg"
    }
  )
}

module "db" {
  source = "terraform-aws-modules/rds/aws"


  identifier = var.db_name

  engine                = "postgres"
  engine_version        = "14"
  family                = var.family
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  port     = 5432

  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az            = var.multi_az
  publicly_accessible = false
  storage_encrypted   = true

  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  # Filter out MySQL-specific parameters, keep only PostgreSQL-compatible ones
  parameters = [
    for param in var.parameters : param if param.name != "character_set_server"
  ]

  options = var.options

  tags = var.common_tags
}