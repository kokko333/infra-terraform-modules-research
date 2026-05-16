variable "name" {
  description = "VPC リソースの名前プレフィックス"
  type        = string
  default     = "terraform-up-and-running"
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
