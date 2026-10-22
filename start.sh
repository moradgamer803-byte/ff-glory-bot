#!/usr/bin/env bash
# Two FF glory squads in one container. Squad1 dashboard on $PORT, squad2 on $PORT+1.
set -u
PORT="${PORT:-8080}"
export MATCH_IDLE_TIMEOUT="${MATCH_IDLE_TIMEOUT:-90}"
export UDP_DEBUG="${UDP_DEBUG:-1}"

# Accounts arrive as env vars (never committed to the repo).
python3 - <<'PY'
import json, os
s1 = os.environ.get("ACCOUNTS_JSON") or "[]"
s2 = os.environ.get("ACCOUNTS2_JSON") or "[]"
for path, raw in (("/app/squad1/accounts.json", s1), ("/app/squad2/accounts.json", s2)):
    data = json.loads(raw)
    if data:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    print(f"[boot] {path}: {len(data)} account(s)", flush=True)
PY

( while :; do
    cd /app/squad1 || exit 1
    WEB_PORT="$PORT" python3 -u app.py
    echo "[supervisor] squad1 exited, restart in 5s"; sleep 5
  done ) &
P1=$!

( while :; do
    cd /app/squad2 || exit 1
    WEB_PORT="$((PORT+1))" python3 -u app.py
    echo "[supervisor] squad2 exited, restart in 5s"; sleep 5
  done ) &
P2=$!

# SELF-PING: hits the public edge URL so Render's free tier never spins down.
( URL="${RENDER_EXTERNAL_URL:-}"; while :; do sleep 240; [ -n "$URL" ] && curl -s -m 30 -o /dev/null "$URL/api/ping"; done ) &

wait $P1 $P2
