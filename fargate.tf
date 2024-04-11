provider "aws" {
  region = var.aws_region # fill in the AWS region
}

# create an S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name  # fill in the bucket name you want
}

# upload the model to the S3 bucket
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.bucket
  key    = "/TokenPricePredictionModel"
  source = "./TokenPricePredictionModel"
  acl    = "private"
}

# create an ECS task execution IAM role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/my-log-group"
  retention_in_days = 14
}

# create an ECS task definition
resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "my-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "tfserving_token_price_prediction"
    image = var.container_image # fill in your container image name and tag in ECR
    portMappings = [{
      containerPort = 8501
      hostPort      = 8501
      protocol      = "tcp"
    }]
    environment = [{
      name  = "MODEL_BASE_PATH"
      value = "s3://${aws_s3_bucket.bucket.bucket}/TokenPricePredictionModel"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-region        = var.aws_region  # fill in the AWS region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# create an ECS service
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs_tasks_sg"
  description = "Allow all inbound traffic on HTTP/HTTPS"

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets  # fill in your subnets' IDs as a list
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
  }

  desired_count = 1
}
