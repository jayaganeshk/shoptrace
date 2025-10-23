# Orders Table
resource "aws_dynamodb_table" "orders" {
  name         = "${var.environment}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"
  range_key    = "order_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "order_id"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-orders"
  }
}

# Coupons Table
resource "aws_dynamodb_table" "coupons" {
  name         = "${var.environment}-coupons"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "coupon_code"

  attribute {
    name = "coupon_code"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-coupons"
  }
}
