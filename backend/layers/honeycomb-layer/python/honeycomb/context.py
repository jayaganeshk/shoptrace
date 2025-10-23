from opentelemetry.context import attach, set_value
from .utils import get_user_context


def set_trace_context(event):
    """
    Set session_id and user_context in OpenTelemetry context.
    This will be automatically picked up by ContextEnrichmentProcessor
    and added to all spans.

    Call this once at the beginning of your Lambda handler.

    Args:
        session_id: Session identifier
        user_context: Dict with user_id, email, username
    """

    # Extract context first
    headers = event.get("headers", {})
    session_id = headers.get("x-session-id", "unknown")
    user_context = get_user_context(event)

    token1 = attach(set_value("session_id", session_id))
    token2 = attach(set_value("user_context", user_context))
    return token1, token2
