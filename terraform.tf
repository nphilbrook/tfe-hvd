terraform {
  required_version = ">=1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.91"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "~>1.2"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~>2.23"
    }
    local = {
      source  = "hashicorp/local"
      version = "~>2.5"
    }
  }
}
