#!/usr/bin/env bash
# Stop RAGUSKY backend / frontend started by start.sh.
# Kills pid + process group, then falls back to whoever still holds the port.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
RUN_DIR="$ROOT/.run"

BACKEND_PORT="${BACKEND_PORT:-8000}"
FRONTEND_PORT="${FRONTEND_PORT:-5173}"

kill_pid() {
  local pid="$1"
  [[ -n "$pid" ]] || return 0
  kill -- -"$pid" 2>/dev/null || true
  kill "$pid" 2>/dev/null || true
}

reap_port() {
  local name="$1" port="$2"
  local holders
  holders="$(lsof -ti ":$port" 2>/dev/null || true)"
  [[ -z "$holders" ]] && return 0
  echo "[stop] $name port $port still held by: $holders, killing"
  echo "$holders" | xargs kill 2>/dev/null || true
  sleep 1
  holders="$(lsof -ti ":$port" 2>/dev/null || true)"
  if [[ -n "$holders" ]]; then
    echo "[stop] $name port $port still held, SIGKILL"
    echo "$holders" | xargs kill -9 2>/dev/null || true
  fi
}

for entry in "frontend:$FRONTEND_PORT" "backend:$BACKEND_PORT"; do
  name="${entry%%:*}"
  port="${entry##*:}"
  pid_file="$RUN_DIR/$name.pid"
  if [[ -f "$pid_file" ]]; then
    pid="$(cat "$pid_file")"
    echo "[stop] $name pid $pid"
    kill_pid "$pid"
    rm -f "$pid_file"
  else
    echo "[stop] $name: no pid file"
  fi
  reap_port "$name" "$port"
done

echo "[stop] done"
