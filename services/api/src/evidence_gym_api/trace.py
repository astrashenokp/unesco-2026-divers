"""Trace identifier validation and request access."""

import re
from uuid import uuid4

from fastapi import Request

TRACE_ID_HEADER = "X-Trace-ID"
_SAFE_TRACE_ID = re.compile(r"^[A-Za-z0-9._-]{8,128}$")


def normalize_trace_id(candidate: str | None) -> str:
    """Reuse bounded safe identifiers and replace all other input."""

    if candidate is not None and _SAFE_TRACE_ID.fullmatch(candidate):
        return candidate
    return str(uuid4())


def get_trace_id(request: Request) -> str:
    """Return the middleware-provided identifier, with a defensive fallback."""

    return getattr(request.state, "trace_id", str(uuid4()))

