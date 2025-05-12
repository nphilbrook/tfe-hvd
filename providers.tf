provider "aws" {
  region = local.primary_region
}

provider "terracurl" {}
