import json
from decimal import Decimal


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder for Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def get_user_context(event):
    """Extract user context from Cognito authorizer"""
    claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
    return {
        'user_id': claims.get('sub', 'unknown'),
        'email': claims.get('email', 'unknown'),
        'username': claims.get('cognito:username', 'unknown')
    }


def get_cors_headers():
    """Return CORS headers"""
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,x-session-id,traceparent,tracestate',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    }
