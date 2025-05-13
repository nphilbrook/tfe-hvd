output "bastion_public_dns" {
  value       = module.tfe_prereqs_w2.bastion_public_dns
  description = "Public DNS name of bastion EC2 instance."
}

output "gh_v4_hook_ranges" {
  value = local.gh_v4_hook_ranges
}

output "helm_overrides" {
  value = module.tfe.tfe_helm_overrides_content
}
