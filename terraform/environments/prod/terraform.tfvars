# Production Environment Variables
environment = "prod"
region = "us-west-2"

# EKS Configuration
cluster_name = "enterprise-eks-prod"
kubernetes_version = "1.29"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

# Node Group Configuration
node_group_name = "enterprise-nodes-prod"
instance_types = ["t2.xlarge"]
desired_capacity = 3
max_capacity = 10
min_capacity = 1

# RDS Configuration
db_instance_class = "db.r5.large"
db_name = "enterprise_prod"
db_username = "dbadmin"

# Tags
common_tags = {
  Environment = "production"
  Project     = "enterprise-deployment"
  ManagedBy   = "terraform"
}