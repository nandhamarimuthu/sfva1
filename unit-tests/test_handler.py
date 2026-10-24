"""Deliberately sparse tests: this fixture should show low test coverage."""

import json

from main.code.handler import lambda_handler


def test_handler_processes_one_record():
    event = {"Records": [{"body": json.dumps({"job_id": "demo-1"})}]}
    result = lambda_handler(event, None)
    assert result["statusCode"] == 200
    assert result["processed"] == 1
