terragrunt_version_constraint = ">= v0.36.0"

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket         = "terraform-state-kokko-sample"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-kokko-sample-locks"
  }
}
