# Scripts

## Insert Coupons

Seeds DynamoDB with sample coupon data.

```bash
pip install boto3
python insert_coupons.py
```

Edit `ENVIRONMENT` variable to match your deployment (dev/prod).

### Sample Coupons

- **SCD10**: 10% off, 100 uses
- **SCD20**: 20% off, 50 uses
- **SCD50**: 50% off, 10 uses
- **EXPIRED**: Expired coupon (testing)
- **MAXEDOUT**: Usage limit reached (testing)
- **INACTIVE**: Inactive status (testing)
