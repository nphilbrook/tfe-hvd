# Testing the non-deprecated version of the prereqs modules
module "cert" {
  source        = "git@github.com:hashicorp-services/terraform-acme-tls-aws?ref=main"
  tls_cert_fqdn = local.tfe_fqdn
  tls_cert_sans = [
    local.tfe_pi_fqdn, local.tfe_pi_new_fqdn, local.tfe_irsa_new_fqdn,
    local.tfe_pi_byo_fqdn, local.tfe_mixed, local.tfe_byo_mixed
  ]
  tls_cert_email_address   = "nick.philbrook@hashicorp.com"
  route53_public_zone_name = local.r53_zone
}

module "prereqs" {
  source = "git@github.com:hashicorp-services/terraform-aws-prereqs?ref=nphilbrook_qol_improvements"

  # --- Common --- #
  friendly_name_prefix = local.new_friendly_name_prefix
  common_tags          = local.common_tags

  # --- Networking --- #
  create_vpc                     = true
  vpc_cidr                       = local.new_vpc_cidr
  public_subnet_cidrs            = ["10.9.0.0/24", "10.9.1.0/24", "10.9.2.0/24"]
  private_subnet_cidrs           = ["10.9.8.0/21", "10.9.16.0/21", "10.9.24.0/21"]
  create_bastion                 = true
  bastion_ec2_keypair_name       = "acme-w2"
  bastion_cidr_allow_ingress_ssh = concat(var.juniper_junction, ["12.37.255.36/32"])

  # --- Secrets Manager Prereq Secrets --- #
  tfe_license_secret_value             = var.tfe_license_secret_value
  tfe_encryption_password_secret_value = var.tfe_encryption_password_secret_value
  tfe_database_password_secret_value   = var.tfe_database_password_secret_value
  tfe_redis_password_secret_value      = var.tfe_redis_password_secret_value

  # --- Cloudwatch Log Group --- #
  create_cloudwatch_log_group = true
}
