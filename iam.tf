data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 1. ECS Task Execution Role (used by ECS agent to pull image & write logs)[cite: 4]
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json

  tags = {
    Name = "${var.prefix}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. S3 Task Role (used by Service 1 Python application)[cite: 4]
resource "aws_iam_role" "s3_task_role" {
  name               = "${var.prefix}-ecs-s3-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json

  tags = {
    Name = "${var.prefix}-ecs-s3-task-role"
  }
}

resource "aws_iam_role_policy" "s3_task_policy" {
  name = "${var.prefix}-s3-upload-access"
  role = aws_iam_role.s3_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.app_bucket.arn}/*"
      }
    ]
  })
}

# 3. SQS Task Role (used by Service 2 Python application)[cite: 4]
resource "aws_iam_role" "sqs_task_role" {
  name               = "${var.prefix}-ecs-sqs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json

  tags = {
    Name = "${var.prefix}-ecs-sqs-task-role"
  }
}

resource "aws_iam_role_policy" "sqs_task_policy" {
  name = "${var.prefix}-sqs-send-access"
  role = aws_iam_role.sqs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.app_queue.arn
      }
    ]
  })
}