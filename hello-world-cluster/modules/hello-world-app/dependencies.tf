data "terraform_remote_state" "db" {
  count = var.mysql_config == null ? 1 : 0

  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "ap-northeast-1"
  }

  lifecycle {
    precondition {
      condition     = var.db_remote_state_bucket != null && var.db_remote_state_key != null
      error_message = "mysql_config が null の場合は db_remote_state_bucket と db_remote_state_key を指定してください。"
    }
  }
}

locals {
  mysql_config = (
    var.mysql_config == null
    ? data.terraform_remote_state.db[0].outputs
    : var.mysql_config
  )
}
