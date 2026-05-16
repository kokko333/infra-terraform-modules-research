output "address" {
  value       = aws_db_instance.example.address
  description = "データベースへの接続エンドポイント"
}

output "port" {
  value       = aws_db_instance.example.port
  description = "データベースが待ち受けるポート番号"
}

output "db_security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS インスタンスにアタッチされたセキュリティグループの ID"
}
