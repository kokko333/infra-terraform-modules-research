output "alb_dns_name" {
  value       = module.hello_world_app.alb_dns_name
  description = "ロードバランサーのドメイン名"
}

output "mysql_address" {
  value       = var.create_mysql ? module.mysql[0].address : null
  description = "MySQL のエンドポイント（create_mysql = true のときのみ値あり）"
}

output "mysql_port" {
  value       = var.create_mysql ? module.mysql[0].port : null
  description = "MySQL のポート番号（create_mysql = true のときのみ値あり）"
}
