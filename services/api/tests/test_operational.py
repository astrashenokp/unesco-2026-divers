"""Operational endpoint and trace propagation tests."""

from fastapi.testclient import TestClient

from evidence_gym_api.app import create_app


class UnavailableProbe:
    async def is_ready(self) -> bool:
        return False


def test_health_is_live_and_returns_trace_id() -> None:
    with TestClient(create_app()) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "alive"}
    assert response.headers["X-Trace-ID"]


def test_valid_incoming_trace_id_is_propagated() -> None:
    trace_id = "client-trace-1234"
    with TestClient(create_app()) as client:
        response = client.get("/health", headers={"X-Trace-ID": trace_id})

    assert response.headers["X-Trace-ID"] == trace_id


def test_unsafe_trace_id_is_replaced() -> None:
    unsafe_trace_id = "<untrusted-trace>"
    with TestClient(create_app()) as client:
        response = client.get("/health", headers={"X-Trace-ID": unsafe_trace_id})

    assert response.headers["X-Trace-ID"] != unsafe_trace_id


def test_readiness_is_distinct_from_liveness() -> None:
    with TestClient(create_app(readiness_probe=UnavailableProbe())) as client:
        health_response = client.get("/health")
        ready_response = client.get("/ready")

    assert health_response.status_code == 200
    assert ready_response.status_code == 503
    assert ready_response.headers["content-type"].startswith(
        "application/problem+json"
    )
    assert ready_response.json() == {
        "type": "about:blank",
        "title": "Service not ready",
        "status": 503,
        "code": "service_not_ready",
        "detail": "Required runtime dependencies are unavailable.",
        "traceId": ready_response.headers["X-Trace-ID"],
    }
