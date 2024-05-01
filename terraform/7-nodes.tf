resource "aws_iam_role" "role-chaos-ipa-test-nodes-assume" {
  name = "role-chaos-ipa-test-nodes-assume"

  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.role-chaos-ipa-test-nodes-assume.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.role-chaos-ipa-test-nodes-assume.name
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-container-registry-read-only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.role-chaos-ipa-test-nodes-assume.name
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-cloud-watch-agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.role-chaos-ipa-test-nodes-assume.name
}

resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.cluster.name
  version         = var.cluster_version
  node_group_name = "eks-chaos-ipa-ng-t4gsmall-test"
  node_role_arn   = aws_iam_role.role-chaos-ipa-test-nodes-assume.arn

  ami_type = "AL2_ARM_64"

  subnet_ids = [
    aws_subnet.private-us-west-2a.id,
    aws_subnet.private-us-west-2b.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t4g.medium"]

  tags = {
    Name = "eks-chaos-ipa-ng-t4gsmall-test"
  }

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon-eks-worker-node-policy,
    aws_iam_role_policy_attachment.amazon-eks-cni-policy,
    aws_iam_role_policy_attachment.amazon-ec2-container-registry-read-only,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}