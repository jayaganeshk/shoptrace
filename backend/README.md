# ShopTrace Backend Infrastructure

Terraform configuration for deploying ShopTrace AWS infrastructure.

## Resources

- **Cognito**: User authentication
- **DynamoDB**: Orders and Coupons tables
- **Lambda**: 5 functions with ADOT tracing
  - create-order
  - get-order
  - list-orders
  - list-products
  - coupon-service
  - validate-coupon
- **Lambda Layers**: Honeycomb tracing, Chaos engineering
- **API Gateway**: REST API with Cognito auth
- **Amplify**: Frontend hosting

## Deployment

```bash
terraform init -backend-config="dev/backend.hcl"
terraform plan -var-file="dev/variable.tfvars" -out tf-output.tfplan

terraform apply tf-output.tfplan
```

## Outputs

```bash
terraform output api_gateway_url
terraform output user_pool_id
terraform output user_pool_client_id
```

## Cleanup

```bash
terraform destroy -var-file="dev/variable.tfvars"
```
