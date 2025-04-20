#!/bin/bash
# Script to create AWS Secrets Manager secret for Contrast Security credentials

# Configuration variables - replace with your actual values
AWS_REGION="us-east-1"
SECRET_NAME="contrast-agent-credentials"
CONTRAST_API_URL="https://app.contrastsecurity.com/Contrast"
CONTRAST_API_KEY="your_api_key"
CONTRAST_API_SERVICE_KEY="your_service_key"
CONTRAST_API_USER_NAME="your_agent_user"

# Option to use Connection Token instead (agent version 51.0.40+)
# CONTRAST_API_TOKEN="your_connection_token"

# Confirm before proceeding
echo "This script will create a secret named '$SECRET_NAME' in AWS Secrets Manager."
echo "The secret will contain Contrast Security API credentials."
read -p "Continue? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Create JSON for the secret
if [[ -n "$CONTRAST_API_TOKEN" ]]; then
  # Using Connection Token
  SECRET_JSON="{\"CONTRAST__API__URL\":\"$CONTRAST_API_URL\",\"CONTRAST__API__TOKEN\":\"$CONTRAST_API_TOKEN\"}"
else
  # Using API Keys
  SECRET_JSON="{\"CONTRAST__API__URL\":\"$CONTRAST_API_URL\",\"CONTRAST__API__API_KEY\":\"$CONTRAST_API_KEY\",\"CONTRAST__API__SERVICE_KEY\":\"$CONTRAST_API_SERVICE_KEY\",\"CONTRAST__API__USER_NAME\":\"$CONTRAST_API_USER_NAME\"}"
fi

# Create the secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --description "Contrast Security .NET Framework agent credentials" \
  --secret-string "$SECRET_JSON" \
  --region "$AWS_REGION"

if [ $? -eq 0 ]; then
  echo "Secret '$SECRET_NAME' created successfully."
  echo "ARN: arn:aws:secretsmanager:$AWS_REGION:$(aws sts get-caller-identity --query 'Account' --output text):secret:$SECRET_NAME"
  echo ""
  echo "Note: This secret will be referenced by the Terraform configuration."
  echo "Make sure the contrast_secret_name variable in terraform.tfvars matches this secret name."
else
  echo "Failed to create secret."
  exit 1
fi
