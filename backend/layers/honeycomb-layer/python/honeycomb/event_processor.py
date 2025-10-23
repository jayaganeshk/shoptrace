import json

# from .context import set_trace_context
from .utils import get_user_context


def add_common_span_attributes(event, span):
    # Extract common context
    body = json.loads(event.get("body", "{}")) if event.get("body") else {}

    user_context = get_user_context(event)

    # Add common attributes
    span.set_attribute("event", json.dumps(event))
    span.set_attribute("event.method", event.get("httpMethod", ""))
    span.set_attribute("event.path", event.get("path", ""))
    span.set_attribute("event.input", json.dumps(body))

    # if method is GET, also include query params
    if event.get("httpMethod", "") == "GET":
        query_params = event.get("queryStringParameters") or {}
        span.set_attribute("event.input", json.dumps(query_params))

    if user_context.get("user_id"):
        span.set_attribute("user_id", user_context["user_id"])
