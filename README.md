# ShopTrace - Smart Shopping with Observability

Full-stack e-commerce platform with end-to-end distributed tracing from Vue.js frontend to AWS Lambda backend using OpenTelemetry and Honeycomb.

## Features

- **Product Catalog** - Browse and shop products
- **Coupon System** - Apply discount codes with validation
- **Order Management** - Create and track orders
- **User Authentication** - Secure login with AWS Cognito
- **End-to-End Tracing** - Complete observability from browser to database

## Tech Stack

**Frontend:** Vue.js 3, Vuetify, OpenTelemetry Web SDK, AWS Amplify  
**Backend:** AWS Lambda (Python 3.12), API Gateway, DynamoDB, Cognito  
**Observability:** AWS ADOT, Honeycomb  
**Infrastructure:** Terraform

## Architecture

```
Vue.js Frontend (Browser Tracing)
    ↓
API Gateway
    ├─→ CreateOrderFunction → CouponServiceFunction → DynamoDB
    ├─→ GetOrderFunction → DynamoDB
    ├─→ ListOrdersFunction → DynamoDB
    └─→ ListProductsFunction
```

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Python 3.11+
- Node.js 18+
- Honeycomb account and API key
- S3 bucket for OTEL collector config

## Quick Start

### 1. Configure Honeycomb

```bash
# Edit collector.yaml with your Honeycomb API key
vim collector.yaml

# Upload to S3
aws s3 mb s3://your-account-id-otel --region ap-south-1
aws s3 cp collector.yaml s3://your-account-id-otel/collector.yaml
```

### 2. Deploy Backend

```bash
cd backend

# Initialize Terraform
terraform init

# Create terraform.tfvars
cat > terraform.tfvars << EOF
environment = "dev"
aws_region = "ap-south-1"
collector_config_s3_uri = "s3://your-account-id-otel.s3.ap-south-1.amazonaws.com/collector.yaml"
honeycomb_dataset = "shoptrace"
EOF

# Deploy
terraform apply
```

### 3. Create Test User

```bash
USER_POOL_ID=$(terraform output -raw user_pool_id)

aws cognito-idp admin-create-user \
    --user-pool-id $USER_POOL_ID \
    --username testuser@example.com \
    --user-attributes Name=email,Value=testuser@example.com Name=email_verified,Value=true \
    --temporary-password TempPass123! \
    --message-action SUPPRESS

aws cognito-idp admin-set-user-password \
    --user-pool-id $USER_POOL_ID \
    --username testuser@example.com \
    --password MyPassword123! \
    --permanent
```

### 4. Seed Sample Data

```bash
cd ../scripts
python insert_coupons.py
```

### 5. Deploy Frontend

```bash
cd ../frontend
npm install

# Create .env
cat > .env << EOF
VITE_API_BASE_URL=$(cd ../backend && terraform output -raw api_gateway_url)
VITE_USER_POOL_ID=$(cd ../backend && terraform output -raw user_pool_id)
VITE_USER_POOL_CLIENT_ID=$(cd ../backend && terraform output -raw user_pool_client_id)
VITE_HONEYCOMB_API_KEY=your_honeycomb_api_key
EOF

# Build
npm run build
```

## Testing

```bash
# Get auth token
ID_TOKEN=$(aws cognito-idp initiate-auth \
    --auth-flow USER_PASSWORD_AUTH \
    --client-id $(terraform output -raw user_pool_client_id) \
    --auth-parameters USERNAME=testuser@example.com,PASSWORD=MyPassword123! \
    --query 'AuthenticationResult.IdToken' \
    --output text)

API_URL=$(terraform output -raw api_gateway_url)

# List products
curl "$API_URL/products" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "x-session-id: test-session-123"

# Create order
curl -X POST "$API_URL/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "x-session-id: test-session-123" \
  -d '{
    "items": [{"name": "Product A", "price": 100, "quantity": 2}],
    "coupon_code": "SAVE20"
  }'
```

## Honeycomb Queries

```
# Session traces
session_id = "abc-123-def"

# User activity
user.email = "testuser@example.com"

# Failed orders
event.status = "Failure"

# Slow requests
duration_ms > 1000

# Coupon errors
error.no_data CONTAINS "Coupon"
```

## Cleanup

```bash
cd backend
terraform destroy
aws s3 rb s3://your-account-id-otel --force
```

## Project Structure

```
shoptrace/
├── backend/                    # Terraform infrastructure
│   ├── functions/              # Lambda functions
│   │   ├── create-order/
│   │   ├── get-order/
│   │   ├── list-orders/
│   │   ├── list-products/
│   │   └── coupon-service/
│   └── layers/                 # Lambda layers
│       └── honeycomb-layer/    # Shared tracing utilities
├── frontend/                   # Vue.js application
│   └── src/
├── scripts/                    # Utility scripts
└── collector.yaml              # OTEL collector config
```

## Resources

- [AWS ADOT](https://aws-otel.github.io/)
- [Honeycomb](https://docs.honeycomb.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [OpenTelemetry](https://opentelemetry.io/)
