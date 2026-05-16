output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "ロードバランサーのドメイン名"
}

output "alb_http_listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "HTTP リスナーの ARN"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB セキュリティグループの ID"
}
