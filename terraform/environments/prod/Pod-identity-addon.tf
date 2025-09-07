# Pod Identity Agent Configuration

# EKS Add-on for Pod Identity Agent
resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.0.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-pod-identity-agent"
  })

  depends_on = [aws_eks_node_group.main]
}

# Note: Pod Identity is a newer alternative to IRSA (IAM Roles for Service Accounts)
# It simplifies the process of associating IAM roles with Kubernetes service accounts
# After enabling this add-on, you can create pod identity associations like:
#
# resource "aws_eks_pod_identity_association" "example" {
#   cluster_name    = aws_eks_cluster.main.name
#   namespace       = "default"
#   service_account = "my-service-account"
#   role_arn        = aws_iam_role.example.arn
# }