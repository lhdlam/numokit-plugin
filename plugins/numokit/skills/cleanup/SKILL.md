---
name: cleanup
description: Sweep a scope of the codebase against the clean-code standard — comments, Vietnamese comments, invented identifier codes, lint/type-check suppressions, customer-decision notes and date stamps — report what was found, stop at a human gate, then delete. Suppressions are removed only together with a real fix. Use via /numokit:cleanup [phạm vi].
license: MIT
---

# Cleanup — quét sạch code theo chuẩn bàn giao

Mục tiêu: dọn **chủ động, một lượt, có kiểm soát** — thay vì chỉ dọn thụ động khi tình cờ đi qua
(luật #12). Dùng trước khi bàn giao khách, trước release, hoặc khi tiếp quản code cũ.

> Luật #12 (dọn khi gặp) vẫn chạy nền trong mọi lệnh khác. Lệnh này là bản **chủ động**: quét có chủ
> đích, báo cáo trước, rồi xoá. Xem luật #7–#12 trong `using-numokit`.

## Luật cứng

1. **Báo cáo trước, xoá sau.** Bước 2 DỪNG ở human gate — trình đầy đủ cái sẽ xoá, chờ duyệt.
   Không bao giờ xoá hàng loạt rồi mới báo.
2. **Suppression không được xoá trần.** `# noqa`, `// @ts-ignore`… bịt miệng một checker đã phát hiện
   vấn đề thật. **Xoá phải đi kèm SỬA nguyên nhân**. Không sửa được → **giữ lại** và đưa vào mục
   "cần người quyết", KHÔNG xoá để rồi bỏ mặc lint đỏ.
3. **KHÔNG đổi hành vi.** Dọn dẹp chỉ xoá comment/ghi chú. Thấy code chết hay bug → **ghi lại, không
   sửa kèm**; xử riêng bằng `/numokit:fixbug`.
4. **Chạy test sau khi xoá.** Xoá comment về lý thuyết là an toàn, nhưng directive (`# fmt: off`,
   `// prettier-ignore`, pragma của trình biên dịch) **không phải comment thường** — phải xác minh.
5. **Không đụng thứ không phải của mình.** Bỏ qua `vendor/`, `node_modules/`, thư mục build, file sinh
   tự động, và license header. Nêu rõ đã bỏ qua những gì.
6. **Không dọn frontmatter của bản đã publish.** Artifact trên Obsidian vault (xem `/numokit:publish`)
   mang frontmatter YAML có `published: <ngày>`. Đó là **metadata tài liệu lưu trữ**, là ngoại lệ có
   chủ đích của luật #12 — **không** phải dấu ngày trong code. Giữ nguyên, kể cả khi quét vào vault.

## Bước 0 — Đầu vào & phạm vi

Arg = **phạm vi** (thư mục, module, glob). Không có arg → hỏi, **đừng mặc định quét cả repo**
(diff khổng lồ thì không ai review nổi, và review được mới là điều kiện để xoá an toàn).

Loại trừ mặc định: `.git/`, `node_modules/`, `vendor/`, `dist/`, `build/`, `target/`, `__pycache__/`,
file sinh tự động (có header "generated"), license header ở đầu file.

## Bước 1 — Quét & phân loại

Tìm trong phạm vi, gom theo **6 nhóm**:

| Nhóm | Tìm gì | Xử lý |
|---|---|---|
| **Comment tiếng Việt** | comment chứa ký tự tiếng Việt | XOÁ |
| **Mã định danh tự đặt** | `TC-xx`, `REQ-xx`, `BUG-xx`, `OQ-xx` trong code | XOÁ |
| **Ghi chú quyết định khách** | tên khách, số hợp đồng/ticket, "khách chốt…", ngày quyết định | XOÁ |
| **Dấu ngày / tác giả** | `// 02/10/2026`, `# author: ...`, `TODO(ai) 15/9` | XOÁ — **trừ** frontmatter bản publish (luật #6) |
| **Comment thừa** | comment lặp lại y hệt tên hàm, code bị comment-out, comment chết | XOÁ |
| **Suppression** | `# noqa`, `# type: ignore`, `# pylint: disable`, `# fmt: off`, `// @ts-ignore`, `// @ts-nocheck`, `// @ts-expect-error`, `// eslint-disable*`, `// prettier-ignore` | XOÁ **+ sửa nguyên nhân**; không sửa được → GIỮ, đưa lên người |

Với nhóm **Suppression**, mỗi mục phải ghi thêm: **checker báo gì nếu gỡ ra** và **cách sửa đề xuất**.
Chưa biết → chạy thử checker để biết, đừng đoán.

## Bước 2 — HUMAN GATE (bắt buộc, dừng ở đây)

Trình bày và **chờ duyệt**:
```
Phạm vi: <...>   | File quét: N   | Mục tìm thấy: M

| Nhóm | Số lượng | File tiêu biểu |
...
Suppression cần sửa kèm: K mục
  - app/auth.ts:31  // @ts-ignore  → lỗi: Type 'string | null' ...  → sửa: thêm guard null
Không sửa được (đề nghị giữ): J mục  → lý do
Đã bỏ qua: vendor/, node_modules/, license header
```
Hỏi rõ: duyệt xoá **tất cả**, hay chỉ **một số nhóm**? DỪNG, chờ trả lời.

## Bước 3 — Xoá (chỉ sau khi được duyệt)

- Xoá đúng những nhóm được duyệt, đúng phạm vi.
- Suppression: xoá **cùng lúc** với sửa nguyên nhân, trong cùng một thay đổi.
- Giữ nguyên định dạng và thụt lề quanh chỗ xoá; không reformat cả file (làm nhiễu diff).
- Xoá hết comment trong một khối làm khối đó khó hiểu → đó là tín hiệu **code cần đặt tên lại**,
  nêu ra ở báo cáo; **không giữ lại comment**.

## Bước 4 — Xác minh (evidence trước khi tuyên bố)

- Chạy **build + lint + type-check + test** của project.
- So trước/sau. Có gì chuyển đỏ → **hoàn tác phần gây đỏ**, báo người. Không để lại cây đỏ.
- Báo output thật, không tô hồng.

## Bước 5 — Ghi nhận

`${NUMOKIT_ROOT:-docs/numokit}/cleanup-<slug>.md`:
```
# Cleanup: <phạm vi>
## Đã xoá              (theo nhóm, kèm số lượng)
## Suppression đã sửa kèm   (mục + nguyên nhân thật đã sửa)
## Còn giữ lại         (lý do, cần người quyết)
## Đã bỏ qua           (vendor, generated, license header)
## Xác minh            (build/lint/type-check/test: trước và sau)
## Nghi bug / code chết phát hiện kèm   (KHÔNG sửa ở đây)
> Review: PENDING
```

## Đầu ra
Code đã dọn + `cleanup-<slug>.md` (`> Review: PENDING`) + danh sách suppression còn giữ cần người quyết.
