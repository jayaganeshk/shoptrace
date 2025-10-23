import json
from opentelemetry import trace
from honeycomb.init import initialize_tracing
from honeycomb.context import set_trace_context
from honeycomb.common_attributes import add_span_status
from honeycomb.enums import HoneycombStatus
from honeycomb.utils import get_user_context, get_cors_headers, DecimalEncoder
from honeycomb.event_processor import add_common_span_attributes
from chaos_utils import inject_dynamodb_chaos

initialize_tracing()
tracer = trace.get_tracer(__name__)

PRODUCTS = [
    {
        "id": 1,
        "name": "Wireless Headphones",
        "description": "Premium noise-cancelling wireless headphones",
        "price": 299.99,
        "image": "https://placehold.co/300x200/1976D2/white?text=Headphones",
        "category": "Electronics",
    },
    {
        "id": 2,
        "name": "Smart Watch",
        "description": "Fitness tracking smartwatch with heart rate monitor",
        "price": 199.99,
        "image": "https://placehold.co/300x200/1976D2/white?text=Smart+Watch",
        "category": "Electronics",
    },
    {
        "id": 3,
        "name": "Laptop Backpack",
        "description": "Durable laptop backpack with multiple compartments",
        "price": 79.99,
        "image": "https://placehold.co/300x200/1976D2/white?text=Backpack",
        "category": "Accessories",
    },
    {
        "id": 4,
        "name": "Bluetooth Speaker",
        "description": "Portable waterproof Bluetooth speaker",
        "price": 89.99,
        "image": "https://placehold.co/300x200/1976D2/white?text=Speaker",
        "category": "Electronics",
    },
    {
        "id": 5,
        "name": "USB-C Hub",
        "description": "7-in-1 USB-C hub with HDMI and card reader",
        "price": 49.99,
        "image": "https://placehold.co/300x200/1976D2/white?text=USB+Hub",
        "category": "Accessories",
    },
    {
        "id": 6,
        "name": "Wireless Mouse",
        "description": "Ergonomic wireless mouse with precision tracking",
        "price": 39.99,
        "image": "https://placehold.co/300x200/1976D2/white?text=Mouse",
        "category": "Accessories",
    },
]


def lambda_handler(event, context):
    set_trace_context(event)

    with tracer.start_as_current_span("list_products") as span:
        span.set_attribute("product_count", len(PRODUCTS))

        add_common_span_attributes(event, span)

        add_span_status(span, HoneycombStatus.SUCCESS)

        return {
            "statusCode": 200,
            "headers": get_cors_headers(),
            "body": json.dumps({"items": PRODUCTS}),
        }
