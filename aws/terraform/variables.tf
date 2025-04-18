# variables.tf - Defines all the variables for the Terraform configuration

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "contrast-dotnet-demo-v2"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "dotnet-framework-contrast-sample"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "windows-contrast-cluster"
}

variable "launch_type" {
  description = "The launch type for the ECS cluster (FARGATE or EC2)"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "EC2"], var.launch_type)
    error_message = "Launch type must be either FARGATE or EC2."
  }
}

variable "vpc_id" {
  description = "The VPC ID to deploy resources into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs to deploy the ECS services into"
  type        = list(string)
}

variable "contrast_secret_name" {
  description = "Name of the secret in AWS Secrets Manager containing Contrast agent credentials"
  type        = string
  default     = "contrast-agent-credentials"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1 vCPU = 1024 units)"
  type        = string
  default     = "2048"
}

variable "task_memory" {
  description = "Memory for the ECS task in MiB"
  type        = string
  default     = "4096"
}

variable "os_family" {
  description = "The Windows OS family to use (must match container base OS)"
  type        = string
  default     = "WINDOWS_SERVER_2022_CORE"
  validation {
    condition     = contains(["WINDOWS_SERVER_2019_CORE", "WINDOWS_SERVER_2019_FULL", "WINDOWS_SERVER_2022_CORE", "WINDOWS_SERVER_2022_FULL"], var.os_family)
    error_message = "OS family must be one of the supported Windows versions."
  }
}

variable "image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
  default     = "latest"
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to Fargate tasks"
  type        = bool
  default     = true
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 instances (only needed for EC2 launch type)"
  type        = string
  default     = ""
}

variable "ec2_instance_type" {
  description = "Instance type for the EC2 instances (only needed for EC2 launch type)"
  type        = string
  default     = "m5.large"
}
