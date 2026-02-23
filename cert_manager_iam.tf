#------------------------------------------------------------------------------
# IAM Role for cert-manager (Route53 DNS-01 validation)
# Uses EKS Pod Identity (consistent with how TFE and LB controller are wired).
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "cert_manager_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
  }
}

resource "aws_iam_role" "cert_manager" {
  name               = "${local.new_friendly_name_prefix}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.cert_manager_assume_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cert_manager_route53" {
  # Required to poll the status of a submitted DNS change
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:${data.aws_partition.current.partition}:route53:::change/*"]
  }

  # Scoped to the single public zone used for ACME DNS-01 challenges
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:route53:::hostedzone/${data.aws_route53_zone.public_zone.zone_id}"
    ]
  }

  # cert-manager needs this to discover the hosted zone by domain name
  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cert_manager_route53" {
  name        = "${local.new_friendly_name_prefix}-cert-manager-route53"
  description = "Allows cert-manager to manage Route53 records for ACME DNS-01 validation"
  policy      = data.aws_iam_policy_document.cert_manager_route53.json
  tags        = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cert_manager_route53" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager_route53.arn
}

#------------------------------------------------------------------------------
# EKS Pod Identity association
# Binds the IAM role to the cert-manager Kubernetes ServiceAccount.
# The ServiceAccount name and namespace match the cert-manager Helm chart defaults.
#------------------------------------------------------------------------------
resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name    = module.tfe_new.eks_cluster_name
  namespace       = "cert-manager"
  service_account = "cert-manager"
  role_arn        = aws_iam_role.cert_manager.arn
  tags            = local.common_tags
}
