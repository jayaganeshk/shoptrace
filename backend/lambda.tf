# Create Order Lambda


locals {
  common_env_variables = {
    ORDERS_TABLE  = aws_dynamodb_table.orders.name
    COUPONS_TABLE = aws_dynamodb_table.coupons.name

    ENVIRONMENT                        = var.environment
    OPENTELEMETRY_COLLECTOR_CONFIG_URI = var.collector_config_s3_uri
    AWS_LAMBDA_EXEC_WRAPPER            = "/opt/otel-instrument"
    OTEL_PROPAGATORS                   = "tracecontext,xray"
    OTEL_SERVICE_NAME                  = var.honeycomb_dataset
  }
  layers = [
    "arn:aws:lambda:${local.region}:901920570463:layer:aws-otel-python-amd64-ver-1-32-0:2",
    module.honeycomb_layer.lambda_layer_arn,
    module.chaos_layer.lambda_layer_arn
  ]
  publish_lambda_version = false
  enable_snap_start      = false // This will incur additional cost; enable only if needed
}

module "create_order_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.environment}-create-order"
  description   = "Create order function"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  source_path = "${path.module}/functions/create-order"

  create_role                             = false
  publish                                 = local.publish_lambda_version
  snap_start                              = local.enable_snap_start
  create_current_version_allowed_triggers = false
  lambda_role                             = aws_iam_role.lambda_execution.arn

  layers = local.layers

  environment_variables = merge(
    local.common_env_variables, {
      COUPON_SERVICE_FUNCTION = module.coupon_service_lambda.lambda_function_name
    }
  )

  tracing_mode = "Active"

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Get Order Lambda
module "get_order_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.environment}-get-order"
  description   = "Get order function"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  source_path = "${path.module}/functions/get-order"

  create_role                             = false
  publish                                 = local.publish_lambda_version
  snap_start                              = local.enable_snap_start
  create_current_version_allowed_triggers = false
  lambda_role                             = aws_iam_role.lambda_execution.arn

  layers = local.layers

  environment_variables = local.common_env_variables


  tracing_mode = "Active"

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
    }
  }

  tags = {
    Environment = var.environment
  }
}

# List Orders Lambda
module "list_orders_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.environment}-list-orders"
  description   = "List orders function"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  source_path = "${path.module}/functions/list-orders"

  create_role                             = false
  publish                                 = local.publish_lambda_version
  snap_start                              = local.enable_snap_start
  create_current_version_allowed_triggers = false
  lambda_role                             = aws_iam_role.lambda_execution.arn

  layers = local.layers

  environment_variables = local.common_env_variables

  tracing_mode = "Active"

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Coupon Service Lambda
module "coupon_service_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.environment}-coupon-service"
  description   = "Coupon service function"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  source_path = "${path.module}/functions/coupon-service"

  create_role                             = false
  publish                                 = local.publish_lambda_version
  snap_start                              = local.enable_snap_start
  create_current_version_allowed_triggers = false
  lambda_role                             = aws_iam_role.lambda_execution.arn

  layers = local.layers

  environment_variables = local.common_env_variables


  tracing_mode = "Active"

  tags = {
    Environment = var.environment
  }
}

# Validate Coupon Lambda
module "validate_coupon_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.environment}-validate-coupon"
  description   = "Validate coupon without reducing usage count"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  source_path = "${path.module}/functions/validate-coupon"

  create_role                             = false
  publish                                 = local.publish_lambda_version
  snap_start                              = local.enable_snap_start
  create_current_version_allowed_triggers = false
  lambda_role                             = aws_iam_role.lambda_execution.arn

  layers = local.layers

  environment_variables = local.common_env_variables

  tracing_mode = "Active"

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
    }
  }

  tags = {
    Environment = var.environment
  }
}

# List Products Lambda
module "list_products_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = "${var.environment}-list-products"
  description   = "List products function"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  source_path = "${path.module}/functions/list-products"

  create_role                             = false
  publish                                 = local.publish_lambda_version
  snap_start                              = local.enable_snap_start
  create_current_version_allowed_triggers = false
  lambda_role                             = aws_iam_role.lambda_execution.arn

  layers                = local.layers
  environment_variables = local.common_env_variables

  tracing_mode = "Active"

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
    }
  }

  tags = {
    Environment = var.environment
  }
}
