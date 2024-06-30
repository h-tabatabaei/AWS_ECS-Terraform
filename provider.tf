terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "5.17.0" }
  }
}

provider "aws" {
  profile    = "default"
  region     = "eu-north-1"
  access_key = ""
  secret_key = ""
}
