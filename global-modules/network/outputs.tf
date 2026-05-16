output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "The IDs of the public subnets (ap-northeast-1a, ap-northeast-1c)"
}
