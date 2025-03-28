module "tfe_prereqs" {
  source = "github.com/hashicorp-services/terraform-aws-tfe-prereqs?ref=a2079f4e2c658ed2b75254c522bbc7be0c1ec4a4"

  # --- Common --- #
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags

  # --- Networking --- #
  create_vpc              = var.create_vpc
  vpc_cidr                = var.vpc_cidr
  lb_subnet_cidrs_public  = var.lb_subnet_cidrs_public
  lb_subnet_cidrs_private = var.lb_subnet_cidrs_private
  compute_subnet_cidrs    = var.compute_subnet_cidrs
  db_subnet_cidrs         = var.db_subnet_cidrs
  redis_subnet_cidrs      = var.redis_subnet_cidrs
  ngw_subnet_cidrs        = var.ngw_subnet_cidrs

  # --- Bastion --- #
  create_bastion                 = var.create_bastion
  bastion_instance_type          = var.bastion_instance_type
  bastion_ec2_keypair_name       = var.bastion_ec2_keypair_name
  bastion_cidr_allow_ingress_ssh = var.bastion_cidr_allow_ingress_ssh

  # --- TLS certificates --- #
  create_tls_certs                  = var.create_tls_certs
  tls_cert_fqdn                     = var.tls_cert_fqdn
  tls_cert_email_address            = var.tls_cert_email_address
  tls_cert_route53_public_zone_name = var.tls_cert_route53_public_zone_name
  create_local_cert_files           = var.create_local_cert_files

  # --- Secrets Manager --- #
  tfe_database_password_secret_value  = var.tfe_database_password_secret_value
  tfe_redis_password_secret_value     = var.tfe_redis_password_secret_value
  tfe_secrets_manager_replica_regions = var.tfe_secrets_manager_replica_regions


  # --- CloudWatch (optional) --- #
  create_cloudwatch_log_group = var.create_cloudwatch_log_group
  cloudwatch_log_group_name   = var.cloudwatch_log_group_name

  # --- KMS (optional) --- #
  create_kms_cmk = var.create_kms_cmk
  kms_cmk_alias  = var.kms_cmk_alias
}
