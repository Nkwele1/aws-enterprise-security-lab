# Generate a random suffix for the S3 bucket name
# S3 bucket names must be globally unique across ALL AWS accounts
# Adding random characters ensures no naming conflicts

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket to store CloudTrail logs
# All audit logs land here for long term storage and analysis

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project_name}-cloudtrail-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-cloudtrail-logs"
    Purpose = "CloudTrail audit log storage"
  }
}

# Block all public access to the log bucket
# Audit logs should never be publicly readable under any circumstances
# This overrides any accidental public access settings

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning on the log bucket
# Versioning keeps previous versions of log files
# This prevents logs from being tampered with or deleted
# Required by many compliance frameworks including NIST

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server side encryption on the log bucket
# All logs are encrypted at rest using AES-256
# This protects sensitive audit data even if someone gains physical access

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy that allows CloudTrail to write logs to this bucket
# Without this policy CloudTrail cannot put files in the bucket
# The two statements allow CloudTrail to check the bucket exists
# and then write log files to it

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch log group to receive CloudTrail events in real time
# S3 gives you long term storage
# CloudWatch gives you real time visibility and alerting capability

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-cloudtrail-logs"
  }
}

# IAM role that allows CloudTrail to write to CloudWatch
# CloudTrail needs permission to put log events into CloudWatch
# This is the same pattern as EC2 IAM roles but for CloudTrail

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

# Policy allowing CloudTrail to write logs to CloudWatch
resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# CloudTrail trail that captures all API calls
# is_multi_region_trail captures events from all AWS regions
# include_global_service_events captures IAM and other global services
# enable_log_file_validation adds a hash to each log file
# so you can verify logs have not been tampered with

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  tags = {
    Name    = "${var.project_name}-trail"
    Purpose = "Audit logging for all AWS API calls"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}