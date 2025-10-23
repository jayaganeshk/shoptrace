data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  s3_bucket_name = regex("s3://([^.]+)", var.collector_config_s3_uri)[0]
}
