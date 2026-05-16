terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "hello_world_app" {
  source = "../../modules/hello-world-app"

  server_text  = var.server_text
  environment  = var.environment
  mysql_config = local.mysql_config

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  instance_type      = "t2.micro"
  min_size           = 2
  max_size           = 2
  enable_autoscaling = false
  ami                = data.aws_ssm_parameter.ubuntu_ami.value
  tags               = var.tags
}

module "mysql" {
  count  = var.create_mysql ? 1 : 0
  source = "../../../global-modules/mysql"

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  vpc_id      = data.aws_vpc.default.id
  subnet_ids  = data.aws_subnets.default.ids
  tags        = var.tags
}

# create_mysql = true のとき、ASG インスタンスから MySQL への ingress を許可する。
# module.mysql と module.hello_world_app の間の循環参照を避けるため、
# 呼び出し側で独立リソースとして定義する。
resource "aws_security_group_rule" "allow_hello_world_to_mysql" {
  count = var.create_mysql ? 1 : 0

  type                     = "ingress"
  security_group_id        = module.mysql[0].db_security_group_id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.hello_world_app.instance_security_group_id
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  mysql_config = var.create_mysql ? {
    address = module.mysql[0].address
    port    = module.mysql[0].port
  } : var.mock_mysql_config
}
