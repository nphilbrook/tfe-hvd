# Automatically injected by Terraform
variable "TFC_WORKSPACE_SLUG" {
  type = string
}

variable "tfe_redis_password_secret_value" {
  type      = string
  sensitive = true
}

variable "tfe_database_password_secret_value" {
  type      = string
  sensitive = true
}

variable "tfe_encryption_password_secret_value" {
  type      = string
  sensitive = true
}

variable "tfe_license_secret_value" {
  type      = string
  sensitive = true
}

variable "juniper_junction" {
  type    = list(string)
  default = []
}

variable "foo" {
  default     = "bar"
  description = "For generating plan changes"
}
