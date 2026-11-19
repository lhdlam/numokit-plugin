---
name: plan-change
description: Analyse ONE incoming dev task (feature, change request, bug batch), measure its blast radius across modules/APIs/schema/shared code/tests/docs, cross-check it against the spec and raise any deviation, then have an independent plan-reviewer subagent audit the finished plan — verifying every citation against real source, hunting missed impact, and resolving the open questions that are in fact already answered in the sources — before a human approves it and any code is written. Use via /numokit:plan <mô tả task | nhánh/tag git>.
license: MIT
---

# Plan — phân tích task & lập kế hoạch trước khi code

Mục tiêu: **hiểu task → đo ảnh hưởng → đối chiếu spec → trình kế hoạch cho người duyệt**, trước khi
viết dòng code nào. Đây là cổng chặn sớm nhất: bắt sai phạm vi, lệch spec và rủi ro lan rộng *trước khi*
tốn công hiện thực.

> **Pha này CHỈ ĐỌC. KHÔNG sửa code, KHÔNG tạo file nguồn.** Chỉ đọc, đo, hỏi và viết `plan-<slug>.md`.
> **Ngôn ngữ:** plan + giao tiếp theo `lang`. Xem luật #1–#13 trong `using-numokit`.

## Luật cứng

1. **KHÔNG bịa.** Mọi khẳng định kèm **trích dẫn nguồn thật** (`SRS §4.2`, `app/auth.ts:31`).
   Không định vị được → ghi vào "Câu hỏi cần trả lời", đừng đoán.
2. **KHÔNG tự đặt mã định danh.** Gọi mọi thứ bằng tiêu đề mô tả.
3. **Lệch spec thì RAISE, không tự quyết** → `open-questions.md`.
4. **Đo ảnh hưởng trung thực.** Không hạ mức rủi ro cho kế hoạch đẹp. Không chắc → ghi "cần xác minh".
5. **Dừng ở plan.** Viết xong `> Review: PENDING` là DỪNG. Không tự chạy sang hiện thực.
6. **Peer review bắt buộc** (Bước 5). Plan do chính agent phân tích task viết ra, nên nó mang đúng điểm
   mù của agent đó: ảnh hưởng không nghĩ tới cũng là ảnh hưởng không biết là mình đã sót, và câu hỏi
   mình không trả lời được thì trông như câu không ai trả lời được.
7. **Câu hỏi nào có đáp án trong nguồn thì KHÔNG được hỏi người.** Mỗi câu hỏi phải có trạng thái
   (Bước 5). Hỏi một điều mà đáp án nằm ngay trong tài liệu là lãng phí thời gian người duyệt — và làm
   họ mất tin vào những câu hỏi còn lại.

## Bước 0 — Đầu vào & định phạm vi

Arg là **mô tả task** (tự do) HOẶC **nhánh/tag git** đã có code. Không có arg → hỏi lại.
- Đặt `slug` kebab ngắn từ tiêu đề task (vd `them-export-csv`).
- **Cách A — git diff**: `git diff --name-only <nhánh-chính>...<nhánh>`. Chắc chắn nhất.
- **Cách B — mô tả**: từ mô tả định vị module/file/tài liệu liên quan. Có graph (luật #13) →
  `search_graph` theo từ khoá trong mô tả. Không định vị được → HỎI, đừng đoán.

## Bước 1 — Phân tích task (đọc tối thiểu, KHÔNG quét cả repo)

Trả lời 3 câu, mỗi câu kèm nguồn:
- **Task yêu cầu gì?** (hành vi mong muốn, ràng buộc, tiêu chí chấp nhận)
- **Tài liệu nói gì về vùng này?** (trích `SRS §x`; không có → ghi rõ "không có nguồn tài liệu")
- **Hiện tại code đang làm gì?** (trích `file:line` — có graph thì `get_code_snippet` để đọc đúng
  symbol thay vì mở cả file; `check_index_coverage` trước khi trích dẫn)

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

Có graph → `trace_path` để lấy caller theo tầng (chính xác hơn grep tên trùng), `get_architecture` cho
vùng dùng chung. **Ranh giới động** (Qt signal/slot, DI, `getattr`, i18n key, route string) graph không
thấy → **grep thêm** và ghi **"cần xác minh"**; kết quả rỗng của graph ở đó không có nghĩa là an toàn.
Mỗi citation ghi `[graph]` hoặc `[grep]` (luật #13).

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

## Câu hỏi
| Câu hỏi | Trạng thái | Đáp án / Đã tìm ở đâu |
|---|---|---|
| <...> | ✅ Đã có đáp án | <đáp án> — [SRS §4.2] |
| <...> | ❓ Cần người trả lời | đã tìm: SRS §3–§5, app/auth.ts |

Cần người trả lời: N câu    (0 → ghi "không còn câu hỏi nào chờ người")

## Peer review
Trích dẫn: X khớp / Y sai / **Z bịa**
Ảnh hưởng peer phát hiện thêm: ...
Câu hỏi peer trả lời giúp: ...
(không chạy được → `Peer review: KHÔNG chạy` + lý do)

> Review: PENDING
```

KHÔNG thêm dấu ngày, tên khách, số hợp đồng hay ghi chú quyết định của khách.

## Bước 5 — Peer review bản plan (bắt buộc)

Mở agent `numokit:plan-reviewer` (Agent tool), truyền: **đường dẫn bản plan vừa viết**, phạm vi code,
và đường dẫn tài liệu yêu cầu.

> **Khác peer review của `/numokit:review`.** Ở đó agent thứ hai **không được thấy** verdict của lượt
> đầu, nên nó độc lập thật. Ở đây **đối tượng review chính là bản plan** — không thể giấu. Nguy cơ vì
> vậy đổi chiều: không phải bị mồi bằng kết luận, mà **bị bản plan thuyết phục**. Một plan viết mạch
> lạc, trích dẫn đầy đủ, rất dễ được đọc thành "đúng rồi".
>
> Đó là lý do `plan-reviewer` bị buộc **tự mở từng nguồn** trước khi kết luận bất cứ điều gì là đúng,
> và **tự đo blast radius trước** khi xem bảng của plan.

Nền không có Agent tool (Cursor…) → **không chạy được** peer review. Nói rõ với user, ghi vào plan
`Peer review: KHÔNG chạy` kèm lý do. **Cấm tự đóng cả hai vai** — tự đọc lại plan của mình hai lần vẫn
là cùng một điểm mù.

### Thu kết quả và xử lý

| Peer báo | Xử lý |
|---|---|
| **Trích dẫn bịa** (`fabricated`) | **nặng nhất** — xoá khẳng định đó khỏi plan hoặc tìm lại nguồn thật. Không được giữ |
| **Trích dẫn sai** (`mismatched`) | sửa lại theo nguồn thật, hoặc hạ thành "cần xác minh" |
| **Ảnh hưởng bỏ sót** | **nhập vào bảng Bước 2**, ghi rõ do peer phát hiện |
| **Hạ mức rủi ro** | nâng lên theo bằng chứng của peer (luật #4: không hạ mức cho plan đẹp) |
| **Câu hỏi đã có đáp án** | **ghi đáp án + nguồn vào plan, chuyển khỏi danh sách chờ người** |
| **Thiếu câu hỏi** | thêm vào mục "Câu hỏi cần trả lời" |
| **"NGOÀI phạm vi" thực ra bắt buộc** | đưa lại vào phạm vi, hoặc nêu thành câu hỏi cho người quyết |
| **Bước phụ thuộc câu hỏi chưa có đáp án** | plan **chưa chốt được phạm vi** — ghi rõ "chờ phân xử" |

**KHÔNG tự phân xử khi hai bên lệch nhau** về mức rủi ro hay về một lệch spec: lấy phía **thận trọng
hơn**, ghi rõ hai bên nói gì, đẩy lên người.

> **Peer không tìm ra lỗi KHÔNG chứng minh plan đúng.** Nó chỉ hạ rủi ro. Đừng diễn giải thành bảo đảm.

## Bước 6 — Soát lại câu hỏi (mỗi câu một trạng thái)

Sau khi nhập kết quả peer, **mọi** câu hỏi trong plan phải mang một trạng thái:

| Trạng thái | Nghĩa |
|---|---|
| ✅ **Đã có đáp án** | trả lời được từ nguồn — ghi **đáp án + trích dẫn**, người duyệt không phải trả lời |
| ❓ **Cần người trả lời** | thật sự không có nguồn — ghi **đã tìm ở đâu** |
| ⚠ **Hỏi lại cho rõ** | câu hỏi mơ hồ/hỏi nhầm chỗ — viết lại trước khi đưa người |

Còn câu nào ở trạng thái ❓ hoặc ⚠ → nêu bật ở Bước 7, và **plan không nên được đánh `APPROVED`** khi
một bước hiện thực phụ thuộc trực tiếp vào câu đó.

## Bước 7 — Dừng & bàn giao

Tóm tắt: phạm vi, **các mục ảnh hưởng mức Cao**, số lệch spec đã raise, và **trạng thái câu hỏi**
(bao nhiêu đã có đáp án / bao nhiêu còn cần người).

Nêu riêng kết quả peer review: trích dẫn bịa/sai, ảnh hưởng bỏ sót, câu hỏi peer đã trả lời giúp.
**Trích dẫn bịa phải nói thẳng**, đừng gói trong ngôn từ mềm.

Nhắc người duyệt plan (`PENDING` → `APPROVED`) rồi mới hiện thực.

Sau khi APPROVED, bước kế theo loại task:
- Sửa bug → `/numokit:fixbug`
- Dọn/tái cấu trúc → `/numokit:refactor`
- Tính năng mới → hiện thực theo "Các bước đề xuất"

## Gate
Trên Claude Code, `hooks/pre-tool-gate.sh` **chặn `fixbug` và `refactor` khi còn `plan-*.md` PENDING**
— đã lập plan thì phải duyệt trước khi sửa code. Chưa lập plan nào thì không chặn (tương thích ngược).

## Đầu ra
`plan-<slug>.md` (`> Review: PENDING`) — đã qua peer review, mỗi câu hỏi mang một trạng thái, trích dẫn
đã được kiểm từ nguồn thật — cộng `open-questions.md` cập nhật nếu phát hiện lệch spec.
