
module "tfe_prereqs_w2" {
  source = "git@github.com:nphilbrook/terraform-aws-tfe-prereqs?ref=nphilbrook_sgs_iam_profiles"
  # source = "git@github.com:hashicorp-services/terraform-aws-tfe-prereqs?ref=7c212d0"
  # source = "/home/nphilbrook/repos/hvd/terraform-aws-tfe-prereqs"

  # --- Common --- #
  friendly_name_prefix = local.friendly_name_prefix
  common_tags          = local.common_tags

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
  create_bastion                     = true
  bastion_instance_type              = "t3a.small"
  bastion_ec2_keypair_name           = "acme-w2"
  bastion_cidr_allow_ingress_ssh     = local.juniper_junction
  bastion_additional_security_groups = [module.tfe.eks_cluster_security_group_id]
  bastion_iam_instance_profile       = aws_iam_instance_profile.bastion_profile.name

  # --- TLS certificates --- #
  create_tls_certs                  = true
  tls_cert_fqdn                     = local.tfe_fqdn
  tls_cert_email_address            = "nick.philbrook@hashicorp.com"
  tls_cert_route53_public_zone_name = "nick-philbrook.sbx.hashidemos.io"
  create_local_cert_files           = false

  # --- Secrets Manager --- #
  tfe_database_password_secret_value  = var.tfe_database_password_secret_value
  tfe_redis_password_secret_value     = var.tfe_redis_password_secret_value
  tfe_secrets_manager_replica_regions = toset(["us-east-2"])

  # --- CloudWatch (optional) --- #
  create_cloudwatch_log_group = true
  cloudwatch_log_group_name   = "tfe-logs"
}


module "tfe" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_pod_identity"
  # --- Common --- #
  friendly_name_prefix = local.friendly_name_prefix
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_fqdn
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id                               = module.tfe_prereqs_w2.vpc_id
  eks_subnet_ids                       = module.tfe_prereqs_w2.compute_subnet_ids
  rds_subnet_ids                       = module.tfe_prereqs_w2.db_subnet_ids
  redis_subnet_ids                     = module.tfe_prereqs_w2.redis_subnet_ids
  cidr_allow_ingress_tfe_443           = concat(local.juniper_junction, local.gh_v4_hook_ranges)
  cidr_allow_ingress_tfe_metrics_http  = local.juniper_junction
  cidr_allow_ingress_tfe_metrics_https = local.juniper_junction

  # --- IAM --- #
  create_eks_oidc_provider      = true
  create_aws_lb_controller_irsa = true
  create_tfe_eks_irsa           = true

  # --- EKS --- #
  create_eks_cluster                 = true
  eks_cluster_endpoint_public_access = false
  eks_cluster_public_access_cidrs    = null

  # --- Database --- #
  tfe_database_password_secret_arn = module.tfe_prereqs_w2.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.tfe_prereqs_w2.tfe_redis_password_secret_arn
}
