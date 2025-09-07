# Staging Environment Variables
environment = "stage"
region = "us-west-2"

# EKS Configuration
cluster_name = "enterprise-eks-stage"
kubernetes_version = "1.29"

# VPC Configuration
vpc_cidr = "10.1.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]

# Node Group Configuration
node_group_name = "enterprise-nodes-stage"
instance_types = ["t2.xlarge"]
desired_capacity = 2
max_capacity = 5
min_capacity = 1

# RDS Configuration
db_instance_class = "db.t3.micro"
db_name = "enterprise_stage"
db_username = "dbadmin"

# Tags
common_tags = {
  Environment = "staging"
  Project     = "enterprise-deployment"
  ManagedBy   = "terraform"
}