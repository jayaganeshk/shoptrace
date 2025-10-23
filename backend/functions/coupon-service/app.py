import json
import os
from datetime import datetime, timezone
import boto3
from opentelemetry import trace
from honeycomb.init import initialize_tracing
from honeycomb.context import set_trace_context
from honeycomb.common_attributes import add_span_exception, add_span_status
from honeycomb.enums import HoneycombStatus, HoneycombErrorType
from honeycomb.event_processor import add_common_span_attributes
from chaos_utils import inject_dynamodb_chaos

# Initialize custom tracing processor
initialize_tracing()

dynamodb = boto3.resource("dynamodb")
coupons_table = dynamodb.Table(os.environ["COUPONS_TABLE"])

tracer = trace.get_tracer(__name__)


def lambda_handler(event, context):
    """Main Lambda handler for coupon service"""
    set_trace_context(event)

    with tracer.start_as_current_span("validate_coupon") as span:
        try:

            # Extract context first
            body = event.get("body", {})
            if isinstance(body, str):
                body = json.loads(body)
            coupon_code = body.get("coupon_code")
            span.set_attribute("coupon.code", coupon_code)

            # Add event input to span
            # add_common_span_attributes(event, span)
            # span.set_attribute("event.input", json.dumps(event))

            if not coupon_code:
                span.set_attribute("error.invalid_data", "Coupon code is required")
                add_span_status(span, HoneycombStatus.FAILURE)
                response = {"valid": False, "error": "Coupon code is required"}
                span.set_attribute("event.response", json.dumps(response))
                return response

            # Query DynamoDB for coupon
            with tracer.start_as_current_span("query_coupon_dynamodb") as db_span:
                db_span.set_attribute("coupon.code", coupon_code)

                inject_dynamodb_chaos()
                response = coupons_table.get_item(Key={"coupon_code": coupon_code})

                if "Item" not in response:
                    db_span.set_attribute("error.no_data", "Coupon code not found")
                    add_span_status(db_span, HoneycombStatus.FAILURE)
                    add_span_exception(
                        span,
                        ValueError("Invalid coupon code"),
                        HoneycombErrorType.INVALID_DATA,
                    )

                    response = {"valid": False, "error": "Invalid coupon code"}
                    span.set_attribute("event.response", json.dumps(response))
                    return response

                coupon = response["Item"]
                add_span_status(db_span, HoneycombStatus.SUCCESS)

            # Validate coupon status
            with tracer.start_as_current_span("validate_coupon_rules") as validate_span:
                validate_span.set_attribute(
                    "coupon.status", coupon.get("status", "UNKNOWN")
                )

                # Check if coupon is active
                if coupon.get("status") != "ACTIVE":
                    error_msg = f"Coupon is {coupon.get('status', 'inactive')}"
                    validate_span.set_attribute("error.invalid_data", error_msg)
                    add_span_status(validate_span, HoneycombStatus.FAILURE)
                    add_span_exception(
                        span, ValueError(error_msg), HoneycombErrorType.INVALID_DATA
                    )
                    response = {"valid": False, "error": error_msg}
                    span.set_attribute("event.response", json.dumps(response))
                    return response

                # Check expiry date
                expiry_date = coupon.get("expiry_date")
                if expiry_date:
                    expiry = datetime.fromisoformat(expiry_date)
                    now = datetime.now(timezone.utc)
                    if expiry < now:
                        error_msg = f"Coupon expired on {expiry_date}"
                        validate_span.set_attribute("error.invalid_data", error_msg)
                        validate_span.set_attribute("coupon.expiry_date", expiry_date)
                        add_span_status(validate_span, HoneycombStatus.FAILURE)
                        add_span_exception(
                            span, ValueError(error_msg), HoneycombErrorType.INVALID_DATA
                        )

                        response = {"valid": False, "error": error_msg}
                        span.set_attribute("event.response", json.dumps(response))
                        return response

                # Check usage limit
                max_usage = int(coupon.get("max_usage_count", 0))
                current_usage = int(coupon.get("current_usage_count", 0))

                validate_span.set_attribute("coupon.max_usage", max_usage)
                validate_span.set_attribute("coupon.current_usage", current_usage)

                if max_usage > 0 and current_usage >= max_usage:
                    error_msg = "Coupon usage limit exceeded"
                    validate_span.set_attribute("error.invalid_data", error_msg)
                    add_span_status(validate_span, HoneycombStatus.FAILURE)
                    add_span_exception(
                        span, ValueError(error_msg), HoneycombErrorType.INVALID_DATA
                    )
                    response = {"valid": False, "error": error_msg}
                    span.set_attribute("event.response", json.dumps(response))
                    return response

                add_span_status(validate_span, HoneycombStatus.SUCCESS)

            # Coupon is valid
            discount_percentage = float(coupon.get("discount_percentage", 0))
            span.set_attribute("coupon.discount", discount_percentage)
            add_span_status(span, HoneycombStatus.SUCCESS)

            response = {
                "valid": True,
                "discount_percentage": discount_percentage,
                "coupon_code": coupon_code,
            }
            span.set_attribute("event.response", json.dumps(response))
            return response

        except Exception as e:
            add_span_exception(span, e, HoneycombErrorType.EXCEPTION)
            response = {"valid": False, "error": f"Coupon validation failed: {str(e)}"}
            span.set_attribute("event.response", json.dumps(response))
            return response
