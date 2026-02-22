resource "aws_db_parameter_group" "postgres" {
  name   = "${var.service}-pg-params"
  family = "postgres${split(".", var.db_engine_version)[0]}"
  
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_statement"
    value        = "ddl"
    apply_method = "immediate"
  }

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "rds" {
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  iops                  = var.db_iops
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_subnet_group_name   = aws_db_subnet_group.subnet_group.id
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  multi_az               = var.db_multi_az

  identifier                             = "${var.service}-db"
  username                            = var.db_username
  manage_master_user_password         = true
  iam_database_authentication_enabled = true

  parameter_group_name = aws_db_parameter_group.postgres.name

  backup_retention_period = var.db_backup_retention_period

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  auto_minor_version_upgrade   = var.db_auto_minor_version_upgrade

  copy_tags_to_snapshot = true

  publicly_accessible = false
  final_snapshot_identifier = "${var.service}-db-final-snapshot"
  skip_final_snapshot       = false
  deletion_protection       = true
  vpc_security_group_ids    = [aws_security_group.database-sgrp.id]

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}
