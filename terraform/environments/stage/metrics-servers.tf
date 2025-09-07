# Metrics Server Configuration

# Note: The actual deployment of Metrics Server will be done via Helm
# This can be uncommented after EKS cluster is created and Helm provider is configured

# resource "helm_release" "metrics_server" {
#   name       = "metrics-server"
#   repository = "https://kubernetes-sigs.github.io/metrics-server/"
#   chart      = "metrics-server"
#   namespace  = "kube-system"
#   version    = "3.11.0"
#
#   values = [
#     file("${path.module}/Values/metricss-servers.yaml")
#   ]
#
#   set {
#     name  = "args"
#     value = "{--cert-dir=/tmp,--secure-port=4443,--kubelet-preferred-address-types=InternalIP\\,ExternalIP\\,Hostname,--kubelet-use-node-status-port,--metric-resolution=15s}"
#   }
#
#   depends_on = [
#     aws_eks_cluster.main,
#     aws_eks_node_group.main
#   ]
# }