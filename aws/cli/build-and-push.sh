#!/bin/bash
# Script to build and push Docker image to AWS ECR

# Configuration variables - replace with your actual values
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="your-aws-account-id" # Replace with your AWS account ID
REPOSITORY_NAME="dotnet-framework-contrast-sample"
IMAGE_TAG="latest"
DOCKERFILE_PATH="../../docker/Dockerfile"
APP_SOURCE_PATH="../../src"

# Validate Docker is running in Windows container mode
if ! docker info | grep -q "windows"; then
  echo "ERROR: Docker is not running in Windows container mode."
  echo "Right-click the Docker Desktop tray icon and select 'Switch to Windows containers...' before running this script."
  exit 1
fi

# Confirm before proceeding
echo "This script will build a Windows container image and push it to AWS ECR."
echo "Repository: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME"
echo "Image tag: $IMAGE_TAG"
read -p "Continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $AWS_REGION >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating ECR repository: $REPOSITORY_NAME"
  aws ecr create-repository --repository-name $REPOSITORY_NAME --region $AWS_REGION
  if [ $? -ne 0 ]; then
    echo "Failed to create ECR repository."
    exit 1
  fi
fi

# Authenticate Docker to ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
if [ $? -ne 0 ]; then
  echo "Failed to authenticate Docker to ECR."
  exit 1
fi

# Build the Docker image
echo "Building Docker image... (this may take a while for Windows containers)"
docker build -t $REPOSITORY_NAME:$IMAGE_TAG -f $DOCKERFILE_PATH $APP_SOURCE_PATH
if [ $? -ne 0 ]; then
  echo "Failed to build Docker image."
  exit 1
fi

# Tag the image for ECR
echo "Tagging image for ECR..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
  echo "Failed to tag Docker image."
  exit 1
fi

# Push the image to ECR
echo "Pushing image to ECR... (this may take some time due to Windows container size)"
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
  echo "Failed to push Docker image to ECR."
  exit 1
fi

echo "Image successfully built and pushed to ECR."
echo "Repository URI: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG"
