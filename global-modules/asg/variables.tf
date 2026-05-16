# ---------------------------------------------------------------------------------------------------------------------
# 必須パラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "クラスターの全リソースに使用する名前"
  type        = string
}

variable "ami" {
  description = "クラスターで使用する AMI"
  type        = string
}

variable "instance_type" {
  description = "起動する EC2 インスタンスタイプ（例: t2.micro）"
  type        = string

  # validation ブロックでビジネス制約を強制する例。
  # ここではインスタンスタイプを AWS 無料枠のみに制限している。
  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.instance_type)
    error_message = "このモジュールは無料枠のインスタンスタイプのみ許可します: t2.micro | t3.micro"
  }
}

variable "min_size" {
  description = "ASG の EC2 インスタンス最小数"
  type        = number

  validation {
    condition     = var.min_size > 0
    error_message = "ASG を 0 にするとサービス停止が発生します！"
  }

  validation {
    condition     = var.min_size <= 10
    error_message = "コスト管理のため ASG のインスタンス数は 10 以下にしてください。"
  }
}

variable "max_size" {
  description = "ASG の EC2 インスタンス最大数"
  type        = number

  validation {
    condition     = var.max_size > 0
    error_message = "ASG を 0 にするとサービス停止が発生します！"
  }

  validation {
    condition     = var.max_size <= 10
    error_message = "コスト管理のため ASG のインスタンス数は 10 以下にしてください。"
  }
}

variable "subnet_ids" {
  description = "デプロイ先のサブネット ID リスト"
  type        = list(string)
}

variable "vpc_id" {
  description = "ASG をデプロイする VPC の ID"
  type        = string
}

variable "enable_autoscaling" {
  description = "true に設定するとオートスケーリングを有効化する"
  type        = bool
}

# ---------------------------------------------------------------------------------------------------------------------
# オプションパラメータ
# ---------------------------------------------------------------------------------------------------------------------

variable "target_group_arns" {
  description = "インスタンスを登録するロードバランサーターゲットグループの ARN リスト"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "ヘルスチェックのタイプ。EC2 または ELB を指定してください。"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type は EC2 または ELB のいずれかを指定してください。"
  }
}

variable "user_data" {
  description = "各インスタンスの起動時に実行する User Data スクリプト"
  type        = string
  default     = null
}

variable "custom_tags" {
  description = "ASG 内のインスタンスに設定するカスタムタグ"
  type        = map(string)
  default     = {}
}

variable "server_port" {
  description = "サーバーが HTTP リクエストを受け付けるポート番号"
  type        = number
  default     = 8080
}

variable "allow_inbound_from_cidr_blocks" {
  description = "server_port への着信を許可する CIDR ブロック。[] を指定すると CIDR ベースの着信ルールを作成しない（SG ベースのルールと組み合わせて使用）。"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
  default     = {}
}
