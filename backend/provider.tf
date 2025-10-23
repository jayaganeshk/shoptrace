terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.15.0"
    }
    honeycombio = {
      source  = "honeycombio/honeycombio"
      version = "~> 0.25"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "honeycombio" {
  # API key should be set via HONEYCOMB_API_KEY environment variable
  api_key = "ZGjqRLxwF6y9VOnkKBP80B"
}
