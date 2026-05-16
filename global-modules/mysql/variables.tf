# ---------------------------------------------------------------------------------------------------------------------
# 必須パラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "db_name" {
  description = "データベース名"
  type        = string
}

variable "subnet_ids" {
  description = "RDS インスタンスをデプロイするサブネット ID リスト"
  type        = list(string)
}

variable "allow_from_security_group_ids" {
  description = "ポート 3306 でデータベースへの接続を許可するセキュリティグループ ID リスト"
  type        = list(string)
  default     = []
}

variable "db_username" {
  description = "データベースのユーザー名"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "データベースのパスワード"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
