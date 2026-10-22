#!/usr/bin/env bash
# Production target script. Installed under /opt/aerodesk, owned by deploy user.
# This account can use Docker => privilege equivalent to root. Keep the SSH key secret.
set -euo pipefail
APP_DIR=/opt/aerodesk
IMAGE="${1:?Image required}"
SHA="${2:?Commit SHA required}"
if ! [[ "$SHA" =~ ^[a-f0-9]{40}$ ]]; then echo 'Invalid SHA' >&2; exit 2; fi
if ! [[ "$IMAGE" =~ ^ghcr\.io/[a-z0-9_.-]+/[a-z0-9_.-]+:[a-f0-9]{40}$ ]] || [[ "$IMAGE" != *":$SHA" ]]; then
  echo 'Image name or SHA not permitted' >&2; exit 2
fi
# Set IMAGE_REPOSITORY=ghcr.io/owner/repo in /opt/aerodesk/deploy.env
source "$APP_DIR/deploy.env"
if [[ "$IMAGE" != "$IMAGE_REPOSITORY:$SHA" ]]; then echo 'Unexpected image repository' >&2; exit 2; fi
exec 9>"$APP_DIR/deploy.lock"
flock -w 30 9 || { echo 'Another deploy is running' >&2; exit 3; }
cd "$APP_DIR"
PREVIOUS=$(sed -n 's/^APP_IMAGE=//p' .env 2>/dev/null | head -n 1 || true)
TEMP=$(mktemp "$APP_DIR/.env.XXXXXX")
chmod 600 "$TEMP"
restore_previous() {
  if [[ -n "$PREVIOUS" ]]; then
    printf 'APP_IMAGE=%s\n' "$PREVIOUS" > "$TEMP"
    mv -f "$TEMP" "$APP_DIR/.env"
    docker compose --env-file .env -f compose.prod.yaml up -d --no-build || true
  fi
}
docker pull "$IMAGE"
printf 'APP_IMAGE=%s\n' "$IMAGE" > "$TEMP"
mv -f "$TEMP" "$APP_DIR/.env"
if ! docker compose --env-file .env -f compose.prod.yaml up -d --no-build; then
  echo 'docker compose failed; rolling back' >&2
  restore_previous
  exit 1
fi
GOOD=0
for i in $(seq 1 20); do
  if curl --fail --silent --show-error --max-time 3 'http://127.0.0.1:3000/health' | grep -Fq "\"revision\":\"$SHA\""; then
    GOOD=1; break
  fi
  sleep 3
done
if [[ "$GOOD" != 1 ]]; then
  echo 'Health verification failed; rolling back' >&2
  TEMP=$(mktemp "$APP_DIR/.env.XXXXXX")
  restore_previous
  exit 1
fi
if ! curl --fail --silent --show-error 'http://127.0.0.1:3000/api/customers?page=1&limit=3' | python3 -c 'import json,sys; r=json.load(sys.stdin); assert len(r["data"])==3 and r["meta"]["limit"]==3; print("Pagination smoke check passed")'; then
  echo 'Pagination smoke test failed; rolling back' >&2
  TEMP=$(mktemp "$APP_DIR/.env.XXXXXX")
  restore_previous
  exit 1
fi
echo "SUCCESS: deployed $IMAGE"
