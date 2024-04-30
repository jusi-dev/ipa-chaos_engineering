provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.cluster.id]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.cluster.id
  }

  set {
    name  = "image.tag"
    value = "v2.4.2"
  }

  set {
    name  = "serviceAccount.name"
    value = "svcaccount-chaos-ipa-test-alb"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.role-chaos-ipa-test-alb.arn
  }

  depends_on = [
    aws_eks_node_group.private-nodes,
    aws_iam_role_policy_attachment.aws_load_balancer_controller_attach
  ]
}

resource "kubernetes_secret" "repo-secret" {
  metadata {
    name = "my-secret"
    namespace = kubernetes_namespace.application-ns.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry_server}" = {
          "username" = var.registry_username
          "password" = var.registry_password
          "email"    = var.registry_email
          "auth"     = base64encode("${var.registry_username}:${var.registry_password}")
        }
      }
    })
  }
}

resource "helm_release" "chaos-mesh-chart" {
  name  = "chaos-mesh"
  chart = "chaos-mesh"
  namespace = "ns-chaos-ipa-test-chaos-mesh"

  depends_on = [
    aws_eks_node_group.private-nodes,
    kubernetes_namespace.chaos-mesh-ns
  ]

}

resource "helm_release" "cinemaApp-chart" {
  name  = "cinemaapp"
  chart = "../helm-charts/cinemaApp"
  namespace = "ns-chaos-ipa-test-application"

  depends_on = [
    aws_eks_node_group.private-nodes,
    kubernetes_namespace.application-ns,
    kubernetes_secret.repo-secret
  ]
}
