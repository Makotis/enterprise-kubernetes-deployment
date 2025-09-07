# Local Values Configuration

locals {
  # Common naming prefix
  name_prefix = "${var.environment}-${random_id.suffix.hex}"
  
  # Common tags that will be applied to all resources
  common_tags = merge(var.common_tags, {
    Environment   = var.environment
    ManagedBy     = "terraform"
    Project       = "enterprise-kubernetes-deployment"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
    Region        = var.region
  })

  # EKS cluster tags
  eks_cluster_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  # Subnet tags for load balancer discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # Security group rules
  node_security_group_rules = {
    ingress_self = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups"
      protocol                     = "tcp"
      from_port                    = 443
      to_port                      = 443
      type                         = "ingress"
      source_cluster_security_group = true
    }
    
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                     = "tcp"
      from_port                    = 10250
      to_port                      = 10250
      type                         = "ingress"
      source_cluster_security_group = true
    }
    
    egress_all = {
      description = "All outbound traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}