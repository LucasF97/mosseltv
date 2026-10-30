#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sleep 5 # wacht even tot netwerk is opgestart

source "$SCRIPT_DIR/venv/bin/activate"

export DISPLAY="${DISPLAY:-:99}"
if command -v Xvfb >/dev/null 2>&1 && ! pgrep -af "Xvfb ${DISPLAY}" >/dev/null 2>&1; then
  Xvfb "$DISPLAY" -screen 0 1920x1080x24 >/dev/null 2>&1 &
  sleep 1
fi

python3 "$SCRIPT_DIR/app.py"
