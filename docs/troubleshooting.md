# Troubleshooting Guide

This guide provides solutions for common issues when deploying the Contrast Security .NET Framework agent on AWS ECS with Windows containers.

## ECS Task Fails to Start

### Problem: Task Remains in PENDING or Cycles Through STOPPED

#### Insufficient Resources

**Symptoms:**
- Task status shows STOPPED with reason "RESOURCE"
- ECS events mention resource constraints

**Solutions:**
- Increase task CPU/memory in the CloudFormation template
- For EC2 launch type, use larger instance types or add more instances
- Check CloudWatch metrics for the cluster to identify resource bottlenecks

#### OS Mismatch

**Symptoms:**
- Task fails with error "container runtime error: container failed to start"
- Task status shows STOPPED with a container engine error

**Solutions:**
- Ensure the `runtimePlatform.operatingSystemFamily` in the Task Definition exactly matches the Windows version of your container base image
- For the official .NET Framework 4.8 image, options are:
  - WINDOWS_SERVER_2019_CORE (for mcr.microsoft.com/dotnet/framework/aspnet:4.8 without year tags)
  - WINDOWS_SERVER_2022_CORE (for mcr.microsoft.com/dotnet/framework/aspnet:4.8-ltsc2022)
- Redeploy with the correct OS family parameter in the `deploy-ecs.sh` script

#### Networking Errors

**Symptoms:**
- Task fails with networking-related errors
- Task cannot pull the image from ECR

**Solutions:**
- Verify Security Groups allow necessary outbound traffic (HTTPS/443) to ECR, Secrets Manager, Contrast UI
- Check subnet route tables for proper internet access (NAT Gateway for private subnets)
- Consider setting up VPC Endpoints for ECR/Secrets Manager if using private subnets without NAT

#### IAM Permissions

**Symptoms:**
- Task fails with "unable to pull secrets" or "unable to pull image" errors
- Access denied messages in CloudTrail logs

**Solutions:**
- Verify the Task Execution Role (ecsTaskExecutionRole-WithSecretsAccess) has:
  - AmazonECSTaskExecutionRolePolicy managed policy
  - Inline policy for secretsmanager:GetSecretValue on the specific secret
  - Proper kms:Decrypt permission if using a custom KMS key
- Use IAM policy simulator to verify permissions

## Contrast Agent Connectivity Issues

### Problem: Agent Doesn't Connect to Contrast UI

#### Incorrect Credentials

**Symptoms:**
- Application runs but no Server/Application appears in Contrast UI
- Agent logs show authentication failures

**Solutions:**
- Check the values stored in AWS Secrets Manager
- Verify the secret keys exactly match what's expected (`CONTRAST__API__URL`, etc.)
- Confirm the Task Definition correctly maps the secret values to environment variables
- If updating credentials, redeploy the service with `--force-new-deployment`

#### Network Blocks

**Symptoms:**
- Agent logs show connection timeouts or network errors
- Application runs but agent cannot connect to Contrast UI

**Solutions:**
- Verify Security Group outbound rules allow HTTPS (port 443) to Contrast UI
- Check Network ACLs for restrictive rules
- If behind a corporate proxy, configure proxy settings in the agent configuration

#### SSL/TLS Interception

**Symptoms:**
- Agent logs show SSL/certificate errors like "UntrustedRoot"
- Security appliances might be intercepting SSL traffic

**Solutions:**
- Trust the proxy's CA certificate on the container
- Configure network to bypass SSL inspection for Contrast UI traffic
- For diagnostic purposes only, you can temporarily add `api.certificate.ignore_cert_errors: true` to the YAML

## Application Not Appearing in Contrast UI

### Server Exists but Application Doesn't Appear

**Symptoms:**
- Server appears in Contrast UI but no application is listed
- Agent logs show successful connection

**Solutions:**
- Generate sufficient traffic to the application by browsing different pages
- Verify that ASP.NET MVC on .NET Framework 4.8 is supported by your agent version
- Check agent logs for application detection messages

### User Permission Issues

**Symptoms:**
- Agent appears to connect but you can't see the server/application in the UI

**Solutions:**
- Verify your Contrast UI user has permissions for the Application Access Group
- Ask an administrator to grant access to the application
- Configure the agent to onboard to a specific group using `application.group` in the YAML

### Previously Archived Application

**Symptoms:**
- Agent connects but application doesn't report data

**Solutions:**
- Check if an application with the identical name was previously archived
- Either unarchive the existing application or configure a unique name using `application.name`

## CloudWatch Logs Access

To view detailed agent logs:

1. Find your task's log stream:
   ```bash
   aws logs describe-log-streams \
     --log-group-name /ecs/dotnet-framework-contrast-sample \
     --region <your-region>
   ```

2. View the logs:
   ```bash
   aws logs get-log-events \
     --log-group-name /ecs/dotnet-framework-contrast-sample \
     --log-stream-name <log-stream-name> \
     --region <your-region>
   ```

3. Look for entries from the Contrast agent, which will include:
   - Agent startup messages
   - Connection attempts to Contrast UI
   - Authentication status
   - Application detection and instrumentation

## Diagnostic Tools

If you need to perform additional diagnostics:

1. Enable ECS Exec (if not already enabled):
   ```bash
   aws ecs update-service \
     --cluster windows-contrast-cluster \
     --service dotnet-framework-contrast-svc \
     --enable-execute-command \
     --region <your-region>
   ```

2. Connect to a running task:
   ```bash
   aws ecs execute-command \
     --cluster windows-contrast-cluster \
     --task <task-id> \
     --container dotnet-app \
     --command "powershell" \
     --interactive \
     --region <your-region>
   ```

3. Once connected, you can:
   - Check environment variables: `Get-ChildItem Env: | Where-Object { $_.Name -like "CONTRAST*" -or $_.Name -like "COR*" }`
   - Verify Contrast files: `Get-ChildItem -Path C:\Contrast -Recurse | Select-Object FullName`
   - Check logs: `Get-Content C:\ContrastLogs\*`

## Terraform-Specific Issues

### Problem: Terraform Apply Fails

**Symptoms:**
- `terraform apply` command returns errors
- Resources fail to create

**Solutions:**
- Check Terraform logs for specific error messages
- Verify AWS credentials have appropriate permissions
- Run `terraform validate` to check for configuration errors
- Check for state lock issues with `terraform force-unlock` (use with caution)

### Problem: Resources Not Visible in AWS Console

**Symptoms:**
- Terraform reports success but resources aren't visible in AWS console

**Solutions:**
- Verify you're looking in the correct AWS region
- Check Terraform state with `terraform state list`
- Verify resource tags are correctly applied
