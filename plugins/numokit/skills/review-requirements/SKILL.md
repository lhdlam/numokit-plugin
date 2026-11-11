---
name: review-requirements
description: Review code that was just written against what the customer actually asked for — extract the requirement list from its real source, score each requirement twice (once here, once by an independent peer-review subagent that never sees these verdicts), then report every requirement with two-sided citations and flag every disagreement for a human. Verdicts are Đạt | Thiếu | Lệch | Thừa | Không kiểm được. Read-only; never softens a requirement to match the code. Use via /numokit:review <nhánh|tag|PR|diff>.
license: MIT
---

# Review — đối chiếu code vừa làm với yêu cầu của khách

Mục tiêu: trả lời đúng một câu — **"code vừa viết có đúng thứ khách yêu cầu không?"** — bằng verdict
từng yêu cầu, mỗi verdict có **bằng chứng hai phía**: nguồn yêu cầu và vị trí code.

Đây là **tự nghiệm thu phía dev**, chạy *trước* khi đẩy cho tester hay khách.

**Chấm hai lượt độc lập.** Agent vừa viết code biết mình **định** làm gì, nên nó đọc diff qua lớp ý
định đó và thấy yêu cầu đã thoả ở chỗ thực ra chưa. Vì vậy lệnh này luôn mở thêm một agent
`requirement-reviewer` chấm lại — nó **không hề biết** verdict của lượt đầu, nên nó chỉ đọc được đúng
cái code đang làm. Chỗ hai lượt lệch nhau là chỗ đáng người xem nhất.

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
6. **Peer review bắt buộc, và brief KHÔNG được chứa kết luận.** Lệnh này luôn mở một agent thứ hai
   chấm độc lập (Bước 2). Brief đưa cho nó **chỉ có yêu cầu + phạm vi**, tuyệt đối **không có verdict,
   nhận định hay phỏng đoán** nào — agent nhận sẵn kết luận sẽ chỉ xác nhận lại kết luận đó, và peer
   review mất sạch giá trị.
7. **KHÔNG tự phân xử khi hai bên lệch nhau.** Chỗ lệch là **tâm điểm** của báo cáo, không phải thứ
   cần làm cho khớp. Lấy phía **thận trọng hơn**, ghi rõ hai bên nói gì, đẩy lên người.

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

## Bước 2 — Phóng peer reviewer NGAY (trước khi tự chấm)

Mở agent `requirement-reviewer` **ngay tại đây**, trước khi tự đọc code. Thứ tự này là có chủ đích:
lúc này bản thân **chưa có verdict nào**, nên brief **không thể** bị nhiễm kết luận. Để tới sau khi
chấm xong mới phóng là tự mở đường cho mình mồi nó.

Nó chạy nền → tự đi làm Bước 3 trong khi chờ, không ngồi đợi.

Gọi bằng **Agent tool**, `subagent_type: "numokit:requirement-reviewer"` (agent của plugin nạp theo
namespace `<plugin>:<tên>`; tên trần `requirement-reviewer` có thể không phân giải được).

**Nền không có Agent tool** (Cursor và nền tương tự) → **không thể** chạy peer review. Khi đó: nói rõ
với user ngay, chạy một lượt, và **ghi vào báo cáo là không có peer review**. Tuyệt đối không tự đóng
cả hai vai rồi gọi đó là peer review — tự chấm hai lần vẫn là cùng một lớp ý định, không độc lập.

Brief gồm **đúng ba thứ**:
1. **Danh sách yêu cầu** ở Bước 1 — nguyên văn + nguồn thật của từng cái
2. **Phạm vi code** — base + ref (hoặc "working tree")
3. **Đường dẫn tài liệu yêu cầu**, để nó tự đối chiếu xem yêu cầu có được thuật lại đúng

**KHÔNG đưa vào brief:** verdict, nhận định, phỏng đoán, "chỗ này chắc ổn", mô tả diff theo cách hiểu
của mình, hay bất cứ thứ gì ám chỉ kết quả mong đợi. Nó phải **tự đọc diff**.

> **Trùng việc ở đây là CÓ CHỦ ĐÍCH.** Hai lượt đọc độc lập rồi so — đó chính là peer review, không
> phải lãng phí. Vẫn phải tự chấm đầy đủ ở Bước 3, đừng khoán cho nó.

User yêu cầu bỏ peer review (`--no-peer`, hoặc nói rõ) → bỏ qua Bước 2 và 4, và **ghi rõ trong báo
cáo là đã chạy không có peer review**, để người đọc biết độ tin cậy thấp hơn.

## Bước 3 — Tự đọc code và chấm verdict

Đọc diff: file nào, hành vi gì được thêm/đổi/bỏ. Chỉ đọc vùng liên đới.
Ghi nhận cả thứ **không nằm trong bất kỳ yêu cầu nào** — nguyên liệu cho verdict **Thừa**.

Chấm xong **rồi** mới xem kết quả của peer reviewer. Xem trước là tự mồi chính mình.

| Verdict | Nghĩa | Bắt buộc kèm |
|---|---|---|
| ✅ **Đạt** | code hiện thực đúng yêu cầu | nguồn yêu cầu + `file:line` |
| ❌ **Thiếu** | yêu cầu chưa được làm | nguồn yêu cầu + nêu rõ đã tìm ở đâu |
| ⚠ **Lệch** | có làm nhưng khác yêu cầu | cả hai phía + **khác ở điểm nào** |
| ➕ **Thừa** | code làm thứ không yêu cầu nào nhắc tới | `file:line` + vì sao cho là ngoài phạm vi |
| ❓ **Không kiểm được** | không đủ nguồn để phán | nêu **thiếu đúng cái gì** để kiểm được |

**Đạt** là verdict khó nhất, không phải dễ nhất: phải chỉ được **đúng dòng code** thoả yêu cầu.
Chỉ "nhìn có vẻ ổn" thì là **Không kiểm được**.

## Bước 4 — Thu kết quả peer review và đối chiếu

Giờ mới đọc kết quả của `requirement-reviewer`, đặt cạnh bảng của mình, so **từng yêu cầu**.

**Xử lý trước hai cờ nó có thể giương:**
- `brief_contaminated: true` → **brief đã lọt kết luận**. Peer review lượt này **không đáng tin**;
  nói thẳng trong báo cáo, đừng im. Còn thời gian thì phóng lại với brief sạch.
- `brief_mismatch` không rỗng → yêu cầu đã **thuật sai** ở Bước 1 so với tài liệu gốc. Sửa lại danh
  sách yêu cầu và **chấm lại** — chấm đúng theo tài liệu sai thì vô nghĩa.

Rồi so verdict. **Hai bên khớp** → verdict đó vững hơn hẳn một lượt đọc, ghi bình thường.
**Hai bên lệch** → KHÔNG tự phân xử (luật #7). Lấy phía **thận trọng hơn** theo thang này:

```
Đạt  <  Không kiểm được  <  Lệch / Thiếu
        (thận trọng dần →)
```

Nghĩa là mình chấm Đạt mà peer chấm Thiếu → **không được ghi Đạt**. Ghi phía thận trọng, đánh dấu
🔀 **tranh chấp**, và nêu rõ hai bên nói gì + dẫn chứng của mỗi bên.

Mục peer tìm được mà mình bỏ sót (`extra`, `easy_to_miss`) → **nhập vào báo cáo**, ghi rõ do peer phát
hiện. Bỏ sót là chuyện bình thường, che việc bỏ sót thì không.

> **Trùng verdict không chứng minh là đúng** — hai agent cùng đọc sai một chỗ là chuyện có thật. Nó chỉ
> hạ rủi ro, không xoá rủi ro. Đừng diễn giải "cả hai đều Đạt" thành bảo đảm.

## Bước 5 — Soát chất lượng kèm (trên diff)

Ngoài việc đúng/sai yêu cầu, soát thêm trên **chính diff này**:
- **Chuẩn code sạch** (luật #7–#12): comment còn sót, comment tiếng Việt, mã định danh tự đặt,
  `noqa`/`@ts-ignore`, ghi chú quyết định khách / dấu ngày
- **Xử lý lỗi**: nhánh lỗi của yêu cầu có được làm không, hay chỉ có happy path
- **Hợp đồng công khai**: có phá vỡ tương thích mà yêu cầu không nhắc tới không
- **Test**: thay đổi này có test đi kèm không

Mỗi phát hiện kèm `file:line`. Đây là **ghi nhận**, không phải sửa.

## Bước 6 — Sinh `review-<slug>.md`

Trong `${NUMOKIT_ROOT:-docs/numokit}/`:

```
# Review: <tiêu đề thay đổi>

## Phạm vi đã review     (diff nào, nguồn yêu cầu nào)

## Verdict theo yêu cầu
| Yêu cầu | Nguồn | Verdict | Peer | Bằng chứng / Ghi chú |
|---|---|---|---|---|

Cột **Peer**: `=` hai bên khớp · `🔀` tranh chấp (ghi rõ hai bên nói gì ở mục dưới)

Tổng: N yêu cầu — X Đạt / Y Thiếu / Z Lệch / W Không kiểm được · T mục Thừa
Peer review: khớp A/N · tranh chấp B/N

## Tranh chấp với peer review   (từng mục: mình chấm gì, peer chấm gì, dẫn chứng mỗi bên)
## Peer phát hiện thêm          (mục mình bỏ sót — ghi rõ do peer tìm ra)
## Ngoài phạm vi (Thừa)
## Soát chất lượng       (code sạch · xử lý lỗi · hợp đồng công khai · test)
## Nghi vấn về yêu cầu   (yêu cầu mơ hồ / có vẻ sai — KHÔNG tự sửa yêu cầu)
## Đề xuất bước tiếp
> Review: PENDING
```

Chạy **không có** peer review → ghi ngay dưới "Phạm vi đã review": `Peer review: KHÔNG chạy` kèm lý do.
Brief bị nhiễm → ghi `Peer review: không đáng tin (brief lọt kết luận)`. Không được im hai việc này.

KHÔNG thêm dấu ngày, tên khách, số hợp đồng hay ghi chú quyết định của khách vào báo cáo.

## Bước 7 — Bàn giao

Tóm tắt trung thực: tổng verdict, **mọi mục Thiếu/Lệch**, số mục Thừa, và **mọi mục tranh chấp với
peer**. Có Thiếu hoặc Lệch → nói thẳng **"chưa đạt yêu cầu"**, đừng gói trong ngôn từ mềm.

Mục tranh chấp là thứ **người cần xem trước nhất** — hai lượt đọc độc lập mà kết luận khác nhau nghĩa
là chỗ đó thật sự mơ hồ. Nêu lên đầu, đừng chôn ở cuối bảng.

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
`review-<slug>.md` (`> Review: PENDING`) — verdict từng yêu cầu đã đối chiếu với peer review, mục
tranh chấp nêu riêng, mục peer phát hiện thêm ghi rõ nguồn — cộng `open-questions.md` cho nghi vấn về
yêu cầu. Không sửa code.
