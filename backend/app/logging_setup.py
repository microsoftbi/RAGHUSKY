"""Centralised logging for RAGUSKY business events.

Three named loggers, each writing JSON-lines to its own rotating file under LOG/:

- `ragusky.ingest`    -> LOG/ingest.log     (files chunked & added)
- `ragusky.retrieval` -> LOG/retrieval.log  (admin retrieval-test queries + results)
- `ragusky.chat`      -> LOG/chat.log       (end-user queries + answers + citations)

Call `setup_logging()` once at process start (FastAPI lifespan + ingest script main).
"""

from __future__ import annotations

import json
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any

_BASE_DIR = Path(__file__).resolve().parent.parent.parent  # repo root
_LOG_DIR = _BASE_DIR / "LOG"

_INITIALISED = False


class _JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, Any] = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S"),
            "level": record.levelname,
            "logger": record.name,
            "msg": record.getMessage(),
        }
        extra = getattr(record, "extra_data", None)
        if isinstance(extra, dict):
            payload.update(extra)
        return json.dumps(payload, ensure_ascii=False)


def _make_handler(filename: str) -> RotatingFileHandler:
    _LOG_DIR.mkdir(parents=True, exist_ok=True)
    handler = RotatingFileHandler(
        _LOG_DIR / filename, maxBytes=10 * 1024 * 1024, backupCount=10, encoding="utf-8"
    )
    handler.setFormatter(_JsonFormatter())
    return handler


def setup_logging() -> None:
    global _INITIALISED
    if _INITIALISED:
        return
    for name, filename in [
        ("ragusky.ingest", "ingest.log"),
        ("ragusky.retrieval", "retrieval.log"),
        ("ragusky.chat", "chat.log"),
    ]:
        lg = logging.getLogger(name)
        lg.setLevel(logging.INFO)
        lg.propagate = False
        # Replace handlers on each call to keep tests/reload clean.
        for h in list(lg.handlers):
            lg.removeHandler(h)
        lg.addHandler(_make_handler(filename))
    _INITIALISED = True


def log_event(logger_name: str, event: str, **fields: Any) -> None:
    """Emit a structured business event.

    Example:
        log_event("ragusky.chat", "query", user_id=u, query=q, top_k=4)
    """
    logging.getLogger(logger_name).info(event, extra={"extra_data": {"event": event, **fields}})
