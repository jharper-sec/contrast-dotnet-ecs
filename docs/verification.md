# Verification Guide

This guide provides steps to verify that the Contrast Security .NET Framework agent has been successfully deployed and is operational in your AWS ECS environment.

## Verification Steps

### 1. Verify ECS Task Status

First, confirm that the ECS task is running correctly:

```bash
# Using AWS CLI
aws ecs list-tasks \
  --cluster windows-contrast-cluster \
  --service-name dotnet-framework-contrast-svc \
  --region <your-region>

# Get detailed task information
aws ecs describe-tasks \
  --cluster windows-contrast-cluster \
  --tasks <task-arn-from-previous-output> \
  --region <your-region>
```

The task should have:
- `lastStatus` of "RUNNING"
- All containers showing `lastStatus` of "RUNNING"
- No error messages in the `stoppedReason` field

### 2. Verify Container Logs

Check the container logs in CloudWatch to confirm the application and Contrast agent are operating correctly:

```bash
# Get log stream names
aws logs describe-log-streams \
  --log-group-name /ecs/dotnet-framework-contrast-sample \
  --region <your-region>

# View logs
aws logs get-log-events \
  --log-group-name /ecs/dotnet-framework-contrast-sample \
  --log-stream-name <log-stream-name> \
  --region <your-region>
```

Look for:
- IIS startup messages
- Contrast agent initialization messages
- Connection attempts to the Contrast UI
- Successful authentication confirmation

Example of positive agent initialization logs:
```
info: Contrast .NET Framework Agent vX.X.X starting
info: Agent connecting to https://app.contrastsecurity.com/Contrast
info: Agent successfully authenticated
info: Agent communicating on secure channel to Contrast UI
info: Agent registering server 'ecs-windows-container-XXXXX'
info: Detecting ASP.NET applications
info: Application 'dotnet-framework-ecs-demo' detected
```

### 3. Access the Application

Access the deployed application to generate traffic for analysis:

#### For Fargate with Public IP:

1. Get the public IP:
   ```bash
   aws ecs describe-tasks \
     --cluster windows-contrast-cluster \
     --tasks <task-arn> \
     --region <your-region> \
     --query "tasks[0].attachments[0].details[?name=='publicIp'].value" \
     --output text
   ```

2. Open a browser and navigate to `http://<public-ip>/`

#### For EC2 or Load Balancer:

1. Access via the EC2 instance public IP and mapped port, or via the load balancer DNS name.

2. Once loaded, browse several pages of the application to generate traffic for the Contrast agent to analyze.

### For Terraform Deployments

If you used Terraform for deployment, you can use Terraform outputs to get resource information:

```bash
# Get the ECR repository URL
terraform output -raw repository_url

# Get the ECS cluster name
terraform output -raw cluster_name

# Get the ECS service name
terraform output -raw service_name
```

### 4. Verify in Contrast UI

Log in to your Contrast Security account and verify:

#### Server Tab
1. Navigate to "Servers" in the Contrast UI
2. Look for a server named similar to "ecs-windows-container-XXXXX" or your custom server name
3. Verify the server status shows as "Active"
4. Verify that server details include:
   - Server type: IIS
   - .NET Framework version
   - Agent version
   - Operating System: Windows Server 

#### Application Tab
1. Navigate to "Applications" in the Contrast UI
2. Look for an application named "dotnet-framework-ecs-demo" or your custom application name
3. Verify the application status shows as "Active"
4. Click on the application to see:
   - Routes detected in your application
   - Libraries used by the application
   - Any vulnerabilities detected
   - Protection rules (if using RASP)

### 5. Generate Test Traffic for Analysis

To trigger the agent's analysis capabilities:

1. Browse various pages and features of your application
2. If your application has forms, submit test data
3. Try different input patterns to exercise various code paths
4. For a more thorough test, you can use tools like Postman or automated test scripts

After generating traffic, check the Contrast UI again to see:
- New routes detected
- Updated library inventory
- Any security findings or vulnerabilities detected

### 6. Verify Secure Credential Handling

Confirm that credentials are being securely managed:

1. Verify no sensitive values in Docker image:
   ```bash
   # Pull the image locally for inspection
   docker pull <ecr-repo-uri>:latest
   
   # Check environment variables - should NOT contain Contrast credentials
   docker inspect <ecr-repo-uri>:latest | grep -A 20 "Env"
   ```

2. Verify credentials are coming from Secrets Manager:
   ```bash
   # Check the task definition
   aws ecs describe-task-definition \
     --task-definition dotnet-framework-contrast-sample \
     --region <your-region>
   ```
   Look for the `secrets` section in the container definition, confirming it references the correct Secrets Manager ARN.

## Success Criteria

The deployment is considered successful when:

1. ✅ ECS task is running with status "RUNNING"
2. ✅ Container logs show successful agent initialization and connectivity
3. ✅ The application is accessible and functional
4. ✅ A server appears in the Contrast UI
5. ✅ An application appears in the Contrast UI
6. ✅ Agent is successfully analyzing traffic (routes appearing, libraries inventoried)
7. ✅ Credentials are managed securely via Secrets Manager
