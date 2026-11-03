#!/usr/bin/env bash
# pre-tool-gate.sh — plan review gate for numokit.
#
# Blocks a code-touching skill while any plan-*.md is still awaiting review.
# Claude Code passes a JSON payload on stdin:
#   { "tool_name": "Skill", "tool_input": { "skill": "numokit:fixbug", ... } }
#
# Hook contract: exit 0 → allow; exit non-0 → block (stderr shown to agent + user).
#
# Conditional gate: planning is opt-in. With no plan present the code-touching
# skills run exactly as before; once a plan exists it must be signed off before
# code gets edited from it. A plan that no longer applies can just be deleted.
#
# Gated skills: fixbug, refactor, cleanup (every skill that edits source).
# Not gated: plan-change, impact, spec-sync (read-only).
#
# Fail-open: jq missing, empty/malformed stdin, skill not gated, or no numokit
# artifacts root. Cursor has no enforced PreToolUse hook, so the skills self-check
# the same marker (advisory) — see using-numokit.

set -euo pipefail

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat || true)"
[[ -n "$input" ]] || exit 0

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null || echo '')"
[[ "$tool_name" == "Skill" ]] || exit 0

skill="$(printf '%s' "$input" | jq -r '.tool_input.skill // ""' 2>/dev/null || echo '')"
skill="${skill#numokit:}"

case "$skill" in
    fixbug|refactor|cleanup) ;;
    *) exit 0 ;;
esac

# Resolve the artifacts root. Honor NUMOKIT_ROOT, else probe known locations.
ROOT=""
for cand in "${NUMOKIT_ROOT:-}" "docs/numokit" "docs"; do
    [[ -n "$cand" && -d "$cand" ]] || continue
    ROOT="$cand"; break
done
# No artifacts root at all → nothing was ever planned → fail-open.
[[ -n "$ROOT" ]] || exit 0

pending=""
for plan in "$ROOT"/plan-*.md; do
    [[ -f "$plan" ]] || continue
    if ! grep -qE '^[[:space:]]*>[[:space:]]*Review:[[:space:]]+APPROVED[[:space:]]*$' "$plan"; then
        pending+="      $plan"$'\n'
    fi
done

# No plan at all, or every plan approved → allow.
[[ -n "$pending" ]] || exit 0

cat >&2 <<EOF
✗ numokit gate: refusing "$skill" — a plan is still awaiting review.

  Not approved yet:
$pending
  Read the plan, settle the questions and the spec deviations it raised, then change
  the trailing line
      > Review: PENDING
  to
      > Review: APPROVED
  and re-run. (A plan that no longer applies can simply be deleted.)
EOF
exit 1
