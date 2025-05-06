terraform {
  cloud {
    organization = "philbrook"

    workspaces {
      name = "tfe-hvd"
    }
  }
}
