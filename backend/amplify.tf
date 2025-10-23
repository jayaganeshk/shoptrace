# Amplify App for Frontend
resource "aws_amplify_app" "main" {
  name        = "${var.environment}-shop-trace-ui"
  description = "Shop Trace UI - Static Hosting"

  tags = {
    Environment = var.environment
  }
}

# Amplify Branch
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.main.id
  branch_name = "main"

  enable_auto_build = false

  tags = {
    Environment = var.environment
  }
}
