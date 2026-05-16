terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "hello-world-cluster/network/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "network" {
  source = "../../../../global-modules/network"

  name = "hello-world-${var.environment}"
  tags = var.tags
}
