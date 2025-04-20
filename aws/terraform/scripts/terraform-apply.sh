#!/bin/bash
# Script to apply Terraform configuration for Contrast Security .NET Framework agent on AWS ECS

# Configuration variables - replace with your actual values
AWS_REGION="us-east-1"

# Confirm before proceeding
echo "This script will deploy AWS resources using Terraform."
echo "It will create an ECR repository, an ECS cluster, and deploy a service with the Contrast Security agent."
echo "Region: $AWS_REGION"
read -p "Continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
  echo "Error: Terraform is not installed. Please install Terraform first."
  exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
  echo "terraform.tfvars file not found."
  echo "Please copy terraform.tfvars.example to terraform.tfvars and update it with your values."
  read -p "Do you want to create it now from the example? (y/n): " CREATE_VARS
  if [[ $CREATE_VARS == "y" || $CREATE_VARS == "Y" ]]; then
    cp terraform.tfvars.example terraform.tfvars
    echo "Created terraform.tfvars from example. Please edit it with your values and run this script again."
    exit 0
  else
    exit 1
  fi
fi

# Initialize Terraform with remote backend
echo "Initializing Terraform with remote backend..."
terraform init

if [ $? -ne 0 ]; then
  echo "Failed to initialize Terraform."
  exit 1
fi

# Validate the configuration
echo "Validating Terraform configuration..."
terraform validate

if [ $? -ne 0 ]; then
  echo "Terraform validation failed."
  exit 1
fi

# Plan the deployment
echo "Planning Terraform deployment..."
terraform plan -out=tfplan

if [ $? -ne 0 ]; then
  echo "Terraform plan failed."
  exit 1
fi

# Apply the plan
echo "Applying Terraform deployment..."
terraform apply tfplan

if [ $? -ne 0 ]; then
  echo "Terraform apply failed."
  exit 1
fi

# Show the outputs
echo "Deployment complete. Here are the resource details:"
terraform output

echo ""
echo "Next steps:"
echo "1. Build and push your Docker image to the ECR repository using build-and-push.sh"
echo "2. Your ECS service will pull the latest image from ECR"