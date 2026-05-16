terraform {
  # Terraform 1.x 系のバージョンを要求する
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "asg" {
  source = "../../../global-modules/asg"

  cluster_name  = "hello-world-${var.environment}"
  ami           = var.ami
  instance_type = var.instance_type

  user_data = templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = local.mysql_config.address
    db_port     = local.mysql_config.port
    server_text = var.server_text
  })

  min_size           = var.min_size
  max_size           = var.max_size
  enable_autoscaling = var.enable_autoscaling

  vpc_id            = var.vpc_id
  subnet_ids        = var.subnet_ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  # インターネットからの直接アクセスを無効化し、ALB 経由のみ許可する
  allow_inbound_from_cidr_blocks = []

  custom_tags = var.tags
  tags        = var.tags
}

module "alb" {
  source = "../../../global-modules/alb"

  alb_name   = "hello-world-${var.environment}"
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_lb_target_group" "asg" {
  name     = "hello-world-${var.environment}"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  tags     = var.tags

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_security_group_rule" "allow_http_from_alb" {
  type                     = "ingress"
  security_group_id        = module.asg.instance_security_group_id
  source_security_group_id = module.alb.alb_security_group_id
  from_port                = var.server_port
  to_port                  = var.server_port
  protocol                 = "tcp"
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = module.alb.alb_http_listener_arn
  priority     = 100
  tags         = var.tags

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}
