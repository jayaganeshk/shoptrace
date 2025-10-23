# Shared Lambda Execution Role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.environment}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = var.environment
  }
}

# Basic Lambda Execution Policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray Tracing Policy
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# DynamoDB Policy
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.environment}-lambda-dynamodb-policy"
  description = "Allow Lambda to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.orders.arn,
          aws_dynamodb_table.coupons.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# S3 Policy for Collector Config
resource "aws_iam_policy" "s3_collector_config" {
  name        = "${var.environment}-lambda-s3-config-policy"
  description = "Allow Lambda to read OTEL collector config from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${local.s3_bucket_name}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_config" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.s3_collector_config.arn
}

# Lambda Invoke Policy for Coupon Service
resource "aws_iam_policy" "lambda_invoke_coupon" {
  name        = "${var.environment}-lambda-invoke-coupon-policy"
  description = "Allow Lambda to invoke Coupon Service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = module.coupon_service_lambda.lambda_function_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_invoke" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_invoke_coupon.arn
}

# SSM Policy for Chaos Configuration
resource "aws_iam_policy" "ssm_chaos_config" {
  name        = "${var.environment}-lambda-ssm-chaos-policy"
  description = "Allow Lambda to read chaos configuration from SSM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = aws_ssm_parameter.chaos_config.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_chaos" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.ssm_chaos_config.arn
}
