#!/usr/bin/env python3
"""Insert sample coupon data into DynamoDB"""

import boto3
from datetime import datetime, timedelta, timezone
from decimal import Decimal

# Configuration
ENVIRONMENT = "dev"
TABLE_NAME = f"{ENVIRONMENT}-coupons"

# Sample coupons
COUPONS = [
    {
        "coupon_code": "SCD10",
        "status": "ACTIVE",
        "discount_percentage": Decimal("10"),
        "expiry_date": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
        "max_usage_count": 100,
        "current_usage_count": 0,
    },
    {
        "coupon_code": "SCD25",
        "status": "ACTIVE",
        "discount_percentage": Decimal("25"),
        "expiry_date": (datetime.now(timezone.utc) + timedelta(days=60)).isoformat(),
        "max_usage_count": 50,
        "current_usage_count": 0,
    },
    {
        "coupon_code": "SCD50",
        "status": "ACTIVE",
        "discount_percentage": Decimal("50"),
        "expiry_date": (datetime.now(timezone.utc) + timedelta(days=7)).isoformat(),
        "max_usage_count": 10,
        "current_usage_count": 0,
    },
    {
        "coupon_code": "EXPIRED",
        "status": "ACTIVE",
        "discount_percentage": Decimal("25"),
        "expiry_date": (datetime.now(timezone.utc) - timedelta(days=1)).isoformat(),
        "max_usage_count": 100,
        "current_usage_count": 0,
    },
    {
        "coupon_code": "MAXEDOUT",
        "status": "ACTIVE",
        "discount_percentage": Decimal("15"),
        "expiry_date": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
        "max_usage_count": 5,
        "current_usage_count": 5,
    },
    {
        "coupon_code": "INACTIVE",
        "status": "INACTIVE",
        "discount_percentage": Decimal("30"),
        "expiry_date": (datetime.now(timezone.utc) + timedelta(days=30)).isoformat(),
        "max_usage_count": 100,
        "current_usage_count": 0,
    },
]


def insert_coupons():
    """Insert coupons into DynamoDB"""
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(TABLE_NAME)

    print(f"Inserting coupons into {TABLE_NAME}...")

    for coupon in COUPONS:
        try:
            table.put_item(Item=coupon)
            print(
                f"✓ Inserted: {coupon['coupon_code']} ({coupon['discount_percentage']}% off)"
            )
        except Exception as e:
            print(f"✗ Failed to insert {coupon['coupon_code']}: {e}")

    print("\nDone!")


if __name__ == "__main__":
    insert_coupons()
