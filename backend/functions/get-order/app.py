import json
import os
import boto3
from opentelemetry import trace
from honeycomb.init import initialize_tracing
from honeycomb.context import set_trace_context
from honeycomb.common_attributes import add_span_exception, add_span_status
from honeycomb.enums import HoneycombStatus, HoneycombErrorType
from honeycomb.utils import get_user_context, get_cors_headers, DecimalEncoder
from honeycomb.event_processor import add_common_span_attributes
from chaos_utils import inject_dynamodb_chaos

# Initialize custom tracing processor
initialize_tracing()

dynamodb = boto3.resource("dynamodb")
orders_table = dynamodb.Table(os.environ["ORDERS_TABLE"])

tracer = trace.get_tracer(__name__)


def lambda_handler(event, context):
    """Get order by ID"""
    set_trace_context(event)

    with tracer.start_as_current_span("get_order") as span:
        try:
            # Extract context first
            add_common_span_attributes(event, span)

            order_id = event["pathParameters"]["order_id"]
            user_context = get_user_context(event)

            span.set_attribute("order_id", order_id)

            # Get order from DynamoDB using composite key
            inject_dynamodb_chaos()
            response = orders_table.get_item(
                Key={"user_id": user_context["user_id"], "order_id": order_id}
            )

            if "Item" not in response:
                span.set_attribute("error.no_data", "Order not found")
                add_span_status(span, HoneycombStatus.FAILURE)
                return {
                    "statusCode": 404,
                    "headers": get_cors_headers(),
                    "body": json.dumps({"error": "Order not found"}),
                }

            add_span_status(span, HoneycombStatus.SUCCESS)

            return {
                "statusCode": 200,
                "headers": get_cors_headers(),
                "body": json.dumps(response["Item"], cls=DecimalEncoder),
            }

        except Exception as e:
            add_span_exception(span, e, HoneycombErrorType.EXCEPTION)
            return {
                "statusCode": 500,
                "headers": get_cors_headers(),
                "body": json.dumps({"error": str(e)}),
            }
