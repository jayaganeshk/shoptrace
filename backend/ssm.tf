# SSM Parameter for Chaos Engineering Configuration
resource "aws_ssm_parameter" "chaos_config" {
  name = "/${var.environment}/order-processing/chaos/dynamodb"
  type = "String"
  value = jsonencode({
    enabled = true
    latency = {
      enabled     = true
      min_ms      = 1000
      max_ms      = 3000
      probability = 0.3
    }
    exceptions = {
      enabled     = true
      probability = 0.2
      types       = ["throttling", "timeout", "service_unavailable"]
    }
  })

  tags = {
    Environment = var.environment
    Purpose     = "chaos-engineering"
  }
}
