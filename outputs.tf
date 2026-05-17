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

#Phase 3
output "cloudtrail_bucket" {
  value       = aws_s3_bucket.cloudtrail_logs.bucket
  description = "S3 bucket storing CloudTrail audit logs"
}

output "cloudtrail_log_group" {
  value       = aws_cloudwatch_log_group.cloudtrail.name
  description = "CloudWatch log group receiving real time CloudTrail events"
}

output "cloudtrail_name" {
  value       = aws_cloudtrail.main.name
  description = "CloudTrail trail name"
}

#Phase 4
output "security_dashboard" {
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
  description = "Direct link to the security monitoring dashboard"
}

output "alarms_count" {
  value       = "4 security alarms configured with AI anomaly detection"
  description = "Summary of configured alarms"
}