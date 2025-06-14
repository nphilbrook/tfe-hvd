locals {
  primary_region       = "us-west-2"
  friendly_name_prefix = "primary"
  common_tags = {
    App                = "tfe"
    Env                = "sbx"
    Owner              = "nick.philbrook@hashicorp.com"
    "created-by"       = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
  }
  tfe_fqdn         = "tfe.nick-philbrook.sbx.hashidemos.io"
  tfe_pi_fqdn      = "tfe-pi.nick-philbrook.sbx.hashidemos.io"
  juniper_junction = ["69.53.107.107/32"]
  it_me            = "arn:aws:iam::590184029125:role/aws_nick.philbrook_test-developer"
  r53_zone         = "nick-philbrook.sbx.hashidemos.io"
  vpc_cidr         = "10.8.0.0/16"
  ngw_cidrs        = [for ip in module.tfe_prereqs_w2.ngw_public_ips : "${ip}/32"]
}
