resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.prefix}-ecs-tasks-sg"
  description = "Allow inbound traffic on port 5001 and 5002 for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description = "Service 1 Flask S3 port"
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Service 2 Flask SQS port"
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic to reach AWS APIs and Docker registries"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-ecs-tasks-sg"
  }
}