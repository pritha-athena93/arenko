resource "aws_cloudwatch_log_group" "ecs_exec" {
  name              = "/${var.service}-cluster/ecs/exec"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn
  skip_destroy      = var.log_skip_destroy

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_cloudwatch_log_group" "container" {
  name              = "/${var.service}/ecs/container"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.logs.arn
  skip_destroy      = var.log_skip_destroy

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_ecs_cluster" "nginx_cluster" {
  name = "${var.service}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
      }
    }
  }

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }

}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.service}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_iam_role_policy" "ecs_task_rds_connect" {
  name = "${var.service}-rds-connect"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "rds-db:connect"
      Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.rds.resource_id}/*"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_exec_command" {
  name = "${var.service}-exec-command"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.service}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Condition = {
        ArnLike = {
          "aws:SourceArn" = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_iam_role_policy" "ecs_execution_logs" {
  name = "${var.service}-execution-logs"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = [
        "${aws_cloudwatch_log_group.ecs_exec.arn}:*",
        "${aws_cloudwatch_log_group.container.arn}:*"
      ]
    }]
  })
}

resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "${var.service}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu               = var.task_cpu
  memory            = var.task_memory
  task_role_arn     = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  runtime_platform {
    cpu_architecture        = var.ecs_cpu_architecture
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([{
    name      = "${var.service}-container"
    image     = "nginx:${var.image_tag}"
    essential = true
    portMappings = [{
      containerPort = 80,
      hostPort      = 80,
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.container.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_ecs_service" "nginx_service" {
  name            = "${var.service}-service"
  cluster         = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.task_desired_count

  network_configuration {
    subnets         = aws_subnet.web[*].id
    security_groups = [aws_security_group.ecs-sgrp.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "${var.service}-container"
    container_port   = 80
  }

  enable_execute_command          = true
  health_check_grace_period_seconds = 60

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_ecs_task_definition.nginx_task,
    aws_lb_listener.http,
    aws_lb_listener.https,
  ]

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}
