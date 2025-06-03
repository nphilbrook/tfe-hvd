resource "aws_eks_access_entry" "tfe_cluster_human" {
  cluster_name  = module.tfe.eks_cluster_name
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = module.tfe.eks_cluster_name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}

resource "aws_eks_access_policy_association" "tfe_pi_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = module.tfe_pi.eks_cluster_name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}
