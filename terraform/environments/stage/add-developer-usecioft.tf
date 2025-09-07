# Developer User Configuration

# Developer IAM Group
resource "aws_iam_group" "developers" {
  name = "${var.environment}-developers"
  path = "/"
}

# Developer IAM Policy for EKS access
resource "aws_iam_policy" "developer_eks_access" {
  name        = "${var.environment}-DeveloperEKSAccess"
  description = "Policy for developer access to EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = aws_eks_cluster.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-developer-eks-policy"
  })
}

# Attach policy to developers group
resource "aws_iam_group_policy_attachment" "developer_eks_access" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.developer_eks_access.arn
}

# Example developer user (commented out - create as needed)
# resource "aws_iam_user" "developer" {
#   name = "${var.environment}-developer-user"
#   path = "/"
#   
#   tags = merge(var.common_tags, {
#     Name = "${var.environment}-developer-user"
#   })
# }

# Add user to developers group (commented out - create as needed)
# resource "aws_iam_user_group_membership" "developer" {
#   user = aws_iam_user.developer.name
#   groups = [aws_iam_group.developers.name]
# }

# Note: After creating users, update the aws-auth ConfigMap in rbac.tf
# to grant appropriate Kubernetes RBAC permissions