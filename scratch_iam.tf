resource "aws_iam_role" "tfe_pi" {
  name        = "pi-tfe-eks-irsa-role-scratch"
  path        = "/"
  description = "IAM role for TFE PI."

  assume_role_policy = data.aws_iam_policy_document.tfe_pi_assume_role.json

}

data "aws_iam_policy_document" "tfe_pi_assume_role" {
  statement {
    sid     = "TfePiAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "tfe_pi_s3" {
  statement {
    sid    = "TfePiAllowS3"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "tfe_pi_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.tfe_pi_s3.json
  ]
}

resource "aws_iam_policy" "tfe_pi" {
  name   = "pi-tfe-eks-irsa-policy-scratch"
  policy = data.aws_iam_policy_document.tfe_pi_combined.json
}

resource "aws_iam_role_policy_attachment" "tfe_pi" {
  role       = aws_iam_role.tfe_pi.name
  policy_arn = aws_iam_policy.tfe_pi.arn
}
