from opentelemetry.sdk.trace import SpanProcessor
from opentelemetry.context import get_value
from opentelemetry import trace
from datetime import datetime


class ContextEnrichmentProcessor(SpanProcessor):
    """
    Custom SpanProcessor that automatically adds session_id, user context,
    operation name, process time, and status to all spans.
    """

    def on_start(self, span, parent_context=None):
        """Called when a span is started - add common attributes"""

        # Get context from current execution context
        session_id = get_value("session_id")
        user_context = get_value("user_context")

        # Add session ID if available
        if session_id:
            span.set_attribute("session_id", session_id)

        # Add user context if available
        if user_context:
            span.set_attribute("user.id", user_context.get("user_id", "unknown"))
            span.set_attribute("user.email", user_context.get("email", "unknown"))
            span.set_attribute("user.username", user_context.get("username", "unknown"))

        # Add operation name from span name
        span.set_attribute("operation.name", span.name)

        # Add process time in UTC
        span.set_attribute("event.processTime", datetime.utcnow().isoformat() + "Z")

    def on_end(self, span):
        """Called when a span is ended"""
        pass

    def shutdown(self):
        """Called when the processor is shutdown"""
        pass

    def force_flush(self, timeout_millis=30000):
        """Force flush spans through the tracer provider"""
        try:
            tracer_provider = trace.get_tracer_provider()
            if hasattr(tracer_provider, "force_flush"):
                return tracer_provider.force_flush(timeout_millis)
        except Exception:
            pass
        return True
