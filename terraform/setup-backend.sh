#!/bin/bash

# Script to create S3 buckets and DynamoDB tables for Terraform backend

set -e

REGION="us-west-2"

echo "Setting up Terraform backend resources..."

# Create S3 buckets
echo "Creating S3 buckets..."
aws s3 mb s3://enterprise-terraform-state-prod --region $REGION
aws s3 mb s3://enterprise-terraform-state-stage --region $REGION

# Enable versioning
echo "Enabling versioning on S3 buckets..."
aws s3api put-bucket-versioning --bucket enterprise-terraform-state-prod --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning --bucket enterprise-terraform-state-stage --versioning-configuration Status=Enabled

# Enable encryption
echo "Enabling encryption on S3 buckets..."
aws s3api put-bucket-encryption --bucket enterprise-terraform-state-prod --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

aws s3api put-bucket-encryption --bucket enterprise-terraform-state-stage --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

# Block public access
echo "Blocking public access on S3 buckets..."
aws s3api put-public-access-block --bucket enterprise-terraform-state-prod --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
aws s3api put-public-access-block --bucket enterprise-terraform-state-stage --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB tables for state locking
echo "Creating DynamoDB tables for state locking..."
aws dynamodb create-table \
  --table-name terraform-state-lock-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --region $REGION

aws dynamodb create-table \
  --table-name terraform-state-lock-stage \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
  --region $REGION

echo "Waiting for DynamoDB tables to be active..."
aws dynamodb wait table-exists --table-name terraform-state-lock-prod --region $REGION
aws dynamodb wait table-exists --table-name terraform-state-lock-stage --region $REGION

echo "Backend setup complete!"
echo ""
echo "Created resources:"
echo "- S3 bucket: enterprise-terraform-state-prod"
echo "- S3 bucket: enterprise-terraform-state-stage"
echo "- DynamoDB table: terraform-state-lock-prod"
echo "- DynamoDB table: terraform-state-lock-stage"
echo ""
echo "You can now run 'terraform init' in your environment directories."