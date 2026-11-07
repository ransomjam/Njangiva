"""
NjangiSave Payment Backend Service (Flask + Fapshi)
Reuses AfroDocs' webhook + verification + idempotency architecture (`credited == True`)
and provides full CORS headers (`Access-Control-Allow-Origin`, preflight `OPTIONS`) for Flutter Web.
"""

import os
import uuid
from datetime import datetime
from flask import Flask, request, jsonify
import fapshi_integration

app = Flask(__name__)

# In-memory transaction ledger for local/staging runs (replace with SQLAlchemy/PostgreSQL in production)
TRANSACTIONS_DB = {}


@app.after_request
def add_cors_headers(response):
    """Ensure Flutter Web (and WASM/Chrome builds) receive required CORS headers."""
    response.headers['Access-Control-Allow-Origin'] = os.getenv('CORS_ALLOW_ORIGIN', '*')
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Client-Platform'
    return response


@app.route('/api/njangi/payment/initiate-deposit', methods=['POST', 'OPTIONS'])
def initiate_njangi_deposit():
    if request.method == 'OPTIONS':
        return ('', 204)

    data = request.get_json() or {}
    goal_id = data.get('goalId', '')
    goal_name = data.get('goalName', 'Njangi Deposit')
    amount = int(data.get('amount', 0))
    phone = data.get('phoneNumber', '')
    payment_method = data.get('paymentMethod', 'mtnMomo')
    user_id = str(data.get('userId', 'usr_001'))
    email = data.get('email', 'member@njangisave.cm')

    if amount < 100:
        return jsonify({'error': 'Minimum deposit amount is 100 FCFA'}), 400

    external_id = f"njangi_{goal_id}_{uuid.uuid4().hex[:8]}"
    app_url = os.getenv('APP_URL', 'http://localhost:8080')

    fapshi_payload = {
        'amount': amount,
        'email': email,
        'userId': user_id,
        'externalId': external_id,
        'redirectUrl': f'{app_url}/transactions?payment=complete',
        'message': f'NjangiSave Deposit - {goal_name}',
    }

    resp = fapshi_integration.initiate_pay(fapshi_payload)
    if resp.get('statusCode') != 200 or 'link' not in resp:
        return jsonify({
            'error': resp.get('message', 'Failed to initialize Fapshi payment'),
            'details': resp,
        }), 500

    trans_id = resp['transId']
    TRANSACTIONS_DB[trans_id] = {
        'transId': trans_id,
        'externalId': external_id,
        'userId': user_id,
        'goalId': goal_id,
        'goalName': goal_name,
        'amount': amount,
        'phoneNumber': phone,
        'paymentMethod': payment_method,
        'status': 'CREATED',
        'credited': False,
        'createdAt': datetime.utcnow().isoformat(),
        'updatedAt': datetime.utcnow().isoformat(),
    }

    return jsonify({
        'success': True,
        'link': resp['link'],
        'transId': trans_id,
        'externalId': external_id,
        'status': 'CREATED',
    }), 200


@app.route('/api/njangi/payment/webhook', methods=['POST'])
def fapshi_webhook():
    """
    Fapshi Webhook Handler — Reuses AfroDocs' server-side verification & idempotency latch:
    1. Always verify with `fapshi_integration.payment_status(trans_id)` before trusting payload.
    2. Use `credited == True` latch so duplicate webhooks/verifications never double-credit savings.
    """
    data = request.get_json() or {}
    trans_id = data.get('transId')
    if not trans_id:
        return jsonify({'error': 'No transId provided'}), 400

    status_info = fapshi_integration.payment_status(trans_id)
    if status_info.get('statusCode') != 200:
        return jsonify({'error': 'Could not verify transaction with Fapshi'}), 400

    real_status = status_info.get('status', 'PENDING')
    tx = TRANSACTIONS_DB.get(trans_id)
    if not tx:
        return jsonify({'message': 'Transaction not tracked locally'}), 200

    tx['status'] = real_status
    tx['updatedAt'] = datetime.utcnow().isoformat()

    if real_status == 'SUCCESSFUL' and not tx['credited']:
        tx['credited'] = True
        return jsonify({
            'message': 'Njangi savings goal credited successfully',
            'transId': trans_id,
            'credited': True,
        }), 200

    return jsonify({'message': f'Status updated to {real_status}', 'credited': tx['credited']}), 200


@app.route('/api/njangi/payment/verify', methods=['POST', 'OPTIONS'])
def verify_njangi_payment():
    """Manual / frontend verification endpoint with idempotency protection."""
    if request.method == 'OPTIONS':
        return ('', 204)

    data = request.get_json() or {}
    trans_id = data.get('transId')
    if not trans_id:
        return jsonify({'error': 'transId is required'}), 400

    tx = TRANSACTIONS_DB.get(trans_id)
    if tx and tx.get('credited'):
        return jsonify({
            'status': 'SUCCESSFUL',
            'transId': trans_id,
            'externalId': tx.get('externalId'),
            'amount': tx.get('amount'),
            'credited': True,
            'message': 'Already credited',
        }), 200

    status_info = fapshi_integration.payment_status(trans_id)
    if status_info.get('statusCode') != 200:
        return jsonify({'status': 'PENDING', 'transId': trans_id, 'credited': False}), 200

    real_status = status_info.get('status', 'PENDING')
    if tx:
        tx['status'] = real_status
        tx['updatedAt'] = datetime.utcnow().isoformat()
        if real_status == 'SUCCESSFUL' and not tx['credited']:
            tx['credited'] = True

    return jsonify({
        'status': real_status,
        'transId': trans_id,
        'externalId': tx.get('externalId') if tx else status_info.get('externalId'),
        'amount': tx.get('amount') if tx else status_info.get('amount'),
        'credited': tx.get('credited', real_status == 'SUCCESSFUL') if tx else (real_status == 'SUCCESSFUL'),
        'message': f'Transaction status: {real_status}',
    }), 200


@app.route('/api/njangi/payment/initiate-payout', methods=['POST', 'OPTIONS'])
def initiate_njangi_payout():
    """Initiate payout once a Njangi goal reaches its contribution date or lock rule allows."""
    if request.method == 'OPTIONS':
        return ('', 204)

    data = request.get_json() or {}
    goal_id = data.get('goalId', '')
    goal_name = data.get('goalName', 'Njangi Payout')
    amount = int(data.get('amount', 0))
    raw_phone = str(data.get('phoneNumber', '')).replace('+237', '').replace(' ', '').strip()

    resp = fapshi_integration.payout({
        'amount': amount,
        'phone': raw_phone,
        'message': f'NjangiSave Matured Payout - {goal_name} ({goal_id})',
    })

    if resp.get('statusCode') != 200:
        return jsonify({'error': resp.get('message', 'Payout failed')}), 400

    return jsonify({
        'status': 'SUCCESSFUL',
        'transId': resp.get('transId', f'PO{uuid.uuid4().hex[:8].upper()}'),
        'amount': amount,
        'credited': True,
        'message': 'Payout initiated via Fapshi',
    }), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', '5000')), debug=True)
