# Net new TFE instance based on the new non-deprecated prereqs module
module "tfe_new" {
  # source  = "hashicorp/terraform-enterprise-eks-hvd/aws"
  # version = "0.1.1"
  # source = "git@github.com:hashicorp/terraform-aws-terraform-enterprise-eks-hvd?ref=main"
  source = "git@github.com:nphilbrook/terraform-aws-terraform-enterprise-eks-hvd?ref=nphilbrook_local_version"
  # --- Common --- #
  friendly_name_prefix = local.new_friendly_name_prefix
  common_tags          = local.common_tags

  # --- TFE configuration settings --- #
  tfe_fqdn                   = local.tfe_fqdn
  create_helm_overrides_file = true

  # --- Networking --- #
  vpc_id           = module.prereqs.vpc_id
  eks_subnet_ids   = module.prereqs.private_subnet_ids
  rds_subnet_ids   = module.prereqs.private_subnet_ids
  redis_subnet_ids = slice(module.prereqs.private_subnet_ids, 0, 2)
  cidr_allow_ingress_tfe_443 = concat([local.new_vpc_cidr, "${module.prereqs.bastion_public_ip}/32"],
    var.juniper_junction,
    local.gh_v4_hook_ranges,
    #   TODO: determine if this is required
    # local.ngw_cidrs
  )
  cidr_allow_ingress_tfe_metrics_http  = var.juniper_junction
  cidr_allow_ingress_tfe_metrics_https = var.juniper_junction

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
    "max_size" : 3,
    "min_size" : 1
  }

  # --- Database --- #
  tfe_database_password_secret_arn = module.prereqs.tfe_database_password_secret_arn
  rds_skip_final_snapshot          = false
  rds_aurora_replica_count         = 0
  rds_aurora_instance_class        = "db.r6i.large"

  # --- Redis --- #
  tfe_redis_password_secret_arn = module.prereqs.tfe_redis_password_secret_arn
  redis_node_type               = "cache.t4g.medium"
}

resource "aws_security_group_rule" "eks_cluster_allow_ingress_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.prereqs.bastion_security_group_id
  description              = "Allow TCP/443 (HTTPS) inbound to EKS cluster from bastion."
  security_group_id        = module.tfe_new.eks_cluster_security_group_id
}
