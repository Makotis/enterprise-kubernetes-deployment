# NATS Configuration

# Note: The actual deployment of NATS will be done via Helm
# This can be uncommented after EKS cluster is created and Helm provider is configured

# resource "helm_release" "nats" {
#   name       = "nats"
#   repository = "https://nats-io.github.io/k8s/helm/charts/"
#   chart      = "nats"
#   namespace  = "nats-system"
#   version    = "1.1.5"
#   
#   create_namespace = true
#
#   set {
#     name  = "config.cluster.enabled"
#     value = "true"
#   }
#
#   set {
#     name  = "config.cluster.replicas"
#     value = "3"
#   }
#
#   set {
#     name  = "config.jetstream.enabled"
#     value = "true"
#   }
#
#   set {
#     name  = "config.jetstream.fileStore.pvc.size"
#     value = "10Gi"
#   }
#
#   depends_on = [
#     aws_eks_cluster.main,
#     aws_eks_node_group.main
#   ]
# }