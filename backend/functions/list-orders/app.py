import json
import os
import base64
import boto3
from boto3.dynamodb.conditions import Key
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
    """List all orders for the authenticated user"""

    # Extract context first
    set_trace_context(event)

    with tracer.start_as_current_span("list_orders") as span:
        try:
            user_context = get_user_context(event)

            # Get pagination params
            query_params = event.get("queryStringParameters") or {}
            page_size = int(query_params.get("page_size", 100))
            after = query_params.get("after")

            add_common_span_attributes(event, span)

            # Build query params
            query_kwargs = {
                "KeyConditionExpression": Key("user_id").eq(user_context["user_id"]),
                "Limit": page_size,
                "ScanIndexForward": False,
            }

            # Add exclusive start key if cursor provided
            if after:
                try:
                    start_key = json.loads(base64.b64decode(after).decode())
                    query_kwargs["ExclusiveStartKey"] = start_key
                    span.set_attribute("pagination.has_cursor", True)
                except Exception as e:
                    span.set_attribute("pagination.cursor_error", str(e))

            # Query orders
            inject_dynamodb_chaos()
            response = orders_table.query(**query_kwargs)

            span.set_attribute("order_count", len(response["Items"]))
            add_span_status(span, HoneycombStatus.SUCCESS)

            # Build response
            result = {"items": response["Items"]}

            # Add next cursor if more results exist
            if "LastEvaluatedKey" in response:
                next_cursor = base64.b64encode(
                    json.dumps(response["LastEvaluatedKey"]).encode()
                ).decode()
                result["after"] = next_cursor
                span.set_attribute("pagination.has_more", True)

            return {
                "statusCode": 200,
                "headers": get_cors_headers(),
                "body": json.dumps(result, cls=DecimalEncoder),
            }

        except Exception as e:
            add_span_exception(span, e, HoneycombErrorType.EXCEPTION)
            return {
                "statusCode": 500,
                "headers": get_cors_headers(),
                "body": json.dumps({"error": str(e)}),
            }
