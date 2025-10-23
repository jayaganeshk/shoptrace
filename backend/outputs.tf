output "honeycomb_layer_arn" {
  description = "Honeycomb Lambda Layer ARN"
  value       = module.honeycomb_layer.lambda_layer_arn
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Local Client ID"
  value       = aws_cognito_user_pool_client.main.id
}

output "user_pool_amplify_client_id" {
  description = "Cognito User Pool Amplify Client ID"
  value       = aws_cognito_user_pool_client.amplify.id
}

output "user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = "${var.environment}-shoptrace-${local.account_id}.auth.${local.region}.amazoncognito.com"
}

output "cognito_hosted_ui_url" {
  description = "Cognito Hosted UI Login URL"
  value       = "https://${var.environment}-shoptrace-${local.account_id}.auth.${local.region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.main.id}&response_type=code&redirect_uri=http://localhost:5173"
}

output "order_api_url" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "orders_table_name" {
  description = "DynamoDB Orders Table Name"
  value       = aws_dynamodb_table.orders.name
}

output "coupons_table_name" {
  description = "DynamoDB Coupons Table Name"
  value       = aws_dynamodb_table.coupons.name
}

output "amplify_app_url" {
  description = "Amplify App URL"
  value       = "https://main.${aws_amplify_app.main.default_domain}"
}

output "amplify_app_id" {
  description = "Amplify App ID for manual deployment"
  value       = aws_amplify_app.main.id
}

output "create_order_function_arn" {
  description = "Create Order Lambda Function ARN"
  value       = module.create_order_lambda.lambda_function_arn
}

output "get_order_function_arn" {
  description = "Get Order Lambda Function ARN"
  value       = module.get_order_lambda.lambda_function_arn
}

output "list_orders_function_arn" {
  description = "List Orders Lambda Function ARN"
  value       = module.list_orders_lambda.lambda_function_arn
}

output "coupon_service_function_arn" {
  description = "Coupon Service Lambda Function ARN"
  value       = module.coupon_service_lambda.lambda_function_arn
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.amplify.domain_name
}

output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${aws_cloudfront_distribution.amplify.domain_name}"
}

output "list_products_function_arn" {
  description = "List Products Lambda Function ARN"
  value       = module.list_products_lambda.lambda_function_arn
}
