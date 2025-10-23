# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.environment}-order-processing-users"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  tags = {
    Environment = var.environment
    Name        = "${var.environment}-order-processing-users"
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "amplify" {
  name         = "${var.environment}-order-processing-amplify-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile",
    "aws.cognito.signin.user.admin"
  ]

  callback_urls = [
    "https://${aws_cloudfront_distribution.amplify.domain_name}"
  ]
  logout_urls = [
    "https://${aws_cloudfront_distribution.amplify.domain_name}"
  ]

  supported_identity_providers = ["COGNITO"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.environment}-order-processing-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile",
    "aws.cognito.signin.user.admin"
  ]

  callback_urls = [
    "http://localhost:5173"
  ]
  logout_urls = [
    "http://localhost:5173"
  ]

  supported_identity_providers = ["COGNITO"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.environment}-shoptrace-${local.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id

  managed_login_version = 2
}

resource "aws_cognito_managed_login_branding" "client" {
  client_id    = aws_cognito_user_pool_client.main.id
  user_pool_id = aws_cognito_user_pool.main.id

  use_cognito_provided_values = true
}


resource "aws_cognito_managed_login_branding" "amplify" {
  client_id    = aws_cognito_user_pool_client.amplify.id
  user_pool_id = aws_cognito_user_pool.main.id

  use_cognito_provided_values = true
}
