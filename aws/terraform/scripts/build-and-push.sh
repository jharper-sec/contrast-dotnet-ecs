#!/bin/bash
# Script to build and push Docker image to AWS ECR for Terraform

# Configuration variables
AWS_REGION="us-east-1"
DOCKERFILE_PATH="../../docker/Dockerfile"
APP_SOURCE_PATH="../../src"
IMAGE_TAG="latest"

# Validate Docker is running in Windows container mode
if ! docker info | grep -q "windows"; then
  echo "ERROR: Docker is not running in Windows container mode."
  echo "Right-click the Docker Desktop tray icon and select 'Switch to Windows containers...' before running this script."
  exit 1
fi

# Get the repository URL from Terraform outputs
if [ ! -f "terraform.tfstate" ]; then
  echo "ERROR: terraform.tfstate not found. Please run terraform-apply.sh first."
  exit 1
fi

REPOSITORY_URL=$(terraform output -raw repository_url)
if [ -z "$REPOSITORY_URL" ]; then
  echo "ERROR: Could not get repository URL from Terraform outputs."
  exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Confirm before proceeding
echo "This script will build a Windows container image and push it to AWS ECR."
echo "Repository: $REPOSITORY_URL"
echo "Image tag: $IMAGE_TAG"
read -p "Continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URL
if [ $? -ne 0 ]; then
  echo "Failed to authenticate Docker to ECR."
  exit 1
fi

# Build the Docker image
echo "Building Docker image... (this may take a while for Windows containers)"
docker build -t $REPOSITORY_URL:$IMAGE_TAG -f $DOCKERFILE_PATH $APP_SOURCE_PATH
if [ $? -ne 0 ]; then
  echo "Failed to build Docker image."
  exit 1
fi

# Push the image to ECR
echo "Pushing image to ECR... (this may take some time due to Windows container size)"
docker push $REPOSITORY_URL:$IMAGE_TAG
if [ $? -ne 0 ]; then
  echo "Failed to push Docker image to ECR."
  exit 1
fi

echo "Image successfully built and pushed to ECR."
echo "Repository URI: $REPOSITORY_URL:$IMAGE_TAG"