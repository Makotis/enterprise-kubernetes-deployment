#!/bin/bash

# Production Environment Deployment Script
echo "Deploying to Production Environment..."

# Set AWS Profile (optional - adjust as needed)
# export AWS_PROFILE=prod

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan the deployment
echo "Planning deployment..."
terraform plan -var-file="terraform.tfvars" -out=tfplan

# Apply if plan looks good
echo "Ready to apply. Review the plan above."
echo "Run 'terraform apply tfplan' to proceed with deployment."
echo "Run 'terraform destroy -var-file=\"terraform.tfvars\"' to destroy resources."