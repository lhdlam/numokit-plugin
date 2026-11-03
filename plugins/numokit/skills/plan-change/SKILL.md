---
name: plan-change
description: Analyse ONE incoming dev task (feature, change request, bug batch), measure its blast radius across modules/APIs/schema/shared code/tests/docs, cross-check it against the spec and raise any deviation, then produce plan-<slug>.md for a human to approve BEFORE any code is written. Use via /numokit:plan <mô tả task | nhánh/tag git>.
license: MIT
---

# Plan — phân tích task & lập kế hoạch trước khi code

Mục tiêu: **hiểu task → đo ảnh hưởng → đối chiếu spec → trình kế hoạch cho người duyệt**, trước khi
viết dòng code nào. Đây là cổng chặn sớm nhất: bắt sai phạm vi, lệch spec và rủi ro lan rộng *trước khi*
tốn công hiện thực.

> **Pha này CHỈ ĐỌC. KHÔNG sửa code, KHÔNG tạo file nguồn.** Chỉ đọc, đo, hỏi và viết `plan-<slug>.md`.
> **Ngôn ngữ:** plan + giao tiếp theo `lang`. Xem luật #1–#12 trong `using-numokit`.

## Luật cứng

1. **KHÔNG bịa.** Mọi khẳng định kèm **trích dẫn nguồn thật** (`SRS §4.2`, `app/auth.ts:31`).
   Không định vị được → ghi vào "Câu hỏi cần trả lời", đừng đoán.
2. **KHÔNG tự đặt mã định danh.** Gọi mọi thứ bằng tiêu đề mô tả.
3. **Lệch spec thì RAISE, không tự quyết** → `open-questions.md`.
4. **Đo ảnh hưởng trung thực.** Không hạ mức rủi ro cho kế hoạch đẹp. Không chắc → ghi "cần xác minh".
5. **Dừng ở plan.** Viết xong `> Review: PENDING` là DỪNG. Không tự chạy sang hiện thực.

## Bước 0 — Đầu vào & định phạm vi

Arg là **mô tả task** (tự do) HOẶC **nhánh/tag git** đã có code. Không có arg → hỏi lại.
- Đặt `slug` kebab ngắn từ tiêu đề task (vd `them-export-csv`).
- **Cách A — git diff**: `git diff --name-only <nhánh-chính>...<nhánh>`. Chắc chắn nhất.
- **Cách B — mô tả**: từ mô tả định vị module/file/tài liệu liên quan. Không định vị được → HỎI.

## Bước 1 — Phân tích task (đọc tối thiểu, KHÔNG quét cả repo)

Trả lời 3 câu, mỗi câu kèm nguồn:
- **Task yêu cầu gì?** (hành vi mong muốn, ràng buộc, tiêu chí chấp nhận)
- **Tài liệu nói gì về vùng này?** (trích `SRS §x`; không có → ghi rõ "không có nguồn tài liệu")
- **Hiện tại code đang làm gì?** (trích `file:line`)

## Bước 2 — Đánh giá ảnh hưởng (blast radius)

Lập bảng, **mỗi dòng kèm nguồn**:

```
| Hạng mục | Cái gì bị ảnh hưởng | Mức | Vì sao / Nguồn |
```

Quét đủ **6 hạng mục**, không bị ảnh hưởng thì ghi "không" (đừng bỏ trống):

| Hạng mục | Soát cái gì |
|---|---|
| **Module / file** | file, class, hàm phải sửa hoặc thêm |
| **API / hợp đồng công khai** | endpoint, signature, kiểu dữ liệu trả về, sự kiện — **thay đổi phá vỡ tương thích?** |
| **Schema / dữ liệu** | bảng, cột, index, migration, dữ liệu sẵn có cần chuyển đổi |
| **Vùng dùng chung** | hàm/component/middleware dùng nhiều nơi — nơi dễ vỡ ngoài ý muốn |
| **Test hiện có** | test nhiều khả năng đỏ sau thay đổi (file + tên test) |
| **Tài liệu / spec** | mục tài liệu cần cập nhật theo task |

Mức: **Cao** (phá vỡ tương thích / chạm luồng critical / đụng dữ liệu thật) · **Trung bình** (phải sửa
theo) · **Thấp** (liên quan gián tiếp). Không đủ dữ kiện → **"cần xác minh"** kèm cách xác minh.

## Bước 3 — So khớp spec & raise khi lệch

Đối chiếu **3 chiều: task ↔ tài liệu ↔ hiện thực**. Mỗi lệch một dòng, kèm reference **cả hai phía**:

| Loại lệch | Nghĩa | Xử lý |
|---|---|---|
| **Task ≠ Tài liệu** | task yêu cầu khác điều tài liệu quy định | RAISE `open-questions.md`, chờ người quyết |
| **Tài liệu ≠ Hiện thực** | tài liệu và code đang vênh sẵn từ trước | RAISE (bug tiềm ẩn HOẶC tài liệu lỗi thời) |
| **Task thiếu định nghĩa** | tài liệu không nói gì về vùng này | nêu ở "Câu hỏi cần trả lời", KHÔNG tự suy diễn |

Có lệch → **chưa được coi là đã chốt phạm vi**; plan ghi rõ "chờ phân xử".

## Bước 4 — Sinh `plan-<slug>.md`

Trong `${NUMOKIT_ROOT:-docs/numokit}/`:

```
# Plan: <tiêu đề task>

## Mục tiêu
## Nguồn                  (trích dẫn thật cho từng ý)
## Phạm vi
### Trong phạm vi
### NGOÀI phạm vi         (ghi rõ để chặn phình việc)
## Đánh giá ảnh hưởng     (bảng 6 hạng mục ở Bước 2)
## Lệch spec phát hiện được   (bảng Bước 3; không có → "không phát hiện lệch")
## Rủi ro & cách giảm thiểu
## Các bước đề xuất       (thứ tự hiện thực, chạm gì, kiểm chứng ra sao)
## Câu hỏi cần trả lời
> Review: PENDING
```

KHÔNG thêm dấu ngày, tên khách, số hợp đồng hay ghi chú quyết định của khách.

## Bước 5 — Dừng & bàn giao

Tóm tắt: phạm vi, **các mục ảnh hưởng mức Cao**, số lệch spec đã raise, câu hỏi đang chờ.
Nhắc người duyệt plan (`PENDING` → `APPROVED`) rồi mới hiện thực.

Sau khi APPROVED, bước kế theo loại task:
- Sửa bug → `/numokit:fixbug`
- Dọn/tái cấu trúc → `/numokit:refactor`
- Tính năng mới → hiện thực theo "Các bước đề xuất"

## Gate
Trên Claude Code, `hooks/pre-tool-gate.sh` **chặn `fixbug` và `refactor` khi còn `plan-*.md` PENDING**
— đã lập plan thì phải duyệt trước khi sửa code. Chưa lập plan nào thì không chặn (tương thích ngược).

## Đầu ra
`plan-<slug>.md` (`> Review: PENDING`) + `open-questions.md` cập nhật nếu phát hiện lệch spec.
