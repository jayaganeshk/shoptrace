import json
import random
import time
import boto3
from botocore.exceptions import ClientError
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

ssm_client = boto3.client("ssm")


@tracer.start_as_current_span("get_chaos_config")
def get_chaos_config(parameter_name="/dev/order-processing/chaos/dynamodb"):
    """Get chaos configuration from SSM parameter"""
    try:
        response = ssm_client.get_parameter(Name=parameter_name)
        return json.loads(response["Parameter"]["Value"])
    except (ClientError, json.JSONDecodeError):
        return {"enabled": False}


def inject_dynamodb_chaos():
    """Inject chaos before DynamoDB operations"""
    with tracer.start_as_current_span("inject_dynamodb_chaos") as span:
        config = get_chaos_config()
        span.set_attribute("chaos_config", json.dumps(config))

        if not config.get("enabled", False):
            return

        # Inject latency
        latency_config = config.get("latency", {})
        if latency_config.get("enabled", False):
            with tracer.start_as_current_span("inject_latency"):
                if random.random() < latency_config.get("probability", 0):
                    delay = (
                        random.randint(
                            latency_config.get("min_ms", 1000),
                            latency_config.get("max_ms", 3000),
                        )
                        / 1000.0
                    )
                    time.sleep(delay)
                return

        # Inject exceptions
        exception_config = config.get("exceptions", {})
        if exception_config.get("enabled", False):
            if random.random() < exception_config.get("probability", 0):
                error_types = exception_config.get("types", ["throttling"])
                error_type = random.choice(error_types)

                if error_type == "throttling":
                    raise ClientError(
                        {"Error": {"Code": "ProvisionedThroughputExceededException"}},
                        "DynamoDB",
                    )
                elif error_type == "timeout":
                    raise ClientError({"Error": {"Code": "RequestTimeout"}}, "DynamoDB")
                elif error_type == "service_unavailable":
                    raise ClientError(
                        {"Error": {"Code": "ServiceUnavailable"}}, "DynamoDB"
                    )
