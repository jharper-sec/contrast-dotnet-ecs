# ecs-cluster.tf - Creates the ECS cluster infrastructure

# ECS Cluster
resource "aws_ecs_cluster" "windows_contrast_cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Application = "ContrastSecurity"
    Environment = "Demo"
  }
}

# EC2 resources - only created if launch type is EC2
resource "aws_iam_role" "ecs_instance_role" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.name_prefix}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.name_prefix}-ecs-instance-profile"
  role  = aws_iam_role.ecs_instance_role[0].name
}

# Security Group for EC2 instances
resource "aws_security_group" "windows_container_sg" {
  count       = var.launch_type == "EC2" ? 1 : 0
  name        = "${var.name_prefix}-windows-container-sg"
  description = "Security group for Windows ECS container instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
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

resource "aws_launch_template" "windows_container" {
  count         = var.launch_type == "EC2" ? 1 : 0
  name          = "${var.name_prefix}-windows-container-lt"
  image_id      = var.ec2_ami_id # Windows ECS-optimized AMI
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile[0].name
  }

  vpc_security_group_ids = [aws_security_group.windows_container_sg[0].id]

  user_data = base64encode(<<EOF
<powershell>
# Initialize ECS agent
Import-Module ECSTools
Initialize-ECSAgent -Cluster ${var.cluster_name}

# Configure Windows features for containers
Install-WindowsFeature -Name Containers
</powershell>
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.name_prefix}-ECS-Windows-Container"
      Application = "ContrastSecurity"
    }
  }
}

resource "aws_autoscaling_group" "windows_container_asg" {
  count               = var.launch_type == "EC2" ? 1 : 0
  name                = "${var.name_prefix}-windows-container-asg"
  vpc_zone_identifier = var.subnet_ids
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.windows_container[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ECS-Windows-Container"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "ContrastSecurity"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "ec2_capacity_provider" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.name_prefix}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.windows_container_asg[0].arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  count              = var.launch_type == "EC2" ? 1 : 0
  cluster_name       = aws_ecs_cluster.windows_contrast_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ec2_capacity_provider[0].name]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.ec2_capacity_provider[0].name
  }
}
