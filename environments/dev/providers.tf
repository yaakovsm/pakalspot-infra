terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}