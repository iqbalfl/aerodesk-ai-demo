#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$(mktemp -d)";trap 'rm -rf "$DIR"' EXIT
cat > "$DIR/gh" <<'GH_MOCK'
#!/usr/bin/env bash
if [[ "$1 $2" == "pr view" ]]; then
  echo "{\"state\":\"OPEN\",\"isDraft\":false,\"baseRefName\":\"main\",\"headRefName\":\"fix/12-pagination\",\"headRefOid\":\"${PR_HEAD_SHA}\",\"isCrossRepository\":false}"
elif [[ "$1 $2" == "pr checks" ]]; then
  if [[ " $* " == *' --json '* ]];then echo "[{\"name\":\"Test & Build\",\"bucket\":\"${CI_STATUS:-pass}\"}]"; else exit 0; fi
elif [[ "$1 $2" == "pr merge" ]];then
  echo "merged:$*" >> "$MERGE_LOG"
else
  echo "unexpected command" >&2;exit 1
fi
GH_MOCK
chmod +x "$DIR/gh"
export PATH="$DIR:$PATH" MERGE_LOG="$DIR/merges" DEMO_GITHUB_REPO=owner/aerodesk-ai-demo
export EXPECTED_SHA=0123456789abcdef0123456789abcdef01234567
export PR_HEAD_SHA="$EXPECTED_SHA"
# Test passing CI: accepted only when explicit SHA and checks match.
bash "$ROOT/scripts/merge-approved-pr.sh" 12 "$EXPECTED_SHA"
[[ $(wc -l < "$MERGE_LOG") == 1 ]]
# Failed CI must never result in another merge.
export CI_STATUS=fail
if bash "$ROOT/scripts/merge-approved-pr.sh" 12 "$EXPECTED_SHA" 2>/dev/null;then echo 'Unexpected merge of failing CI' >&2;exit 1;fi
[[ $(wc -l < "$MERGE_LOG") == 1 ]]
# Wrong SHA must never be merged.
unset CI_STATUS
if bash "$ROOT/scripts/merge-approved-pr.sh" 12 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 2>/dev/null;then echo 'Unexpected merge of wrong SHA' >&2;exit 1;fi
[[ $(wc -l < "$MERGE_LOG") == 1 ]]
printf 'Merge gate tests PASS (happy path, failed CI, wrong SHA)\n'
