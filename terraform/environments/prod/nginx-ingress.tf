# NGINX Ingress Configuration

# Note: The actual deployment of NGINX Ingress Controller will be done via Helm
# This can be uncommented after EKS cluster is created and Helm provider is configured

# resource "helm_release" "nginx_ingress" {
#   name       = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   chart      = "ingress-nginx"
#   namespace  = "ingress-nginx"
#   version    = "4.7.1"
#   
#   create_namespace = true
#
#   values = [
#     file("${path.module}/Values/nginx-ingress.yaml")
#   ]
#
#   set {
#     name  = "controller.service.type"
#     value = "LoadBalancer"
#   }
#
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
#     value = "nlb"
#   }
#
#   set {
#     name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
#     value = "true"
#   }
#
#   depends_on = [
#     aws_eks_cluster.main,
#     aws_eks_node_group.main
#   ]
# }