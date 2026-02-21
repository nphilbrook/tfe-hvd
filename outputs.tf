# output "bastion_public_dns" {
#   value       = module.tfe_prereqs_w2.bastion_public_dns
#   description = "Public DNS name of bastion EC2 instance."
# }

output "new_bastion_public_dns" {
  value       = module.prereqs.bastion_public_dns
  description = "Public DNS name of bastion EC2 instance."
}

output "new_bastion_private_ip" {
  value       = module.prereqs.bastion_private_ip
  description = "Private IP address of bastion EC2 instance."
}

output "new_bastion_sg_id" {
  value       = module.prereqs.bastion_security_group_id
  description = "Security group ID of bastion EC2 instance."
}

output "vpc_id" {
  value       = module.prereqs.vpc_id
  description = "ID of the VPC created for TFE."
}

output "foo" {
  value = var.foo
}

output "gh_v4_hook_ranges" {
  value = local.gh_v4_hook_ranges
}

output "rds_aurora_global_cluster_id" {
  value = module.tfe_new.rds_aurora_global_cluster_id
}

output "rds_aurora_cluster_arn" {
  value = module.tfe_new.rds_aurora_cluster_arn
}

output "rds_aurora_cluster_members" {
  value = module.tfe_new.rds_aurora_cluster_members
}

output "rds_aurora_cluster_endpoint" {
  value = module.tfe_new.rds_aurora_cluster_endpoint
}
