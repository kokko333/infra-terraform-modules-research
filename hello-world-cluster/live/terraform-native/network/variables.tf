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
