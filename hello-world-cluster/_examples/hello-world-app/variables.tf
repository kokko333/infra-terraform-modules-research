# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "create_mysql" {
  description = "true のとき実際の MySQL RDS インスタンスを作成する。false のとき mock_mysql_config を使用する。"
  type        = bool
  default     = false
}

variable "mock_mysql_config" {
  description = "create_mysql = false のときに使用するモック MySQL 設定"
  type = object({
    address = string
    port    = number
  })
  default = {
    address = "mock-mysql-address"
    port    = 12345
  }
}

variable "db_name" {
  description = "MySQL データベース名（create_mysql = true のときのみ使用）"
  type        = string
  default     = "example_database"
}

variable "db_username" {
  description = "MySQL データベースのユーザー名（create_mysql = true のときのみ使用）"
  type        = string
  sensitive   = true
  default     = null
}

variable "db_password" {
  description = "MySQL データベースのパスワード（create_mysql = true のときのみ使用）"
  type        = string
  sensitive   = true
  default     = null
}

variable "tags" {
  description = "全リソースに付与するタグ。OPA ポリシー enforce_specified_tags が ManagedBy タグを必須とするため、デフォルトで設定している。"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "server_text" {
  description = "Web サーバーが返すテキスト"
  type        = string
  default     = "Hello, World"
}

variable "environment" {
  description = "デプロイ先の環境名"
  type        = string
  default     = "example"
}
