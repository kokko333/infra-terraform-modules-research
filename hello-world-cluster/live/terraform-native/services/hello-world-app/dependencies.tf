data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.network_remote_state_bucket
    key    = var.network_remote_state_key
    region = "ap-northeast-1"
  }
}
