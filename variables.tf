# AWS region where all resources will be deployed
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

# Project name used for tagging and naming all resources
variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "aws-enterprise-security-lab"
}

# Environment tag to distinguish dev, staging, prod deployments
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# VPC address space
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public subnet address range
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Private subnet address range
variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}