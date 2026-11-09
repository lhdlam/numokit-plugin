---
name: review-requirements
description: Review code that was just written against what the customer actually asked for — extract the requirement list from its real source, then give each requirement a verdict (Đạt | Thiếu | Lệch | Thừa | Không kiểm được) with citations from both the requirement and the code. Read-only; never softens a requirement to match the code. Use via /numokit:review <nhánh|tag|PR|diff>.
license: MIT
---

# Review — đối chiếu code vừa làm với yêu cầu của khách

Mục tiêu: trả lời đúng một câu — **"code vừa viết có đúng thứ khách yêu cầu không?"** — bằng verdict
từng yêu cầu, mỗi verdict có **bằng chứng hai phía**: nguồn yêu cầu và vị trí code.

Đây là **tự nghiệm thu phía dev**, chạy *trước* khi đẩy cho tester hay khách.

> **CHỈ ĐỌC. KHÔNG sửa code.** Đây là báo cáo, không phải phiên sửa.
> Muốn sửa chỗ Thiếu/Lệch → `/numokit:fixbug` hoặc hiện thực tiếp (đều có gate riêng).

## Luật cứng

1. **KHÔNG nới yêu cầu cho khớp code.** Đây là luật quan trọng nhất. Code làm khác yêu cầu → ghi
   **Lệch**, KHÔNG diễn giải lại yêu cầu cho vừa với thứ đã viết. Thấy yêu cầu có vẻ sai/lỗi thời →
   vẫn chấm theo yêu cầu, rồi nêu riêng ở mục "Nghi vấn về yêu cầu" cho người quyết.
2. **Mỗi verdict phải có bằng chứng HAI PHÍA**: nguồn yêu cầu (`SRS §4.2`, `plan-them-export-csv.md →
   Trong phạm vi`) và vị trí code (`app/report.ts:88`). Thiếu một phía → verdict là
   **Không kiểm được**, không phải Đạt.
3. **KHÔNG bịa yêu cầu.** Không có nguồn yêu cầu → DỪNG và hỏi. Tuyệt đối không suy ra yêu cầu từ
   chính code đang review (vòng luẩn quẩn: code nào cũng sẽ "đạt").
4. **Soát cả chiều ngược.** Code làm **thừa** thứ không ai yêu cầu cũng là phát hiện (phình phạm vi,
   rủi ro ngoài kế hoạch), không được bỏ qua.
5. **KHÔNG sửa gì.** Kể cả lỗi rõ ràng. Ghi lại, để người quyết.

## Bước 0 — Đầu vào: phạm vi code & nguồn yêu cầu

**Phạm vi code** (arg thứ nhất, hoặc mặc định):
- nhánh/tag → `git diff --name-only <nhánh-chính>...<ref>`
- số PR → `gh pr diff <n>`
- không có arg → `git diff` của working tree; không có thay đổi → hỏi lại

**Nguồn yêu cầu** — tìm theo thứ tự, dừng ở cái đầu tiên có thật:
1. `plan-<slug>.md` đã `> Review: APPROVED` trong `${NUMOKIT_ROOT:-docs/numokit}/` — **ưu tiên cao nhất**,
   vì mục "Trong phạm vi"/"NGOÀI phạm vi" là phạm vi đã được chốt
2. Tài liệu yêu cầu (`docs/`, `input/docs/`, SRS, user story) ứng với tính năng
3. Mô tả khách do user dán trực tiếp vào lệnh
4. Issue/ticket mà user chỉ định

Không tìm được nguồn nào → **DỪNG, hỏi user**. Đừng review chay.

Đặt `slug` kebab ngắn cho tên file báo cáo.

## Bước 1 — Trích danh sách yêu cầu

Liệt kê từng yêu cầu **rời rạc, kiểm được**, mỗi cái kèm nguồn thật.
Gọi bằng **tiêu đề mô tả**, KHÔNG tự đặt mã định danh.

Yêu cầu mơ hồ (không đủ rõ để phán Đạt/Không) → vẫn đưa vào danh sách, đánh dấu để chấm
**Không kiểm được**, và nêu ở mục "Nghi vấn về yêu cầu".

## Bước 2 — Đọc code vừa làm

Đọc diff: file nào, hành vi gì được thêm/đổi/bỏ. Chỉ đọc vùng liên đới.
Ghi nhận cả thứ **không nằm trong bất kỳ yêu cầu nào** — nguyên liệu cho verdict **Thừa**.

## Bước 3 — Chấm verdict từng yêu cầu

| Verdict | Nghĩa | Bắt buộc kèm |
|---|---|---|
| ✅ **Đạt** | code hiện thực đúng yêu cầu | nguồn yêu cầu + `file:line` |
| ❌ **Thiếu** | yêu cầu chưa được làm | nguồn yêu cầu + nêu rõ đã tìm ở đâu |
| ⚠ **Lệch** | có làm nhưng khác yêu cầu | cả hai phía + **khác ở điểm nào** |
| ➕ **Thừa** | code làm thứ không yêu cầu nào nhắc tới | `file:line` + vì sao cho là ngoài phạm vi |
| ❓ **Không kiểm được** | không đủ nguồn để phán | nêu **thiếu đúng cái gì** để kiểm được |

**Đạt** là verdict khó nhất, không phải dễ nhất: phải chỉ được **đúng dòng code** thoả yêu cầu.
Chỉ "nhìn có vẻ ổn" thì là **Không kiểm được**.

## Bước 4 — Soát chất lượng kèm (trên diff)

Ngoài việc đúng/sai yêu cầu, soát thêm trên **chính diff này**:
- **Chuẩn code sạch** (luật #7–#12): comment còn sót, comment tiếng Việt, mã định danh tự đặt,
  `noqa`/`@ts-ignore`, ghi chú quyết định khách / dấu ngày
- **Xử lý lỗi**: nhánh lỗi của yêu cầu có được làm không, hay chỉ có happy path
- **Hợp đồng công khai**: có phá vỡ tương thích mà yêu cầu không nhắc tới không
- **Test**: thay đổi này có test đi kèm không

Mỗi phát hiện kèm `file:line`. Đây là **ghi nhận**, không phải sửa.

## Bước 5 — Sinh `review-<slug>.md`

Trong `${NUMOKIT_ROOT:-docs/numokit}/`:

```
# Review: <tiêu đề thay đổi>

## Phạm vi đã review     (diff nào, nguồn yêu cầu nào)

## Verdict theo yêu cầu
| Yêu cầu | Nguồn | Verdict | Bằng chứng / Ghi chú |
|---|---|---|---|

Tổng: N yêu cầu — X Đạt / Y Thiếu / Z Lệch / W Không kiểm được · T mục Thừa

## Ngoài phạm vi (Thừa)
## Soát chất lượng       (code sạch · xử lý lỗi · hợp đồng công khai · test)
## Nghi vấn về yêu cầu   (yêu cầu mơ hồ / có vẻ sai — KHÔNG tự sửa yêu cầu)
## Đề xuất bước tiếp
> Review: PENDING
```

KHÔNG thêm dấu ngày, tên khách, số hợp đồng hay ghi chú quyết định của khách vào báo cáo.

## Bước 6 — Bàn giao

Tóm tắt trung thực: tổng verdict, **mọi mục Thiếu/Lệch**, và số mục Thừa.
Có Thiếu hoặc Lệch → nói thẳng **"chưa đạt yêu cầu"**, đừng gói trong ngôn từ mềm.

Bước tiếp theo:
- Thiếu/Lệch → hiện thực tiếp, hoặc `/numokit:fixbug` nếu là lỗi
- Thừa → hỏi người: giữ hay gỡ
- Nghi vấn về yêu cầu → `open-questions.md` cho BA/khách phân xử
- Sạch rồi → bàn giao cho tester (`/testkit:review-dev` nghiệm thu theo test case)

## Khác gì `/numokit:spec-sync`?

| | `spec-sync` | `review` |
|---|---|---|
| Đầu vào | **phạm vi** (module/thư mục) | **diff** vừa làm (nhánh/PR) |
| Câu hỏi | "code và tài liệu có vênh nhau không?" | "**code vừa viết có đúng yêu cầu không?**" |
| Dùng khi | kiểm kê định kỳ, tiếp quản code cũ | **vừa code xong, trước khi bàn giao** |
| Kết quả | `spec-drift.md` | `review-<slug>.md` + verdict từng yêu cầu |

## Đầu ra
`review-<slug>.md` (`> Review: PENDING`) + `open-questions.md` cho nghi vấn về yêu cầu.
Không sửa code.
