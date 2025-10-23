# Honeycomb Lambda Layer using terraform-aws-modules
module "honeycomb_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  create_layer = true

  layer_name          = "${var.environment}-honeycomb-layer"
  description         = "Shared Honeycomb tracing utilities"
  compatible_runtimes = ["python3.12"]

  source_path = "${path.module}/layers/honeycomb-layer"
}

# Chaos Engineering Lambda Layer
module "chaos_layer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  create_layer = true

  layer_name          = "${var.environment}-chaos-layer"
  description         = "Chaos engineering utilities"
  compatible_runtimes = ["python3.12"]

  source_path = "${path.module}/layers/chaos-layer"
}

