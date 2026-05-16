terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "hello-world-cluster/data-stores/mysql/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "mysql" {
  source = "../../../../../global-modules/mysql"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids  = data.terraform_remote_state.network.outputs.subnet_ids
  tags        = var.tags
}
