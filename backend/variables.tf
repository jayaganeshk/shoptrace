variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod"
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "collector_config_s3_uri" {
  description = "S3 URI for the OpenTelemetry collector configuration file"
  type        = string
}

variable "honeycomb_dataset" {
  description = "Honeycomb dataset name"
  type        = string
  default     = "order-processing-service"
}
