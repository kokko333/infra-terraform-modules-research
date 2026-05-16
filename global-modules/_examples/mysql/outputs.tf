output "address" {
  value       = module.mysql.address
  description = "データベースへの接続エンドポイント"
}

output "port" {
  value       = module.mysql.port
  description = "データベースが待ち受けるポート番号"
}
