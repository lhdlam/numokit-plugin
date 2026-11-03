---
name: spec-sync
description: Detect where the code has drifted from the spec documents — behaviour the docs describe but the code does not do, behaviour the code does that no document covers, and outright contradictions. Read-only; every finding cites both sides. Produces spec-drift.md and routes undecidable cases to open-questions.md. Use via /numokit:spec-sync [phạm vi].
license: MIT
---

# Spec-sync — dò code đã trôi khỏi tài liệu

Mục tiêu: tìm chỗ **code và tài liệu không còn khớp**, và **trình cả hai phía kèm nguồn** cho người
phân xử. Đây là việc chống "tài liệu chết": spec viết một đằng, hệ thống chạy một nẻo, không ai biết
bên nào mới đúng.

> **CHỈ ĐỌC. KHÔNG sửa code, KHÔNG sửa tài liệu.** Phân xử bên nào đúng là việc của con người.
> **Ngôn ngữ:** báo cáo theo `lang`.

## Luật cứng

1. **Mỗi phát hiện phải có reference CẢ HAI PHÍA**: `[SRS §4.2]` ↔ `[app/auth.ts:31]`.
   Thiếu một phía → không phải "drift", mà là "thiếu nguồn" → xếp loại khác (xem bảng dưới).
2. **KHÔNG tự phân xử bên nào đúng.** Agent chỉ trình bày. Kết luận "đây là bug" hay "tài liệu lỗi thời"
   là quyết định của BA/dev lead → `open-questions.md`.
3. **KHÔNG bịa.** Không suy diễn ý định của tài liệu. Tài liệu mơ hồ → ghi là **mơ hồ**, đừng đoán.
4. **Không sửa gì cả.** Kể cả thấy rõ là lỗi chính tả trong code.

## Bước 0 — Đầu vào & nguồn tài liệu

Arg là **phạm vi** (module, thư mục, tính năng). Không có arg → hỏi phạm vi, **đừng quét cả hệ thống
một lượt** (báo cáo sẽ quá lớn để ai đó thật sự đọc).

Xác định nguồn tài liệu theo thứ tự: thư mục user chỉ định → `docs/` → `input/docs/` → README.
Không tìm thấy tài liệu nào → báo thẳng "không có nguồn spec để đối chiếu" và DỪNG.

## Bước 1 — Trích yêu cầu từ tài liệu

Trong phạm vi, liệt kê từng **hành vi tài liệu quy định**, mỗi cái kèm `[tài liệu §mục]`.
Gọi bằng **tiêu đề mô tả**, KHÔNG tự đặt mã định danh.

## Bước 2 — Trích hành vi từ code

Đọc code trong phạm vi, liệt kê **hành vi thực tế** kèm `file:line`.
Chỉ đọc vùng liên đới — không quét cả repo.

## Bước 3 — Đối chiếu hai chiều & phân loại

| Loại | Nghĩa | Mức |
|---|---|---|
| **Tài liệu ≠ Code** | cùng một hành vi nhưng hai bên nói khác nhau | **Cao** — bug tiềm ẩn HOẶC tài liệu lỗi thời |
| **Tài liệu có, Code không** | yêu cầu chưa được hiện thực (hoặc đã bị gỡ) | **Cao** nếu là luồng chính |
| **Code có, Tài liệu không** | hành vi không ai mô tả — rủi ro "tính năng ma" | **Trung bình** |
| **Tài liệu mơ hồ** | không đủ rõ để kết luận code đúng hay sai | **Trung bình** — cần làm rõ |
| **Khớp** | hai bên trùng nhau | không ghi vào báo cáo |

**Đi cả hai chiều.** Chỉ soát "tài liệu → code" sẽ bỏ sót toàn bộ tính năng ma.

## Bước 4 — Sinh `spec-drift.md`

Trong `${NUMOKIT_ROOT:-docs/numokit}/`:

```
# Spec drift: <phạm vi>

## Tổng quan        (N chỗ lệch: X cao / Y trung bình)

| Hành vi | Tài liệu nói | Code làm | Loại | Mức |
|---|---|---|---|---|
| <tiêu đề mô tả> | ... [SRS §4.2] | ... [app/auth.ts:31] | Tài liệu ≠ Code | Cao |

## Cần phân xử     (chuyển sang open-questions.md)
> Review: PENDING
```

Mọi dòng mức **Cao** đồng thời ghi vào `open-questions.md` để không bị trôi.
KHÔNG thêm dấu ngày, tên khách hay ghi chú quyết định của khách.

## Bước 5 — Bàn giao

Tóm tắt: số chỗ lệch theo loại, **các mục mức Cao**, và nêu rõ: *"đây là báo cáo đối chiếu, chưa kết
luận bên nào đúng — cần người phân xử"*.

Sau khi người phân xử:
- Code sai → `/numokit:fixbug`
- Tài liệu sai → cập nhật tài liệu (numokit không tự sửa)

## Đầu ra
`spec-drift.md` (`> Review: PENDING`) + `open-questions.md` cho các mục mức Cao.
