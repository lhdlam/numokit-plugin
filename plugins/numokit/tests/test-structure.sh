#!/usr/bin/env bash
# Verify numokit's shape: manifests, the six skill/command pairs, and that every
# command actually resolves to a skill that exists.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE/.."
REPO="$ROOT/../.."
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
has() { [[ -f "$1" ]] && ok "$2" || bad "missing $1"; }

has "$REPO/.claude-plugin/marketplace.json" "marketplace manifest exists"
has "$ROOT/.claude-plugin/plugin.json"      "plugin manifest exists"
has "$ROOT/README.md"                       "plugin README exists"
has "$ROOT/LICENSE"                         "LICENSE exists"

if command -v jq >/dev/null 2>&1; then
    jq -e . "$REPO/.claude-plugin/marketplace.json" >/dev/null 2>&1 \
        && ok "marketplace.json is valid JSON" || bad "marketplace.json is invalid JSON"
    jq -e . "$ROOT/.claude-plugin/plugin.json" >/dev/null 2>&1 \
        && ok "plugin.json is valid JSON" || bad "plugin.json is invalid JSON"
    jq -e . "$ROOT/hooks/hooks.json" >/dev/null 2>&1 \
        && ok "hooks.json is valid JSON" || bad "hooks.json is invalid JSON"
    [[ "$(jq -r '.plugins[0].source.path' "$REPO/.claude-plugin/marketplace.json")" == "plugins/numokit" ]] \
        && ok "marketplace points at plugins/numokit" || bad "marketplace source.path is wrong"
    [[ "$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json")" == "numokit" ]] \
        && ok "plugin is named numokit" || bad "plugin name is wrong"
    # Claude Code keys marketplaces by the declared name: reusing "lhdlam" would
    # silently overwrite the testkit marketplace registration on every add.
    mp="$(jq -r '.name' "$REPO/.claude-plugin/marketplace.json")"
    [[ "$mp" != "lhdlam" ]] \
        && ok "marketplace name ($mp) does not collide with testkit's" \
        || bad "marketplace name 'lhdlam' collides with the testkit marketplace"
    grep -q "numokit@$mp" "$ROOT/README.md" \
        && ok "README install command matches the marketplace name" \
        || bad "README install command does not match marketplace name '$mp'"
else
    echo "  skip: jq missing — JSON checks skipped"
fi

# Entry skill
has "$ROOT/skills/using-numokit/SKILL.md" "using-numokit entry skill exists"

# Every command must map to a skill that exists
declare -a CMDS=(plan impact spec-sync review fixbug refactor cleanup)
declare -a SKILLS=(plan-change impact spec-sync review-requirements fixbug refactor cleanup)
for i in "${!CMDS[@]}"; do
    has "$ROOT/commands/${CMDS[$i]}.md"          "command /numokit:${CMDS[$i]} exists"
    has "$ROOT/skills/${SKILLS[$i]}/SKILL.md"    "skill ${SKILLS[$i]} exists"
    grep -q "${SKILLS[$i]}" "$ROOT/commands/${CMDS[$i]}.md" 2>/dev/null \
        && ok "/numokit:${CMDS[$i]} invokes ${SKILLS[$i]}" \
        || bad "/numokit:${CMDS[$i]} does not name its skill"
done

# Every SKILL.md needs frontmatter name + description
for s in "$ROOT"/skills/*/SKILL.md; do
    n="$(basename "$(dirname "$s")")"
    head -5 "$s" | grep -q "^name: " && grep -q "^description: " "$s" \
        && ok "$n has frontmatter name + description" \
        || bad "$n frontmatter incomplete"
done

# Hooks
has "$ROOT/hooks/hooks.json"        "hooks.json exists"
has "$ROOT/hooks/pre-tool-gate.sh"  "pre-tool-gate.sh exists"
has "$ROOT/hooks/session-start.sh"  "session-start.sh exists"
for h in pre-tool-gate session-start; do
    bash -n "$ROOT/hooks/$h.sh" 2>/dev/null && ok "$h.sh is syntactically valid" || bad "$h.sh has a syntax error"
done

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
