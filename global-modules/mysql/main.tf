terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_db_subnet_group" "example" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "rds" {
  name = "${var.db_name}-rds"
  tags = var.tags
}

resource "aws_security_group_rule" "allow_from_app" {
  for_each = toset(var.allow_from_security_group_ids)

  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  from_port                = local.mysql_port
  to_port                  = local.mysql_port
  protocol                 = local.tcp_protocol
  source_security_group_id = each.value
}

resource "aws_db_instance" "example" {
  identifier_prefix      = "terraform-up-and-running"
  engine                 = "mysql"
  allocated_storage      = 10
  instance_class         = "db.t3.micro"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.example.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  tags                   = var.tags
}

locals {
  mysql_port   = 3306
  tcp_protocol = "tcp"
}
