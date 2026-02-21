locals {
  primary_region       = "us-west-2"
  secondary_region     = "us-east-2"
  friendly_name_prefix = "primary"
  common_tags = {
    App                = "tfe"
    Env                = "sbx"
    Owner              = "nick.philbrook@hashicorp.com"
    "created-by"       = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
  }

  # DEPRECATED
  tfe_fqdn          = "tfe.nick-philbrook.sbx.hashidemos.io"
  tfe_pi_fqdn       = "tfe-pi.nick-philbrook.sbx.hashidemos.io"
  tfe_irsa_new_fqdn = "tfe-irsa-new.nick-philbrook.sbx.hashidemos.io"
  tfe_pi_byo_fqdn   = "tfe-pi-byo.nick-philbrook.sbx.hashidemos.io"
  tfe_byo_mixed     = "tfe-pi-byo-mixed.nick-philbrook.sbx.hashidemos.io"
  tfe_mixed         = "tfe-mixed.nick-philbrook.sbx.hashidemos.io"
  # END DEPRECATED

  # CURRENT
  tfe_pi_new_fqdn = "tfe-pi-new.nick-philbrook.sbx.hashidemos.io"

  it_me     = data.aws_iam_session_context.human.issuer_arn
  r53_zone  = "nick-philbrook.sbx.hashidemos.io"
  ngw_cidrs = [for ip in module.prereqs.ngw_public_ips : "${ip}/32"]

  new_friendly_name_prefix = "new"
  new_vpc_cidr             = "10.9.0.0/16"
}
