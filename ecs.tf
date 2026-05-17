# ECR repository to store your container images
# ECR is AWS's private container registry - like Docker Hub but private
# Images pushed here can only be accessed by your AWS account

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  # Scan images for vulnerabilities automatically when pushed
  # This is a security best practice for container registries
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.project_name}-ecr"
  }
}

# ECR lifecycle policy to automatically clean up old images
# Without this your registry fills up with old unused images
# This keeps only the last 10 images and deletes older ones

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECS cluster - the logical grouping for your containers
# Think of it like a data center specifically for containers
# Fargate means AWS manages the underlying servers for you

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  # Enable Container Insights for enhanced monitoring
  # This sends detailed metrics to CloudWatch automatically
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# IAM role that ECS tasks use to pull images and write logs
# ECS needs permission to pull your container image from ECR
# and write container logs to CloudWatch

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
# This gives ECS permission to pull images from ECR
# and send logs to CloudWatch - the minimum needed

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch log group for container logs
# All stdout and stderr from your containers goes here
# This is how you see what your containers are doing

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

# Task definition describes what container to run
# This is like a job description for ECS
# It says what image to use, how much CPU and memory,
# what ports to open, and where to send logs

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "nginx"
      image = "nginx:latest"

      # Port 80 is the standard HTTP port
      # The container listens on this port for web traffic
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      # Send all container logs to CloudWatch
      # awslogs driver is the AWS native logging driver
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "nginx"
        }
      }

      # Health check runs inside the container
      # ECS uses this to know if the container is healthy
      # If it fails ECS automatically replaces the container
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-task-definition"
  }
}

# Security group for ECS tasks
# Allows HTTP traffic into the container
# and all outbound traffic so the container
# can pull images and reach AWS services

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow HTTP from within VPC only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound for image pulling and AWS API calls"
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# ECS service keeps your container running
# If the container crashes ECS automatically starts a new one
# desired_count = 1 means keep exactly 1 container running at all times

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Network configuration puts the container in your public subnet
  # assign_public_ip is needed for Fargate to pull images from ECR
  # In production you would use a NAT gateway and private subnet instead

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  # Wait for the service to be stable before Terraform considers it done
  # This means Terraform waits until the container is actually running

  tags = {
    Name = "${var.project_name}-ecs-service"
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}