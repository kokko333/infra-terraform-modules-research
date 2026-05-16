output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC の ID"
}

output "subnet_ids" {
  value       = module.network.subnet_ids
  description = "パブリックサブネットの ID リスト"
}
