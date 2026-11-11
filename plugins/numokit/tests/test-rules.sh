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

# Peer review: an independent second scoring, launched before any verdict exists so the
# brief cannot carry a conclusion, with disagreements escalated instead of reconciled.
AG="agents/requirement-reviewer.md"
has_file() { [[ -f "$ROOT/$1" ]] && ok "$2" || bad "missing $1"; }
has_file "$AG" "requirement-reviewer agent exists"
head -5 "$ROOT/$AG" | grep -q "^name: requirement-reviewer" \
    && ok "requirement-reviewer has frontmatter name" || bad "requirement-reviewer frontmatter name"
grep -q "^tools: " "$ROOT/$AG" && ok "requirement-reviewer declares its tools" \
    || bad "requirement-reviewer must declare tools"
# The peer must stay read-only: granting Edit/Write would let a reviewer rewrite what it reviews.
if grep -qE "^tools: .*(Edit|Write|NotebookEdit)" "$ROOT/$AG"; then
    bad "requirement-reviewer must not have write tools"
else
    ok "requirement-reviewer is read-only (no Edit/Write)"
fi
chk "$AG" "Chấm độc lập"            "peer scores independently"
chk "$AG" "Brief bị nhiễm"          "peer ignores a contaminated brief"
chk "$AG" "brief_contaminated"      "peer reports a contaminated brief"
chk "$AG" "KHÔNG bịa yêu cầu từ code" "peer refuses to infer requirements from the code"
chk "$AG" "Đạt là verdict khó nhất" "peer treats Đạt as the hardest verdict"
chk "$AG" "Không kiểm được"         "peer has an unverifiable verdict"

REV="skills/review-requirements/SKILL.md"
chk "$REV" "requirement-reviewer"   "review launches the peer reviewer"
chk "$REV" "Peer review bắt buộc"   "review runs peer review by default"
chk "$REV" "trước khi tự chấm"      "peer is launched before the first verdict exists"
chk "$REV" "KHÔNG đưa vào brief"    "review keeps verdicts out of the brief"
chk "$REV" "KHÔNG tự phân xử"       "review does not adjudicate a disagreement"
chk "$REV" "thận trọng hơn"         "review takes the conservative verdict on dispute"
chk "$REV" "Trùng verdict không chứng minh là đúng" "review does not treat agreement as proof"
chk "$REV" "CÓ CHỦ ĐÍCH"            "review states the duplicated work is deliberate"
chk "$REV" "no-peer"                "review documents how to skip peer review"
chk "$REV" "KHÔNG chạy"             "review discloses a run without peer review"
# The agent name must carry the plugin namespace or the dispatch silently fails to resolve
chk "$REV" "numokit:requirement-reviewer" "review dispatches the namespaced agent name"
chk "$REV" "không có Agent tool"    "review handles a platform without subagents"
chk "$REV" "cùng một lớp ý định"    "review refuses to fake peer review by itself"
chk "commands/review.md" "requirement-reviewer" "review command names the peer agent"
chk "commands/review.md" "more conservative"    "review command states the dispute rule"

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

# address-feedback: judge the feedback, never silently skip, gate before editing
chk "skills/address-feedback/SKILL.md" "không phải MỆNH LỆNH"      "feedback is judged, not executed"
chk "skills/address-feedback/SKILL.md" "im lặng bỏ qua"            "every comment gets a status"
chk "skills/address-feedback/SKILL.md" "HUMAN GATE"                "address-feedback gates before editing"
chk "skills/address-feedback/SKILL.md" "KHÔNG bịa là đã sửa"       "never claims an unverified fix"
chk "skills/address-feedback/SKILL.md" "TUYỆT ĐỐI không tự làm"    "destructive feedback stops for the user"
chk "skills/address-feedback/SKILL.md" "inline"                    "collects inline review comments too"
chk "skills/address-feedback/SKILL.md" "KHÔNG tự đăng"             "address-feedback never posts on its own"
chk "skills/address-feedback/SKILL.md" "現状維持"                   "reply has a kept-as-is status in Japanese"
chk "hooks/pre-tool-gate.sh" "address-feedback"                    "gate hook covers address-feedback"

# publish-vault: one-way, never guesses the customer, quarantines drafts, scans for secrets
chk "skills/publish-vault/SKILL.md" "Một chiều"            "publish is one-way (never reads back)"
chk "skills/publish-vault/SKILL.md" "Không tự publish"     "publish waits for confirmation"
chk "skills/publish-vault/SKILL.md" "KHÔNG đoán khách"     "publish never guesses the customer folder"
chk "skills/publish-vault/SKILL.md" "phân quyền"           "publish explains the permission boundary"
chk "skills/publish-vault/SKILL.md" "_draft/"              "publish quarantines unapproved drafts"
chk "skills/publish-vault/SKILL.md" "Quét rủi ro"          "publish scans for secrets before copying"
chk "skills/publish-vault/SKILL.md" "Không ghi đè thầm"    "publish never overwrites silently"
chk "skills/publish-vault/SKILL.md" "Không xoá gì trên vault" "publish never deletes from the shared store"
chk "skills/publish-vault/SKILL.md" ".obsidian/"           "publish leaves the obsidian config alone"
chk "skills/publish-vault/SKILL.md" "đường dẫn đầy"        "publish uses full-path wikilinks"
chk "skills/publish-vault/SKILL.md" "NUMOKIT_VAULT"        "publish reads the vault path from the env"
chk "commands/publish.md" "publish-vault"                  "publish command names its skill"
chk "commands/publish.md" "One-way"                        "publish command states it is one-way"

# The vault frontmatter date is a deliberate, documented exception to rule #12
chk "$ENTRY" "ngoại lệ duy nhất"                   "entry documents the frontmatter date exception"
chk "skills/publish-vault/SKILL.md" "Ngoại lệ"     "publish marks its date field as an exception"
chk "skills/publish-vault/SKILL.md" "Đừng \"dọn\" frontmatter" "publish warns later runs not to strip it"
chk "skills/cleanup/SKILL.md" "frontmatter"        "cleanup knows not to strip vault frontmatter"

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
