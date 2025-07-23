module "tfe_pi_new" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_pod_identity"
  # --- Common --- #
  friendly_name_prefix = "pi-new"
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_pi_new_fqdn
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id           = module.tfe_prereqs_w2.vpc_id
  eks_subnet_ids   = module.tfe_prereqs_w2.compute_subnet_ids
  rds_subnet_ids   = module.tfe_prereqs_w2.db_subnet_ids
  redis_subnet_ids = slice(module.tfe_prereqs_w2.redis_subnet_ids, 0, 2)
  cidr_allow_ingress_tfe_443 = concat([local.vpc_cidr, "${module.tfe_prereqs_w2.bastion_public_ip}/32"],
    local.juniper_junction,
    local.gh_v4_hook_ranges,
    local.ngw_cidrs
  )
  cidr_allow_ingress_tfe_metrics_http  = local.juniper_junction
  cidr_allow_ingress_tfe_metrics_https = local.juniper_junction

  # --- IAM --- #
  create_eks_oidc_provider              = false
  create_aws_lb_controller_irsa         = false
  create_tfe_eks_irsa                   = false
  create_tfe_eks_pod_identity           = true
  create_aws_lb_controller_pod_identity = true

  # --- EKS --- #
  create_eks_cluster                 = true
  eks_cluster_endpoint_public_access = false
  eks_cluster_public_access_cidrs    = null
  eks_nodegroup_instance_type        = "m7i.large"
  eks_nodegroup_scaling_config = {
    "desired_size" : 1,
    "max_size" : 2,
    "min_size" : 1
  }

  # --- Database --- #
  tfe_database_password_secret_arn = module.tfe_prereqs_w2.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false
  rds_aurora_replica_count         = 0
  rds_aurora_instance_class        = "db.r6i.large"

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.tfe_prereqs_w2.tfe_redis_password_secret_arn
  redis_node_type               = "cache.t4g.medium"
}

module "tfe_irsa_new" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_pod_identity"
  # --- Common --- #
  friendly_name_prefix = "irsa-new"
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_irsa_new_fqdn
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id           = module.tfe_prereqs_w2.vpc_id
  eks_subnet_ids   = module.tfe_prereqs_w2.compute_subnet_ids
  rds_subnet_ids   = module.tfe_prereqs_w2.db_subnet_ids
  redis_subnet_ids = slice(module.tfe_prereqs_w2.redis_subnet_ids, 0, 2)
  cidr_allow_ingress_tfe_443 = concat([local.vpc_cidr, "${module.tfe_prereqs_w2.bastion_public_ip}/32"],
    local.juniper_junction,
    local.gh_v4_hook_ranges,
    local.ngw_cidrs
  )
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
  eks_nodegroup_instance_type        = "m7i.large"
  eks_nodegroup_scaling_config = {
    "desired_size" : 1,
    "max_size" : 2,
    "min_size" : 1
  }

  # --- Database --- #
  tfe_database_password_secret_arn = module.tfe_prereqs_w2.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false
  rds_aurora_replica_count         = 0
  rds_aurora_instance_class        = "db.r6i.large"

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.tfe_prereqs_w2.tfe_redis_password_secret_arn
  redis_node_type               = "cache.t4g.medium"
}

module "tfe_pi_byo" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_pod_identity"
  # --- Common --- #
  friendly_name_prefix = "pi-byo"
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_pi_byo_fqdn
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id           = module.tfe_prereqs_w2.vpc_id
  eks_subnet_ids   = module.tfe_prereqs_w2.compute_subnet_ids
  rds_subnet_ids   = module.tfe_prereqs_w2.db_subnet_ids
  redis_subnet_ids = slice(module.tfe_prereqs_w2.redis_subnet_ids, 0, 2)
  cidr_allow_ingress_tfe_443 = concat([local.vpc_cidr, "${module.tfe_prereqs_w2.bastion_public_ip}/32"],
    local.juniper_junction,
    local.gh_v4_hook_ranges,
    local.ngw_cidrs
  )
  sg_allow_egress_from_tfe_lb = aws_security_group.tfe_eks_nodegroup_allow.id

  # --- IAM --- #
  create_eks_oidc_provider              = false
  create_aws_lb_controller_irsa         = false
  create_tfe_eks_irsa                   = false
  create_tfe_eks_pod_identity           = true
  create_aws_lb_controller_pod_identity = true
  existing_eks_cluster_name             = "existing-cluster"

  # --- EKS --- #
  create_eks_cluster = false

  # --- Database --- #
  tfe_database_password_secret_arn = module.tfe_prereqs_w2.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false
  rds_aurora_replica_count         = 0
  rds_aurora_instance_class        = "db.r6i.large"
  sg_allow_ingress_to_rds          = aws_security_group.tfe_eks_nodegroup_allow.id

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.tfe_prereqs_w2.tfe_redis_password_secret_arn
  redis_node_type               = "cache.t4g.medium"
  sg_allow_ingress_to_redis     = aws_security_group.tfe_eks_nodegroup_allow.id
}

module "tfe_byo_mixed" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_pod_identity"
  # --- Common --- #
  friendly_name_prefix = "byo-mixed"
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_pi_byo_mixed
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id           = module.tfe_prereqs_w2.vpc_id
  eks_subnet_ids   = module.tfe_prereqs_w2.compute_subnet_ids
  rds_subnet_ids   = module.tfe_prereqs_w2.db_subnet_ids
  redis_subnet_ids = slice(module.tfe_prereqs_w2.redis_subnet_ids, 0, 2)
  cidr_allow_ingress_tfe_443 = concat([local.vpc_cidr, "${module.tfe_prereqs_w2.bastion_public_ip}/32"],
    local.juniper_junction,
    local.gh_v4_hook_ranges,
    local.ngw_cidrs
  )
  sg_allow_egress_from_tfe_lb = aws_security_group.tfe_eks_nodegroup_allow_mixed.id

  # --- IAM --- #
  create_eks_oidc_provider              = true
  eks_oidc_provider_url                 = aws_eks_cluster.existing_mixed.identity[0].oidc[0].issuer
  create_aws_lb_controller_irsa         = true
  create_tfe_eks_irsa                   = false
  create_aws_lb_controller_pod_identity = false
  create_tfe_eks_pod_identity           = true
  existing_eks_cluster_name             = "existing-cluster-mixed"

  # --- EKS --- #
  create_eks_cluster = false

  # --- Database --- #
  tfe_database_password_secret_arn = module.tfe_prereqs_w2.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false
  rds_aurora_replica_count         = 0
  rds_aurora_instance_class        = "db.r6i.large"
  sg_allow_ingress_to_rds          = aws_security_group.tfe_eks_nodegroup_allow_mixed.id

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.tfe_prereqs_w2.tfe_redis_password_secret_arn
  redis_node_type               = "cache.t4g.medium"
  sg_allow_ingress_to_redis     = aws_security_group.tfe_eks_nodegroup_allow_mixed.id
}

module "tfe_mixed_new" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_pod_identity"
  # --- Common --- #
  friendly_name_prefix = "mixed-new"
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_mixed
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id           = module.tfe_prereqs_w2.vpc_id
  eks_subnet_ids   = module.tfe_prereqs_w2.compute_subnet_ids
  rds_subnet_ids   = module.tfe_prereqs_w2.db_subnet_ids
  redis_subnet_ids = slice(module.tfe_prereqs_w2.redis_subnet_ids, 0, 2)
  cidr_allow_ingress_tfe_443 = concat([local.vpc_cidr, "${module.tfe_prereqs_w2.bastion_public_ip}/32"],
    local.juniper_junction,
    local.gh_v4_hook_ranges,
    local.ngw_cidrs
  )
  cidr_allow_ingress_tfe_metrics_http  = local.juniper_junction
  cidr_allow_ingress_tfe_metrics_https = local.juniper_junction

  # --- IAM --- #
  create_eks_oidc_provider      = true
  create_aws_lb_controller_irsa = true
  create_tfe_eks_irsa           = true
  # create_aws_lb_controller_pod_identity = true
  # create_tfe_eks_pod_identity           = false

  # --- EKS --- #
  create_eks_cluster                 = true
  eks_cluster_endpoint_public_access = false
  eks_cluster_public_access_cidrs    = null
  eks_nodegroup_instance_type        = "m7i.large"
  eks_nodegroup_scaling_config = {
    "desired_size" : 1,
    "max_size" : 2,
    "min_size" : 1
  }

  # --- Database --- #
  tfe_database_password_secret_arn = module.tfe_prereqs_w2.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false
  rds_aurora_replica_count         = 0
  rds_aurora_instance_class        = "db.r6i.large"

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.tfe_prereqs_w2.tfe_redis_password_secret_arn
  redis_node_type               = "cache.t4g.medium"
}
