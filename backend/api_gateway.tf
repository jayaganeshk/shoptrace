# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.environment}-shop-trace-api"
  description = "Shop Trace API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
  }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "CognitoAuthorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main.arn]
}

# /orders Resource
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orders"
}

# /orders/{order_id} Resource
resource "aws_api_gateway_resource" "order_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.orders.id
  path_part   = "{order_id}"
}

# /coupons Resource
resource "aws_api_gateway_resource" "coupons" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "coupons"
}

# /coupons/validate Resource
resource "aws_api_gateway_resource" "validate_coupon" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.coupons.id
  path_part   = "validate"
}

# /products Resource
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "products"
}

# GET /products
resource "aws_api_gateway_method" "list_products" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_products" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.list_products.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.list_products_lambda.lambda_function_qualified_invoke_arn
}

resource "aws_api_gateway_method_response" "list_products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.list_products.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method" "products_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "products_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "products_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_options.http_method
  status_code = aws_api_gateway_method_response.products_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,x-session-id,traceparent,tracestate'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# POST /coupons/validate - Validate Coupon
resource "aws_api_gateway_method" "validate_coupon" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.validate_coupon.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "validate_coupon" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.validate_coupon.id
  http_method             = aws_api_gateway_method.validate_coupon.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.validate_coupon_lambda.lambda_function_qualified_invoke_arn
}

# OPTIONS /coupons/validate - CORS Preflight
resource "aws_api_gateway_method" "validate_coupon_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.validate_coupon.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "validate_coupon_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.validate_coupon.id
  http_method = aws_api_gateway_method.validate_coupon_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "validate_coupon_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.validate_coupon.id
  http_method = aws_api_gateway_method.validate_coupon_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "validate_coupon_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.validate_coupon.id
  http_method = aws_api_gateway_method.validate_coupon_options.http_method
  status_code = aws_api_gateway_method_response.validate_coupon_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,x-session-id,traceparent,tracestate'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# POST /orders - Create Order
resource "aws_api_gateway_method" "create_order" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "create_order" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.create_order.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.create_order_lambda.lambda_function_qualified_invoke_arn
}

# GET /orders - List Orders
resource "aws_api_gateway_method" "list_orders" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_orders" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.list_orders.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.list_orders_lambda.lambda_function_qualified_invoke_arn
}

# GET /orders/{order_id} - Get Order
resource "aws_api_gateway_method" "get_order" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.order_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_order" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.order_id.id
  http_method             = aws_api_gateway_method.get_order.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.get_order_lambda.lambda_function_qualified_invoke_arn
}

# OPTIONS /orders - CORS Preflight
resource "aws_api_gateway_method" "orders_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "orders_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "orders_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "orders_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_options.http_method
  status_code = aws_api_gateway_method_response.orders_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,x-session-id,traceparent,tracestate'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# OPTIONS /orders/{order_id} - CORS Preflight
resource "aws_api_gateway_method" "order_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.order_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "order_id_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.order_id.id
  http_method = aws_api_gateway_method.order_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "order_id_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.order_id.id
  http_method = aws_api_gateway_method.order_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "order_id_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.order_id.id
  http_method = aws_api_gateway_method.order_id_options.http_method
  status_code = aws_api_gateway_method_response.order_id_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,x-session-id,traceparent,tracestate'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_integration.list_products,
    aws_api_gateway_integration.validate_coupon,
    aws_api_gateway_integration.create_order,
    aws_api_gateway_integration.list_orders,
    aws_api_gateway_integration.get_order,
    aws_api_gateway_integration.products_options,
    aws_api_gateway_integration.validate_coupon_options,
    aws_api_gateway_integration.orders_options,
    aws_api_gateway_integration.order_id_options,
    aws_api_gateway_method.create_order,
    aws_api_gateway_method.list_orders,
    aws_api_gateway_method.get_order,
    aws_api_gateway_method.orders_options,
    aws_api_gateway_method.order_id_options,
    aws_api_gateway_method.validate_coupon_options,
    aws_api_gateway_method.products_options,
    aws_api_gateway_method.validate_coupon,
    aws_api_gateway_method.orders_options,
    aws_api_gateway_method.products_options,
    aws_api_gateway_method.products_options
  ]

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  # xray_tracing_enabled = true

  tags = {
    Environment = var.environment
  }
}

# Lambda Invoke Permissions
resource "aws_lambda_permission" "list_products" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${module.list_products_lambda.lambda_function_name}:${module.list_products_lambda.lambda_function_version}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "validate_coupon" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${module.validate_coupon_lambda.lambda_function_name}:${module.validate_coupon_lambda.lambda_function_version}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "create_order" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${module.create_order_lambda.lambda_function_name}:${module.create_order_lambda.lambda_function_version}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "list_orders" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${module.list_orders_lambda.lambda_function_name}:${module.list_orders_lambda.lambda_function_version}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_order" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${module.get_order_lambda.lambda_function_name}:${module.get_order_lambda.lambda_function_version}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}
