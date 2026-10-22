#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$HERE/openclaw-workspace"
DEST="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
[ -f "$SRC/MEMORY.md" ] || { echo "MEMORY.md tidak ditemukan" >&2; exit 1; }
mkdir -p "$DEST/memory"
backup="$DEST/.demo-kit-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup"
for f in MEMORY.md AGENTS.md; do
  if [ -e "$DEST/$f" ]; then cp -a "$DEST/$f" "$backup/$f"; fi
  cp "$SRC/$f" "$DEST/$f"
done
for f in "$SRC"/memory/*.md; do
  base="$(basename "$f")"
  if [ -e "$DEST/memory/$base" ]; then cp -a "$DEST/memory/$base" "$backup/$base"; fi
  cp "$f" "$DEST/memory/$base"
done
chmod 700 "$DEST" "$DEST/memory" || true
printf 'Copied fictional demo memory to: %s\nPrevious same-name files backed up under: %s\n' "$DEST" "$backup"
