terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "global-modules/examples/mysql/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "mysql" {
  source = "../../mysql"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = data.aws_subnets.default.ids
}