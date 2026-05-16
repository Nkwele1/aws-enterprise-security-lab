# Get the latest Amazon Linux 2 AMI automatically
# This means your code always uses the latest patched version
# without you having to manually update the AMI ID

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance deployed into the private subnet
# Uses the IAM instance profile for permissions
# User data script runs automatically on first boot

resource "aws_instance" "private_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # User data runs as root when the instance first starts
  # This script installs and starts the CloudWatch agent automatically
  # No manual configuration needed after deployment

  user_data = <<-EOF
    #!/bin/bash
    # Update all packages first for security patches
    yum update -y

    # Install the CloudWatch agent
    yum install -y amazon-cloudwatch-agent

    # Create CloudWatch agent configuration
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
    {
      "metrics": {
        "metrics_collected": {
          "cpu": {
            "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
            "metrics_collection_interval": 60
          },
          "mem": {
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": ["used_percent"],
            "metrics_collection_interval": 60
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/ec2/${var.project_name}",
                "log_stream_name": "{instance_id}/messages"
              }
            ]
          }
        }
      }
    }
    CWCONFIG

    # Start the CloudWatch agent with the config we just created
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOF

  tags = {
    Name = "${var.project_name}-private-instance"
  }
}