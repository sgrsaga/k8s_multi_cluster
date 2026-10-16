terraform {
  required_version = ">= 1.6.0"

  required_providers {
    latitudesh = {
      source  = "latitudesh/latitudesh"
      version = "~> 4.6"
    }
  }

  backend "s3" {}
}
