# ecs-service.tf - Defines the ECS service and task definitions

# Task Execution Role - Required to pull from ECR and access Secrets Manager
resource "aws_iam_role" "task_execution_role" {
  name = "${var.name_prefix}-ECSTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

resource "aws_iam_policy" "secrets_access_policy" {
  name        = "${var.name_prefix}-SecretsManagerReadAccess"
  description = "Allow ECS tasks to read Contrast security credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.contrast_secret_name}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}

# Task Role - The role that the container assumes when running
resource "aws_iam_role" "task_role" {
  name = "${var.name_prefix}-ECSTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Add any policies needed for your container to access AWS services
resource "aws_iam_role_policy_attachment" "task_role_policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Group for the Task
resource "aws_security_group" "task_security_group" {
  name        = "${var.name_prefix}-task-security-group"
  description = "Security group for ECS Tasks running Contrast Security agent"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Logs Group
resource "aws_cloudwatch_log_group" "contrast_app_logs" {
  name              = "/ecs/${var.name_prefix}-dotnet-framework-contrast-sample"
  retention_in_days = 30
}

# ECS Task Definition
resource "aws_ecs_task_definition" "dotnet_contrast" {
  family                   = "dotnet-framework-contrast-sample"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  runtime_platform {
    operating_system_family = var.os_family
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "dotnet-app"
      image     = "${aws_ecr_repository.contrast_demo.repository_url}:${var.image_tag}"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.contrast_app_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      healthCheck = {
        command = [
          "PowerShell",
          "try { $response = Invoke-WebRequest -Uri 'http://localhost/' -UseBasicParsing; if ($response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      secrets = [
        {
          name      = "CONTRAST__API__URL"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.contrast_secret_name}:CONTRAST__API__URL::"
        },
        {
          name      = "CONTRAST__API__API_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.contrast_secret_name}:CONTRAST__API__API_KEY::"
        },
        {
          name      = "CONTRAST__API__SERVICE_KEY"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.contrast_secret_name}:CONTRAST__API__SERVICE_KEY::"
        },
        {
          name      = "CONTRAST__API__USER_NAME"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.contrast_secret_name}:CONTRAST__API__USER_NAME::"
        }
      ]

      # environment = [
      #   {
      #     name  = "CONTRAST__APPLICATION__NAME"
      #     value = "dotnet-framework-ecs-demo"
      #   },
      #   {
      #     name  = "CONTRAST__SERVER__NAME"
      #     value = "ecs-windows-${var.name_prefix}"
      #   }
      # ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "dotnet_contrast_service" {
  name            = "dotnet-framework-contrast-svc"
  cluster         = aws_ecs_cluster.windows_contrast_cluster.id
  task_definition = aws_ecs_task_definition.dotnet_contrast.arn
  desired_count   = 1
  launch_type     = var.launch_type

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.task_security_group.id]
    assign_public_ip = var.assign_public_ip ? true : false
  }

  enable_execute_command = true
  propagate_tags         = "SERVICE"

  tags = {
    Application = "ContrastSecurity"
    Environment = "Demo"
  }
}
