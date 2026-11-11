---
name: publish-vault
description: Publish finished numokit artifacts to a shared Obsidian vault so the whole team can read them — adds YAML frontmatter for filtering, cross-links the artifacts of one PR with wikilinks, routes unapproved drafts to a _draft folder with a banner, and regenerates the project index. One-way; it never reads back from the vault and never publishes without confirmation. Use via /numokit:publish [phạm vi].
license: MIT
---

# Publish-vault — đẩy artifact lên kho nội bộ (Obsidian)

Mục tiêu: artifact numokit sinh ra đang nằm **local trong `$NUMOKIT_ROOT`**, chỉ người chạy lệnh thấy.
Lệnh này đưa chúng lên một **Obsidian vault dùng chung** để cả team đọc được.

> **Một chiều.** Vault là **bản publish**, không phải bản làm việc. Lệnh này **chỉ ghi ra vault**,
> **không bao giờ đọc ngược** về repo. Ai sửa trực tiếp trong vault sẽ bị ghi đè lần publish sau —
> phải nói rõ điều này với team.

## Luật cứng

1. **Không tự publish.** Bước 3 DỪNG, trình bảng, **chờ user xác nhận**. Đưa tài liệu của khách cho
   cả team đọc là hành vi chia sẻ dữ liệu — không được làm thầm.
2. **KHÔNG đoán khách / dự án.** Suy không ra → **hỏi**. Đặt sai thư mục khách là **lộ dữ liệu sang
   khách khác**, vì phân quyền của drive đặt ở mức thư mục.
3. **Quét rủi ro trước khi đẩy.** Artifact có thể vô tình chứa token, chuỗi kết nối, đường dẫn tuyệt
   đối trên máy, hay thông tin cá nhân. Thấy → **DỪNG, báo, không đẩy mục đó**.
4. **Bản chưa duyệt phải thấy rõ là chưa duyệt.** `> Review: PENDING` → vào `_draft/` **và** có banner
   ở đầu file. Member đọc nhầm nhận định chưa duyệt như kết luận là lỗi nặng của lệnh này.
5. **Không ghi đè thầm.** File đã có trên vault mà nội dung khác → báo, hỏi trước khi thay.
6. **Không đụng `.obsidian/`.** Thư mục cấu hình của Obsidian là của từng người; ghi vào đó gây xung
   đột sync. Chỉ ghi phần nội dung.
7. **Không xoá gì trên vault.** Artifact local đã bỏ → **báo là mồ côi**, để user tự xử. Lệnh này
   không bao giờ xoá file trên kho dùng chung.

## Ngoại lệ có chủ đích với luật #12

Luật #12 (dọn rác khi gặp) cấm dấu ngày và ghi chú quyết định **trong code**. Bản vault thì **được
mang frontmatter có `published`** — đó là **metadata tài liệu lưu trữ**, không phải comment trong code,
và Obsidian cần nó để sắp theo thời gian.

> Ngoại lệ này **chỉ áp cho frontmatter của bản trên vault**. Bản local, và mọi code, giữ nguyên luật
> #7–#12. **Đừng "dọn" frontmatter này** ở lần chạy sau.

## Bước 0 — Vault, phạm vi, danh tính

| Cần gì | Lấy ở đâu | Không có thì |
|---|---|---|
| Đường dẫn vault | `NUMOKIT_VAULT` env | hỏi user |
| Khách · dự án | `.numokit-vault` ở gốc repo | hỏi, rồi **đề nghị ghi file** để lần sau không hỏi lại |
| Phạm vi | arg (`plan`, `review`, tên file, glob) | mặc định **toàn bộ** `$NUMOKIT_ROOT` |

`.numokit-vault` (gốc repo, hai dòng, không phải code nên không chịu luật comment):
```
customer: <tên khách>
project: <tên dự án>
```

Vault không tồn tại → **DỪNG**, báo đường dẫn đã thử. Không tự tạo vault ở nơi đoán được.

## Bước 1 — Quét & phân loại artifact

Đọc `${NUMOKIT_ROOT:-docs/numokit}/`, với mỗi file lấy: **loại** (từ tiền tố tên file), **trạng thái**
(dòng `> Review:` cuối file), **số PR** (nếu tên file có), **slug**.

| Tiền tố file | `kind` | Thư mục đích |
|---|---|---|
| `plan-*` | `plan` | `plan/` |
| `impact-*` | `impact` | `impact/` |
| `review-*` | `review` | `review/` |
| `pr-review-*` | `pr-review` | `review/` |
| `pr-feedback-*` | `pr-feedback` | `feedback/` |
| `spec-drift*` | `spec-drift` | `spec-drift/` |
| `bug-fix-*` | `bug-fix` | `fixbug/` |
| `refactor-*` | `refactor` | `refactor/` |
| `cleanup-*` | `cleanup` | `cleanup/` |
| `open-questions*` | `open-questions` | thư mục dự án (gốc) |

Tiền tố lạ → **không tự xếp loại**, đưa vào mục "chưa rõ" ở bảng Bước 3 và hỏi.

## Bước 2 — Quét rủi ro (luật #3)

Trong nội dung mỗi file, tìm:

- token / key / secret: `sk-`, `ghp_`, `AKIA`, `Bearer `, `password=`, `api[_-]?key`
- chuỗi kết nối: `postgres://`, `mysql://`, `mongodb://`, `redis://` có kèm thông tin đăng nhập
- đường dẫn tuyệt đối trên máy: `/Users/<ai đó>/`, `C:\Users\`
- thông tin cá nhân: email, số điện thoại không thuộc nội dung nghiệp vụ

Có bất kỳ mục nào → **mục đó KHÔNG được đẩy**. Nêu rõ `file:line` ở Bước 3 để user xử lý trước.
**Không tự xoá, không tự che** — đó là nội dung của user, user quyết.

## Bước 3 — DỪNG, trình bảng, chờ xác nhận (bắt buộc)

```
Vault:  <đường dẫn>
Đích:   <khách>/<dự án>/
Phạm vi: <...>

| File local | Loại | Trạng thái | Đích trên vault | Ghi đè? |
|---|---|---|---|---|
| plan-export-csv.md | plan | APPROVED | plan/plan-export-csv.md | mới |
| pr-review-acme-api-12.md | pr-review | PENDING | _draft/review/... | ghi đè (nội dung đã khác) |

Sẽ đẩy: N (trong đó <m> vào _draft/)
Bị giữ lại vì rủi ro: K  → <file:line> + lý do
Chưa rõ loại: J
Mồ côi trên vault (local đã bỏ): <danh sách>  → không xoá, user tự xử
```

DỪNG. Chờ xác nhận. User có thể chọn đẩy một phần.

## Bước 4 — Dựng bản vault

Bản trên vault = **nội dung gốc, cộng thêm** frontmatter, banner (nếu draft), và mục liên quan.
**Không sửa phần thân.** Bản local không bị đụng.

Frontmatter:
```yaml
---
customer: acme
project: billing-api
kind: pr-review
status: approved
pr: 12
source: docs/numokit/pr-review-acme-api-12.md
published: 2026-11-09
tags: [numokit, pr-review]
---
```
`status`: `approved` khi `> Review: APPROVED`, `draft` khi `PENDING`. `pr` bỏ trống nếu không có.

Bản `draft` thêm ngay dưới frontmatter:
```markdown
> [!warning] Bản nháp — chưa được duyệt
> Nhận định trong tài liệu này **chưa qua người duyệt**, đừng dùng làm kết luận.
```

Cuối file, nếu có artifact khác **cùng PR hoặc cùng slug**, thêm liên kết chéo — **dùng đường dẫn đầy
đủ**, vì tên file trùng giữa hai dự án sẽ làm wikilink trỏ sai:
```markdown
## Liên quan
- [[acme/billing-api/plan/plan-export-csv|plan: export CSV]]
- [[acme/billing-api/feedback/pr-feedback-acme-api-12|feedback khách PR 12]]
```

## Bước 5 — Ghi ra vault

- Ghi bằng tool ghi file, **không copy bằng shell**.
- Đường dẫn: `<vault>/<khách>/<dự án>/<thư mục đích>/<tên file>`; draft chèn `_draft/` trước thư mục đích.
- Tên file giữ nguyên tên local. Có ký tự `/ \ : * ? " < > |` → thay bằng `-` (Obsidian và OS không nhận).
- Báo đúng: file nào đã ghi, file nào bỏ qua, vì sao.

## Bước 6 — Sinh index

Ghi `<vault>/<khách>/<dự án>/index.md` — **bảng markdown tĩnh**, chạy được mà không cần plugin nào:

```markdown
---
customer: acme
project: billing-api
kind: index
tags: [numokit, index]
---

# acme / billing-api

| Tài liệu | Loại | PR | Trạng thái |
|---|---|---|---|
| [[plan/plan-export-csv\|export CSV]] | plan | — | duyệt |
| [[_draft/review/pr-review-acme-api-12\|review PR 12]] | pr-review | 12 | nháp |
```

Sắp theo loại, trong mỗi loại sắp theo `published` giảm dần. Bản nháp ghi rõ `nháp`.

> Frontmatter đã có sẵn nên team **có thể** thêm Dataview/Bases để tự lọc. Index tĩnh này vẫn phải
> sinh ra, để vault đọc được trên máy chưa cài plugin.

## Bước 7 — Báo cáo

Theo `lang`: đã đẩy gì, vào đâu, bao nhiêu bản nháp, mục nào bị giữ vì rủi ro, mục nào mồ côi.
Nhắc lại một câu: **vault là bản publish, sửa trực tiếp ở đó sẽ bị ghi đè**.

Không ghi artifact mới vào `$NUMOKIT_ROOT` — lệnh này không sinh artifact, nó chỉ chuyển.

## Đầu ra
Artifact đã lên vault (có frontmatter, draft tách riêng và có banner, liên kết chéo) + `index.md`
đã cập nhật + danh sách mục bị giữ lại kèm lý do.
