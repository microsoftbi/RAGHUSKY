#!/usr/bin/env bash
# Start RAGUSKY backend (uvicorn) and frontend (vite) in the background.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$ROOT/.run"
mkdir -p "$RUN_DIR"

BACKEND_PORT="${BACKEND_PORT:-8000}"
FRONTEND_PORT="${FRONTEND_PORT:-5173}"

echo "[start] backend on :$BACKEND_PORT"
(cd "$ROOT/backend" && nohup uv run uvicorn app.main:app \
  --host 0.0.0.0 --port "$BACKEND_PORT" \
  >"$RUN_DIR/backend.log" 2>&1 & echo $! >"$RUN_DIR/backend.pid")

echo "[start] frontend on :$FRONTEND_PORT"
(cd "$ROOT/frontend" && nohup pnpm dev --host --port "$FRONTEND_PORT" \
  >"$RUN_DIR/frontend.log" 2>&1 & echo $! >"$RUN_DIR/frontend.pid")

echo "[start] backend pid $(cat "$RUN_DIR/backend.pid"), frontend pid $(cat "$RUN_DIR/frontend.pid")"
echo "[start] logs: tail -f .run/backend.log .run/frontend.log"
