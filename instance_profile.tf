data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["eks:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "bastion_policy" {
  name   = "bastion-policy"
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role" "bastion_role" {
  name               = "bastion-role"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_policy.arn
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_eks_access_entry" "tfe_cluster_user" {
  cluster_name  = module.tfe_new.eks_cluster_name
  principal_arn = aws_iam_role.bastion_role.arn
  type          = "STANDARD"

  tags = local.common_tags
}

resource "aws_eks_access_policy_association" "tfe_cluster_user" {
  access_scope {
    type       = "cluster"
    namespaces = []
  }

  cluster_name = module.tfe_new.eks_cluster_name

  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.bastion_role.arn
}

# resource "aws_eks_access_entry" "tfe_pi_cluster_user" {
#   cluster_name  = module.tfe_pi.eks_cluster_name
#   principal_arn = aws_iam_role.bastion_role.arn
#   type          = "STANDARD"

#   tags = local.common_tags
# }

# resource "aws_eks_access_policy_association" "tfe_pi_cluster_user" {
#   access_scope {
#     type       = "cluster"
#     namespaces = []
#   }

#   cluster_name = module.tfe_pi.eks_cluster_name

#   policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.bastion_role.arn
# }

# resource "aws_eks_access_entry" "tfe_pi_new_cluster_user" {
#   cluster_name  = module.tfe_pi_new.eks_cluster_name
#   principal_arn = aws_iam_role.bastion_role.arn
#   type          = "STANDARD"

#   tags = local.common_tags
# }

# resource "aws_eks_access_policy_association" "tfe_pi_new_cluster_user" {
#   access_scope {
#     type       = "cluster"
#     namespaces = []
#   }

#   cluster_name = module.tfe_pi_new.eks_cluster_name

#   policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.bastion_role.arn
# }

# resource "aws_eks_access_entry" "tfe_irsa_new_cluster_user" {
#   cluster_name  = module.tfe_irsa_new.eks_cluster_name
#   principal_arn = aws_iam_role.bastion_role.arn
#   type          = "STANDARD"

#   tags = local.common_tags
# }

# resource "aws_eks_access_policy_association" "tfe_irsa_new_cluster_user" {
#   access_scope {
#     type       = "cluster"
#     namespaces = []
#   }

#   cluster_name = module.tfe_irsa_new.eks_cluster_name

#   policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.bastion_role.arn
# }

# resource "aws_eks_access_entry" "tfe_byo_cluster_user" {
#   cluster_name  = aws_eks_cluster.existing.name
#   principal_arn = aws_iam_role.bastion_role.arn
#   type          = "STANDARD"

#   tags = local.common_tags
# }

# resource "aws_eks_access_policy_association" "tfe_byo_cluster_user" {
#   access_scope {
#     type       = "cluster"
#     namespaces = []
#   }

#   cluster_name = aws_eks_cluster.existing.name

#   policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.bastion_role.arn
# }

# resource "aws_eks_access_entry" "tfe_byo_mixed_cluster_user" {
#   cluster_name  = aws_eks_cluster.existing_mixed.name
#   principal_arn = aws_iam_role.bastion_role.arn
#   type          = "STANDARD"

#   tags = local.common_tags
# }

# resource "aws_eks_access_policy_association" "tfe_byo_cluster_user_mixed" {
#   access_scope {
#     type       = "cluster"
#     namespaces = []
#   }

#   cluster_name = aws_eks_cluster.existing_mixed.name

#   policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.bastion_role.arn
# }

# resource "aws_eks_access_entry" "tfe_new_mixed_cluster_user" {
#   cluster_name  = module.tfe_mixed_new.eks_cluster_name
#   principal_arn = aws_iam_role.bastion_role.arn
#   type          = "STANDARD"

#   tags = local.common_tags
# }

# resource "aws_eks_access_policy_association" "tfe_new_cluster_user_mixed" {
#   access_scope {
#     type       = "cluster"
#     namespaces = []
#   }

#   cluster_name = module.tfe_mixed_new.eks_cluster_name

#   policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_iam_role.bastion_role.arn
# }

