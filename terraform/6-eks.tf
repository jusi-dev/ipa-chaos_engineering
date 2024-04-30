resource "aws_iam_role" "role-chaos-ipa-eks-assume" {
  name = "role-chaos-ipa-test-eks-assume"

  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.role-chaos-ipa-eks-assume.name
}

resource "aws_eks_cluster" "cluster" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.role-chaos-ipa-eks-assume.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private-us-west-2a.id,
      aws_subnet.private-us-west-2b.id,
      aws_subnet.public-us-west-2a.id,
      aws_subnet.public-us-west-2b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.amazon-eks-cluster-policy]
}

resource "aws_eks_addon" "cloud-watch-addon" {
  addon_name   = "amazon-cloudwatch-observability"
  cluster_name = var.cluster_name

  depends_on = [ aws_eks_cluster.cluster ]
}

// Update Kubeconfig
resource "null_resource" "kubectl" {
    provisioner "local-exec" {
        command = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}"
    }

    depends_on = [aws_eks_cluster.cluster]
}

resource "kubernetes_namespace" "application-ns" {
  metadata {
    annotations = {
      name = "ns-chaos-ipa-test-application"
      # "instrumentation.opentelemetry.io/inject-java" = "true"
    }

    name = "ns-chaos-ipa-test-application"
  }

  depends_on = [null_resource.kubectl, aws_eks_cluster.cluster]
}

resource "kubernetes_namespace" "chaos-mesh-ns" {
  metadata {
    annotations = {
      name = "ns-chaos-ipa-test-chaos-mesh"
    }

    name = "ns-chaos-ipa-test-chaos-mesh"
  }

  depends_on = [null_resource.kubectl, aws_eks_cluster.cluster]
}

