terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "global-modules/examples/asg/terraform.tfstate"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "asg" {
  source = "../../asg"

  cluster_name  = var.cluster_name
  vpc_id        = data.aws_vpc.default.id
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t2.micro"

  min_size           = 1
  max_size           = 1
  enable_autoscaling = false

  subnet_ids = data.aws_subnets.default.ids
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}
