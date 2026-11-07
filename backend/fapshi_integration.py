"""
Fapshi Payment Gateway Integration Module for NjangiSave
Adapted directly from AfroDocs' production Fapshi integration (`pattern-formatter/backend/fapshi_integration.py`).
Supports Cameroon Mobile Money (MTN MoMo & Orange Money) collections, status checks, expiration, and payouts.
"""

import os
import re
from typing import Dict, Any, List
import requests

# Environment variables — never hardcode Fapshi credentials in frontend/mobile builds
API_USER = os.getenv('FAPSHI_API_USER', 'your_api_user_here')
API_KEY = os.getenv('FAPSHI_API_KEY', 'your_api_key_here')
BASE_URL = os.getenv('FAPSHI_BASE_URL', 'https://sandbox.fapshi.com')

HEADERS = {
    'Content-Type': 'application/json',
    'apiuser': API_USER,
    'apikey': API_KEY,
}


def check_Integer(value: Any) -> bool:
    """Validate if value is an integer."""
    return isinstance(value, int) and not isinstance(value, bool)


def check_String(value: Any) -> bool:
    """Validate if value is a non-empty string."""
    return isinstance(value, str) and len(value.strip()) > 0


def check_Email(email: str) -> bool:
    """Validate email format."""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def error_response(message: str, status_code: int = 400) -> Dict[str, Any]:
    """Generate standardized error response."""
    return {
        'message': message,
        'statusCode': status_code,
    }


def initiate_pay(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate a payment link or mobile money prompt where users complete NjangiSave deposits.

    Required fields:
    - amount (integer >= 100 FCFA)

    Optional fields:
    - email (string)
    - redirectUrl (string)
    - userId (string, ^[a-zA-Z0-9\\-_]{1,100}$)
    - externalId (string, ^[a-zA-Z0-9\\-_]{1,100}$)
    - message (string)
    """
    if not isinstance(data, dict):
        return error_response('invalid type, data must be a dictionary')

    if 'amount' not in data:
        return error_response('amount required')
    if not check_Integer(data['amount']):
        return error_response('amount must be of type integer')
    if data['amount'] < 100:
        return error_response('amount cannot be less than 100 XAF')

    if 'email' in data and data['email']:
        if not check_String(data['email']):
            return error_response('email must be of type string')
        if not check_Email(data['email']):
            return error_response('invalid email')

    if 'redirectUrl' in data and data['redirectUrl']:
        if not check_String(data['redirectUrl']):
            return error_response('redirectUrl must be of type string')

    if 'userId' in data and data['userId']:
        if not check_String(data['userId']):
            return error_response('userId must be of type string')
        if not re.match(r'^[a-zA-Z0-9\-_]{1,100}$', data['userId']):
            return error_response('invalid userId')

    if 'externalId' in data and data['externalId']:
        if not check_String(data['externalId']):
            return error_response('externalId must be of type string')
        if not re.match(r'^[a-zA-Z0-9\-_]{1,100}$', data['externalId']):
            return error_response('invalid externalId')

    if 'message' in data and data['message']:
        if not check_String(data['message']):
            return error_response('message must be of type string')

    url = f'{BASE_URL}/initiate-pay'
    try:
        response = requests.post(url=url, json=data, headers=HEADERS, timeout=30)
        result = response.json()
        result['statusCode'] = response.status_code
        return result
    except requests.exceptions.RequestException as e:
        return error_response(f'request failed: {str(e)}', 500)
    except Exception as e:
        return error_response(f'unexpected error: {str(e)}', 500)


def payment_status(trans_id: str) -> Dict[str, Any]:
    """
    Retrieve the canonical status of a transaction by Fapshi transId (8-10 alphanumeric chars).
    Statuses: CREATED, PENDING, SUCCESSFUL, FAILED, EXPIRED.
    """
    if not check_String(trans_id):
        return error_response('invalid type, transId must be a string of type ^[a-zA-Z0-9]{8,10}$')
    if not re.match(r'^[a-zA-Z0-9]{8,10}$', trans_id):
        return error_response('invalid transId')

    url = f'{BASE_URL}/payment-status/{trans_id}'
    try:
        response = requests.get(url=url, headers=HEADERS, timeout=30)
        result = response.json()
        result['statusCode'] = response.status_code
        return result
    except requests.exceptions.RequestException as e:
        return error_response(f'request failed: {str(e)}', 500)
    except Exception as e:
        return error_response(f'unexpected error: {str(e)}', 500)


def expire_pay(trans_id: str) -> Dict[str, Any]:
    """Invalidate a payment link to prevent further payments."""
    if not check_String(trans_id):
        return error_response('invalid type, transId must be a string of type ^[a-zA-Z0-9]{8,10}$')
    if not re.match(r'^[a-zA-Z0-9]{8,10}$', trans_id):
        return error_response('invalid transId')

    data = {'transId': trans_id}
    url = f'{BASE_URL}/expire-pay'
    try:
        response = requests.post(url=url, json=data, headers=HEADERS, timeout=30)
        result = response.json()
        result['statusCode'] = response.status_code
        return result
    except requests.exceptions.RequestException as e:
        return error_response(f'request failed: {str(e)}', 500)
    except Exception as e:
        return error_response(f'unexpected error: {str(e)}', 500)


def payout(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Initiate a payout / withdrawal to a user's Mobile Money (MTN MoMo / Orange Money) account
    once a NjangiSave goal reaches its maturity date or meets withdrawal rules.
    """
    if not isinstance(data, dict):
        return error_response('invalid type, data must be a dictionary')

    if 'amount' not in data:
        return error_response('amount required')
    if not check_Integer(data['amount']):
        return error_response('amount must be of type integer')
    if data['amount'] < 100:
        return error_response('amount cannot be less than 100 XAF')

    if 'phone' not in data:
        return error_response('phone number required')
    if not check_String(data['phone']):
        return error_response('phone must be of type string')
    if not re.match(r'^6[0-9]{8}$', data['phone']):
        return error_response('invalid Cameroon phone number (must be 9 digits starting with 6)')

    url = f'{BASE_URL}/payout'
    try:
        response = requests.post(url=url, json=data, headers=HEADERS, timeout=30)
        result = response.json()
        result['statusCode'] = response.status_code
        return result
    except requests.exceptions.RequestException as e:
        return error_response(f'request failed: {str(e)}', 500)
    except Exception as e:
        return error_response(f'unexpected error: {str(e)}', 500)
