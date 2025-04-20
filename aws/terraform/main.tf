# main.tf - Main Terraform configuration file

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
  
  backend "s3" {
    bucket         = "contrast-dotnet-ecs-terraform-state"
    key            = "contrast-dotnet-ecs/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Get current caller identity for account ID
data "aws_caller_identity" "current" {}
