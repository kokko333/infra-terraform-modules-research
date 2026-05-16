terraform {
  source = "../../../../global-modules//network"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  name = "hello-world-prod"
  tags = {
    ManagedBy = "terraform"
  }
}
