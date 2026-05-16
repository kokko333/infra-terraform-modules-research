terraform {
  source = "../../../../../global-modules//mysql"
}

include {
  path = find_in_parent_folders()
}

dependency "network" {
  config_path = "../../network"
}

inputs = {
  db_name     = "example_prod"
  vpc_id      = dependency.network.outputs.vpc_id
  subnet_ids  = dependency.network.outputs.subnet_ids

  # 実用では TF_VAR_db_username, TF_VAR_db_password で指定すること
  db_username = "admin"
  db_password = "Passw0rd"

  tags = {
    ManagedBy = "terraform"
  }
}
