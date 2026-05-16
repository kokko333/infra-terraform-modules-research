terraform {
  source = "../../../../..//hello-world-cluster/modules/hello-world-app"
}

include {
  path = find_in_parent_folders()
}

dependency "mysql" {
  config_path = "../../data-stores/mysql"
}

dependency "network" {
  config_path = "../../network"
}

inputs = {
  environment = "prod"
  ami = "ami-0bf052f8a9dd8bf42"

  vpc_id     = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.subnet_ids

  min_size = 2
  max_size = 2

  enable_autoscaling = false

  mysql_config = {
    address = dependency.mysql.outputs.address
    port    = dependency.mysql.outputs.port
  }

  tags = {
    ManagedBy = "terraform"
  }
}