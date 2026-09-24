from flask import Flask, jsonify, request
from twilio.rest import Client
import os

app = Flask(__name__)

ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "")
AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "")
FROM_NUMBER = os.getenv("TWILIO_FROM_NUMBER", "")
TO_NUMBERS = [
    x.strip()
    for x in os.getenv("TWILIO_TO_NUMBERS", "").split(",")
    if x.strip()
]

@app.get("/health")
def health():
    return jsonify({"status": "ok"}), 200

@app.route("/trigger-calls", methods=["GET", "POST"])
def trigger_calls():
    if not ACCOUNT_SID or not AUTH_TOKEN or not FROM_NUMBER or not TO_NUMBERS:
        return jsonify({"error": "Twilio configuration is incomplete"}), 503

    payload = request.get_json(silent=True) or {}
    message = payload.get(
        "message",
        "Uptime Kuma alert. A monitored service is down."
    )

    client = Client(ACCOUNT_SID, AUTH_TOKEN)
    call_sids = []

    for number in TO_NUMBERS:
        call = client.calls.create(
            twiml=f"<Response><Say>{message}</Say></Response>",
            to=number,
            from_=FROM_NUMBER,
        )
        call_sids.append(call.sid)

    return jsonify({
        "status": "calls_initiated",
        "call_sids": call_sids
    }), 200
