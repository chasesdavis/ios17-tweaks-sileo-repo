#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${1:-8088}"

echo "Serving Sileo repo from: $ROOT/repo"
for iface in en0 en1; do
  if ip="$(ipconfig getifaddr "$iface" 2>/dev/null)"; then
    echo "Try in Sileo: http://$ip:$PORT/"
  fi
done
echo "Stop with Ctrl-C."

cd "$ROOT/repo"
exec python3 -m http.server "$PORT"
