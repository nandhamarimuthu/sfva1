"""Minimal contract test; intentionally does not cover failure paths."""

from main.code.handler import lambda_handler


def test_empty_event_returns_zero_processed():
    assert lambda_handler({}, None)["processed"] == 0
