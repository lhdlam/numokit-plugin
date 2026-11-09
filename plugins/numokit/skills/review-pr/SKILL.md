---
name: review-pr
description: Review a pull request from its link — treat the PR's own description as the stated requirement, check it against the actual diff and the spec, and draft a SHORT bilingual (English/Japanese) review comment where every point cites file:line or a line of the PR description. Never posts without explicit approval. Use via /numokit:review-pr <PR URL>.
license: MIT
---

# Review-PR — nhận xét pull request từ link

Mục tiêu: nhận **một link PR** → đối chiếu **điều PR tự nói nó làm** với **điều diff thực sự làm** và
với **spec** → soạn **một comment ngắn, song ngữ Anh/Nhật, có dẫn chứng**.

> ## ĐỐI TƯỢNG ĐỌC LÀ KHÁCH HÀNG
> Comment này user sẽ **gửi cho khách** qua PR, không phải ghi chú nội bộ giữa dev với nhau.
> Mọi quyết định về giọng văn và nội dung đều xuất phát từ điều đó:
> - **Giọng chuyên nghiệp, trung lập.** Nêu sự việc kèm bằng chứng; KHÔNG phê bình con người,
>   KHÔNG mỉa mai, KHÔNG dùng tiếng lóng nội bộ ("code bẩn", "làm ẩu", "nit").
> - **Lọc nội dung.** Chỉ đưa vào comment thứ **ảnh hưởng tới bàn giao** cho khách. Lỗi style nội bộ
>   (thiếu comment, lint, đặt tên biến) **KHÔNG gửi khách** — tách riêng, báo user ở Bước 5.
> - Chỗ chưa chắc → **đặt câu hỏi lịch sự**, không phán. Với khách, một lời khẳng định sai còn tốn kém
>   hơn một câu hỏi thừa.

> **CHỈ ĐỌC. KHÔNG sửa code. KHÔNG tự đăng comment** — xem luật #5.

## Hai điều khác với `/numokit:review`

| | `/numokit:review` | `/numokit:review-pr` |
|---|---|---|
| Nguồn yêu cầu | `plan-*.md` đã duyệt / tài liệu | **chính mô tả của PR** (+ issue liên kết, + spec để đối chiếu) |
| Đầu ra | `review-<slug>.md` dài, verdict từng yêu cầu | **comment NGẮN**, song ngữ **en/jp**, dán được lên PR |

## Ngôn ngữ — đọc kỹ, đây là ngoại lệ

- **Nội dung comment: luôn song ngữ ENGLISH + 日本語.** KHÔNG dùng `lang` (vi/en) cho phần này.
- **Giao tiếp với user** (tóm tắt, hỏi lại): theo `lang` như bình thường (mặc định `vi`).
- Trong comment: code, tên hàm, `file:line`, tên nhánh giữ nguyên — không dịch.
- Tiếng Nhật dùng **です・ます**, register **thương mại với khách hàng** (ビジネス敬体) — không phải
  giọng review giữa đồng nghiệp. Dùng `ご確認ください` / `〜と存じます` / `〜のほど、よろしくお願いいたします`
  ở chỗ tự nhiên. Không dùng thể ngắn (だ・である), không mệnh lệnh trống (`直して`).
- Nêu vấn đề theo lối **giảm nhẹ (クッション言葉)**: `恐れ入りますが`, `念のため`, `〜のように見受けられます`.
  Khẳng định trần trụi dễ bị đọc là trách cứ.
- Không chắc cách diễn đạt tiếng Nhật cho một ý kỹ thuật → **giữ thuật ngữ tiếng Anh trong câu Nhật**
  (vd `breaking change`), đừng dịch ép thành từ lạ.
- Tiếng Anh cũng theo lối tương ứng: `It looks like…`, `Could you confirm…` thay vì `This is wrong`.

## Luật cứng

1. **KHÔNG bịa.** Mỗi nhận xét phải trỏ được tới **`file:line` trong diff** hoặc **một câu trong mô tả
   PR**. Không chỉ được bằng chứng → bỏ nhận xét đó, hoặc hạ thành **câu hỏi**.
2. **NGẮN.** Mục tiêu: người review đọc hết trong **dưới một phút**. Giới hạn: **tối đa 7 mục**
   (thấy nhiều hơn → giữ 7 cái nặng nhất, ghi "và N mục nhỏ khác"). Mỗi mục **1–2 câu**.
   Comment dài là comment không ai đọc.
3. **KHÔNG nới yêu cầu cho khớp code.** PR nói làm X mà code làm khác → ghi đúng là lệch, không diễn
   giải lại lời PR cho vừa code.
4. **Phân biệt THỰC TẾ và Ý KIẾN.** Dẫn chứng được = phát hiện. Không dẫn chứng được = **câu hỏi**,
   diễn đạt như câu hỏi, không như lời phán.
5. **KHÔNG tự đăng.** Soạn xong thì **trình cho user duyệt**. Chỉ đăng khi user nói rõ "đăng đi".
   Đăng là hành vi công khai, không thể rút lại sạch.

## Bước 0 — Lấy PR

Arg = **URL PR** (hoặc `owner/repo#số`). Không có arg → hỏi, đừng đoán.

```
gh pr view <url> --json title,body,author,headRefName,baseRefName,files,additions,deletions,state
gh pr diff <url>
```

`gh` lỗi (PR private không có quyền / repo không tồn tại) → **báo thẳng và DỪNG**, đừng review chay.
PR quá lớn (vd > 2000 dòng đổi) → nói rõ sẽ tập trung vào file cốt lõi nào và vì sao.

Issue liên kết trong mô tả (`Closes #12`) → đọc thêm `gh issue view` để lấy yêu cầu gốc.

## Bước 1 — Trích "PR tự nói nó làm gì"

Từ **title + body** (và issue liên kết), liệt kê từng điều PR **tuyên bố**. Giữ nguyên câu chữ gốc để
còn trích dẫn. Mô tả PR trống/sơ sài → đó **tự nó đã là một phát hiện** (không review được tuyên bố
nào cả), nêu ở comment.

## Bước 2 — Đọc diff thật

Đọc `gh pr diff`. Ghi nhận hành vi thực sự thêm/đổi/bỏ, kèm `file:line`.

## Bước 3 — Đối chiếu 3 chiều

| Kiểm | Câu hỏi | Nếu lệch |
|---|---|---|
| **Tuyên bố ↔ Diff** | PR nói làm X, code có làm X không? | **Claim không khớp** |
| **Diff ↔ Tuyên bố** | code làm gì mà mô tả KHÔNG nhắc tới? | **Thay đổi không khai báo** — rất đáng nêu |
| **Diff ↔ Spec** | có trái tài liệu không? | **Lệch spec** — kèm `[SRS §x]` |

Soát thêm trên diff, chỉ nêu khi **có dẫn chứng** — và **phân luồng theo người đọc**:

**→ ĐƯA VÀO COMMENT GỬI KHÁCH** (ảnh hưởng tới bàn giao):
- phá vỡ tương thích (API/kiểu trả về/schema) mà mô tả không nhắc
- nhánh lỗi bị bỏ qua (chỉ có happy path) ở luồng nghiệp vụ khách quan tâm
- thay đổi không khai báo, lệch spec
- thay đổi không có test đi kèm

**→ GIỮ NỘI BỘ, KHÔNG gửi khách** (báo user riêng ở Bước 5):
- vi phạm chuẩn code sạch (luật #7–#12): comment sót, `noqa`/`@ts-ignore`, mã định danh tự đặt
- đặt tên, bố cục, trùng lặp nhỏ, gu cá nhân

Ranh giới: **khách quan tâm sản phẩm chạy đúng và bàn giao được**, không quan tâm style nội bộ.
Không chắc một mục thuộc luồng nào → **để nội bộ** và hỏi user.

## Bước 4 — Soạn comment (song ngữ, ngắn)

Khuôn mẫu — giữ đúng thứ tự, bỏ mục nào rỗng:

```markdown
**Summary** — <một câu: PR này làm gì, có khớp mô tả không>

**Points to confirm**
- `path/to/file.ts:88` — It looks like <sự việc>. Could you confirm <điều cần xác nhận>?
- `path/to/other.py:12` — <sự việc, 1 câu, trung lập>

**Questions**
- <câu hỏi khi không đủ bằng chứng để khẳng định>

---

**概要** — <một câu, tương ứng phần Summary>

**ご確認いただきたい点**
- `path/to/file.ts:88` — <sự việc>のように見受けられます。<điều cần xác nhận>をご確認いただけますでしょうか。
- `path/to/other.py:12` — <sự việc, 1 câu>

**ご質問**
- <câu hỏi>
```

Quy tắc trình bày:
- Phần Nhật là **bản dịch tương ứng**, không phải nội dung khác. Số mục hai bên phải **bằng nhau**.
- Không có phát hiện nào → nói thẳng là khớp mô tả, kèm **một câu nêu đã kiểm những gì** (để người đọc
  biết phạm vi đã soát, không tưởng là liếc qua).
- KHÔNG thêm dấu ngày, tên khách, lời chào, emoji trang trí.
- KHÔNG chèn chữ ký hay dòng "generated by".

## Bước 5 — Trình user duyệt (BẮT BUỘC — không tự đăng)

Hiện **hai phần tách bạch**:

1. **Nguyên văn comment gửi khách** (song ngữ en/jp) — để user đọc lại trước khi gửi.
2. **Ghi chú nội bộ** (theo `lang`, KHÔNG nằm trong comment): lỗi style/chuẩn code sạch, các mục
   **đã bỏ qua vì không đủ bằng chứng**, và mục nào đang phân vân giữa gửi/không gửi.

Nhắc user: đây là nội dung **gửi cho khách** — đọc kỹ giọng văn trước khi đồng ý.

Rồi hỏi rõ: **đăng lên PR, hay để user tự dán?**
- User nói đăng → `gh pr comment <url> --body-file <file>`
- User chưa trả lời → **KHÔNG đăng**. Im lặng không phải là đồng ý.

## Bước 6 — Lưu bản nháp

`${NUMOKIT_ROOT:-docs/numokit}/pr-review-<owner>-<repo>-<số>.md`: nguyên văn comment + danh sách bằng
chứng (`file:line` ↔ câu trong mô tả PR) + ghi chú đã đăng hay chưa.
Kết thúc bằng `> Review: PENDING`.

## Đầu ra
Comment song ngữ en/jp đã soạn (chưa đăng trừ khi user bảo đăng) + bản nháp lưu lại.
Không sửa code, không sửa PR.
