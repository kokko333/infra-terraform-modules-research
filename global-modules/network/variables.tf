variable "name" {
  description = "VPC リソースの名前プレフィックス"
  type        = string
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
