---
name: refactor
description: Refactor with a safety net — measure the blast radius, require a characterisation test that pins current behaviour, stop at a human gate, then change in small verified steps. Behaviour must not change; if it must, that is a feature change and belongs in /numokit:plan. Use via /numokit:refactor <mục tiêu>.
license: MIT
---

# Refactor — tái cấu trúc có lưới an toàn

Mục tiêu: đổi **cấu trúc** code mà **không đổi hành vi** — và **chứng minh được** là không đổi.

> Định nghĩa dùng xuyên suốt: **refactor = hành vi quan sát được KHÔNG đổi.** Nếu hành vi phải đổi thì
> đó là **thay đổi tính năng**, không phải refactor → dừng lại, dùng `/numokit:plan`.
> Xem luật #1–#12 trong `using-numokit`.

## Luật cứng

1. **Không có lưới thì không trèo.** Chưa có test phủ vùng sắp sửa → **viết characterisation test
   TRƯỚC** (ghim hành vi hiện tại, kể cả hành vi xấu). Không có lưới mà vẫn sửa là đánh bạc.
2. **Gate trước khi sửa.** Bước 3 DỪNG, trình phương án + blast radius, chờ duyệt.
3. **Bước nhỏ, mỗi bước xanh.** Mỗi bước một phép biến đổi, chạy test ngay. Đỏ → **hoàn tác bước đó**,
   không chồng thêm sửa lên một cây đang đỏ.
4. **KHÔNG đổi hành vi.** Phát hiện bug trong lúc refactor → **ghi lại, KHÔNG sửa kèm**; xử riêng bằng
   `/numokit:fixbug`. Trộn fix vào refactor làm diff không review được.
5. **KHÔNG làm xanh giả.** Không nới/xoá assertion, không skip, không `noqa`/`@ts-ignore`.
   Test đỏ sau refactor = refactor sai, không phải test sai.
6. **Code sạch.** Kết quả không có comment, không mã định danh tự đặt. Gặp rác cũ → XOÁ (luật #12).

## Bước 0 — Đầu vào & mục tiêu

Arg = **mục tiêu refactor** (vd `tách UserService thành repository + service`). Không có arg → hỏi.
Chốt ngay **tiêu chí "xong"** đo được: cái gì phải khác, cái gì phải y nguyên.
Mục tiêu mơ hồ kiểu "làm cho sạch hơn" → hỏi lại cho cụ thể, đừng tự định nghĩa.

## Bước 1 — Đo ảnh hưởng

Chạy phân tích như `/numokit:impact` trên vùng sắp sửa: module · API/hợp đồng công khai · schema ·
vùng dùng chung · test hiện có · tài liệu. Mỗi dòng kèm `file:line` và mức Cao/Trung bình/Thấp.

Đặc biệt nêu rõ: **có chạm API công khai không?** Nếu có, đó không còn là refactor nội bộ — người dùng
ngoài có thể vỡ. Phải nêu ở gate.

## Bước 2 — Dựng lưới an toàn

- Liệt kê test **hiện có** phủ vùng này (file + tên test).
- **Khoảng trống không có test** → viết **characterisation test** ghim hành vi hiện tại trước khi sửa.
  Test này mô tả *hệ thống đang làm gì*, không phải *nên làm gì*. Gặp hành vi trông như bug → vẫn ghim
  đúng hành vi hiện tại, và ghi nó vào danh sách "nghi bug" cho Bước 6.
- Chạy toàn bộ lưới, xác nhận **xanh trước khi bắt đầu**. Đỏ sẵn từ đầu → DỪNG, báo người: không thể
  refactor trên nền đang đỏ.

## Bước 3 — HUMAN GATE (bắt buộc, dừng ở đây)

Trình bày và **chờ duyệt**:
1. **Mục tiêu** + tiêu chí "xong".
2. **Blast radius** (bảng Bước 1), nêu bật mức Cao và việc có chạm API công khai không.
3. **Lưới an toàn**: test nào đang phủ, đã thêm characterisation test nào, chỗ nào vẫn **không phủ được**
   (rủi ro còn lại — nói thẳng, đừng giấu).
4. **Các bước biến đổi dự kiến**, theo thứ tự.
5. **Câu hỏi** nếu còn mơ hồ.

DỪNG. Không sửa code tới khi được duyệt.

## Bước 4 — Biến đổi từng bước

Với **mỗi** bước:
1. Thực hiện **một** phép biến đổi (đổi tên, trích hàm, dời module, gộp trùng lặp…).
2. Chạy lưới an toàn.
3. Xanh → tiếp bước sau. **Đỏ → hoàn tác đúng bước đó**, phân tích, rồi thử cách khác.
4. Không gộp nhiều phép biến đổi vào một bước "cho nhanh".

Giữa chừng phát hiện phạm vi lớn hơn dự kiến → **quay lại gate**, đừng tự nới phạm vi.

## Bước 5 — Xác minh (evidence trước khi tuyên bố)

- Chạy **toàn bộ** suite liên quan, không chỉ lưới cục bộ.
- Báo output thật: số pass/fail trước và sau. Còn đỏ → CHƯA xong.
- Khẳng định rõ: **hành vi quan sát được không đổi** (và nêu bằng chứng là gì).

## Bước 6 — Ghi nhận

`${NUMOKIT_ROOT:-docs/numokit}/refactor-<slug>.md`:
```
# Refactor: <mục tiêu>
## Tiêu chí xong
## Blast radius
## Lưới an toàn        (test sẵn có + characterisation test đã thêm + chỗ không phủ được)
## Các bước đã làm
## Xác minh            (lệnh + pass/fail trước và sau)
## Nghi bug phát hiện kèm  (KHÔNG sửa ở đây — chuyển /numokit:fixbug)
> Review: PENDING
```
KHÔNG thêm dấu ngày, tên khách hay ghi chú quyết định của khách.

## Đầu ra
Code đã tái cấu trúc + characterisation test (nếu có thêm) + `refactor-<slug>.md`
(`> Review: PENDING`) + danh sách nghi bug để xử riêng.
