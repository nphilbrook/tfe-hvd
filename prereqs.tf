# Testing the non-deprecated version of the prereqs modules

module "cert" {
  source        = "git@github.com:nphilbrook/terraform-acme-tls-aws?ref=nphilbrook_sans"
  tls_cert_fqdn = local.tfe_fqdn
  tls_cert_sans = [
    local.tfe_pi_fqdn, local.tfe_pi_new_fqdn, local.tfe_irsa_new_fqdn,
    local.tfe_pi_byo_fqdn, local.tfe_mixed, local.tfe_byo_mixed
  ]
  tls_cert_email_address   = "nick.philbrook@hashicorp.com"
  route53_public_zone_name = local.r53_zone
}

