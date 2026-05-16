output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "Auto Scaling Group の名前"
}

output "instance_security_group_id" {
  value       = aws_security_group.instance.id
  description = "EC2 インスタンスセキュリティグループの ID"
}
