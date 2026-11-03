# numokit — AI dev toolkit

> Một plugin, một namespace `/numokit:*` — agent **phân tích & sửa code**, lập trình viên **gác cổng**.
> Mọi thao tác chạm code đều dừng ở một **human gate** trước khi sửa.

## Triết lý

1. **Human gate trước khi sửa code.** Phân tích → trình nhận định + hướng sửa + file sẽ đổi + blast
   radius → **DỪNG, hỏi, chờ duyệt** → mới sửa. Không bao giờ sửa trước rồi báo sau.
2. **Không bịa.** Mọi khẳng định kèm **trích dẫn nguồn thật** (`SRS §4.2`, `app/auth.ts:31`).
   Không định vị được → nói thẳng và hỏi.
3. **Sửa nguyên nhân gốc, không vá triệu chứng.** Diff tối thiểu, khớp convention quanh đó.
4. **Evidence trước khi tuyên bố.** Chạy test và **báo output thật**. Còn đỏ = CHƯA xong.
5. **Lỗi ở tài liệu thì không sửa code.** Spec lỗi thời → `open-questions.md`, để người phân xử.
6. **Code sạch để bàn giao khách** — xem chuẩn dưới đây.

## Chuẩn code sạch (áp cho mọi code numokit sinh ra hoặc sửa)

7. **KHÔNG comment trong code** — không comment truy vết/giải thích, không dấu ngày, không tên khách.
8. **KHÔNG tự đặt mã định danh** (`TC-xx`, `REQ-xx`, `BUG-xx`, `OQ-xx`). Dùng tiêu đề mô tả.
   Trích dẫn nguồn thật chỉ sống trong **tài liệu**, không trong code.
9. **NGHIÊM CẤM comment tiếng Việt trong code.** Tài liệu viết tiếng Việt, CODE thì không.
10. **Không che lỗi bằng suppression** (`# noqa`, `# type: ignore`, `// @ts-ignore`,
    `// eslint-disable*`…). Gặp cái có sẵn → XOÁ **rồi sửa nguyên nhân thật**; không sửa được thì
    báo người, KHÔNG che.
11. **Không ghi quyết định của khách / ngày quyết định vào code.** Quyết định nghiệp vụ thuộc về tài liệu.
12. **Dọn rác khi gặp (cleanup-on-sight)** — thấy ở **BẤT KỲ đâu** là XOÁ NGAY trong cùng lần sửa.

## Các lệnh

| Lệnh | Việc | Chạm code? |
|---|---|---|
| `/numokit:plan <task>` | Phân tích task → đo ảnh hưởng 6 hạng mục → so khớp spec → `plan-<slug>.md` 🚦 | không |
| `/numokit:impact <thay đổi>` | Đo blast radius: module · API · schema · vùng dùng chung · test · tài liệu | không |
| `/numokit:spec-sync [phạm vi]` | Dò code đã trôi khỏi tài liệu (hai chiều) → `spec-drift.md` | không |
| `/numokit:fixbug <mô tả bug>` | Chẩn đoán → **hỏi (gate)** → sửa root cause + regression test → xác minh | **CÓ** |
| `/numokit:refactor <mục tiêu>` | Đo ảnh hưởng → lưới an toàn → **gate** → sửa từng bước xanh | **CÓ** |
| `/numokit:cleanup [phạm vi]` | Quét sạch theo luật #7–#12 → báo cáo → **gate** → xoá | **CÓ** |

3 lệnh đầu **chỉ đọc**, chạy thoải mái. 3 lệnh sau **đều dừng ở human gate**.

## Cài đặt

### Claude Code
```
/plugin add marketplace github:lhdlam/numokit-plugin
/plugin install numokit@lhdlam
```

### Cursor
Slash `/numokit:X` xử qua rule bridge (đọc `commands/X.md`). Lưu ý: Cursor không có PreToolUse hook
cưỡng chế → **gate là advisory** (agent tự giác kiểm dòng `> Review:`).

## Quy trình điển hình

```
/numokit:plan "thêm export CSV"     → phân tích + đo ảnh hưởng + raise lệch spec   🚦 duyệt
        ↓
hiện thực theo "Các bước đề xuất"   (hoặc /numokit:fixbug · /numokit:refactor)
        ↓
/numokit:impact <nhánh>             → đo lại blast radius thực tế của diff
        ↓
/numokit:cleanup <phạm vi>          → dọn sạch trước khi bàn giao               🚦 duyệt
```

## Artifact & review gate

Artifact sống trong `${NUMOKIT_ROOT:-docs/numokit}/`: `plan-*.md`, `impact-*.md`, `spec-drift.md`,
`bug-fix-*.md`, `refactor-*.md`, `cleanup-*.md`, `open-questions.md`.

Mỗi artifact kết thúc bằng `> Review: PENDING`; người duyệt đổi thành `> Review: APPROVED`.

**Gate có điều kiện:** lập plan là **tùy chọn** — chưa có plan thì `fixbug`/`refactor`/`cleanup` chạy
bình thường. Nhưng **đã lập plan thì phải duyệt**: `hooks/pre-tool-gate.sh` chặn 3 lệnh sửa code khi
còn `plan-*.md` ở trạng thái `PENDING`. Plan hết dùng thì xoá file.

## Ngôn ngữ (en/vi)

Ưu tiên: yêu cầu trực tiếp của user > `NUMOKIT_LANG` env > `.numokit-lang` > `vi`.
Áp cho **artifact và giao tiếp**. Code, tên định danh, từ khoá framework luôn tiếng Anh — và nhắc lại
luật #9: **trong code không có comment nào cả**.

## Quan hệ với testkit

numokit lo **phía dev** (sửa code, refactor, dọn code, đo ảnh hưởng, dò spec drift).
[testkit](https://github.com/lhdlam/testkit-plugin) lo **phía tester** (sinh & bảo trì test, nghiệm thu).
Hai plugin **độc lập**, dùng song song được: numokit sửa code xong → chạy suite của testkit để xác minh.

## License

MIT.
