#!/usr/bin/env bash
# Run ONLY after native Telegram exec approval, once PR diff has been reviewed.
# Requires gh CLI credentials and protected main with required checks.
set -euo pipefail
NUMBER="${1:?PR number required}"
EXPECTED_SHA="${2:?Exact PR head SHA required}"
REPO="${DEMO_GITHUB_REPO:?Set DEMO_GITHUB_REPO=owner/repo}"
[[ "$NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo 'Invalid PR number' >&2; exit 2; }
[[ "$EXPECTED_SHA" =~ ^[a-fA-F0-9]{40}$ ]] || { echo 'Invalid commit SHA' >&2; exit 2; }
[[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { echo 'Invalid repo' >&2; exit 2; }
DETAILS=$(gh pr view "$NUMBER" -R "$REPO" --json state,isDraft,baseRefName,headRefName,headRefOid,isCrossRepository)
export DETAILS NUMBER EXPECTED_SHA
node - <<'NODE'
const p=JSON.parse(process.env.DETAILS);
const ok=p.state==='OPEN' && !p.isDraft && p.baseRefName==='main' &&
  p.headRefName.startsWith('fix/') && !p.isCrossRepository &&
  p.headRefOid.toLowerCase()===process.env.EXPECTED_SHA.toLowerCase();
if(!ok){console.error('PR does not match expected branch, target or SHA. Refusing merge.');process.exit(1)}
NODE
# Enforce that a named PR CI check exists and passes; not just `gh pr checks` exit 0 for zero checks.
CHECKS=$(gh pr checks "$NUMBER" -R "$REPO" --json name,bucket)
export CHECKS
node - <<'NODE'
const checks=JSON.parse(process.env.CHECKS);
const found=checks.find(c=>c.name==='Test & Build');
if(!found||found.bucket!=='pass') {console.error('Required Test & Build check has not passed.');process.exit(1)}
NODE
# Also honor all required status checks configured by repo branch/ruleset.
gh pr checks "$NUMBER" -R "$REPO" --required
# SHA assertion protects approval from an intervening force push.
gh pr merge "$NUMBER" -R "$REPO" --squash --delete-branch --match-head-commit "$EXPECTED_SHA"
