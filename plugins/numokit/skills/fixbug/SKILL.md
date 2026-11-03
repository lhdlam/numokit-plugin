---
name: fixbug
description: Diagnose and fix ONE bug — locate the root cause in code + spec with source citations, ask the developer clarifying questions at a hard human gate, then fix the root cause and add a regression test that reproduces the bug (red before, green after). Use via /numokit:fixbug <mô tả bug>.
license: MIT
---

# Fixbug — chẩn đoán & sửa một bug

Mục tiêu: từ mô tả bug → **định vị nguyên nhân gốc** trong code + tài liệu, **hỏi người** những gì còn
mơ hồ, **sửa đúng root cause**, và **luôn** để lại regression test để bug không tái phát.

> An toàn nằm ở **human gate bắt buộc**: không sửa một dòng code nào trước khi người dùng trả lời câu
> hỏi và duyệt hướng sửa. Xem luật #1–#12 trong `using-numokit`.

## Luật cứng

1. **Gate trước khi sửa.** Bước 2 phải DỪNG, đặt câu hỏi + trình hướng sửa, chờ duyệt. Tuyệt đối không
   edit code trước đó.
2. **Sửa root cause, không vá triệu chứng.** Diff tối thiểu, theo convention quanh đó.
3. **KHÔNG làm xanh giả.** Không nới assertion, không skip test, không gắn `noqa`/`@ts-ignore` để che.
   Regression test phải **thật sự** tái hiện bug: đỏ trước fix, xanh sau fix.
4. **KHÔNG bịa.** Mọi nhận định kèm reference (`SRS §4.2`, `app/auth.ts:31`).
   Không định vị được → nói thẳng và hỏi.
5. **Lỗi ở tài liệu, không phải code → không sửa code.** Ghi `open-questions.md`, để người phân xử.
6. **Code sạch.** Code sửa ra và regression test **KHÔNG chứa comment**, KHÔNG mã định danh tự đặt,
   KHÔNG ghi chú ngày/tên khách. Gặp rác cũ trong vùng đụng tới → **XOÁ ngay** (luật #12).

## Bước 0 — Đầu vào & nhận dạng
- Arg = **mô tả bug** (tự do). Không có arg → hỏi lại, đừng tự chọn bug.
- Đọc `${NUMOKIT_ROOT:-docs/numokit}/.numokit-lang` (nếu có) và `CLAUDE.md` của project.
- **KHÔNG tự sinh mã bug.** Bug nhận diện bằng **tiêu đề mô tả ngắn**; tên file artifact dùng slug kebab.

## Bước 1 — Định vị nguyên nhân gốc (KHÔNG sửa gì)

Áp dụng systematic-debugging: hiểu trước khi sửa.
- Chốt **expected vs actual**: bug nói hệ thống làm sai gì so với điều gì.
- **Nguồn yêu cầu:** tìm mục tài liệu định nghĩa hành vi đúng — trích `[SRS §4.2]`. Không có tài liệu →
  ghi rõ và dựa trên hành vi hợp lý, nêu giả định.
- **Nguồn hiện thực:** tìm ĐÚNG chỗ phát sinh hành vi sai (`file:line`). Chỉ đọc vùng liên đới.
- **Cross-check** code ↔ tài liệu ↔ bug, rồi phân định:

| Phân định | Nghĩa | Hành động |
|---|---|---|
| **Bug code thật** | code lệch spec / lệch hành vi hợp lý | sửa được → tiếp Bước 2 |
| **Spec/doc lỗi** | "bug" do kỳ vọng sai, code đúng | KHÔNG sửa code → `open-questions.md` + hỏi |
| **Không tái hiện được** | thiếu dữ kiện (env/data/bước) | hỏi ở Bước 2, chưa kết luận |

Viết **root-cause hypothesis** kèm bằng chứng có reference.

## Bước 2 — Đặt câu hỏi (HUMAN GATE — bắt buộc, dừng ở đây)

Trước khi chạm code, trình bày gọn và **chờ trả lời**:
1. **Câu hỏi** cho mọi chỗ mơ hồ: hành vi kỳ vọng chính xác? tái hiện trên env/data nào?
   phạm vi ảnh hưởng nào chấp nhận được?
2. **Nhận định** root cause (kèm reference) — bug code hay spec issue.
3. **Hướng sửa đề xuất** + **file sẽ đổi** + **blast radius/rủi ro** (còn gì dùng chung đoạn code đó).
4. Nếu là spec issue → nêu rõ "sẽ KHÔNG sửa code", chờ người quyết.

DỪNG. Không tiếp Bước 3 tới khi người dùng trả lời và duyệt.

## Bước 3 — Sửa code (chỉ sau khi được duyệt)
- Sửa **nguyên nhân gốc**, diff tối thiểu, khớp style/convention trong `CLAUDE.md` và code xung quanh.
- Không ôm đồm refactor ngoài phạm vi bug. Đụng nhiều nơi → nêu lý do.
- Spec issue → **không sửa code**; hoàn tất ở `open-questions.md`, sang Bước 6.

## Bước 4 — Regression test (LUÔN — đóng vòng lặp bug)
- Test **phải đỏ trước fix, xanh sau fix**. Không làm nó đỏ được trên code cũ → chưa tái hiện đúng bug,
  xem lại root cause.
- **Tên test = mô tả hành vi đúng mà bug đã phá** (vd `không cho đăng nhập khi sai mật khẩu`).
  KHÔNG mã bug, KHÔNG comment.
- Đặt cạnh test hiện có của module, theo đúng framework và convention của project.

## Bước 5 — Xác minh (evidence trước khi tuyên bố)
- Chạy regression test + test liên quan của module.
- Xác nhận: regression test **đỏ→xanh**, và **không làm vỡ** test khác. Còn đỏ → CHƯA xong, quay lại
  Bước 3/1, tuyệt đối không tuyên bố đã fix.
- Báo cáo output thật (số pass/fail), không tô hồng.

## Bước 6 — Ghi nhận
`${NUMOKIT_ROOT:-docs/numokit}/bug-fix-<slug>.md`:
```
# Bug fix: <tiêu đề bug>
## Nội dung bug
## Nguyên nhân gốc      (kèm reference: [SRS §x], [file:line])
## Thay đổi              (file đã sửa + tóm tắt; hoặc "spec issue — không sửa code")
## Regression test       (đường dẫn + tên test; đỏ trước / xanh sau)
## Xác minh              (lệnh + kết quả pass/fail)
> Review: PENDING
```
KHÔNG thêm dấu ngày, tên khách hay ghi chú quyết định của khách.

## Đầu ra
Code đã sửa (hoặc `open-questions.md` nếu là spec issue) + 1 regression test + `bug-fix-<slug>.md`
(`> Review: PENDING`). Mọi thứ sinh ra: không comment, không mã định danh, không dấu ngày.
