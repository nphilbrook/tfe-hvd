# output "bastion_public_dns" {
#   value       = module.tfe_prereqs_w2.bastion_public_dns
#   description = "Public DNS name of bastion EC2 instance."
# }

output "new_bastion_public_dns" {
  value       = module.prereqs.bastion_public_dns
  description = "Public DNS name of bastion EC2 instance."
}

output "foo" {
  value = var.foo
}

output "gh_v4_hook_ranges" {
  value = local.gh_v4_hook_ranges
}
