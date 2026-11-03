#!/usr/bin/env bash
# session-start.sh — surface pending numokit plans so a gate block is never a surprise.
# Advisory only; never fails the session.
set -uo pipefail

for ROOT in "${NUMOKIT_ROOT:-}" "docs/numokit" "docs"; do
    [[ -n "$ROOT" && -d "$ROOT" ]] || continue

    pending=0
    for plan in "$ROOT"/plan-*.md; do
        [[ -f "$plan" ]] || continue
        grep -qE '^[[:space:]]*>[[:space:]]*Review:[[:space:]]+APPROVED[[:space:]]*$' "$plan" || pending=$((pending+1))
    done

    lang="${NUMOKIT_LANG:-}"
    [[ -z "$lang" && -f "$ROOT/.numokit-lang" ]] && lang="$(tr -d '[:space:]' < "$ROOT/.numokit-lang" 2>/dev/null || echo '')"
    [[ -z "$lang" ]] && lang="vi"

    if [[ "$pending" -gt 0 ]]; then
        echo "[numokit] lang = $lang | $pending plan chưa duyệt trong $ROOT/ → fixbug/refactor/cleanup đang bị chặn. Duyệt plan (> Review: APPROVED) hoặc xoá plan không còn dùng."
    fi
    exit 0
done
exit 0
