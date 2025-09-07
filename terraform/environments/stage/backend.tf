# Staging Backend Configuration
terraform {
  backend "s3" {
    bucket         = "enterprise-terraform-state-stage"
    key            = "eks/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-stage"
  }
}