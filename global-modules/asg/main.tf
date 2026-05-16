terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_launch_template" "example" {
  name_prefix            = "${var.cluster_name}-"
  image_id               = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data              = var.user_data != null ? base64encode(var.user_data) : null
  tags                   = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  name                = var.cluster_name
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  # ロードバランサーとの統合設定
  target_group_arns = var.target_group_arns
  health_check_type = var.health_check_type

  min_size = var.min_size
  max_size = var.max_size

  # Instance Refresh を使って ASG への変更をローリング適用する
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags :
      key => upper(value)
      if key != "Name"
    }

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_security_group" "instance" {
  name   = "${var.cluster_name}-instance"
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  count             = length(var.allow_inbound_from_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = var.allow_inbound_from_cidr_blocks
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name  = "${var.cluster_name}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count = format("%.1s", var.instance_type) == "t" ? 1 : 0

  alarm_name  = "${var.cluster_name}-low-cpu-credit-balance"
  namespace   = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.example.name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Minimum"
  threshold           = 10
  unit                = "Count"
  tags                = var.tags
}

locals {
  tcp_protocol = "tcp"
  any_port     = 0
  any_protocol = "-1"
  all_ips      = ["0.0.0.0/0"]
}