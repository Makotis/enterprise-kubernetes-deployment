# Production Environment

This directory contains the Terraform configuration for the **Production** environment.

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform installed (version >= 1.0)
3. S3 bucket for state storage: `enterprise-terraform-state-prod`
4. DynamoDB table for state locking: `terraform-state-lock-prod`

## Usage

### Initialize and Deploy
```bash
# On Linux/Mac
./deploy.sh

# On Windows
deploy.bat
```

### Manual Commands
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"

# Destroy infrastructure
terraform destroy -var-file="terraform.tfvars"
```

## Configuration

- **Environment**: Production
- **VPC CIDR**: 10.0.0.0/16
- **EKS Cluster**: enterprise-eks-prod
- **Node Instance Types**: t2.xlarge
- **RDS Instance**: db.r5.large

## Security Notes

- All resources are tagged for production environment
- State is stored remotely in S3 with encryption
- DynamoDB table provides state locking for team collaboration