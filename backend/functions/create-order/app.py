import json
import os
from datetime import datetime
from decimal import Decimal
import boto3
from ulid import ULID
from opentelemetry import trace
from honeycomb.init import initialize_tracing
from honeycomb.context import set_trace_context
from honeycomb.common_attributes import add_span_exception, add_span_status
from honeycomb.enums import HoneycombStatus, HoneycombErrorType
from honeycomb.utils import get_user_context, get_cors_headers
from honeycomb.event_processor import add_common_span_attributes
from chaos_utils import inject_dynamodb_chaos

# Initialize custom tracing processor
initialize_tracing()

dynamodb = boto3.resource("dynamodb")
lambda_client = boto3.client("lambda")
orders_table = dynamodb.Table(os.environ["ORDERS_TABLE"])
coupon_service_function = os.environ["COUPON_SERVICE_FUNCTION"]

tracer = trace.get_tracer(__name__)


def lambda_handler(event, context):
    """Create a new order"""

    # Extract context first
    body = json.loads(event.get("body", "{}"))
    headers = event.get("headers", {})
    session_id = headers.get("x-session-id", "unknown")

    user_context = get_user_context(event)

    set_trace_context(event)

    with tracer.start_as_current_span("create_order") as span:
        try:
            # Add event input to span
            add_common_span_attributes(event, span)

            # Extract context first
            body = json.loads(event.get("body", "{}"))

            # Validate order
            with tracer.start_as_current_span("validate_order"):
                items = body.get("items", [])
                if not items:
                    raise ValueError("Order must contain at least one item")

                for item in items:
                    if item.get("quantity", 0) <= 0:
                        raise ValueError("Item quantity must be positive")

                add_span_status(span, HoneycombStatus.SUCCESS)

            # Calculate base price
            with tracer.start_as_current_span("calculate_price") as price_span:
                total_price = sum(item["price"] * item["quantity"] for item in items)
                price_span.set_attribute("base_price", float(total_price))

            # Validate coupon if provided
            discount = 0
            coupon_code = body.get("coupon_code")
            if coupon_code:
                with tracer.start_as_current_span("validate_coupon") as coupon_span:
                    coupon_span.set_attribute("coupon.code", coupon_code)

                    coupon_result = invoke_coupon_service(
                        coupon_code, session_id, user_context, event
                    )

                    print("Coupon result:", coupon_result)
                    span.set_attribute("coupon.result", json.dumps(coupon_result))

                    if coupon_result["valid"]:
                        discount = coupon_result["discount_percentage"]
                        total_price = round(total_price * (1 - discount / 100), 2)
                        coupon_span.set_attribute("coupon.discount", discount)
                        add_span_status(coupon_span, HoneycombStatus.SUCCESS)
                    else:
                        error_msg = coupon_result["error"]
                        add_span_exception(
                            coupon_span,
                            ValueError(error_msg),
                            HoneycombErrorType.INVALID_DATA,
                        )
                        add_span_exception(
                            span, ValueError(error_msg), HoneycombErrorType.INVALID_DATA
                        )
                        return {
                            "statusCode": 400,
                            "headers": get_cors_headers(),
                            "body": json.dumps({"error": error_msg}),
                        }

            # Save order to DynamoDB
            with tracer.start_as_current_span("save_order_to_dynamodb") as db_span:
                order_id = str(ULID())

                # Convert items to use Decimal for DynamoDB
                items_decimal = [
                    {
                        **item,
                        "price": Decimal(str(item["price"])),
                        "quantity": item["quantity"],
                    }
                    for item in items
                ]

                order = {
                    "user_id": user_context["user_id"],
                    "order_id": order_id,
                    "session_id": session_id,
                    "user_email": user_context["email"],
                    "items": items_decimal,
                    "coupon_code": coupon_code or "none",
                    "discount_percentage": Decimal(str(discount)),
                    "total_price": Decimal(str(total_price)),
                    "status": "CREATED",
                    "created_at": datetime.utcnow().isoformat(),
                }

                inject_dynamodb_chaos()
                orders_table.put_item(Item=order)
                db_span.set_attribute("order_id", order_id)
                db_span.set_attribute("user_id", user_context["user_id"])
                add_span_status(db_span, HoneycombStatus.SUCCESS)

            add_span_status(span, HoneycombStatus.SUCCESS)

            return {
                "statusCode": 201,
                "headers": get_cors_headers(),
                "body": json.dumps(
                    {
                        "order_id": order_id,
                        "total_price": round(float(total_price), 2),
                        "discount_applied": discount,
                        "status": "CREATED",
                    }
                ),
            }

        except ValueError as e:
            add_span_exception(span, e, HoneycombErrorType.INVALID_DATA)
            return {
                "statusCode": 400,
                "headers": get_cors_headers(),
                "body": json.dumps({"error": str(e)}),
            }
        except Exception as e:
            add_span_exception(span, e, HoneycombErrorType.EXCEPTION)
            return {
                "statusCode": 500,
                "headers": get_cors_headers(),
                "body": json.dumps({"error": str(e)}),
            }


def invoke_coupon_service(coupon_code, session_id, user_context, event):
    """Invoke coupon service Lambda function"""

    with tracer.start_as_current_span("invoke_coupon_service") as span:
        span.set_attribute("coupon.code", coupon_code)

        try:
            payload = {
                "body": {
                    "coupon_code": coupon_code,
                    "session_id": session_id,
                    "user_context": user_context,
                },
                "headers": event.get("headers", {}),
                "requestContext": event.get("requestContext", {}),
            }

            response = lambda_client.invoke(
                FunctionName=coupon_service_function,
                InvocationType="RequestResponse",
                Payload=json.dumps(payload),
            )

            result = json.loads(response["Payload"].read())
            add_span_status(span, HoneycombStatus.SUCCESS)
            return result

        except Exception as e:
            span.set_attribute("error.exception", str(e))
            add_span_status(span, HoneycombStatus.FAILURE)
            return {"valid": False, "error": "Coupon service unavailable"}
