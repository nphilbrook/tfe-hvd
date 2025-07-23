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

resource "aws_eks_access_entry" "tfe_pi_cluster_human" {
  cluster_name  = module.tfe_pi.eks_cluster_name
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
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

resource "aws_eks_access_entry" "tfe_pi_new_cluster_human" {
  cluster_name  = module.tfe_pi_new.eks_cluster_name
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_pi_new_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = module.tfe_pi_new.eks_cluster_name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}

resource "aws_eks_access_entry" "tfe_irsa_new_cluster_human" {
  cluster_name  = module.tfe_irsa_new.eks_cluster_name
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_irsa_new_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = module.tfe_irsa_new.eks_cluster_name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}

resource "aws_eks_access_entry" "tfe_pi_byo_cluster_human" {
  cluster_name  = "existing-cluster"
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_pi_byo_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = "existing-cluster"

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}

resource "aws_eks_access_entry" "tfe_byo_mixed_cluster_human" {
  cluster_name  = "existing-cluster-mixed"
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_byo_mixed_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = "existing-cluster-mixed"

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}

resource "aws_eks_access_entry" "tfe_mixed_new_cluster_human" {
  cluster_name  = module.tfe_mixed_new.eks_cluster_name
  principal_arn = local.it_me
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_mixed_new_cluster_human" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = module.tfe_mixed_new.eks_cluster_name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.it_me
}

