data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "fixture" {
  name        = "${var.project_name}-open-sg"
  description = "Intentionally insecure fixture security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Intentional scanner finding: SSH open to the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Intentional scanner finding: app port open to the internet"
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "oversized" {
  count                  = var.enable_expensive_ec2 ? 1 : 0
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "m7i.4xlarge"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.fixture.id]

  root_block_device {
    volume_size = 200
    volume_type = "gp3"
    # Intentionally does not set encrypted = true.
  }

  tags = {
    Name = "${var.project_name}-oversized"
    # Intentionally missing Owner / CostCenter / Environment tags.
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project_name}-artifacts-${data.aws_caller_identity.current.account_id}"
  # Intentional findings: no public access block, no default encryption,
  # no versioning, and no lifecycle expiration policy.
}

data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "work" {
  name                       = "${var.project_name}-work-queue"
  message_retention_seconds  = 1209600
  visibility_timeout_seconds = 180
  # Intentional finding: no server-side encryption / DLQ configured.
}

resource "aws_lambda_function" "worker" {
  function_name = "${var.project_name}-worker"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  filename      = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  memory_size   = 3008
  timeout       = 900

  environment {
    variables = {
      QUEUE_URL       = aws_sqs_queue.work.url
      API_SECRET      = "not-a-real-secret-placeholder"
      LOG_LEVEL       = "DEBUG"
    }
  }
  # Intentional findings: oversized memory/timeout and sensitive-looking env var.
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "../main/code/handler.py"
  output_path = "${path.module}/lambda_payload.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${aws_lambda_function.worker.function_name}"
  # Intentional finding: no retention_in_days; logs may be retained indefinitely.
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.work.arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 10
}
