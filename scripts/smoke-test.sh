#!/usr/bin/env bash
# BEFORE FIX ONLY. Intentionally expects the seeded pagination bug.
set -euo pipefail
BASE="${BASE_URL:-http://127.0.0.1:3000}"
command -v curl >/dev/null || { echo "curl not installed" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 not installed" >&2; exit 1; }
health="$(curl -fsS --max-time 8 "$BASE/health")"
body="$(curl -fsS --max-time 8 "$BASE/api/customers?page=1&limit=3")"
python3 - "$health" "$body" <<'PYSMOKE'
import json, sys
health, data = (json.loads(s) for s in sys.argv[1:])
assert health.get('status') == 'ok', health
assert data['meta']['limit'] == 3, data['meta']
count = len(data['data'])
assert count == 10, f'Intentional demo defect missing: count was {count}, expected 10 before fix'
print('PASS: /health responds OK')
print('PASS: Intentionally broken pagination is reproducible: requested limit=3; returned 10')
print('Ready for the AI investigation and GitHub Issue demonstration.')
PYSMOKE
