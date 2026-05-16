terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "global-modules/examples/alb/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "alb" {
  source = "../../alb"

  alb_name   = var.alb_name
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids
}
