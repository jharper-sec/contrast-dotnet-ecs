# Terraform Deployment Guide: Contrast Security .NET Framework Agent on AWS ECS

This guide provides step-by-step instructions for deploying using Terraform.

## Prerequisites

Same as the CloudFormation deployment, plus:
- Terraform CLI (v1.0.0 or newer) installed

## Step 1-2: Same as CloudFormation Deployment

Follow Steps 1-2 in the main deployment guide.

## Step 3: Store Contrast Credentials in AWS Secrets Manager

Same as the CloudFormation deployment.

## Step 4: Deploy with Terraform

1. Navigate to the Terraform directory:
```bash
cd aws/terraform
```
2. Copy and customize the variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```
Update with your AWS account details, VPC IDs, and other configuration.

3. Initialize Terraform:
```bash
terraform init
```
4. Plan the deployment:
```bash
terraform plan
```
5. Deploy the infrastructure:
```bash
terraform apply
```
Alternatively, use the terraform-apply.sh helper script:
```bash
chmod +x scripts/terraform-apply.sh
./scripts/terraform-apply.sh
```

## Step 5: Build and Push the Docker Image
1. Run the Terraform-specific build script:
```bash
chmod +x scripts/build-and-push.sh
./scripts/build-and-push.sh
```

## Step 6: Verify the Deployment
Follow the verification steps in the main deployment guide. The verification process is the same regardless of deployment method.
