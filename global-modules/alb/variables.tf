# ---------------------------------------------------------------------------------------------------------------------
# 必須パラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "alb_name" {
  description = "ALB の名前"
  type        = string
}

variable "subnet_ids" {
  description = "デプロイ先のサブネット ID リスト"
  type        = list(string)
}

variable "vpc_id" {
  description = "ALB をデプロイする VPC の ID"
  type        = string
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
