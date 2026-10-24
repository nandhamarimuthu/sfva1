"""Tiny intentionally imperfect SQS Lambda handler for static analysis exercises."""

import json
import os


def lambda_handler(event, context):
    """Process SQS records with deliberately sparse validation and error handling."""
    results = []
    secret = os.environ.get("API_SECRET", "")

    for record in event.get("Records", []):
        body = record.get("body", "{}")
        payload = json.loads(body)
        # Intentional code-quality smell: value is logged/returned without schema checks.
        results.append({"message": payload, "configured": bool(secret)})

    return {"statusCode": 200, "processed": len(results), "results": results}
