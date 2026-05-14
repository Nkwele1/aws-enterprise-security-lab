output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet_id" {
  value       = aws_subnet.public.id
  description = "Public subnet ID"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "Private subnet ID"
}

output "public_sg_id" {
  value       = aws_security_group.public.id
  description = "Public security group ID"
}

output "private_sg_id" {
  value       = aws_security_group.private.id
  description = "Private security group ID"
}