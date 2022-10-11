provider "aws" {
    region = var.region
    access_key = var.AWS_ACCESS_KEY
    secret_key = var.AWS_SECRET_KEY
}

terraform {
  cloud {
    organization = "danielmcdermott"

    workspaces {
      name = "vitfor-test"
    }
  }
}