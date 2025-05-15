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
  juniper_junction = ["69.53.107.107/32"]
  it_me            = "arn:aws:iam::590184029125:role/aws_nick.philbrook_test-developer"
  r53_zone         = "nick-philbrook.sbx.hashidemos.io"
}
