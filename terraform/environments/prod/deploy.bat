@echo off
REM Production Environment Deployment Script for Windows
echo Deploying to Production Environment...

REM Set AWS Profile (optional - adjust as needed)
REM set AWS_PROFILE=prod

REM Initialize Terraform
echo Initializing Terraform...
terraform init

REM Plan the deployment
echo Planning deployment...
terraform plan -var-file="terraform.tfvars" -out=tfplan

REM Apply if plan looks good
echo Ready to apply. Review the plan above.
echo Run 'terraform apply tfplan' to proceed with deployment.
echo Run 'terraform destroy -var-file="terraform.tfvars"' to destroy resources.
pause