terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.38.0"
    }
    rhcs = {
      #version = "= 1.6.0-prerelease.3"
      version = "= 1.6.0"
      source  = "terraform-redhat/rhcs"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
  # backend "s3" {
  #   region                 = "ap-southeast-2"
  #   encrypt                = true
  #   skip_region_validation = true
  # }
}

provider "shell" {
  interpreter        = ["/bin/sh", "-c"]
  enable_parallelism = false
  sensitive_environment = {
  }
}