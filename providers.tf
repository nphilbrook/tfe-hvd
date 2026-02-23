provider "aws" {
  region = local.primary_region
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "secondary"
  region = local.secondary_region
  default_tags {
    tags = local.common_tags
  }
}

provider "terracurl" {}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
