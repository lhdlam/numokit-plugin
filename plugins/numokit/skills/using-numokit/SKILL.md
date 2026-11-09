---
name: using-numokit
description: Use when starting any conversation in a development project, OR when the user types a `/numokit:<name>` slash-command pattern (e.g. `/numokit:plan`, `/numokit:fixbug`, `/numokit:refactor`) — establishes the human gate before any code edit, the clean-code standard, and the slash-command bridge for platforms without native slash discovery (Cursor).
license: MIT
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

# Using numokit

numokit là toolkit để **AI agent phân tích và sửa code**, còn **lập trình viên là người gác cổng**.
Khác với một trợ lý sửa bừa: mọi thao tác **chạm vào code** đều phải qua một **human gate** — agent
phân tích, trình phương án, hỏi, rồi **chờ duyệt** mới sửa.

## Nguyên tắc tối thượng (không thương lượng)

1. **Human gate trước khi sửa code.** Phân tích → trình nhận định + hướng sửa + file sẽ đổi + blast
   radius → **DỪNG, hỏi, chờ duyệt** → mới sửa. Không bao giờ sửa trước rồi báo sau.
2. **KHÔNG bịa.** Mọi khẳng định về yêu cầu/hiện thực phải kèm **trích dẫn nguồn thật**
   (`SRS §4.2`, `app/auth.ts:31`). Không định vị được → nói thẳng và hỏi, đừng đoán.
3. **Sửa nguyên nhân gốc, không vá triệu chứng.** Diff tối thiểu, khớp convention quanh đó.
4. **Evidence trước khi tuyên bố.** Chạy test/kiểm chứng và **báo output thật**. Còn đỏ = CHƯA xong.
5. **Lỗi ở tài liệu, không phải code → không sửa code.** Spec lỗi thời/mâu thuẫn → ghi
   `open-questions.md`, để người phân xử. Đừng uốn code cho khớp một spec sai.
6. **User instructions > skill.** CLAUDE.md / yêu cầu trực tiếp của user luôn thắng.

## Chuẩn code sạch (áp cho MỌI code numokit sinh ra hoặc sửa)

7. **Code sạch để bàn giao khách.** **KHÔNG viết comment trong code** — không comment truy vết, không
   comment giải thích, không dấu ngày, không tên khách. Code tự diễn đạt qua tên biến/hàm rõ nghĩa.
8. **KHÔNG tự đặt mã định danh** (`TC-xx`, `REQ-xx`, `BUG-xx`, `OQ-xx`). Gọi mọi thứ bằng **tiêu đề mô
   tả**. Trích dẫn **nguồn thật** (`SRS §4.2`, `file:line`) chỉ sống trong **tài liệu**, không trong code.
9. **NGHIÊM CẤM comment tiếng Việt trong code.** Không ngoại lệ — tài liệu viết tiếng Việt, CODE thì không.
10. **Không che lỗi bằng suppression.** Cấm `# noqa`, `# type: ignore`, `# pylint: disable`, `# fmt: off`,
    `// @ts-ignore`, `// @ts-nocheck`, `// @ts-expect-error`, `// eslint-disable*`, `// prettier-ignore`
    để làm xanh. Gặp cái có sẵn → **XOÁ** rồi **SỬA nguyên nhân thật**; không sửa được thì báo người,
    KHÔNG che.
11. **Không ghi quyết định của khách và ngày quyết định vào code** — vd `// khách chốt bỏ validate —
    02/10/2026`, `# theo yêu cầu KH ngày 15/9`, tên khách, số hợp đồng/ticket. Quyết định nghiệp vụ
    thuộc về **tài liệu**, không phải code.
12. **Dọn rác khi gặp (cleanup-on-sight).** Thấy mã định danh tự đặt, comment tiếng Việt, comment thừa,
    ghi chú quyết định của khách, hay chỉ thị tắt lint ở **BẤT KỲ đâu** → **XOÁ NGAY** trong cùng lần
    sửa. Không giới hạn phạm vi, không hỏi lại, không để "dọn sau".

## Ngôn ngữ (en/vi)

Thứ tự ưu tiên khi xác định `lang`: yêu cầu trực tiếp của user > `NUMOKIT_LANG` env >
`.numokit-lang` > mặc định `vi`.

**Áp dụng cho:** mọi artifact (`plan-*.md`, `impact-*.md`, `bug-fix-*.md`, `spec-drift.md`,
`open-questions.md`) và mọi câu trả lời/giải thích/câu hỏi của agent.

**KHÔNG dịch:** code, tên biến/hàm/class, từ khoá framework, tên file, lệnh shell.
Và nhắc lại luật #9 — **trong code không có comment tiếng Việt**, cũng không có comment nào khác.

## Các lệnh

| Lệnh | Việc | Chạm code? |
|---|---|---|
| `/numokit:plan <task>` | Phân tích task → đo ảnh hưởng → so khớp spec → `plan-<slug>.md` 🚦 | không (chỉ đọc) |
| `/numokit:impact <thay đổi>` | Đo blast radius phía code: module · API · DB · vùng dùng chung | không (chỉ đọc) |
| `/numokit:spec-sync [phạm vi]` | Dò code đã trôi khỏi tài liệu → `spec-drift.md` | không (chỉ đọc) |
| `/numokit:review <nhánh\|PR>` | Đối chiếu code vừa làm với **yêu cầu của khách** → verdict từng yêu cầu | không (chỉ đọc) |
| `/numokit:review-pr <link PR>` | Nhận xét PR từ link → comment **song ngữ en/jp**, có dẫn chứng (không tự đăng) | không (chỉ đọc) |
| `/numokit:fixbug <mô tả bug>` | Chẩn đoán → **hỏi (gate)** → sửa code + regression test → xác minh | **CÓ** |
| `/numokit:refactor <mục tiêu>` | Đo ảnh hưởng → **gate** → sửa từng bước → test xác minh không đổi hành vi | **CÓ** |
| `/numokit:cleanup [phạm vi]` | Quét sạch repo theo luật #7–#12 → **gate** → xoá | **CÓ** |

**Quy tắc chung:** 5 lệnh đầu chỉ đọc, chạy thoải mái. 3 lệnh sau **đều dừng ở human gate** trước khi
sửa. Riêng `review-pr` tuy chỉ đọc nhưng **đăng comment là hành vi công khai** → luôn hỏi trước khi đăng. Artifact kết thúc bằng `> Review: PENDING`; người duyệt đổi thành `> Review: APPROVED`.

## Artifact & review gate

Artifact sống trong `${NUMOKIT_ROOT:-docs/numokit}/`. Mỗi artifact có dòng cuối
`> Review: PENDING|APPROVED`. Trên **Claude Code**, `hooks/pre-tool-gate.sh` chặn skill sửa code khi
còn `plan-*.md` PENDING. Trên **Cursor** gate là **advisory** — tự kiểm dòng `> Review:` trước khi đi tiếp.

## Slash command bridge (`/numokit:<name>`)

- **Claude Code**: slash auto-discover từ `commands/`. Platform tự gọi.
- **Cursor / nền không có native slash**: khi user gõ `/numokit:<name>`:
  1. Đọc `${NUMOKIT_PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT}}/commands/<name>.md`
  2. Làm theo nội dung (đa số wrap một skill cùng tên)
  3. Không có file → fallback invoke skill cùng tên

> Đừng đoán `/numokit:<name>` nghĩa là gì — đọc command file vì nó chứa pre-flight check & argument parsing.

## Quan hệ với testkit

numokit lo **phía dev** (sửa code, refactor, dọn code, đo ảnh hưởng). testkit lo **phía tester**
(sinh & bảo trì test, nghiệm thu). Hai plugin độc lập, dùng song song được. Khi numokit sửa code xong,
chạy suite của testkit để xác minh là cách phối hợp tự nhiên.
