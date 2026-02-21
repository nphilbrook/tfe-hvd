provider "aws" {
  region = local.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = local.secondary_region
}

provider "terracurl" {}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
