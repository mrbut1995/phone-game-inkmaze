# AI AGENT — TẠO MÀN CHƠI (LEVEL MAKER) CHO INKMAZE  (bản có Ô KHOÁ + CHÌA)

> File instruction gốc bạn gửi bị TRỐNG (0 byte) nên đây là bản viết lại từ đầu, dựa trên code thật:
> `LevelData.gd`, `MazeData.gd` (add_lock / add_key / get_play_path), `tools/level_designer`.

## 1. Việc của agent
Tạo/sửa file `res://data/levels/<nhóm>/level_<id>.tres` (kiểu `LevelData`) rồi xếp vào danh sách `levels`
của event (`res://data/events/<event>.tres`). Event chơi LIÊN TỤC theo đúng thứ tự mảng `levels` — không chọn màn.
Cách nhanh nhất: sửa bảng `EVENTS` trong `tools/level_designer/make_event_levels.py` rồi chạy
`python make_event_levels.py` (seed cố định ⇒ chạy lại ra đúng màn cũ; `--only tomb` chỉ làm 1 event; `--dry-run` chỉ in).

## 2. Hệ toạ độ & tường (PHẢI đúng, sai là màn hỏng)
- Ô (x, y): x sang phải, y xuống dưới, gốc (0,0) góc trên-trái. `width` × `height` ≥ 2.
- `v_walls` (tường DỌC): kích thước (width+1)·height, index = `ix*height + iy`. Tường dọc `(ix, iy)` nằm bên TRÁI ô (ix, iy).
- `h_walls` (tường NGANG): kích thước width·(height+1), index = `ix*(height+1) + iy`. Tường ngang `(ix, iy)` nằm PHÍA TRÊN ô (ix, iy).
- Đi từ (x,y) sang phải bị chặn bởi v(x+1,y); sang trái: v(x,y); xuống: h(x,y+1); lên: h(x,y).
- `*_visible` cùng kích thước: 1 = tường nhìn thấy, 0 = tường ẨN (người chơi phải suy ra từ số trên ô — số = số tường quanh ô, tính cả tường ẩn).
- Viền ngoài luôn là tường hiện (game tự ép). `cell_mask` rỗng = lưới chữ nhật đặc.

## 3. Ô KHOÁ + CHÌA (MỚI)
- `lock_cells` / `key_cells` = `PackedInt32Array` các BỘ BA `(x, y, id)` nối tiếp: `(1, 2, 1,  3, 2, 2)` = khoá id1 ở (1,2), khoá id2 ở (3,2).
- Ô khoá: hiện ổ khoá, KHÔNG đi/dịch chuyển vào được cho tới khi nhặt chìa CÙNG id. Chìa: bước vào ô là nhặt, mở MỌI khoá cùng id.
- id trong 1..30. Một id có thể có nhiều khoá và/hoặc nhiều chìa.
- Cấm: khoá trên S hoặc F · chìa trên S · 1 ô vừa khoá vừa chìa · ô ngoài `cell_mask`.
- Mỗi id khoá phải có ≥ 1 chìa TỚI ĐƯỢC mà không cần đi qua chính khoá đó (chìa nằm trong vùng S tới được khi khoá còn đóng).
- Thiết kế hay: khoá nằm TRÊN đường S→F (chắn lối), chìa nằm ở NHÁNH CỤT lệch khỏi đường ⇒ người chơi phải đi vòng lấy chìa rồi quay lại. Với 2 khoá: khoá 1 ở nửa đầu đường, khoá 2 ở nửa sau; chìa 2 đặt ở vùng chỉ tới được SAU khi mở khoá 1 là tăng độ khó.
- Số bước tối thiểu PHẢI tính theo BFS trạng thái (ô, tập chìa) — KHÔNG dùng BFS thường:
  `validator.min_steps_with_keys(level)` (tools) hoặc `MazeData.get_play_path()` (game). `max_steps = min_steps + dự phòng`.
- Ô khoá/chìa nhìn thấy trong game nên không cần tường ẩn để lộ chúng; tường ẩn vẫn dùng bình thường.

## 4. Quy trình bắt buộc cho MỖI màn
1. Chọn `width/height/start_pos/end_pos`; dựng tường sao cho có đường S→F (khuyến nghị mê cung hoàn hảo: 1 đường duy nhất, sinh bằng DFS).
2. Chọn tỉ lệ tường ẩn theo độ khó; đặt khoá/chìa (mục 3).
3. Tính `min_steps` (có khoá) → `max_steps = min_steps + 2..4` (easy +4 · medium +3 · hard +2). `par_time ≈ min_steps*3 + 12`.
4. Chạy validator: KHÔNG được có lỗi (bỏ qua duy nhất lỗi "level_id 1..999" vì id event ≥ 1000 là chủ đích).
5. Nạp lại file bằng `tres_io.load_file` và kiểm tra lại giải được (round-trip).
6. Cập nhật mảng `levels` của event đúng thứ tự dễ → khó; số màn = số tầng hiển thị ("TẦNG n/N").

## 5. Quy ước event
- id màn: mỗi event 1 dải riêng: halloween 1000 · mansion 1100 · tomb 1200 · april 1300 · winter 1400 · anniversary 1500 · autumn 1600 · easter 1700 · new_year 1800 · spring 1900 · summer 2000 · thanksgiving 2100 · valentine 2200 (+i theo thứ tự). `chapter = 0`, `mode_id = "play"`.
- Độ khó tăng dần: 1/3 đầu `easy` (3×3, không khoá) → giữa `medium` (4×3–4×4, 1 khoá) → cuối `hard` (4×4–6×5, 1–2 khoá, nhiều tường ẩn).
- `level_title`: "<Tên event> · <số thứ tự>". Để trống `mission_*` (game dùng 3 nhiệm vụ mặc định).
- Không dùng chế độ Special/Challenge trong event chuỗi trừ khi được yêu cầu (HUD vẫn theo chế độ của màn).

## 6. Không được làm
- Không sửa script/scene; không đổi `level_id` của màn đã phát hành (tiến độ người chơi lưu theo id).
- Không đặt khoá/chìa trên S/F sai luật; không để id khoá thiếu chìa; không để `max_steps` < số bước tối thiểu có khoá.
