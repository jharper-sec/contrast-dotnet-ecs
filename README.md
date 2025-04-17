# Contrast Security .NET Framework Agent Deployment on AWS ECS with Windows Containers

This project demonstrates how to deploy an ASP.NET MVC application with the Contrast Security .NET Framework agent in a Windows Docker container on AWS Elastic Container Service (ECS).

## Overview

The repository contains everything needed to:
1. Set up a sample ASP.NET MVC application
2. Integrate the Contrast Security .NET agent into a Windows container
3. Deploy the containerized application to AWS ECS
4. Configure secure credential management using AWS Secrets Manager
5. Verify the deployment and agent functionality

## Repository Structure

- `src/` - Sample ASP.NET MVC application code
- `docker/` - Dockerfile and related configuration
- `aws/` - AWS configuration files
  - `cloudformation/` - CloudFormation templates for AWS resources
  - `terraform/` - Terraform configurations for AWS resources
  - `cli/` - Helper scripts for AWS CLI operations
- `docs/` - Additional documentation and guides

## Infrastructure Options

This repository provides two options for infrastructure deployment:
- **CloudFormation**: Templates for AWS CloudFormation
- **Terraform**: HCL configuration files for Terraform

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Docker Desktop for Windows with Windows containers enabled
- Contrast Security account with agent credentials
- Git

## Quick Start

1. Clone this repository
2. Follow the step-by-step instructions in `docs/deployment-guide.md`

## Security Notes

This project demonstrates secure practices for managing Contrast agent credentials:
- Credentials are stored in AWS Secrets Manager
- Credentials are injected at runtime via environment variables
- No sensitive information is hardcoded in the Docker image

## Resources

For detailed information about the Contrast Security .NET Framework agent and AWS ECS, refer to the following resources:
- [Contrast Security Documentation](https://docs.contrastsecurity.com/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
