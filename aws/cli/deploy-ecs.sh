#!/bin/bash
# Script to deploy the ECS resources using CloudFormation templates

# Configuration variables - replace with your actual values
AWS_REGION="us-east-1"
CF_STACK_PREFIX="contrast-dotnet-demo"
ECR_STACK_NAME="${CF_STACK_PREFIX}-ecr"
CLUSTER_STACK_NAME="${CF_STACK_PREFIX}-cluster"
SERVICE_STACK_NAME="${CF_STACK_PREFIX}-service"
ECR_TEMPLATE_PATH="../cloudformation/ecr-repository.yaml"
CLUSTER_TEMPLATE_PATH="../cloudformation/ecs-cluster.yaml"
SERVICE_TEMPLATE_PATH="../cloudformation/ecs-service.yaml"

# AWS resource specific parameters
CLUSTER_NAME="windows-contrast-cluster"
VPC_ID="vpc-xxxxxxxx" # Replace with your VPC ID
SUBNET_IDS="subnet-xxxxxxxx,subnet-yyyyyyyy" # Replace with your subnet IDs
CONTRAST_SECRET_NAME="contrast-agent-credentials"
LAUNCH_TYPE="FARGATE" # or EC2
OS_FAMILY="WINDOWS_SERVER_2022_CORE" # Match your container base OS

# Confirm before proceeding
echo "This script will deploy ECS resources using CloudFormation."
echo "Region: $AWS_REGION"
echo "Stack prefix: $CF_STACK_PREFIX"
read -p "Continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Deploy ECR Repository
echo "Deploying ECR repository..."
aws cloudformation deploy \
  --template-file $ECR_TEMPLATE_PATH \
  --stack-name $ECR_STACK_NAME \
  --region $AWS_REGION \
  --capabilities CAPABILITY_NAMED_IAM

if [ $? -ne 0 ]; then
  echo "Failed to deploy ECR repository."
  exit 1
fi

# Get the ECR repository URI
ECR_REPO_URI=$(aws cloudformation describe-stacks \
  --stack-name $ECR_STACK_NAME \
  --region $AWS_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='RepositoryURI'].OutputValue" \
  --output text)

echo "ECR Repository URI: $ECR_REPO_URI"

# Deploy ECS Cluster
echo "Deploying ECS cluster..."
aws cloudformation deploy \
  --template-file $CLUSTER_TEMPLATE_PATH \
  --stack-name $CLUSTER_STACK_NAME \
  --region $AWS_REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ClusterName=$CLUSTER_NAME \
    LaunchType=$LAUNCH_TYPE \
    VpcId=$VPC_ID \
    SubnetIds=$SUBNET_IDS

if [ $? -ne 0 ]; then
  echo "Failed to deploy ECS cluster."
  exit 1
fi

# Get the cluster ARN
CLUSTER_ARN=$(aws cloudformation describe-stacks \
  --stack-name $CLUSTER_STACK_NAME \
  --region $AWS_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='ClusterArn'].OutputValue" \
  --output text)

echo "ECS Cluster ARN: $CLUSTER_ARN"

# Deploy ECS Service and Task Definition
echo "Deploying ECS service and task definition..."
aws cloudformation deploy \
  --template-file $SERVICE_TEMPLATE_PATH \
  --stack-name $SERVICE_STACK_NAME \
  --region $AWS_REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ClusterName=$CLUSTER_NAME \
    ImageRepositoryUri=$ECR_REPO_URI \
    ImageTag="latest" \
    LaunchType=$LAUNCH_TYPE \
    OperatingSystemFamily=$OS_FAMILY \
    ContrastSecretName=$CONTRAST_SECRET_NAME \
    VpcId=$VPC_ID \
    SubnetIds=$SUBNET_IDS \
    AssignPublicIp=ENABLED

if [ $? -ne 0 ]; then
  echo "Failed to deploy ECS service."
  exit 1
fi

echo "Deployment complete."
echo "To monitor the deployment, check the AWS ECS console or run:"
echo "aws ecs describe-services --cluster $CLUSTER_NAME --services dotnet-framework-contrast-svc --region $AWS_REGION"
