# Deployment Guide: Contrast Security .NET Framework Agent on AWS ECS with Windows Containers

This guide provides step-by-step instructions for deploying the Contrast Security .NET Framework agent with a sample ASP.NET MVC application on AWS ECS using Windows containers.

## Prerequisites

Before proceeding, ensure you have:

- AWS Account with appropriate permissions for ECR, ECS, IAM, and Secrets Manager
- AWS CLI installed and configured
- Docker Desktop for Windows with Windows containers enabled
- Contrast Security account with agent credentials
- Git

## Step 1: Clone the Repository

```bash
git clone <repository-url>
cd contrast-dotnet-ecs
```

## Step 2: Configure Your Environment

1. **Set up AWS CLI:**
   Ensure your AWS CLI is configured with credentials that have sufficient permissions:
   ```bash
   aws configure
   ```

2. **Switch Docker to Windows Containers:**
   Right-click the Docker Desktop tray icon and select "Switch to Windows containers..." if not already on Windows containers.

3. **Prepare Contrast Security Credentials:**
   Obtain your Contrast agent credentials from the Contrast UI:
   - API URL
   - API Key
   - Service Key
   - User Name
   - (or Connection Token for newer agents)

## Step 3: Store Contrast Credentials in AWS Secrets Manager

1. Edit the script with your credentials:
   ```bash
   cd aws/cli
   nano create-secret.sh
   ```
   Replace the placeholder values with your actual Contrast credentials.

2. Run the script to create the secret:
   ```bash
   chmod +x create-secret.sh
   ./create-secret.sh
   ```

## Step 4: Build and Push the Docker Image

1. Edit the build script with your AWS account ID:
   ```bash
   nano build-and-push.sh
   ```
   Update `AWS_ACCOUNT_ID` and `AWS_REGION` values.

2. Run the script to build and push the Docker image:
   ```bash
   chmod +x build-and-push.sh
   ./build-and-push.sh
   ```
   Note: Building Windows containers can take significant time.

## Step 5: Deploy AWS Resources

1. Edit the deployment script:
   ```bash
   nano deploy-ecs.sh
   ```
   Update:
   - `AWS_REGION`
   - `VPC_ID` (your VPC ID)
   - `SUBNET_IDS` (comma-separated list of your subnet IDs)
   - `LAUNCH_TYPE` (FARGATE or EC2)
   - `OS_FAMILY` (ensure it matches your container base OS)

2. Run the script to deploy the CloudFormation stacks:
   ```bash
   chmod +x deploy-ecs.sh
   ./deploy-ecs.sh
   ```

## Step 6: Verify the Deployment

1. **Check ECS Service Status:**
   ```bash
   aws ecs describe-services \
     --cluster windows-contrast-cluster \
     --services dotnet-framework-contrast-svc \
     --region <your-region>
   ```
   The service should show a status of "ACTIVE" and have running tasks.

2. **Access the Application:**
   If using Fargate with public IP, find the public IP in the ECS console:
   - Navigate to ECS > Clusters > windows-contrast-cluster
   - Click on the service (dotnet-framework-contrast-svc)
   - Click on the running task
   - Find the Public IP in the "Network" section
   - Open http://<public-ip> in a browser

3. **Verify Contrast Agent Connection:**
   - Check CloudWatch Logs:
     ```bash
     aws logs get-log-events \
       --log-group-name /ecs/dotnet-framework-contrast-sample \
       --log-stream-name <log-stream-name> \
       --region <your-region>
     ```
   - Look for logs indicating successful agent startup and Contrast UI connection.

   - Log in to your Contrast UI:
     - Navigate to the "Servers" tab to see if a new server entry appears
     - Navigate to the "Applications" tab to see if your application is listed
     - Generate traffic to the application to see vulnerability assessment results

## Troubleshooting

If you encounter issues, check the following:

- **Task Fails to Start:**
  - Check ECS service events
  - Check task stopped reason
  - Verify IAM roles have correct permissions
  - Ensure OS family in task definition matches container base OS
  - Verify VPC/subnet networking configuration

- **Agent Connectivity Issues:**
  - Validate credentials in Secrets Manager
  - Check container logs in CloudWatch
  - Verify security group allows outbound connections to Contrast UI
  - Ensure task execution role has permission to access the secret

- **Application Not Appearing in Contrast UI:**
  - Generate traffic to the application
  - Check agent logs for connection errors
  - Verify Contrast account status and permissions

See the troubleshooting.md file for more detailed troubleshooting steps.
