import json
import os
from datetime import datetime, timezone
import boto3
from opentelemetry import trace
from honeycomb.init import initialize_tracing
from honeycomb.context import set_trace_context
from honeycomb.common_attributes import add_span_exception, add_span_status
from honeycomb.enums import HoneycombStatus, HoneycombErrorType
from honeycomb.utils import get_user_context, get_cors_headers
from honeycomb.event_processor import add_common_span_attributes
from chaos_utils import inject_dynamodb_chaos

initialize_tracing()

dynamodb = boto3.resource("dynamodb")
coupons_table = dynamodb.Table(os.environ["COUPONS_TABLE"])

tracer = trace.get_tracer(__name__)


def lambda_handler(event, context):
    """Validate coupon without reducing usage count"""
    set_trace_context(event)

    with tracer.start_as_current_span("validate_coupon_preview") as span:
        try:
            body = json.loads(event.get("body", "{}"))
            coupon_code = body.get("coupon_code")
            if coupon_code:
                coupon_code = coupon_code.upper()

            add_common_span_attributes(event, span)

            span.set_attribute("coupon.code", coupon_code)

            if not coupon_code:
                add_span_status(span, HoneycombStatus.FAILURE)
                return {
                    "statusCode": 400,
                    "headers": get_cors_headers(),
                    "body": json.dumps(
                        {"valid": False, "error": "Coupon code is required"}
                    ),
                }

            inject_dynamodb_chaos()
            response = coupons_table.get_item(Key={"coupon_code": coupon_code})

            if "Item" not in response:
                add_span_status(span, HoneycombStatus.INVALID_DATA)
                return {
                    "statusCode": 200,
                    "headers": get_cors_headers(),
                    "body": json.dumps(
                        {"valid": False, "error": "Invalid coupon code"}
                    ),
                }

            coupon = response["Item"]

            if coupon.get("status") != "ACTIVE":
                add_span_status(span, HoneycombStatus.INVALID_DATA)
                return {
                    "statusCode": 200,
                    "headers": get_cors_headers(),
                    "body": json.dumps(
                        {
                            "valid": False,
                            "error": f"Coupon is {coupon.get('status', 'inactive')}",
                        }
                    ),
                }

            expiry_date = coupon.get("expiry_date")
            if expiry_date:
                expiry = datetime.fromisoformat(expiry_date)
                if expiry < datetime.now(timezone.utc):
                    return {
                        "statusCode": 200,
                        "headers": get_cors_headers(),
                        "body": json.dumps(
                            {"valid": False, "error": "Coupon has expired"}
                        ),
                    }

            max_usage = int(coupon.get("max_usage_count", 0))
            current_usage = int(coupon.get("current_usage_count", 0))

            if max_usage > 0 and current_usage >= max_usage:
                return {
                    "statusCode": 200,
                    "headers": get_cors_headers(),
                    "body": json.dumps(
                        {"valid": False, "error": "Coupon usage limit exceeded"}
                    ),
                }

            discount_percentage = float(coupon.get("discount_percentage", 0))
            add_span_status(span, HoneycombStatus.SUCCESS)

            return {
                "statusCode": 200,
                "headers": get_cors_headers(),
                "body": json.dumps(
                    {
                        "valid": True,
                        "discount_percentage": discount_percentage,
                        "coupon_code": coupon_code,
                    }
                ),
            }

        except Exception as e:
            add_span_exception(span, e, HoneycombErrorType.EXCEPTION)
            return {
                "statusCode": 500,
                "headers": get_cors_headers(),
                "body": json.dumps({"valid": False, "error": "Validation failed"}),
            }
