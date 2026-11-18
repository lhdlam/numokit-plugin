---
name: impact
description: Measure the blast radius of a code change already made or proposed — which modules, public APIs, schema, shared code, tests and docs it reaches, each rated with a real citation. Read-only; produces impact-<slug>.md. Use via /numokit:impact <mô tả thay đổi | nhánh/tag git | file>.
license: MIT
---

# Impact — đo blast radius của một thay đổi code

Mục tiêu: trả lời chính xác câu **"sửa chỗ này thì vỡ chỗ nào?"** — bằng bằng chứng truy vết được,
không phải cảm giác.

> **CHỈ ĐỌC.** Không sửa code, không chạy lệnh có tác dụng phụ.
> Khác `/numokit:plan`: plan đi từ **một task chưa làm** và lên kế hoạch; impact đi từ **một thay đổi
> cụ thể** (đã có diff, hoặc đề xuất) và chỉ đo lan toả. Cần cả hai thì chạy `plan` là đủ.

## Bước 0 — Đầu vào

Arg là một trong:
- **nhánh/tag git** → `git diff --name-only <nhánh-chính>...<ref>` (chắc chắn nhất)
- **đường dẫn file/hàm** → đo từ chính nó
- **mô tả thay đổi dự định** → định vị code liên quan; không định vị được → HỎI, đừng đoán

Không có arg → mặc định lấy `git diff` của working tree; không có thay đổi nào → hỏi lại.
Đặt `slug` kebab ngắn cho tên file artifact.

## Bước 1 — Dựng tập hạt giống (seed)

Liệt kê **symbol** thực sự bị đổi: hàm, class, hằng, endpoint, cột DB — kèm `file:line`.
Chỉ lấy cái **đổi hành vi**; đổi định dạng/thụt lề thì bỏ qua và nói rõ đã bỏ.

Có graph (luật #13) → `search_graph` để định vị từng symbol, rồi `check_index_coverage` cho các path
sắp trích dẫn. Chưa phủ hoặc không có graph → grep như thường.

## Bước 2 — Lan toả ngược (ai gọi tôi?)

Đây là bước graph giúp nhiều nhất: grep chỉ thấy **tên trùng**, `trace_path` đi theo **quan hệ gọi thật**.

Có graph → với mỗi symbol hạt giống, `trace_path` để lấy caller theo **từng tầng**.
Không có graph, hoặc path chưa phủ index → grep/glob trên toàn repo, cũng theo từng tầng.

- Tầng 1: gọi trực tiếp
- Tầng 2: gọi gián tiếp qua tầng 1 (chỉ đi tiếp khi tầng 1 đổi hành vi theo)

Dừng khi hết lan hoặc khi đã rõ biên. **Nêu rõ đã dừng ở tầng mấy và vì sao** — đừng ngầm cắt.

Lan toả qua **ranh giới động** (Qt signal/slot, DI, reflection, event bus, `getattr`/chuỗi tên hàm,
i18n key, route string) **dễ sót** → đánh dấu **"cần xác minh"**, đừng khẳng định là an toàn.

> **Graph KHÔNG thấy ranh giới động** — nó trả về rỗng, và cái rỗng đó trông y như "không ai gọi".
> Vì vậy ở các vùng này **vẫn phải grep thêm**, dù graph đã trả lời. Tin một kết quả rỗng của graph tại
> ranh giới động là cách bỏ sót nguy hiểm nhất của bước này.

Mỗi dòng lan toả ghi nguồn bằng chứng: `[graph]` hoặc `[grep]` (luật #13).

## Bước 3 — Bảng ảnh hưởng 6 hạng mục

```
| Hạng mục | Cái gì bị ảnh hưởng | Mức | Vì sao / Nguồn |
```

| Hạng mục | Soát cái gì |
|---|---|
| **Module / file** | file, class, hàm chịu tác động |
| **API / hợp đồng công khai** | endpoint, signature, kiểu trả về, sự kiện — **có phá vỡ tương thích không?** |
| **Schema / dữ liệu** | bảng, cột, index, migration, dữ liệu sẵn có |
| **Vùng dùng chung** | hàm/component/middleware dùng nhiều nơi — `get_architecture` cho cái nhìn tổng quan module nếu có graph |
| **Test hiện có** | test nhiều khả năng đỏ (file + tên test) |
| **Tài liệu / spec** | mục tài liệu nay sai so với code |

Mức: **Cao** (phá vỡ tương thích / luồng critical / đụng dữ liệu thật) · **Trung bình** (phải sửa theo) ·
**Thấp** (gián tiếp). Thiếu dữ kiện → **"cần xác minh"** kèm cách xác minh.
**KHÔNG hạ mức để báo cáo đẹp.**

## Bước 4 — Kết luận

Nêu thẳng:
- **Phá vỡ tương thích?** có/không + ở đâu
- **Cần migration dữ liệu?** có/không
- **Điểm rủi ro cao nhất** và cách kiểm chứng nó
- **Vùng không chắc** (lan toả động) cần người xác nhận

## Bước 5 — Sinh `impact-<slug>.md`

Trong `${NUMOKIT_ROOT:-docs/numokit}/`:

```
# Impact: <tiêu đề thay đổi>

## Thay đổi được đo       (symbol + file:line)
## Lan toả                (tầng 1 / tầng 2; nêu rõ dừng ở đâu, vì sao)
## Bảng ảnh hưởng         (6 hạng mục)
## Kết luận               (phá vỡ tương thích · migration · rủi ro cao nhất · vùng cần xác minh)
> Review: PENDING
```

Mỗi citation mang hậu tố `[graph]` hoặc `[grep]`. Ghi ở đầu báo cáo đã dùng graph hay không:
`Nguồn định vị: codebase-memory graph` / `Nguồn định vị: grep (không có graph trong phiên)`.

KHÔNG thêm dấu ngày, tên khách hay ghi chú quyết định của khách.

## Đầu ra
`impact-<slug>.md` (`> Review: PENDING`). Không sửa code. Muốn sửa → `/numokit:fixbug` hoặc
`/numokit:refactor` (cả hai đều có human gate riêng).
