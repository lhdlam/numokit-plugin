#!/usr/bin/env bash
# Drive the conditional plan gate for real: code-touching skills must be blocked
# only while a plan is PENDING, and read-only skills must never be blocked.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE/.."
HOOK="$ROOT/hooks/pre-tool-gate.sh"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

command -v jq >/dev/null 2>&1 || { echo "  skip: jq missing — gate is fail-open without it"; echo "PASS=0 FAIL=0"; exit 0; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/numokit"

gate() {
    ( cd "$TMP" && printf '{"tool_name":"Skill","tool_input":{"skill":"numokit:%s"}}' "$1" \
        | bash "$HOOK" >/dev/null 2>&1; echo $? )
}

# No plan → everything allowed
for s in fixbug refactor cleanup; do
    [[ "$(gate "$s")" == "0" ]] && ok "no plan: $s allowed" || bad "no plan must not block $s"
done

# Pending plan → code-touching skills blocked
printf '# Plan: x\n> Review: PENDING\n' > "$TMP/docs/numokit/plan-x.md"
for s in fixbug refactor cleanup; do
    [[ "$(gate "$s")" == "1" ]] && ok "pending plan: $s blocked" || bad "pending plan must block $s"
done

# Read-only skills are never gated, even with a pending plan
for s in plan-change impact spec-sync review-requirements review-pr; do
    [[ "$(gate "$s")" == "0" ]] && ok "pending plan: read-only $s still allowed" \
                                || bad "read-only $s must never be blocked"
done

# Approved → allowed again
printf '# Plan: x\n> Review: APPROVED\n' > "$TMP/docs/numokit/plan-x.md"
[[ "$(gate fixbug)" == "0" ]] && ok "approved plan: fixbug allowed" || bad "approved plan must allow fixbug"

# Any one pending among several blocks
printf '# Plan: y\n> Review: PENDING\n' > "$TMP/docs/numokit/plan-y.md"
[[ "$(gate fixbug)" == "1" ]] && ok "one of several plans pending: fixbug blocked" \
                              || bad "must block when any plan is pending"

# Deleting the stale plan unblocks
rm "$TMP/docs/numokit/plan-y.md"
[[ "$(gate fixbug)" == "0" ]] && ok "deleting a stale plan unblocks fixbug" \
                              || bad "deleting a stale plan must unblock"

# Unknown skill and non-Skill tools are never touched
[[ "$(gate something-else)" == "0" ]] && ok "unknown skill is not gated" || bad "unknown skill must not be gated"
printf '{"tool_name":"Bash","tool_input":{}}' | bash "$HOOK" >/dev/null 2>&1 \
    && ok "non-Skill tool calls pass through" || bad "non-Skill tool calls must pass through"

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
