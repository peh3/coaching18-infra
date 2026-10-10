data "aws_region" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}-cluster"

  tags = {
    Name = "${var.prefix}-cluster"
  }
}

# CloudWatch Log Groups[cite: 4]
resource "aws_cloudwatch_log_group" "s3_service" {
  name              = "/ecs/${var.prefix}-flask-s3-service"
  retention_in_days = 7

  tags = {
    Name = "/ecs/${var.prefix}-flask-s3-service"
  }
}

resource "aws_cloudwatch_log_group" "sqs_service" {
  name              = "/ecs/${var.prefix}-flask-sqs-service"
  retention_in_days = 7

  tags = {
    Name = "/ecs/${var.prefix}-flask-sqs-service"
  }
}

# ==========================================================
# SERVICE 1: Flask S3 File Upload Service[cite: 4]
# ==========================================================
resource "aws_ecs_task_definition" "s3_service" {
  family                   = "${var.prefix}-flask-s3-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.s3_task_role.arn

  container_definitions = jsonencode([{
    name      = "flask-s3"
    image     = "${aws_ecr_repository.flask_s3.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 5001
      hostPort      = 5001
      protocol      = "tcp"
    }]
    environment = [
      { name = "AWS_REGION", value = data.aws_region.current.name },
      { name = "BUCKET_NAME", value = aws_s3_bucket.app_bucket.id }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.s3_service.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "${var.prefix}-flask-s3-task"
  }
}

resource "aws_ecs_service" "s3_service" {
  name            = var.s3_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.s3_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = var.s3_service_name
  }
}

# ==========================================================
# SERVICE 2: Flask SQS Message Service[cite: 4]
# ==========================================================
resource "aws_ecs_task_definition" "sqs_service" {
  family                   = "${var.prefix}-flask-sqs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.sqs_task_role.arn

  container_definitions = jsonencode([{
    name      = "flask-sqs"
    image     = "${aws_ecr_repository.flask_sqs.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 5002
      hostPort      = 5002
      protocol      = "tcp"
    }]
    environment = [
      { name = "AWS_REGION", value = data.aws_region.current.name },
      { name = "QUEUE_URL", value = aws_sqs_queue.app_queue.url }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.sqs_service.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "${var.prefix}-flask-sqs-task"
  }
}

resource "aws_ecs_service" "sqs_service" {
  name            = var.sqs_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sqs_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = var.sqs_service_name
  }
}