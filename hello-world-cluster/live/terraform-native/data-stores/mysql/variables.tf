# ---------------------------------------------------------------------------------------------------------------------
# 必須パラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "network_remote_state_bucket" {
  description = "ネットワーク remote state を保存する S3 バケット名"
  type        = string
}

variable "network_remote_state_key" {
  description = "S3 上のネットワーク remote state のパス"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# オプションパラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "db_username" {
  description = "データベースのユーザー名"
  type        = string
  sensitive   = true
  default     = "admin" # サンプルコードのため、簡便のためにデフォルトを設定
}

variable "db_password" {
  description = "データベースのパスワード"
  type        = string
  sensitive   = true
  default     = "Passw0rd" # サンプルコードのため、簡便のためにデフォルトを設定
}

variable "db_name" {
  description = "データベース名"
  type        = string
  default     = "example_database_prod"
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = { ManagedBy = "terraform" }
}
