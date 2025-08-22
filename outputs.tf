# output "bastion_public_dns" {
#   value       = module.tfe_prereqs_w2.bastion_public_dns
#   description = "Public DNS name of bastion EC2 instance."
# }

output "new_bastion_public_dns" {
  value       = module.prereqs.bastion_public_dns
  description = "Public DNS name of bastion EC2 instance."
}

output "gh_v4_hook_ranges" {
  value = local.gh_v4_hook_ranges
}

output "iam_session_context_issuer_arn" {
  value = data.aws_iam_session_context.current.issuer_arn
}
