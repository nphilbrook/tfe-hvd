module "tfe_prereqs_w2" {
  source = "git@github.com:nphilbrook/terraform-aws-tfe-prereqs?ref=nphilbrook_git_ssh"

  # --- Common --- #
  friendly_name_prefix = "tfe"
  common_tags          = {
  App   = "tfe"
  Env   = "sbx"
    Owner = "nick.philbrook@hashicorp.com"
    "created-by" = "terraform"
    "source_workspace" = var.TFC_WORKSPACE_SLUG
}

  # --- Networking --- #
  create_vpc              = true
  vpc_cidr                = "10.8.0.0/16"
  lb_subnet_cidrs_public  = ["10.8.0.0/24", "10.8.1.0/24", "10.8.2.0/24"]
  lb_subnet_cidrs_private = ["10.8.3.0/24", "10.8.4.0/24", "10.8.5.0/24"]
  compute_subnet_cidrs    = ["10.8.6.0/24", "10.8.7.0/24", "10.8.8.0/24"]
  db_subnet_cidrs         = ["10.8.9.0/26", "10.8.9.64/26", "10.8.9.128/26"]
  redis_subnet_cidrs      = ["10.8.10.0/26", "10.8.10.64/26", "10.8.10.128/26"]
  ngw_subnet_cidrs        = ["10.8.11.0/26", "10.8.11.64/26", "10.8.11.128/26"]

  # --- Bastion --- #
  create_bastion                 = true
  bastion_instance_type          = "t3a.small"
  bastion_ec2_keypair_name       = "terraform-key"
  bastion_cidr_allow_ingress_ssh = ["69.53.107.107/32"]

  # --- TLS certificates --- #
  create_tls_certs                  = true
  tls_cert_fqdn                     = "tfe.philbrook.sbx.hashidemos.io"
  tls_cert_email_address            = "nick.philbrook@hashicorp.com"
  tls_cert_route53_public_zone_name = "philbrook.sbx.hashidemos.io"
  create_local_cert_files           = true

  # --- Secrets Manager --- #
  tfe_database_password_secret_value  = var.tfe_database_password_secret_value
  tfe_redis_password_secret_value     = var.tfe_redis_password_secret_value
  tfe_secrets_manager_replica_regions = toset(["us-east-2"])

  # --- CloudWatch (optional) --- #
  create_cloudwatch_log_group = true
  cloudwatch_log_group_name   = "tfe-logs"
}
