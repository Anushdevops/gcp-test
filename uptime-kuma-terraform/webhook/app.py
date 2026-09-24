from flask import Flask, jsonify, request
from twilio.rest import Client
import os

app = Flask(__name__)
sid = os.getenv("TWILIO_ACCOUNT_SID", "")
token = os.getenv("TWILIO_AUTH_TOKEN", "")
sender = os.getenv("TWILIO_FROM_NUMBER", "")
targets = [x.strip() for x in os.getenv("TWILIO_TO_NUMBERS", "").split(",") if x.strip()]

@app.get("/health")
def health():
    return jsonify({"status": "ok"})

@app.route("/trigger-calls", methods=["GET", "POST"])
def trigger_calls():
    if not all([sid, token, sender]) or not targets:
        return jsonify({"error": "Twilio configuration is incomplete"}), 503
    payload = request.get_json(silent=True) or {}
    message = payload.get("message", "Uptime Kuma alert. A monitored service is down.")
    client = Client(sid, token)
    calls = []
    for number in targets:
        call = client.calls.create(
            twiml=f"<Response><Say>{message}</Say></Response>",
            to=number, from_=sender
        )
        calls.append(call.sid)
    return jsonify({"status": "calls_initiated", "call_sids": calls})
