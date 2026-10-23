#!/usr/bin/env bash
# Runs on the VPS as the SSH deploy user. Demo-only: validate before production reuse.
set -Eeuo pipefail
umask 077

APP_DIR="${AERODESK_RUNTIME_DIR:-$HOME/projects/aerodesk-runtime}"
PROJECT_NAME="aerodesk-ai-demo"
IMAGE="${1:?Immutable GHCR image required}"
SHA="${2:?40-character commit SHA required}"
MODE="${3:?Mode fixed or baseline required}"
GHCR_USER="${4:?GitHub actor required}"

[[ "$SHA" =~ ^[a-f0-9]{40}$ ]] || { echo 'Invalid commit SHA' >&2; exit 2; }
[[ "$MODE" == fixed || "$MODE" == baseline ]] || { echo 'Invalid deploy mode' >&2; exit 2; }
[[ "$IMAGE" =~ ^ghcr\.io/[a-z0-9_.-]+/[a-z0-9_.-]+:[a-f0-9]{40}$ ]] || { echo 'Invalid GHCR image' >&2; exit 2; }
[[ "$IMAGE" == *":$SHA" ]] || { echo 'Image SHA mismatch' >&2; exit 2; }
[[ "$GHCR_USER" =~ ^[A-Za-z0-9-]+(\[bot\])?$ ]] || { echo 'Invalid registry account' >&2; exit 2; }
[[ -f "$APP_DIR/compose.prod.yaml" && -f "$APP_DIR/deploy.env" ]] || { echo 'Runtime not prepared' >&2; exit 2; }
command -v flock >/dev/null && command -v docker >/dev/null && command -v python3 >/dev/null || { echo 'Missing required commands' >&2; exit 2; }

# An SSH-delivered, short-lived GitHub Actions token is piped to docker login.
# DOCKER_CONFIG lives in a disposable directory, so tokens are not retained.
DOCKER_CONFIG="$(mktemp -d)"
export DOCKER_CONFIG
BACKUP=""
HEALTH_FILE="$(mktemp)"
cleanup() {
  [[ -z "$BACKUP" ]] || rm -f "$BACKUP"
  rm -f "$HEALTH_FILE"
  rm -rf "$DOCKER_CONFIG"
}
trap cleanup EXIT
IFS= read -r GHCR_TOKEN || { echo 'Missing GHCR token on stdin' >&2; exit 2; }
[[ -n "$GHCR_TOKEN" ]] || { echo 'Empty GHCR token' >&2; exit 2; }
printf '%s' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin >/dev/null
unset GHCR_TOKEN

cd "$APP_DIR"
# deploy.env contains only expected IMAGE_REPOSITORY=ghcr.io/owner/repo.
# It must not be writable by the coding agent in real production environments.
IMAGE_REPOSITORY="$(sed -n 's/^IMAGE_REPOSITORY=//p' ./deploy.env | head -n1)"
[[ "${IMAGE_REPOSITORY:-}" =~ ^ghcr\.io/[a-z0-9_.-]+/[a-z0-9_.-]+$ ]] || { echo 'Invalid IMAGE_REPOSITORY' >&2; exit 2; }
[[ "$IMAGE" == "$IMAGE_REPOSITORY:$SHA" ]] || { echo 'Unexpected image repository' >&2; exit 2; }

exec 9> "$APP_DIR/deploy.lock"
flock -w 120 9 || { echo 'Another deployment is in progress' >&2; exit 3; }

compose() { docker compose -p "$PROJECT_NAME" --env-file "$APP_DIR/.env" -f "$APP_DIR/compose.prod.yaml" "$@"; }
if [[ -f .env ]]; then
  BACKUP="$(mktemp "$APP_DIR/.env.backup.XXXXXX")"
  cp .env "$BACKUP"
fi
rollback() {
  echo 'Deploy validation failed; attempting rollback...' >&2
  if [[ -n "$BACKUP" && -f "$BACKUP" ]]; then
    cp "$BACKUP" "$APP_DIR/.env"
    compose up -d --no-build || true
  else
    rm -f "$APP_DIR/.env"
    echo 'No previous deployed image. Inspect Docker manually.' >&2
  fi
}

echo "Pulling $IMAGE (mode=$MODE)"
docker pull "$IMAGE"
TEMP="$(mktemp "$APP_DIR/.env.new.XXXXXX")"
printf 'APP_IMAGE=%s\nDEPLOY_MODE=%s\n' "$IMAGE" "$MODE" > "$TEMP"
chmod 600 "$TEMP"
mv -f "$TEMP" "$APP_DIR/.env"

if ! compose up -d --no-build; then rollback; exit 1; fi

healthy=0
for i in $(seq 1 25); do
  if curl -fsS --max-time 3 http://127.0.0.1:3000/health >"$HEALTH_FILE" 2>/dev/null; then
    if python3 - "$SHA" "$HEALTH_FILE" <<'PY'
import json,sys
with open(sys.argv[2],encoding="utf-8") as f: x=json.load(f)
assert x.get('status') == 'ok' and x.get('revision') == sys.argv[1], x
PY
    then healthy=1; break; fi
  fi
  sleep 2
done
if [[ "$healthy" != 1 ]]; then rollback; exit 1; fi

if ! python3 - "$MODE" <<'PY'
import json,sys,urllib.request
mode=sys.argv[1]
base='http://127.0.0.1:3000'

def check(page):
    with urllib.request.urlopen(f'{base}/api/customers?page={page}&limit=3',timeout=5) as response:
        result=json.load(response)
    return result

first=check(1)
second=check(2)
assert first['meta']['limit']==3 and second['meta']['limit']==3
if mode=='fixed':
    assert [x['id'] for x in first['data']]==[1,2,3], first
    assert [x['id'] for x in second['data']]==[4,5,6], second
else:
    assert [x['id'] for x in first['data']]==list(range(1,11)),first
    assert [x['id'] for x in second['data']]==list(range(11,21)),second
print(f'PASS: {mode} mode; pagination and metadata verified')
PY
then rollback; exit 1; fi

echo "SUCCESS: $IMAGE deployed in $MODE mode"
compose ps
