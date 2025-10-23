from opentelemetry.trace import Status, StatusCode
from .enums import HoneycombStatus, HoneycombErrorType


def add_user_context(span, user_context):
    """Add user context attributes to span"""
    span.set_attribute('user.id', user_context.get('user_id', 'unknown'))
    span.set_attribute('user.email', user_context.get('email', 'unknown'))
    span.set_attribute('user.username', user_context.get('username', 'unknown'))


def add_session_context(span, session_id):
    """Add session ID to span"""
    span.set_attribute('session_id', session_id)


def add_operation_name(span, operation_name):
    """Add operation name to span"""
    span.set_attribute('operation.name', operation_name)


def add_common_context(span, session_id, user_context, operation_name=None):
    """Add session, user context, and optionally operation name to span"""
    add_session_context(span, session_id)
    add_user_context(span, user_context)
    if operation_name:
        add_operation_name(span, operation_name)


def add_span_status(span, status: HoneycombStatus):
    """Set span status attribute"""
    span.set_attribute('event.status', status.value)


def add_span_exception(span, err, error_type: HoneycombErrorType):
    """Add exception details to span"""
    span.set_attribute('error.type', error_type.value)
    span.set_attribute('error.message', str(err))
    span.set_status(Status(StatusCode.ERROR))
    span.record_exception(err)
    span.set_attribute('event.status', HoneycombStatus.FAILURE.value)
