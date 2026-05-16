terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Owner     = "tf sample"
      ManagedBy = "Terraform"
    }
  }
}

# --- state管理用 S3バケット ---

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  # 動作確認用環境なので、簡易的に削除可能にしておく
  force_destroy = true

  # # terraform destroyコマンドで誤って削除されないようにするための保護設定
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# stateファイルのバージョニングを有効化
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
# サーバーサイド暗号化をデフォルトで有効化
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# # バケット自体の削除をすべてのプリンシパルに対して拒否
# resource "aws_s3_bucket_policy" "prevent_delete" {
#   bucket = aws_s3_bucket.terraform_state.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "DenyDeleteBucket"
#         Effect    = "Deny"
#         Principal = "*"
#         Action    = "s3:DeleteBucket"
#         Resource  = aws_s3_bucket.terraform_state.arn
#       }
#     ]
#   })
# }

# S3バケットへのすべてのパブリックアクセスを明示的にブロック
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- state更新時のロック管理用 DynamoDBテーブル ---

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID" # ロック管理用のハッシュキー（名前は固定）
  # deletion_protection_enabled = true # AWSネイティブのテーブルの削除保護

  attribute {
    name = "LockID"
    type = "S"
  }

  # # terraform destroyコマンドで誤って削除されないようにするための保護設定
  # lifecycle {
  #   prevent_destroy = true
  # }
}
