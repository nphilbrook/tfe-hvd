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
  }
}
