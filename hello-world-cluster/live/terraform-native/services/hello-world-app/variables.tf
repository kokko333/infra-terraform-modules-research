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

variable "db_remote_state_bucket" {
  description = "データベース remote state を保存する S3 バケット名"
  type        = string
}

variable "db_remote_state_key" {
  description = "S3 上のデータベース remote state のパス"
  type        = string
}

variable "ami_id" {
  description = "クラスターで使用する AMI ID（Ubuntu 24.04、ap-northeast-1）"
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# オプションパラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "server_text" {
  description = "Web サーバーが返すテキスト"
  default     = "Hello, World"
  type        = string
}

variable "environment" {
  description = "デプロイ先の環境名"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = { ManagedBy = "terraform" }
}
