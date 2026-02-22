terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket       = "pritha-do-not-delete"
    key          = "nginx/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    # profile      = "sandbox"
    use_lockfile = true
  }
}

provider "aws" {
  # profile = "sandbox"
  region  = var.region
}

data "aws_caller_identity" "current" {}
