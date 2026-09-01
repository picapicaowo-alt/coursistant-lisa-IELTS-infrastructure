output "vpc_id" {
  description = "ID of the environment VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR of the environment VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by application instances."
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs used by private application subnets."
  value       = aws_nat_gateway.this[*].id
}
