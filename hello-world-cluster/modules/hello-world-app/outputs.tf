output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ロードバランサーのドメイン名"
}

output "asg_name" {
  value       = module.asg.asg_name
  description = "Auto Scaling Group の名前"
}

output "instance_security_group_id" {
  value       = module.asg.instance_security_group_id
  description = "EC2 インスタンスセキュリティグループの ID"
}
