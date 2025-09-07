# Secrets Store CSI Driver Configuration

# IAM Role for AWS Secrets Manager CSI Driver
resource "aws_iam_role" "secrets_store_csi_driver" {
  name = "${var.environment}-secrets-store-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:secrets-store-csi-driver"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-secrets-store-csi-driver-role"
  })
}

# IAM Policy for Secrets Manager access
resource "aws_iam_policy" "secrets_store_csi_driver" {
  name        = "${var.environment}-SecretsStoreCSIDriverPolicy"
  description = "IAM policy for Secrets Store CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:*:secret:${var.environment}/*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-secrets-store-csi-policy"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "secrets_store_csi_driver" {
  policy_arn = aws_iam_policy.secrets_store_csi_driver.arn
  role       = aws_iam_role.secrets_store_csi_driver.name
}

# Note: AWS Secrets Manager CSI Driver add-on is not supported in Kubernetes 1.29
# Use Helm deployment instead or install manually after cluster creation

# Helm deployment option (uncomment after EKS cluster is created and Helm provider is configured)
# resource "helm_release" "secrets_store_csi_driver" {
#   name       = "secrets-store-csi-driver"
#   repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
#   chart      = "secrets-store-csi-driver"
#   namespace  = "kube-system"
#   version    = "1.4.0"
#
#   set {
#     name  = "syncSecret.enabled"
#     value = "true"
#   }
#
#   set {
#     name  = "enableSecretRotation"
#     value = "true"
#   }
#
#   depends_on = [aws_eks_node_group.main]
# }
#
# resource "helm_release" "aws_secrets_manager_csi_provider" {
#   name       = "secrets-store-csi-driver-provider-aws"
#   repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
#   chart      = "secrets-store-csi-driver-provider-aws"
#   namespace  = "kube-system"
#   version    = "0.3.4"
#
#   depends_on = [helm_release.secrets_store_csi_driver]
# }