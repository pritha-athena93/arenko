variable "environment" {
  description = "the environment name"
  type        = string
}

variable "region" {
  description = "the AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "availability_zones" {
  description = "list of availability zones to use"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

variable "service" {
  description = "the service name"
  type        = string
  default     = "nginx"
}

variable "owner" {
  description = "the team or person responsible for this resource"
  type        = string
  default     = "Infra team"
}

variable "image_tag" {
  description = "the nginx image tag to deploy"
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.task_cpu)
    error_message = "task_cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "memory in MB for the ECS task"
  type        = string
  default     = "512"
}

variable "task_desired_count" {
  description = "number of task instances to run in the ECS service"
  type        = number
  default     = 3
}

variable "task_max_count" {
  description = "maximum number of ECS task instances for autoscaling"
  type        = number
  default     = 6
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS (must be in the same region). Leave unset to disable HTTPS (dev only)."
  type        = string
  default     = null
}

variable "ssl_policy" {
  description = "SSL/TLS security policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection on the ALB. Set false in dev/CI to allow terraform destroy."
  type        = bool
  default     = true
}

variable "s3_force_destroy" {
  description = "Allow Terraform to delete the ALB logs bucket even if it contains objects. Set true in dev/CI to allow clean terraform destroy."
  type        = bool
  default     = false
}

variable "db_allocated_storage" {
  description = "allocated storage in GB for the RDS instance (minimum 20 for gp3)"
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "db_allocated_storage must be at least 20 GB for gp3 storage type."
  }
}

variable "db_engine_version" {
  description = "postgres engine version for the RDS instance"
  type        = string
  default     = "16.8"
}

variable "db_instance_class" {
  description = "instance class for the RDS instance"
  type        = string
  default     = "db.r8g.large"
}

variable "db_max_allocated_storage" {
  description = "upper limit in GB for RDS storage autoscaling"
  type        = number
  default     = 100
}

variable "db_backup_retention_period" {
  description = "number of days to retain RDS backups (0 disables backups)"
  type        = number
  default     = 7
}

variable "db_iops" {
  description = "IOPS to provision above the gp3 baseline. Leave null to use the free 3000 IOPS baseline. Required for io1/io2."
  type        = number
  default     = null
}

variable "db_multi_az" {
  description = "enable Multi-AZ standby for RDS (set false in dev to reduce cost)"
  type        = bool
  default     = true
}

variable "db_username" {
  description = "master username for the RDS instance"
  type        = string
  default     = "postgres"
}

variable "db_auto_minor_version_upgrade" {
  description = "automatically upgrade minor RDS engine versions during the maintenance window. Set false to control upgrade timing manually."
  type        = bool
  default     = true
}

variable "ecs_cpu_architecture" {
  description = "CPU architecture for Fargate tasks. Must match the Docker image architecture. Use ARM64 for Graviton (~20% cheaper), X86_64 for standard. nginx official images are multi-arch and support both."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.ecs_cpu_architecture)
    error_message = "ecs_cpu_architecture must be X86_64 or ARM64."
  }
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs to CloudWatch. Can be disabled in dev to reduce costs."
  type        = bool
  default     = true
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilisation (%) for ECS autoscaling. Scale out when average exceeds this."
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilisation (%) for ECS autoscaling. Scale out when average exceeds this."
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log groups. Use lower values in dev to reduce costs."
  type        = number
  default     = 90
}

variable "log_skip_destroy" {
  description = "Prevent Terraform from deleting CloudWatch log groups on destroy. Set false in dev/CI to allow clean teardowns."
  type        = bool
  default     = true
}

variable "db_storage_type" {
  description = "Storage type for the RDS instance."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.db_storage_type)
    error_message = "db_storage_type must be one of: gp2, gp3, io1, io2."
  }
}
