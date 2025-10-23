from opentelemetry import trace
from .span_processor import ContextEnrichmentProcessor


def initialize_tracing():
    """
    Initialize custom tracing with ContextEnrichmentProcessor.
    Call this once when your Lambda function initializes (outside handler).
    """
    tracer_provider = trace.get_tracer_provider()
    
    # Add custom processor to automatically enrich spans
    if hasattr(tracer_provider, 'add_span_processor'):
        tracer_provider.add_span_processor(ContextEnrichmentProcessor())
