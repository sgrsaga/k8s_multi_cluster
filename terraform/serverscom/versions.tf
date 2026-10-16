terraform {
  required_version = ">= 1.6.0"

  required_providers {
    serverscom = {
      source  = "serverscom/serverscom"
      version = "~> 0.7"
    }
  }

  backend "s3" {}
}
