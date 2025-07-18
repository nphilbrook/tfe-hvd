data "terracurl_request" "gh_meta" {
  name   = "github-meta"
  url    = "https://api.github.com/meta"
  method = "GET"

  response_codes = [
    200
  ]

  max_retry      = 2
  retry_interval = 5
}

locals {
  gh_v4_hook_ranges = [for ip in jsondecode(data.terracurl_request.gh_meta.response).hooks : ip if !strcontains(ip, ":")]
}

#------------------------------------------------------------------------------
# AWS environment
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_partition" "current" {}
