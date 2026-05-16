# ---------------------------------------------------------------------------------------------------------------------
# 必須パラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "environment" {
  description = "デプロイ先の環境名"
  type        = string
}

variable "min_size" {
  description = "ASG の EC2 インスタンス最小数"
  type        = number
}

variable "max_size" {
  description = "ASG の EC2 インスタンス最大数"
  type        = number
}

variable "enable_autoscaling" {
  description = "true に設定するとオートスケーリングを有効化する"
  type        = bool
}

variable "ami" {
  description = "クラスターで使用する AMI"
  type        = string
}

variable "vpc_id" {
  description = "デプロイ先の VPC の ID"
  type        = string
}

variable "subnet_ids" {
  description = "デプロイ先のサブネット ID リスト"
  type        = list(string)
}

# ---------------------------------------------------------------------------------------------------------------------
# オプションパラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_type" {
  description = "起動する EC2 インスタンスタイプ（例: t2.micro）"
  type        = string
  default     = "t2.micro"
}

variable "server_text" {
  description = "Web サーバーが返すテキスト"
  default     = "Hello, World"
  type        = string
}

variable "server_port" {
  description = "サーバーが HTTP リクエストを受け付けるポート番号"
  type        = number
  default     = 8080
}

variable "tags" {
  description = "全リソースに付与するタグ。ASG インスタンスへの伝播にも使用される。"
  type        = map(string)
  default     = {}
}

variable "db_remote_state_bucket" {
  description = "DB の Terraform state を保存する S3 バケット名"
  type        = string
  default     = null
}

variable "db_remote_state_key" {
  description = "S3 上の DB Terraform state のパス"
  type        = string
  default     = null
}

variable "mysql_config" {
  description = "MySQL DB の接続設定"
  type = object({
    address = string
    port    = number
  })
  default = null
}
