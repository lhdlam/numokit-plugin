#!/usr/bin/env bash
# Verify the non-negotiables actually appear where they must: the human gate before
# any code edit, the clean-code standard, and the per-skill safety rules.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HERE/.."
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
chk() { grep -q -- "$2" "$ROOT/$1" 2>/dev/null && ok "$3" || bad "$3 ($1)"; }

ENTRY="skills/using-numokit/SKILL.md"

# The 6 core principles
chk "$ENTRY" "Human gate trước khi sửa code" "entry: human gate before editing code"
chk "$ENTRY" "KHÔNG bịa"                     "entry: no fabrication"
chk "$ENTRY" "nguyên nhân gốc"               "entry: fix root cause"
chk "$ENTRY" "Evidence trước khi tuyên bố"   "entry: evidence before claiming"
chk "$ENTRY" "open-questions.md"             "entry: spec faults route to open-questions"

# The clean-code standard (inherited from the handover rules)
chk "$ENTRY" "KHÔNG viết comment trong code"    "entry: no comments in code"
chk "$ENTRY" "KHÔNG tự đặt mã định danh"        "entry: no invented identifier codes"
chk "$ENTRY" "NGHIÊM CẤM comment tiếng Việt"    "entry: no Vietnamese comments"
chk "$ENTRY" "noqa"                             "entry: no lint suppressions"
chk "$ENTRY" "quyết định của khách"             "entry: no customer-decision notes"
chk "$ENTRY" "cleanup-on-sight"                 "entry: cleanup on sight"
chk "README.md" "NGHIÊM CẤM comment tiếng Việt" "README states the clean-code standard"

# Every code-touching skill must stop at a gate and refuse green-washing
for s in fixbug refactor cleanup; do
    chk "skills/$s/SKILL.md" "GATE" "$s stops at a human gate"
done
chk "skills/fixbug/SKILL.md"   "đỏ trước fix, xanh sau fix" "fixbug regression test is red-then-green"
chk "skills/fixbug/SKILL.md"   "KHÔNG làm xanh giả"         "fixbug forbids green-washing"
chk "skills/refactor/SKILL.md" "characterisation test"      "refactor requires a characterisation test"
chk "skills/refactor/SKILL.md" "KHÔNG đổi hành vi"          "refactor must not change behaviour"
chk "skills/refactor/SKILL.md" "hoàn tác"                   "refactor reverts a red step"
chk "skills/cleanup/SKILL.md"  "Báo cáo trước, xoá sau"     "cleanup reports before deleting"
chk "skills/cleanup/SKILL.md"  "SỬA nguyên nhân"            "cleanup pairs suppression removal with a fix"

# review must never bend the requirement to fit the code
chk "skills/review-requirements/SKILL.md" "KHÔNG nới yêu cầu cho khớp code" "review never softens a requirement"
chk "skills/review-requirements/SKILL.md" "bằng chứng HAI PHÍA" "review cites both requirement and code"
chk "skills/review-requirements/SKILL.md" "Không kiểm được" "review has an unverifiable verdict"
chk "skills/review-requirements/SKILL.md" "Thừa" "review flags scope creep"
chk "skills/review-requirements/SKILL.md" "KHÔNG bịa yêu cầu" "review refuses to infer requirements from the code"
chk "skills/review-requirements/SKILL.md" "spec-sync" "review documents how it differs from spec-sync"

# review-pr: bilingual, short, evidence-bound, and never posts on its own
chk "skills/review-pr/SKILL.md" "日本語"            "review-pr drafts in Japanese too"
chk "skills/review-pr/SKILL.md" "ENGLISH"           "review-pr drafts in English too"
chk "skills/review-pr/SKILL.md" "KHÔNG dùng \`lang\`" "review-pr comment language overrides lang"
chk "skills/review-pr/SKILL.md" "tối đa 7 mục"      "review-pr caps the number of points"
chk "skills/review-pr/SKILL.md" "KHÔNG tự đăng"     "review-pr never posts without approval"
chk "skills/review-pr/SKILL.md" "Im lặng không phải là đồng ý" "review-pr treats silence as refusal"
chk "skills/review-pr/SKILL.md" "Thay đổi không khai báo" "review-pr flags undisclosed changes"
chk "skills/review-pr/SKILL.md" "hạ thành"          "review-pr demotes unevidenced points to questions"
chk "commands/review-pr.md" "never posts"           "review-pr command states it never posts"
chk "skills/review-pr/SKILL.md" "ĐỐI TƯỢNG ĐỌC LÀ KHÁCH HÀNG" "review-pr writes for the customer"
chk "skills/review-pr/SKILL.md" "ビジネス敬体"        "review-pr uses business keigo"
chk "skills/review-pr/SKILL.md" "クッション言葉"       "review-pr cushions how issues are raised"
chk "skills/review-pr/SKILL.md" "GIỮ NỘI BỘ, KHÔNG gửi khách" "review-pr keeps style nits internal"
chk "skills/review-pr/SKILL.md" "để nội bộ" "review-pr defaults an unclear point to internal"
chk "commands/review-pr.md" "for the customer to read" "review-pr command states the audience"

# Read-only skills must say so
for s in plan-change impact spec-sync review-requirements review-pr; do
    grep -qiE "CHỈ ĐỌC|read-only" "$ROOT/skills/$s/SKILL.md" \
        && ok "$s declares itself read-only" || bad "$s must declare read-only"
done
chk "skills/spec-sync/SKILL.md" "KHÔNG tự phân xử" "spec-sync does not adjudicate"
chk "skills/plan-change/SKILL.md" "cần xác minh"   "plan admits insufficient evidence"
chk "skills/impact/SKILL.md"      "cần xác minh"   "impact admits insufficient evidence"

# No invented identifier codes leaked into numokit's own docs
if grep -rqE "TC-[A-Z0-9]{2}|REQ-[0-9]{2}|BUG-[A-Z0-9]{2}|OQ-[0-9]" \
     --include="*.md" "$ROOT" 2>/dev/null; then
    bad "numokit docs contain invented identifier codes"
else
    ok "numokit docs carry no invented identifier codes"
fi

echo "---"; echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
