#Phase 1
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

#Phase 2
output "ec2_instance_id" {
  value       = aws_instance.private_instance.id
  description = "EC2 instance ID"
}

output "ec2_private_ip" {
  value       = aws_instance.private_instance.private_ip
  description = "Private IP address of EC2 instance"
}

output "iam_role_name" {
  value       = aws_iam_role.ec2_role.name
  description = "IAM role attached to EC2 instance"
}