#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
for f in scripts/*.sh deploy/*.sh; do bash -n "$f"; done
node --check app/server.js
node --check app/test/pagination.test.js
node -e "let p=require('./app/package.json');if(!p.scripts.test)process.exit(1)"
python3 - <<'PY'
from pathlib import Path
files=['.github/workflows/pr-ci.yml','.github/workflows/deploy.yml','compose.prod.yaml']
for f in files:
 assert Path(f).is_file(),f
 print('present:', f)
PY
printf 'Static checks complete. Initial regression tests are intentionally RED until agent fixes bug.
'
