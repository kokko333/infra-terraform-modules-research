output "vpc_id" {
  value       = module.network.vpc_id
  description = "The ID of the VPC"
}

output "subnet_ids" {
  value       = module.network.subnet_ids
  description = "The IDs of the public subnets"
}
