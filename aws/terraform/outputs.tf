# outputs.tf - Defines output values from the Terraform configuration

output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.contrast_demo.repository_url
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.windows_contrast_cluster.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.windows_contrast_cluster.arn
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.dotnet_contrast.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.dotnet_contrast_service.name
}

output "security_group_id" {
  description = "ID of the security group created for the task"
  value       = aws_security_group.task_security_group.id
}