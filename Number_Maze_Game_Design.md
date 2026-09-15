# Number Maze — Game Design Document

## 0. Tiêu chuẩn tài liệu (Design Template)

| | |
|---|---|
| **Tài liệu** | Number Maze — Game Design Document (InkMaze) |
| **Phiên bản** | v2.0 — 2026-11 (chuẩn hoá template đặc tả mode + bổ sung bộ mockup matchup cho 9 chế độ) |
| **Trạng thái** | Đang phát triển · build Godot 4.7 · màn hình dọc 1080×1920 |
| **Nguồn sự thật** | **Code là nguồn sự thật cuối cùng**: `scripts/modes/*.gd` · `nodes/hud/*.tscn` · `scenes/game.tscn` · `resources/levels/*.tres`. Tài liệu này mô tả đúng theo code tại thời điểm cập nhật. |
| **Quy ước mode** | 1 bộ luật = 1 `class_name` kế thừa `BaseGameMode`; mỗi mode có `mode_id` (khoá xoay vòng Daily + tra chuỗi `STR_MODE_<ID>`), luật riêng, và **1 mockup matchup** ở mục 10 |

**Template đặc tả mỗi bộ luật (mục 5.1–5.9)** — mọi mode dùng CÙNG bộ 9 trường sau, để đọc/đối chiếu nhanh giữa các mode:

| Trường | Ý nghĩa |
|---|---|
| **Cổng vào** | Màn hình/mục mở được mode · `mode_id` · file mode |
| **Bàn cờ** | Cách sinh bàn: kích thước, tường, ràng buộc bảo đảm màn **luôn thắng được** |
| **Số trên ô** | Con số trên ô nghĩa là gì (tường · mìn · điểm · chi phí · mực · không có số) |
| **Di chuyển** | Số hướng đi · chi phí bước · giới hạn bước/thời gian · công cụ (UNDO/GỢI Ý) |
| **Thắng** | Điều kiện qua màn + thưởng/xếp hạng |
| **Thua** | Điều kiện thua + hành vi khi đâm tường/đạp mìn |
| **Hồi sinh** | Hồi sinh thay đổi những gì (undo bước · +bước · giữ nguyên màn) |
| **HUD** | Scene HUD thật + các thẻ hiển thị + file mockup matchup |
| **Chi tiết** | Diễn giải đầy đủ luật + ghi chú thiết kế/edge case |

**Quy ước màu & chất liệu UI (áp dụng mọi màn hình):** nền giấy kem `#FAF5EB` + lưới vở ô ly 40px `#8FB9D2` + lề đỏ `#D84444`; thẻ HUD là **mẩu giấy trắng** `#FEFDFA` viền xanh `#6EA0C8` / xanh đậm `#3D83AE` / đỏ `#D84444` + **lề sổ tay** cùng màu + **dòng kẻ ngang** `#9FC0D6`; mực chữ `#224C6D`, nhãn phụ `#718B9E`. **Không dùng emoji trong UI thật** — icon là SVG vẽ tay trong `assets/images/icons/`.

## 1. Tổng quan

**Tên game:** Number Maze
**Thể loại:** Puzzle / Logic, chơi trên di động
**Ý tưởng cốt lõi:** Kết hợp lối suy luận kiểu Minesweeper (dùng số để đoán vị trí "tường vô hình") với việc vẽ đường đi trong mê cung, dưới áp lực số bước di chuyển hoặc thời gian có hạn.

Game có **9 bộ luật chơi** dùng chung 1 bộ khung Grid / S-F / vẽ đường (mục 2–3), nhưng được tổ chức lại thành **3 cổng vào chính** trên Main Screen thay vì 9 mục ngang hàng — xem mục 4.

Phần thưởng **Sao (Star)** của **mọi match-up** nay do **3 Thử thách (Challenge)** quyết định: hoàn thành 1 Thử thách = 1 Sao (tối đa 3 Sao), **KHÔNG còn tính theo thời gian còn lại** — xem mục 3.1.

---

## 2. Cấu trúc bàn chơi (Grid)

- Grid kích thước linh hoạt từ **2x2, 3x3, 4x4, 5x5** hoặc lớn hơn tùy chế độ / độ khó.
- **Board có thể KHÔNG phải hình chữ nhật**: mỗi màn có thêm `cell_mask` đánh dấu **ô nào thuộc board**,
  nên board có thể là **hình bất kỳ (polyomino)** — ví dụ chữ H, thập tự, vòng có lỗ, chữ U…
  Ô không thuộc board coi như “ngoài board”: không có ô để bước vào, không hiện số, và **viền bao quanh
  board luôn là tường nhìn thấy được**.
- Mỗi ô (cell) có:
  - 4 điểm neo (dot / anchor) ở 4 góc, dùng để kéo nối đánh dấu tường giữa các khe (Tường Nghi Ngờ).
    Góc nào không dính ô nào thuộc board thì không có neo.
  - Con số ở giữa ô (ý nghĩa con số **thay đổi tùy theo chế độ chơi** — xem mục 5).
- Ở các chế độ dùng số làm "tường vô hình" (Dungeon Mode, Play Mode, Fog of War), con số biểu thị **số lượng cạnh GIỮA 2 Ô THUỘC BOARD của ô đó là tường vô hình (0 đến 4)** — cạnh bao quanh board (viền ngoài hoặc giáp ô trống) không tính vào ô; số này không hiển thị mặc định — người chơi phải suy luận để biết cạnh nào là tường thật.
- Riêng **Countdown Cost** con số **không liên quan tới tường**: nó là **chi phí bước** của ô (xem mục 5).

---

## 3. Mục tiêu & Luật chơi cơ bản (áp dụng mọi chế độ)

- Có 1 điểm bắt đầu **S** và 1 điểm kết thúc **F** trên grid.
- Người chơi vẽ đường đi bằng cách kéo nối tâm các ô liền kề (lên/xuống/trái/phải), tạo thành một đường liên tục từ S đến F.
- Người chơi có thể kéo nối (drag) giữa các điểm neo (anchor) kề nhau để tự vẽ ra "tường nghi ngờ" nhằm hỗ trợ hình dung — thao tác này **không bắt buộc đúng/sai**, chỉ là công cụ hỗ trợ suy luận cá nhân.

### 3.1. Hệ thống Thử thách & Sao (áp dụng MỌI chế độ)

- Mỗi match-up — mỗi **Màn** (Play Mode), mỗi **Tầng** (Dungeon Mode), mỗi **ngày** (Daily Challenge) — gắn **TỐI ĐA 3 Challenge (thử thách)**.
- **Hoàn thành 1 Challenge ⇒ được thưởng 1 Sao.** Tối đa **3 Sao / match-up** (màn chỉ chọn 2 challenge thì tối đa 2 Sao).
- ❗ **Thay đổi so với bản thiết kế cũ:** Sao **KHÔNG** còn được tính theo **thời gian còn lại**; nay **Sao = số Challenge đã hoàn thành**.
- Trạng thái các Challenge hiển thị **ngay trên HUD khi đang chơi** (panel "THỬ THÁCH" — xem mockup `matchup_level.svg`) và được **tổng kết ở popup kết quả / popup thua** (xem 5.10).
- **Màn cũ / màn không chọn gì** → game tự dùng 3 thử thách mặc định:
  1. `no_wall` — Không đâm vào tường vô hình
  2. `steps_max` — Đi không quá N bước (N = `max_steps` thiết kế của màn)
  3. `time_max` — Về đích dưới T giây (T = N × 3, kẹp trong 30..240 giây)

**Danh sách 16 loại thử thách** (Level Designer cho chọn tối đa 3; lưu vào `LevelData.challenge_types` + `challenge_params`):

| id | Ý nghĩa | Tham số |
|---|---|---|
| `no_wall` | Không đâm vào tường vô hình | – |
| `steps_max` | Đi không quá N bước | N (bước) |
| `time_max` | Về đích dưới T giây | T (giây) |
| `only_numbered` | Chỉ đi vào ô CÓ số (trừ S/F) | – |
| `avoid_numbered` | Không đi vào ô CÓ số | – |
| `no_revisit` | Không đi lại ô đã đi (không lặp lại đường) | – |
| `visit_all` | Đi qua hết mọi ô của board | – |
| `visit_all_numbered` | Đi qua hết mọi ô CÓ số | – |
| `len_min_percent` | Đi tối thiểu n% số ô của board | n (%) |
| `len_max_percent` | Đi tối đa n% số ô của board | n (%) |
| `sum_lt` · `sum_le` · `sum_gt` · `sum_ge` | Tổng số hiện trên các ô đã đi **<** / **≤** / **>** / **≥** N | N |
| `no_hint` | Không dùng nút Gợi ý lần nào | – |
| `no_undo` | Không dùng nút Hoàn tác lần nào | – |

> Ô **"có số"** = ô mà chế độ chơi đang hiện số (Play/Dungeon/Fog: số tường quanh ô > 0 · Minesweeper: số mìn · Sum Path / Countdown Cost: giá trị riêng). S và F **không** tính là ô có số.
> **Level Designer kiểm tra trước khi lưu:** mâu thuẫn `only_numbered` + `avoid_numbered`, `steps_max` nhỏ hơn đường đi ngắn nhất, `len_max_percent` nhỏ hơn độ dài đường ngắn nhất, `visit_all` khi có ô không tới được, `sum_gt/ge` lớn hơn tổng số tối đa của board… và cảnh báo khi màn không có ô nào hiện số.

---

## 4. Ba cổng vào chính (Main Screen)

Theo mockup `mainscreen.svg` mới nhất, Main Screen chỉ hiện **3 thẻ chế độ lớn**, không liệt kê cả 9 luật chơi ngang hàng:

| Thẻ trên Main Screen | Bộ luật đứng sau | Truy cập |
|---|---|---|
| **PLAY · CHỌN MÀN** | Play Mode (Level Selection) | Luôn mở, chơi tự do theo Chương/Màn |
| **DUNGEON MODE** | Dungeon Mode | Luôn mở, chơi endless không giới hạn |
| **DAILY CHALLENGE** | 7 bộ luật còn lại (luân phiên theo ngày) | Chỉ chơi được đúng bộ luật của ngày hôm đó |

**Nguyên tắc quan trọng:** Chỉ có **Play Mode** và **Dungeon Mode** là 2 chế độ "thường trực" người chơi có thể vào chơi bất cứ lúc nào. **7 bộ luật còn lại** (Time Attack Maze, Minesweeper Maze, **Fading Ink**, Sum Path, Countdown Cost, Blind Memory Maze, Fog of War Maze) **không tồn tại như mục chọn riêng** trên Main Screen — chúng chỉ xuất hiện **lần lượt, mỗi ngày 1 bộ luật**, thông qua màn hình Daily Challenge (mục 6).

### 4.1. Các nút truy cập khác trên Main Screen

| Nút | Vị trí | Nội dung |
|---|---|---|
| **Sổ tay thành tựu** (Badge Book) | **Góc trên phải tờ giấy** | Icon huy chương **lớn 224×224** vẽ theo theme giấy ô ly (sticker dán + băng keo washi + huy chương có ruy băng); **ô giữa huy chương hiện `x/y` danh hiệu đã mở**, nhãn `DANH HIỆU` ngay bên dưới sticker |
| **XẾP HẠNG** | Hàng nút nhỏ (1/3) | Icon cúp vàng — mở **Bảng xếp hạng** (mục 11) |
| **CỬA HÀNG (SHOP)** | Hàng nút nhỏ (2/3) | Icon cửa hiệu — **thay cho nút "LUẬT CHƠI" cũ** (bản mockup `mainscreen.svg` vẽ Luật Chơi; trong game nay là Cửa hàng) |
| **CÀI ĐẶT** | Hàng nút nhỏ (3/3) | Icon bánh răng — mở màn Settings |

- Icon huy chương có **đủ 4 trạng thái nút** (`assets/images/main/btn_menu_badge_{normal,pressed,focus,disabled}.svg`): normal = viền mực xanh đậm · pressed = sticker lún 3px, giấy sậm hơn · focus = viền nét đứt mực cam · disabled = bạc màu (khi chưa mở danh hiệu nào).
- 3 nút nhỏ đều dùng chung khuôn giấy `btn_menu_utility_*` kích thước art **210×110** (node 230×130), xếp giữa hàng, cách nhau 5px — thay cho kích thước 180×146 trước đây (làm art bị co méo).
- Bấm icon huy chương → mở **Sổ tay thành tựu** (mục 8); bấm nút XẾP HẠNG → mở **Bảng xếp hạng** (mục 11); nút CỬA HÀNG chưa có màn hình riêng (mới chỉ chạy hiệu ứng bấm).

---

## 5. Chi tiết từng bộ luật chơi

| Bộ luật | Thuộc cổng | Ý nghĩa con số trên ô | Xử lý khi đâm tường | Điều kiện Thắng / Mục tiêu |
|---|---|---|---|---|
| **Play Mode** | Play · Chọn màn | Số tường quanh ô (0..4) | **Game Over ngay** (hồi sinh: quay lại bước trước đó) | Đến F an toàn, xếp hạng theo thời gian nhanh nhất |
| **Dungeon Mode** | Dungeon | Số tường quanh ô (0..4) | Về lại S, trừ 1 bước | Vượt qua càng nhiều Floor càng tốt (chế độ DUY NHẤT có bộ đếm bước còn lại) |
| Time Attack Maze | Daily Challenge | Số tường quanh ô (0..4) | Về lại S, mất thời gian | Đến F trước khi đồng hồ đếm ngược về 0 |
| Minesweeper Maze | Daily Challenge | Số mìn quanh ô (0..8) | Đạp mìn: **THUA NGAY** (nổ, đứng nguyên tại ô, hiện biểu tượng Bomb, giữ nguyên số) | Tránh các ô mìn ẩn, đến đích F an toàn |
| Fading Ink | Daily Challenge | **MỰC của ô** (giá trị riêng, KHÔNG liên quan tường) — giảm 1 mỗi bước đi | Không có tường; ô hết mực = không đi vào được (không mất bước) | Đến F trước khi mực phai hết; hết lối đi = THUA |
| Sum Path | Daily Challenge | Điểm số của ô (1..9) | Không có tường | Đến F với tổng điểm thỏa `SUM < / > / = Target` |
| Countdown Cost | Daily Challenge | **Chi phí bước** của ô (số riêng, KHÔNG liên quan tường) | Về lại S, trừ theo ô đích | Đến F với ngân sách bước hạn chế, tối ưu chi phí |
| Blind Memory Maze | Daily Challenge | Không có số (ẩn hoàn toàn) | Tùy chọn (về S hoặc thua ngay) | Ghi nhớ tường khi Countdown (3..2..1) rồi đi khi tường ẩn |
| Fog of War Maze | Daily Challenge | Số tường (chỉ hiện ô gần) | Tùy chọn (về S hoặc thua ngay) | Dò đường trong sương mù quanh vị trí nhân vật |
> **Quy ước "Số tường quanh ô":** chỉ tính **4 cạnh bên trong board** (kể cả tường vô hình). **Tường viền bao quanh board KHÔNG tính vào ô** — nếu tính thì mọi ô sát biên đều bị cộng thêm (ô góc +2) và con số mất ý nghĩa. Viền ngoài vẫn **chặn đường đi như cũ**, chỉ không được đếm.
> ⇒ Ô sát biên tối đa 3, ô giữa board tối đa 4, ô trống hoàn toàn = 0 (không hiện số).

> **Quy ước "Số bước":** **CHỈ Dungeon Mode có bộ đếm số bước còn lại** (thẻ **SỐ BƯỚC** + thẻ **TẦNG** trên HUD — xem `matchup_dungeon.svg`). **Mọi chế độ khác KHÔNG giới hạn và KHÔNG hiển thị số bước còn lại** — Play Mode chỉ hiện thẻ **THỬ THÁCH** + **THỜI GIAN** (`matchup_level.svg`), các bộ luật Daily hiện tài nguyên riêng của chúng (đồng hồ, điểm, số mìn...). *Ngoại lệ duy nhất:* **Countdown Cost** vẫn dùng **ngân sách bước**, vì đó chính là cơ chế cốt lõi của bộ luật này (xem 5.3–5.9).

> **Bố cục HUD màn chơi (bộ mockup matchup — xem mục 10):** khung thẻ rộng **980px** (x = 50 → 1030) nằm tại `y = 175..424`; mỗi chế độ có 1 mockup `mockup/matchup_<mode>.svg` vẽ đúng hàng thẻ của mình:
> - **Play Mode** (`matchup_level.svg`): thẻ **THỜI GIAN** 250×138 bên trái + thẻ **THỬ THÁCH** 720×156 bên phải.
>   Thẻ THỬ THÁCH gồm cột tổng kết (**số Thử thách đã đạt** `x/3 ✓` + dòng `n ĐÃ HOÀN THÀNH`) và **3 dải thử thách** 490×42: **ô tích đỏ** = đã đạt (kèm nhãn đỏ `✓ ĐẠT`), **ô chờ tích** (nét đứt) = chưa đạt (kèm tiến độ ở góc phải).
> - **Dungeon Mode** (`matchup_dungeon.svg`): thẻ **THỜI GIAN** 250×138 + thẻ **SỐ BƯỚC** 440×158 (viền đỏ, con số lớn 72px — KHÔNG còn dạng `14/20`) + thẻ **TẦNG** 250×138.
> - **Minesweeper Maze**: thẻ **THỜI GIAN** 250×138 + thẻ **BOM CÒN LẠI** 440×158 — art `card_bomb.svg` (mẩu giấy viền ĐỎ + lề đỏ + dòng kẻ ngang kiểu vở) + **sticker icon_bomb** bên phải, con số `còn/tổng` mực đỏ 72px. Panel MISSION cũ được thay bằng thẻ Bomb.
> - **Sum Path**: thẻ **THỜI GIAN** 250×138 + thẻ **TỔNG HIỆN TẠI** 440×158 (`card_sum.svg` — viền xanh đậm, mực xanh, dòng kẻ ngang) + **thẻ TOÁN TỬ 112×112** (`card_op.svg`, nằm CHÍNH GIỮA thẻ Tổng và thẻ Mục tiêu, đè lên mép 2 thẻ — dạng `12 = 23`, ký hiệu mực ĐỎ) + thẻ **MỤC TIÊU** 250×138 (chỉ hiện con số). Panel MISSION cũ được thay bằng 3 thẻ này.
> - **Blind Memory**: thẻ **THỜI GIAN** 250×138 + thẻ **GHI NHỚ VỊ TRÍ TƯỜNG** 440×158 (`card_sum.svg`) — **KHÔNG có thẻ THỬ THÁCH** (`mockup/matchup_blind_memory.svg`).
> - **4 chế độ dùng chung LevelHUD** — Time Attack (`matchup_time_attack.svg`), Countdown Cost (`matchup_countdown_cost.svg`), Fog of War (`matchup_fog_of_war.svg`), Fading Ink (`matchup_fading_ink.svg`): cùng bố cục **THỜI GIAN + THỬ THÁCH**, mockup khác nhau ở phần bàn cờ minh hoạ + chú thích luật.
> - **Chất liệu HUD (từ 2026-11):** mọi thẻ là **mẩu giấy trắng trên nền vở kẻ ngang** — viền màu (xanh `#6EA0C8` / xanh đậm `#3D83AE` / đỏ `#D84444`) + lề sổ tay cùng màu + **dòng kẻ ngang** `#9FC0D6` (opacity 0.5) như trang vở. Art dùng cho các HUD mới: `card_time_slip.svg` (250×138), `card_bomb.svg` (440×158), `card_sum.svg` (440×158), `card_op.svg` (112×112).
> - Tiêu đề game: Dungeon = `DUNGEON MODE` (một dòng, số tầng đã chuyển xuống thẻ TẦNG); Play Mode = dòng phụ đỏ `PLAY MODE · CHƯƠNG n` + dòng lớn `MÀN xx`.

> **Kiến trúc HUD (tách thành scene theo chế độ):** khung **Information** trong `scenes/game.tscn` không còn chứa sẵn mọi thẻ — mỗi chế độ có 1 scene HUD riêng, tất cả đều kế thừa `nodes/hud/base.tscn` (khung 980×249 tại `(50,175)`, script `scripts/nodes/hud/base.gd`):
> - `nodes/hud/level_mode.tscn` → `LevelHUD` — thẻ **THỬ THÁCH** + **THỜI GIAN** (Play Mode và các bộ luật không có thẻ riêng).
> - `nodes/hud/dungeon_mode.tscn` → `DungeonHUD` — **SỐ BƯỚC** + **THỜI GIAN** + **TẦNG**.
> - `nodes/hud/minesweep_hud.tscn` → `MinesweepHUD` — **BOM CÒN LẠI** + **THỜI GIAN**.
> - `nodes/hud/sum_path_hud.tscn` → `SumPathHUD` — **TỔNG HIỆN TẠI** + **TOÁN TỬ** (giữa) + **MỤC TIÊU** + **THỜI GIAN**.
> - `nodes/hud/blind_memory_hud.tscn` → `BlindMemoryHUD` — **THỜI GIAN** + thẻ **GHI NHỚ VỊ TRÍ TƯỜNG** (không có thẻ Thử thách).
>
> `GameScene._apply_hud_for_mode()` thay node HUD đúng lúc đổi chế độ rồi gắn lại cho `UIController.set_hud()` (vẽ số liệu) và `ChallengeController.card` (chỉ LevelHUD có thẻ Thử thách). Mỗi HUD nhận dữ liệu qua `update_hud(ctx)` với các khoá `title / subtitle / steps_remaining / elapsed_time / floor_number / extra / mode`.
### 5.1. 🎯 Play Mode (Level Selection) *(đổi tên từ "Classic Maze" / "Level Maze")*

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Nút **PLAY** trên Main Screen · `mode_id = play` (`standard_game_mode.gd`) |
| **Bàn cờ** | Theo dữ liệu Màn trong `resources/levels/level_*.tres` (kích thước, tường, `cell_mask` polyomino, 3 thử thách riêng) |
| **Số trên ô** | **Số tường quanh ô** (0..4, chỉ tính 4 cạnh bên trong board — xem quy ước ở đầu mục 5) — hiện cả tường vô hình |
| **Di chuyển** | 4 hướng (không đi chéo) · **không giới hạn số bước** · kéo từ tâm ô / bấm ô kề · có **UNDO** + **GỢI Ý** |
| **Thắng** | Tới F · 3 thử thách chốt khi kết thúc → tối đa 3 Sao · xếp hạng theo **thời gian nhanh nhất** |
| **Thua** | **Đâm tường vô hình = THUA NGAY** (giữ nguyên vị trí + xử lý ở popup) |
| **Hồi sinh** | **Quay lại ô ngay trước đó** (undo bước vừa đi, không cộng bước) — xem 5.10 |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`): **THỜI GIAN** + **THỬ THÁCH** · mockup `mockup/matchup_level.svg` |
| **Chi tiết** | Xem bên dưới |

> Đây là **chế độ chính, cửa vào đầu tiên của game** — thay cho khái niệm "chọn độ khó Dễ/Vừa/Khó" ở bản thiết kế cũ.

- Theo mockup `level_selection.svg`: màn chơi được tổ chức thành **Chương (Chapter)**, mỗi Chương có kích thước lưới cố định (ví dụ *"CHƯƠNG 1: BÀN CỜ NHẬP MÔN (7×7)"*), gồm nhiều **Màn (Level)** đánh số tuần tự (Màn 01, 02, 03...).
- Người chơi chọn đúng 1 Màn cụ thể để chơi, không còn chọn độ khó tổng quát — độ khó tăng dần tự nhiên theo số thứ tự Màn và theo Chương.
- Có thanh tiến trình phần trăm hoàn thành theo Chương (ví dụ "65%"), nút "TIẾP TỤC MÀN 07" để chơi tiếp Màn dở dang gần nhất, và nút "ĐỔI CHƯƠNG" để chuyển giữa các Chương đã mở khóa.
- Mỗi Màn: **Đâm vào tường vô hình = Game Over ngay lập tức** — không có cơ hội quay về S thử lại (giữ nguyên tinh thần "một-lần-ăn-cả" của Classic Maze cũ). Người chơi có thể **hồi sinh bằng cách quay lại bước trước đó** (xem 5.10).
- **Không có giới hạn số bước:** Play Mode **không** dùng bộ đếm bước. HUD của màn chơi chỉ gồm thẻ **THỬ THÁCH** (3 thử thách + ô tích đỏ đã đạt) và thẻ **THỜI GIAN** — theo mockup `matchup_level.svg`; đã bỏ hẳn thẻ số bước và thẻ điểm của bản Dungeon cũ.
- Mỗi Màn có **3 Thử thách**; hoàn thành 1 Thử thách = **1 Sao** (tối đa 3 Sao) — xem 3.1. Tổng kết ở popup thắng màn `popup_win_level.svg`, còn popup thua là `popup_game_over_level.svg`.
- Bảng xếp hạng theo **Thời gian hoàn thành nhanh nhất (Fastest Clear Time)** cho từng Màn.

### 5.2. 🏰 Dungeon Mode

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Nút **DUNGEON** trên Main Screen · `mode_id = dungeon` (`dungeon_game_mode.gd`) |
| **Bàn cờ** | Sinh theo Tầng: kích thước + mật độ tường tăng dần (`FloorController.setup_floor`) |
| **Số trên ô** | **Số tường quanh ô** (0..4) · tỉ lệ tường **hiện sẵn** giảm dần theo Tầng (về 0% ở tầng sâu) |
| **Di chuyển** | 4 hướng · có **bộ đếm bước còn lại** (duy nhất trong game) · UNDO + GỢI Ý |
| **Thắng** | Tới F → cộng điểm + thưởng bước → sang **Tầng kế tiếp** (endless, không có màn cuối) |
| **Thua** | **Hết bước** (đâm tường không thua ngay — chỉ về S và mất 1 bước) |
| **Hồi sinh** | **+N bước** (`revive_bonus_steps`, mặc định 3) và **giữ nguyên 100%** mê cung · vị trí · đường vẽ · tường đã lộ |
| **HUD** | `nodes/hud/dungeon_mode.tscn` (`DungeonHUD`): **SỐ BƯỚC** + **THỜI GIAN** + **TẦNG** · mockup `mockup/matchup_dungeon.svg` |
| **Chi tiết** | Xem bên dưới |

- Chế độ endless, chơi qua nhiều Floor liên tiếp — càng đi sâu càng khó.
- Áp dụng cơ chế **Endless Visible Wall**: tỉ lệ tường hiển thị (visible) giảm dần liên tục theo mỗi Floor càng lên cao, tiến tới 0% ở các floor sâu.
- Đâm tường vô hình: trừ 1 bước, lộ tường thật, rung bàn cờ và đưa nhân vật về điểm S.
- Đến đích F: cộng điểm (Base Score, Move Bonus, Time Bonus, Perfect Floor) và thưởng thêm số bước cho Floor tiếp theo.
- ⚠️ **Dungeon Mode là chế độ DUY NHẤT có bộ đếm số bước còn lại** (thẻ **SỐ BƯỚC** + thẻ **TẦNG** trên HUD, theo mockup `matchup_dungeon.svg`; thẻ chỉ hiện con số bước còn lại, không có `/max`). Hết bước = thua Tầng; **hồi sinh = nhận thêm +3 bước** để đi tiếp ở đúng Tầng hiện tại, **giữ nguyên mê cung — vị trí nhân vật — đường đã vẽ — tường đã lộ** (không sinh lại màn, popup `popup_game_over_dungeon.svg`, xem 5.10).
- Mỗi Tầng có **3 Thử thách**; hoàn thành 1 Thử thách = 1 Sao (tối đa 3 Sao) — xem 3.1.
- Theo mockup `matchup_dungeon.svg`: màn chơi có thêm nút **UNDO** (hoàn tác bước vừa đi) và **GỢI Ý** (Hint) bên cạnh thao tác "VẼ ĐƯỜNG" (kéo từ tâm ô) và "GHI NHỚ" (nối 2 Anchor để đánh dấu tường nghi ngờ) — bổ sung so với bản thiết kế UX trước đó (mục 9).

### 5.3–5.9. Bảy bộ luật chỉ chơi được qua Daily Challenge

Nội dung luật của từng bộ **giữ nguyên như bản thiết kế trước**, chỉ khác về **cách truy cập**: không còn là mục chọn độc lập trên Main Screen, mà là **nội dung xoay vòng theo ngày** trong Daily Challenge (`GameManager.DAILY_MODES`, xem mục 6).

Mỗi bộ luật dưới đây được đặc tả theo **cùng một template**: Cổng vào · Bàn cờ · Số trên ô · Di chuyển · Thắng · Thua · Hồi sinh · HUD & mockup · Chi tiết.

### 5.3. ⏱ Time Attack Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = time_attack` |
| **Bàn cờ** | Sinh theo Tầng/độ khó, tường vô hình |
| **Số trên ô** | Số tường quanh ô (0..4) |
| **Di chuyển** | 4 hướng · **không giới hạn bước** · đâm tường về S và mất thời gian |
| **Thắng** | Tới F trước khi đồng hồ đếm ngược về 0 |
| **Thua** | **Hết giờ** |
| **Hồi sinh** | Quay lại bước trước đó (undo) |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`) · mockup `mockup/matchup_time_attack.svg` |
| **Chi tiết** | ✨ **⏱ Time Attack Maze** — Giới hạn thời gian tổng (60s/90s/120s) đếm ngược, không giới hạn số bước. Đâm tường về S mất thời gian. Hết giờ = Game Over. |

### 5.4. 💣 Minesweeper Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = minesweeper` |
| **Bàn cờ** | Vuông **`2 + tầng`, kẹp 3..5** (tầng 1 = 3×3) · **không tường trong** · luôn có đường BFS **không mìn** từ S tới F · mật độ mìn `min(0.18 + tầng×0.03, 0.32)` |
| **Số trên ô** | Số mìn trong **8 ô lân cận** (0..8) · S/F luôn an toàn |
| **Di chuyển** | 4 hướng · mỗi bước 1 điểm · hồi sinh = quay lại ô trước đó |
| **Thắng** | Tới F mà không đạp mìn |
| **Thua** | **Đạp mìn = THUA NGAY** — đứng nguyên tại ô, hiện **icon Bomb** (giữ nguyên con số), HUD **BOM CÒN LẠI** giảm 1 rồi mở popup thua |
| **Hồi sinh** | Quay lại ô ngay trước đó |
| **HUD** | `nodes/hud/minesweep_hud.tscn` (`MinesweepHUD`): **BOM CÒN LẠI** + **THỜI GIAN** · mockup `mockup/matchup_minesweeper.svg` |
| **Chi tiết** | ✨ **💣 Minesweeper Maze** — Số trên ô = số mìn trong 8 ô lân cận. S/F luôn an toàn, luôn tồn tại ít nhất 1 đường BFS không mìn. **Đạp mìn = THUA NGAY** (giống Play Mode đâm tường): nhân vật **đứng nguyên tại ô vừa nổ** (không bị đưa về S), trừ 1 bước rồi mở **popup thua**; ô đó hiện **biểu tượng Bomb to ở giữa ô** (icon `game/icon_bomb.svg`) nhưng **giữ nguyên con số** — số nằm ĐÈ LÊN icon (có viền màu giấy cho dễ đọc). HUD hiện thẻ **BOM CÒN LẠI** dạng `còn/tổng` (giảm 1 mỗi quả đã nổ). Hồi sinh = quay lại ô ngay trước đó. |

### 5.5. 🧠 Blind Memory Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = blind_memory` |
| **Bàn cờ** | Thường: 4×4 · Hardcore: 5×5 · tường vô hình, **không hiện số** |
| **Số trên ô** | **Không có số** (chỉ S/F) — người chơi phải **ghi nhớ** vị trí tường |
| **Di chuyển** | 4 hướng · bị **khoá tương tác** trong lúc đếm ngược · có UNDO + GỢI Ý |
| **Thắng** | Tới F sau khi tường đã ẩn, đi bằng trí nhớ |
| **Thua** | Hết giờ · Hardcore: đâm tường = thua ngay (Thường: về S) |
| **Hωi sinh** | Quay lại bước trước đó |
| **HUD** | `nodes/hud/blind_memory_hud.tscn` (`BlindMemoryHUD`): **THỜI GIAN** + thẻ **GHI NHỚ VỊ TRÍ TƯỜNG** (**KHÔNG có thẻ Thử thách**) · mockup `mockup/matchup_blind_memory.svg` |
| **Popup riêng** | `nodes/popups/memory_countdown.tscn` — mẩu giấy đếm ngược **3 → 2 → 1 → GO!**, **không nền mờ** (vẫn thấy mê cung) |
| **Chi tiết** | * **🧠 Blind Memory Maze** — Không số. **Pha GHI NHỚ khi vào màn:** hiện **toàn bộ tường thật** + mở **popup giấy đếm ngược `3 → 2 → 1 → GO!`** (`nodes/popups/memory_countdown.tscn`, **không có nền mờ** nên vẫn nhìn rõ mê cung), **khoá tương tác** và **đồng hồ ĐỨNG YÊN** (thời gian ghi nhớ không tính vào giờ chơi). Hết đếm ngược: tường ẩn hoàn toàn, mở tương tác, đồng hồ bắt đầu chạy — người chơi đi bằng trí nhớ. **HUD riêng không có thẻ THỬ THÁCH** (`BlindMemoryHUD`): THỜI GIAN + thẻ nhắc GHI NHỚ. Tùy chọn Thường (về S) / Hardcore (thua ngay). |

### 5.6. 🌫 Fog of War Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = fog_of_war` |
| **Bàn cờ** | Sinh theo tầng/độ khó, tường vô hình như Play Mode |
| **Số trên ô** | Số tường quanh ô — **chỉ hiện ở các ô trong bán kính 1** quanh nhân vật; ô xa bị phủ mờ (modulate `0.6` / alpha `0.4`) |
| **Di chuyển** | 4 hướng · sương mù cập nhật theo từng bước đi |
| **Thắng** | Tới F |
| **Thua** | Hết giờ · Hardcore: đâm tường = thua ngay (Thường: về S) |
| **Hồi sinh** | Quay lại bước trước đó |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`) · mockup `mockup/matchup_fog_of_war.svg` |
| **Chi tiết** | * **🌫️ Fog of War Maze** — Có tường vô hình như Play Mode, nhưng chỉ hiện số ở các ô trong bán kính 1 quanh vị trí hiện tại; ô xa ẩn số. Tùy chọn Thường (về S) / Hardcore (thua ngay). |

### 5.7. ➕ Sum Path

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = sum_path` |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 · **không có tường** |
| **Số trên ô** | **Điểm số của ô (1..9)** — không liên quan tường |
| **Di chuyển** | 4 hướng · mỗi ô **chỉ tính điểm 1 lần** (quay lại ô cũ không cộng thêm) |
| **Thắng** | Tới F với tổng điểm thỏa điều kiện `SUM < / > / = Target` (luôn tồn tại ít nhất 1 nghiệm đúng) |
| **Thua** | Hết đường hợp lệ / hết thời gian (không có hazard) |
| **HUD** | `nodes/hud/sum_path_hud.tscn` (`SumPathHUD`): **TỔNG HIỆN TẠI — TOÁN TỬ — MỤC TIÊU** + **THỜI GIAN** · mockup `mockup/matchup_sum_path.svg` |
| **Chi tiết** | ✨ **➕ Sum Path** — Không có tường. Số trên ô là điểm (1..9). Thắng khi tới F với tổng điểm thỏa `SUM < / > / = Target`. Mỗi ô chỉ tính điểm 1 lần. Luôn đảm bảo tồn tại ít nhất 1 nghiệm đúng. **HUD hiện 3 thẻ theo đúng thứ tự `TỔNG HIỆN TẠI — TOÁN TỬ — MỤC TIÊU`** (thẻ TOÁN TỬ nhỏ 112×112 nằm chính giữa, đè lên mép 2 thẻ kia; MỤC TIÊU chỉ hiện con số) thay cho panel MISSION cũ. |

### 5.8. ⏳ Countdown Cost

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = countdown_cost` |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 (xem bảng chi phí/ngân sách bên dưới) |
| **Số trên ô** | **CHI PHÍ BƯỚC** khi bước vào ô đó (mọi ô trừ S/F đều có số ≥ 1) |
| **Di chuyển** | 4 hướng · bước vào ô nào trừ đúng chi phí ô đó · đâm tường về S và trừ chi phí ô đích |
| **Thắng** | Tới F trong ngân sách (ngân sách = đường rẻ nhất + dự phòng ⇒ luôn thắng được nếu chọn đường rẻ) |
| **Thua** | **Hết bước** |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`) — thử thách thứ 2 (`steps_max`) đóng vai ngân sách bước · mockup `mockup/matchup_countdown_cost.svg` |
| **Chi tiết** | ✨ **⏳ Countdown Cost** — **Số trên ô = CHI PHÍ BƯỚC khi bước vào ô đó**, hoàn toàn **không liên quan tới số tường quanh ô** (khác Play / Dungeon / Fog of War). Mọi ô trừ S/F đều có số ≥ 1 và luôn hiện số. Bước vào ô nào thì trừ đúng chi phí của ô đó; đâm tường: về S và trừ chi phí của ô đích vừa đâm vào. Ngân sách bước được tính đủ cho **đường đi rẻ nhất + khoảng dự phòng**, nên màn luôn thắng được nếu chọn đúng đường ít tốn kém; đi lệch qua các ô đắt sẽ hết bước. |

  | Độ khó | Lưới | Chi phí mỗi ô | Dự phòng | Ngân sách tối thiểu |
  |---|---|---|---|---|
  | Easy | 3×3 | 1..2 bước | +6 | 12 bước |
  | Medium | 4×4 | 1..3 bước | +4 | 14 bước |
  | Hard | 5×5 | 1..4 bước | +3 | 15 bước |

  > Ngân sách thực tế = `max(ngân sách tối thiểu, chi phí đường đi rẻ nhất + dự phòng)`, tính bằng Dijkstra trên trọng số là chi phí ô đích — xem `scripts/modes/countdown_cost_game_mode.gd` (`cheapest_path_cost()` / `_ensure_budget()`).

### 5.9. 💧 Fading Ink (Mực Phai)

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge (thay chỗ **Area Maze** — đã BỎ từ 2026-11) · `mode_id = fading_ink` |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 · **không có tường trong** |
| **Số trên ô** | **MỰC của riêng ô đó** (ban đầu 2..9) — **giảm 1 mỗi bước đi** (mọi ô cùng phai một nhịp) |
| **Di chuyển** | 4 hướng · **chỉ đi vào ô còn mực**; ô hết mực bị chặn (không mất bước), mất số và **mờ đi** (alpha 0.4) |
| **Thắng** | Tới F trước khi mực phai hết — phải đi **đường ngắn nhất** |
| **Thua** | **Hết lối đi mà chưa tới F** → popup thua tiêu đề riêng `HẾT ĐƯỜNG ĐI!` (`STR_GAME_OVER_NO_PATH`) |
| **Hồi sinh** | Quay lại bước trước đó — **mực hồi lại** đúng 1 điểm cho mọi ô |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`) · mockup `mockup/matchup_fading_ink.svg` |
| **Chi tiết** | * **💧 Fading Ink (Mực Phai)** — *(thay cho Area Maze — đã BỎ từ 2026-11)* **Không có tường trong bàn.** Con số trên ô **KHÔNG phải số tường** mà là **MỰC của riêng ô đó** (mực ban đầu 2..9). **Người chơi chỉ được đi vào ô còn mực**; ô đã phai hết mực coi như ô trống — không đi vào được (bị chặn, KHÔNG mất bước, ô đó mờ đi và mất số). **MỖI BƯỚC ĐI làm MỌI ô trên bàn nhạt đi đúng 1 điểm mực** (không riêng ô vừa đi), nên phải tìm **đường ngắn nhất** tới F trước khi lối đi biến mất; đi vòng sẽ tự bịt đường của chính mình. Bàn luôn được sinh sao cho **đường ngắn nhất có đủ mực để tới F** (các ô trên đường đi được cấp mực theo số bước cần tới chúng, ô ngoài đường nhận mực thấp làm lối tắt dự phòng). **Đồng hồ đếm thời gian như thường**, không giới hạn số bước. **Hết lối đi mà chưa tới F = THUA** (popup thua hiện tiêu đề riêng `HẾT ĐƯỜNG ĐI!`). Nút **UNDO** lùi 1 bước thì **mực hồi lại** đúng 1 điểm cho mọi ô (trạng thái mực được tính lại từ số bước đã đi, không cần lưu lịch sử). HUD dùng bản mặc định (**THỬ THÁCH** + **THỜI GIAN**) — không có thẻ riêng. |
### 5.10. Popup kết quả & Hồi sinh khi thua (Revive)

| Cổng chơi | Mockup popup thua | Nội dung chính | Con dấu (stamp) | Nút HỒI SINH |
|---|---|---|---|---|
| **Play Mode** (Chọn màn) | `popup_game_over_level.svg` | Danh sách **3 Thử thách** kèm trạng thái ĐẠT / CHƯA ĐẠT | **Số Thử thách đã hoàn thành** (ví dụ `1 / 3 ★`) | **Quay lại bước trước đó** |
| **Dungeon Mode** | `popup_game_over_dungeon.svg` | Quãng đường đã đi · số lần va chạm tường vô hình · điểm an ủi tích lũy | **Bước còn lại** khi thua (ví dụ `HẾT BƯỚC — 00 / 20 BƯỚC`) | **Nhận thêm +3 bước để đi tiếp** |

- **Play Mode — hồi sinh = Quay lại bước trước đó:** Play Mode thua vì **đâm vào tường vô hình**; hồi sinh đưa nhân vật **về đúng ô ngay trước bước vừa rồi** (giữ nguyên đường đã vẽ, đồng hồ vẫn chạy). Play Mode **không cộng thêm bước** vì vốn không có giới hạn bước.
- **Dungeon Mode — hồi sinh = Thêm bước (giữ nguyên màn đang chơi):** Dungeon thua vì **hết bước**; hồi sinh **cộng thêm +N bước** (`GameController.revive_bonus_steps`, mặc định **3** — dòng mô tả ở popup tự hiện đúng số này) và **chơi tiếp ngay tại chỗ**: mê cung, vị trí nhân vật, đường đã vẽ và các đoạn tường đã lộ **giữ nguyên 100%** (không sinh lại màn — sinh lại mê cung coi như chơi ván khác). Đồng hồ chạy tiếp.

> **Quy ước nút "Chơi lại" (Retry) — phân biệt theo chế độ:**
> | Chế độ | "Chơi lại" (popup thua · popup thắng · nút Restart trên HUD) | "Hồi sinh" |
> |---|---|---|
> | **Dungeon** (endless) | Mở **ván mới — bắt đầu từ TẦNG 1** | Ở lại **đúng Tầng hiện tại** + cộng thêm **+N bước** |
> | **Play Mode / Level** và các mode khác (trừ endless) | Chơi lại **ĐÚNG màn đang chơi** | **Quay lại bước trước đó** (undo bước vừa đi, không cộng bước) |
- **Popup thắng màn ở Play Mode** (`popup_win_level.svg`) hiển thị: thời gian hoàn thành, số bước đã đi, **3 sticker sao = 3 Thử thách** (sao vàng = đã đạt · sao rỗng = chưa đạt) cùng bảng trạng thái từng Thử thách và con dấu `2 / 3 THỬ THÁCH`.

---

## 6. Hệ thống Daily Challenge

Theo mockup `daily_challenge.svg`, đây là màn hình quản lý toàn bộ 7 bộ luật ở mục 5.3–5.9:

- **Lịch dạng calendar theo tháng**, mỗi ngày là 1 ô có thể bấm vào (nếu đã đến/đã qua ngày đó) hoặc khóa (nếu là ngày tương lai — hiển thị "CHƯA MỞ").
- Mỗi ngày trong quá khứ/hiện tại hiển thị **số sao đã đạt** (ví dụ "3/3 SAO", "2/3 SAO") hoặc trạng thái đang dở dang ("2/3 XONG").
- **Streak** (chuỗi ngày chơi liên tiếp) hiển thị nổi bật trên Main Screen (ví dụ "🔥 STREAK: 7 NGÀY") và trên chính màn Daily Challenge.
- Mỗi ngày, hệ thống chọn **1 trong 7 bộ luật** ở mục 5.3–5.9 làm nội dung thử thách, kèm theo **3 Challenge** (đúng hệ thống Thử thách & Sao ở mục 3.1 — mỗi Challenge hoàn thành = 1 Sao, tối đa 3 Sao) liên quan đến cách chơi bộ luật hôm đó (đi càng ít bước, đánh dấu đúng tường nghi ngờ, không đâm tường lần nào...). Cụ thể từng Challenge nên được thiết kế riêng theo đặc thù mỗi bộ luật, không dùng chung 1 khuôn cho cả 7.
- Vì mỗi ngày chỉ có 1 bộ luật cố định (không chọn được), người chơi không thể "chọn lại" chơi bộ luật khác trong cùng ngày — muốn chơi Minesweeper Maze lần nữa phải đợi đến lượt xoay vòng kế tiếp của bộ luật đó.

*(Cơ chế xoay vòng cụ thể — ví dụ thứ tự cố định lặp mỗi 7 ngày, hay random có kiểm soát không lặp liên tiếp — cần thiết kế chi tiết thêm.)*

---

## 7. Hệ thống Điểm số & Xếp hạng (Scoring & Leaderboards)

- **Sao (Star) — áp dụng MỌI chế độ:** 1 match-up có **3 Challenge**, hoàn thành 1 Challenge = **1 Sao** (xem 3.1). Sao **KHÔNG** còn phụ thuộc thời gian còn lại.
- **Play Mode:** Xếp hạng theo **Thời gian hoàn thành nhanh nhất** cho từng Màn (không xếp theo số bước — Play Mode không giới hạn bước).
- **Dungeon Mode:** Xếp hạng theo **Floor cao nhất đạt được** và tổng điểm tích lũy (chế độ duy nhất có bộ đếm bước còn lại).
- **Time Attack Maze / Blind Memory Maze / Fog of War Maze:** Xếp hạng theo **Thời gian hoàn thành nhanh nhất** cho ngày Daily Challenge tương ứng.
- **Countdown Cost:** Xếp hạng theo **tổng chi phí bước đã dùng** (càng ít càng tốt, đúng tinh thần "tối ưu chi phí"), sau đó mới tới thời gian — hoặc theo cách server tổ chức ngày hôm đó.
- **Sum Path / Fading Ink:** Xếp hạng theo **Điểm độ chính xác và thời gian**.
- Ngoài xếp hạng riêng từng bộ luật, Daily Challenge còn có **bảng xếp hạng theo tổng số sao tích lũy trong tháng** và **độ dài Streak**.

**Đã hiện thực (bản offline, 2026-02):** màn **BẢNG XẾP HẠNG** với 3 tab DUNGEON · CHẾ ĐỘ PLAY · CHUỖI NGÀY — xem **mục 11** để biết công thức điểm, dữ liệu thật/mô phỏng và các file liên quan. Khi nối Google Play Games sẽ thay nguồn dữ liệu đối thủ, không phải sửa UI.

---

## 8. Sổ tay thành tựu (Badge Book / Achievement)

Màn hình `scenes/archivement.tscn` — vào từ **Main Screen → nút "SỔ TAY THÀNH TỰU"** (hàng nút Other, nút thứ 4) hoặc từ Debug Console (`Badge Book`).

### 8.1. Dữ liệu: mỗi danh hiệu = 1 file `.tres` (data-driven)

- Danh sách danh hiệu **không nằm trong code**: `ArchivementManager` quét toàn bộ `resources/archivements/*.tres` (`ArchivementData`) lúc khởi động → **thêm/bớt danh hiệu chỉ cần thêm/bớt file**, không sửa code.
- Trường của 1 danh hiệu: `id` (duy nhất) · `category` · `title` / `description` (tiếng Việt hiển thị trong game) · `title_key` / `desc_key` (tuỳ chọn, dùng chuỗi localization) · `icon` · `stat` (khoá số liệu) + `target` + `unit` (đơn vị hiển thị, ví dụ "Tầng") · `reward_coins` (xu) · `points` (AP) · `secret` (danh hiệu ẩn).
- Danh sách đầy đủ 28 danh hiệu hiện có (id · điều kiện · thưởng) được xuất ra **`archivements_list.txt`** ở gốc project.

### 8.2. Phân nhóm (5 tab)

| Tab | `category` | Số danh hiệu | Nội dung |
|---|---|---|---|
| **TẤT CẢ (n)** | `` (rỗng) | 28 | Toàn bộ catalog |
| **MÀN CHƠI** | `levels` | 7 | Số màn đã qua · tổng sao · số màn 3 sao · tốc độ phá màn |
| **DUNGEON** | `dungeon` | 7 | Tầng sâu nhất · tổng tầng đã vượt · điểm cao nhất 1 ván |
| **DAILY** | `daily` | 7 | Số ngày Daily · chuỗi ngày liên tiếp · tổng sao Daily |
| **ĐẶC BIỆT** | `special` | 7 (2 ẩn) | Thắng không gợi ý / không hoàn tác · Hardcore · số danh hiệu đã nhận + **2 danh hiệu ẨN** |

### 8.3. Bốn trạng thái của thẻ danh hiệu

| Trạng thái | Điều kiện | Hiển thị |
|---|---|---|
| **ĐÃ ĐẠT** (xanh lá `#2E7D32`) | đủ điều kiện **và** đã bấm NHẬN | dấu mộc đỏ "ĐÃ ĐẠT · +N xu", thanh tiến độ 100%, dòng tiến độ thêm "(Hoàn thành)" |
| **NHẬN THƯỞNG** (cam `#D97706`) | đủ điều kiện, **chưa** nhận | nút **NHẬN +N** kèm icon xu |
| **ĐANG LÀM** (xanh dương `#3D83AE`) | chưa đủ điều kiện | chip "Thưởng: +N" + tiến độ `x / y đơn vị` |
| **ẨN / KHÓA** (xám `#7A8F9B`) | danh hiệu `secret` chưa đạt | ổ khoá + "Thành Tựu Ẩn • Chưa Khám Phá" + tiến độ `??? / ???` |

### 8.4. Phân trang & thao tác

- **5 thẻ / trang** (`ArchivementScene.CARDS_PER_PAGE = 5`, nhịp thẻ 190px) — catalog nhiều lên thì số trang tự tăng, giống màn **Chọn màn**; hiện tại 28 danh hiệu = 6 trang ở tab TẤT CẢ.
- Chuyển trang: **vuốt ngang** (Touch / Drag / lăn chuột), bấm **dots**, hoặc `go_to_page(i)`. Mở Sổ tay sẽ tự nhảy tới **trang chứa danh hiệu đầu tiên đang chờ nhận thưởng**.
- Bấm tab → dựng lại danh sách + dots theo nhóm đó (kèm SFX lật trang).
- Bấm **NHẬN** → `ArchivementManager.claim(id)`: cộng `reward_coins` vào ví, đánh dấu đã nhận, phát SFX con dấu, vẽ lại toàn bộ màn + cập nhật thẻ tổng kết. **Nhận lần 2 bị chặn** (không cộng xu).
- Thẻ tổng kết (đầu trang): thanh tiến độ **% đã mở khoá**, dòng `Đã mở: x / y Danh hiệu • Điểm: n AP`, dấu mộc góc phải `x/y BADGES`.

### 8.5. Số liệu (stats) — 2 loại

| Loại | Cách có dữ liệu | Khoá |
|---|---|---|
| **Dẫn xuất** (đọc lại khi mở Sổ tay) | đọc từ `GameManager` (sao + best time từng màn) và `DailyManager` (số ngày · chuỗi ngày · tổng sao) | `levels_cleared`, `level_stars_total`, `level_perfect`, `fastest_clear`, `daily_days`, `daily_streak`, `daily_stars_total`, `claimed_count` |
| **Tích luỹ** (game báo về mỗi ván) | `GameController` gọi `Archivement.notify_run_result({mode_id, won, endless, floor, score, elapsed, wall_hits, hints_used, undos_used, hardcore})` ở popup thắng/thua | `dungeon_best_floor`, `dungeon_floors_total`, `dungeon_best_score`, `wins_total`, `wins_no_hint`, `wins_no_undo`, `hints_total`, `undos_total`, `hardcore_wins`, `play_seconds` |

- `dungeon_best_floor` = tầng **sâu nhất đã tới** (thắng tầng N ⇒ đã tới tầng N+1) nên danh hiệu "Tầng 5/15/30" luôn khớp với dòng "Tầng tiếp theo" ở popup thắng.
- Danh hiệu ẩn vẫn **đếm tiến độ ngầm**; khi đủ điều kiện thì tự hiện tên thật + mô tả điều kiện (người chơi mới biết mình vừa đạt gì).

### 8.6. Lưu trữ

- `ArchivementManager` là **provider của SaveManager**: `export_progress()` → `{coins, claimed[], stats{}}`, `import_progress(data)`, `reset_progress()`; mọi thay đổi số liệu phát `progress_changed` → SaveManager **autosave** (giống `level_completed` của GameManager, `daily_changed` của DailyManager).
- Số liệu **dẫn xuất KHÔNG lưu** (luôn tính lại từ GameManager/DailyManager) → tránh lệch dữ liệu khi save cũ được nạp.
- **Điểm danh hiệu (AP)** = tổng `points` của các danh hiệu **đã đạt** (không cần nhận thưởng); **xu** chỉ cộng vào ví khi bấm NHẬN (tổng thưởng tối đa của catalog hiện tại: 5.260 xu · 810 AP).

### 8.7. File liên quan

| File | Vai trò |
|---|---|
| `resources/archivements/*.tres` | **Catalog** 28 danh hiệu (data-driven) |
| `scripts/resources/archivement_data.gd` | Resource `ArchivementData` — schema 1 danh hiệu |
| `scripts/manager/ArchivementManager.gd` | Autoload: nạp catalog · tính số liệu · kiểm tra mở khoá · nhận thưởng · lưu trữ |
| `scripts/utils/archivement.gd` | Facade tĩnh `Archivement.*` cho UI/test (không tham chiếu autoload trực tiếp) |
| `scenes/archivement.tscn` + `scripts/scenes/archivement.gd` | Màn "Sổ tay thành tựu" (tab + phân trang + tổng kết + nút Nhận) |
| `nodes/archivements/card.tscn` + `scripts/nodes/archivements/card.gd` | Thẻ 1 danh hiệu (4 trạng thái) |
| `assets/images/archivements/*.svg` | Giấy sổ tay · 4 nền thẻ · tab · thanh tiến độ · dấu mộc · chip · nút NHẬN · huy hiệu |
| `scripts/test_case/test_archivement.gd` | Test catalog · tiến độ · nhận thưởng · lưu trữ · phân trang scene (54 check) |
| `archivements_list.txt` | Danh sách danh hiệu dạng văn bản (xuất từ catalog) |

---

## 9. Debug Console (chỉ có ở bản dev)

Mở bằng **F9** (hoặc bấm 5 lần vào con dấu phiên bản ở màn Settings, hoặc `Nav.goto_debug()`); bấm F9 lần nữa để quay lại.

| Nhóm | Nội dung |
|---|---|
| STATE | FPS/MEM/Obj · locale · mode · **ván test** (cờ + tầng ép) · số popup đang mở |
| NAVIGATE | Main · Chọn màn · Daily · Settings · Sổ tay thành tựu · Dungeon run |
| PROGRESS | Nhảy tới màn 1–9 · mở khoá tất cả · ghi 3 sao · xoá tiến trình |
| DAILY | Ngày hôm nay · chuỗi ngày · chơi daily hôm nay · đánh dấu hoàn thành · xoá dữ liệu Daily |
| **SPECIAL MODES (TEST)** | Vào thẳng **7 chế độ Special** (vốn chỉ chơi được qua Daily) — xem 9.1 |
| SAVE | Backend · save now · reload · đổi backend · xoá toàn bộ + dump blob JSON |
| POPUPS | Mở thử win / next floor / game over / pause / language |
| DEBUG FLAGS | Bật/tắt log theo nhóm (general · sfx · flow · save) |

### 9.1. Test 7 chế độ Special (SPECIAL MODES)

Daily Challenge chỉ cho chơi **1 luật/ngày** (`(ngày-1) % 7`), nên Debug Console cho vào thẳng từng luật để test:

- **Test mode (mặc định BẬT):** ván mở từ đây **không ghi tiến trình** — không đánh dấu ngày Daily (`_mark_daily_completed_if_needed` bỏ qua) và không tính vào Sổ tay thành tựu (`_report_to_archivements` bỏ qua). Tắt toggle nếu muốn ghi như chơi thật.
- **Độ khó:** easy · medium · hard (áp dụng cho các luật có tham số độ khó: `time_attack`, `sum_path`, `countdown_cost`, `blind_memory`, `fog_of_war`).
- **Tầng bắt đầu:** 1 · 2 · 3 · 5 — một số luật sinh bàn theo tầng (`minesweeper`: `2 + tầng`, tối đa 5×5) nên chọn tầng cao để test bàn to.
- **Mỗi chế độ 1 hàng lệnh:** tiêu đề ghi `Tên mode [id] · Daily ngày N, N+7, N+14…`; dòng mô tả lấy trực tiếp từ `BaseGameMode.mode_description` của chính mode đó (không chép lại chữ).
- Thêm **“Chế độ kế tiếp”** (xoay vòng 7 luật) và **“Chế độ ngẫu nhiên”** để test nhanh nhiều luật liên tiếp.

Cơ chế: `GameManager.prepare_mode_run(mode_id, difficulty, test_run, floor_override)` (đặt cờ, **không** đổi scene — test gọi được) và `GameManager.start_mode(...)` (= prepare + vào `scenes/game.tscn`); `game.gd::_start_floor_for()` đọc `start_floor_override` để chọn tầng xuất phát cho ván test.

---

## 10. Mockup matchup & đặc tả HUD theo chế độ

**Mockup matchup** = bản vẽ 1080×1920 mô tả **đúng hàng HUD của một chế độ** (khung `Information` 980×249 tại `(50,175)`), kèm màn chơi, thanh nút dưới, và **bảng chú thích đánh số** cho từng thẻ.

### 10.1. Danh sách mockup

| Chế độ | `mode_id` | HUD scene | Mockup matchup | Thẻ trên HUD |
|---|---|---|---|---|
| Play Mode | `play` | `nodes/hud/level_mode.tscn` (LevelHUD) | `mockup/matchup_level.svg` | THỜI GIAN + THỬ THÁCH |
| Dungeon Mode | `dungeon` | `nodes/hud/dungeon_mode.tscn` (DungeonHUD) | `mockup/matchup_dungeon.svg` | THỜI GIAN + SỐ BƯỚC + TẦNG |
| Time Attack Maze | `time_attack` | `nodes/hud/level_mode.tscn` | `mockup/matchup_time_attack.svg` | THỜI GIAN (đếm ngược) + THỬ THÁCH |
| Minesweeper Maze | `minesweeper` | `nodes/hud/minesweep_hud.tscn` (MinesweepHUD) | `mockup/matchup_minesweeper.svg` | THỜI GIAN + BOM CÒN LẠI |
| Blind Memory Maze | `blind_memory` | `nodes/hud/blind_memory_hud.tscn` (BlindMemoryHUD) | `mockup/matchup_blind_memory.svg` | THỜI GIAN + GHI NHỚ VỊ TRÍ TƯỜNG (+ popup đếm ngược) |
| Fog of War Maze | `fog_of_war` | `nodes/hud/level_mode.tscn` | `mockup/matchup_fog_of_war.svg` | THỜI GIAN + THỬ THÁCH |
| Sum Path | `sum_path` | `nodes/hud/sum_path_hud.tscn` (SumPathHUD) | `mockup/matchup_sum_path.svg` | THỜI GIAN + TỔNG HIỆN TẠI + TOÁN TỬ + MỤC TIÊU |
| Countdown Cost | `countdown_cost` | `nodes/hud/level_mode.tscn` | `mockup/matchup_countdown_cost.svg` | THỜI GIAN + THỬ THÁCH |
| Fading Ink | `fading_ink` | `nodes/hud/level_mode.tscn` | `mockup/matchup_fading_ink.svg` | THỜI GIAN + THỬ THÁCH |

> 4 chế độ (`time_attack`, `countdown_cost`, `fog_of_war`, `fading_ink`) **dùng chung `LevelHUD`** nên mockup của chúng chỉ khác phần bàn cờ + chú thích luật; `matchup_level.svg` (Play) vẫn là mockup gốc cho layout này.

### 10.2. Vị trí & kích thước thẻ (đo trực tiếp từ scene)

Khung HUD: `Information` = Control tại `(50, 175)` kích thước `980 × 249` (mọi toạ độ dưới đây tính trong khung này).

| Thẻ | Kích thước | Vị trí (x, y) | Art (res://assets/images/game/) | Label / Value |
|---|---|---|---|---|
| **THỜI GIAN** | 250 × 138 | (0, 31) | `card_time_slip.svg` (HUD mới) · `card_time.svg` (Play/Dungeon) | `text_game_card_label` 18px · `text_game_information_subvalue` 42px |
| **THỬ THÁCH** | 720 × 246 | (271, −29) | `card_challenge.svg` | 3 dải 490×58 tại y = 28/94/160 · cột tổng kết x = 36..186 |
| **SỐ BƯỚC** | 440 × 158 | (270, 18) | `card_steps.svg` | `text_game_challenge_count_sub` 36px · `text_game_card_value_steps` 72px |
| **TẦNG** | 250 × 138 | (730, 28) | `card_floor.svg` | label 18px · `text_game_information_value` 58px |
| **BOM CÒN LẠI** | 440 × 158 | (270, 18) | `card_bomb.svg` + sticker `icon_bomb.svg` 80×80 tại (336, 39) | label 36px đỏ · value 72px đỏ dạng `còn/tổng` |
| **TỔNG HIỆN TẠI** | 440 × 158 | (270, 18) | `card_sum.svg` | label 36px `#718B9E` · value 72px `#224C6D` |
| **TOÁN TỬ** | 112 × 112 | (664, 68) | `card_op.svg` (lề đỏ) | `text_game_information_value` 58px mực đỏ, căn giữa |
| **MỤC TIÊU** | 250 × 138 | (730, 28) | `card_time_slip.svg` | label 18px · value 58px (chỉ con số) |
| **GHI NHỚ** | 440 × 158 | (270, 18) | `card_sum.svg` | title 36px · hint 18px (auto-wrap) · dòng chế độ 18px đỏ |

> Toạ độ trên **khớp với scene thật** (kiểm tra bằng `tools/mockup/gen_matchup.py --dump`), thẻ TOÁN TỬ vẽ SAU cùng nên đè lên mép thẻ TỔNG và thẻ MỤC TIÊU (dạng `12 = 23`).

### 10.3. Sinh lại mockup

```bash
python tools/mockup/gen_matchup.py            # sinh lại 7 mockup matchup_<mode>.svg
python tools/mockup/gen_matchup.py --list     # danh sách mode sẽ sinh
python tools/mockup/gen_matchup.py --dump     # in toạ độ node thật của các scene HUD
```

- Tool đọc **toạ độ thật** từ `nodes/hud/*.tscn` + `scenes/game.tscn` (Board `(41,420)-(1061,1440)`, thanh nút `(73,1528)-(1031,1688)`, Status `(50,85)`).
- **Không ghi đè** `matchup_level.svg` / `matchup_dungeon.svg` (bản vẽ tay có art bàn cờ chi tiết của bản thiết kế gốc).
- Mockup mang **bảng chú thích đánh số**: badge số đặt ngay trên thành phần cần giải thích + danh sách chú thích dưới thanh nút.

---

## 11. Bảng xếp hạng (Ranking Screen)

Màn hình mới theo mockup `mockup/ranking.svg` (1080×1920). Lối vào: nút **XẾP HẠNG** ở Main Screen (mục 4.1) hoặc Debug Console → NAVIGATE → *Leaderboard*.

### 11.1. Ba bảng (tab)

| Tab | Kỷ lục chính (dòng trên mỗi hàng) | Công thức điểm xếp hạng |
|---|---|---|
| **DUNGEON** | Tầng cao nhất | `best_floor × 620 + best_score ÷ 8` |
| **CHẾ ĐỘ PLAY** | Số màn đã qua | `levels_cleared × 360 + stars × 40 + max(0, 600 − fastest_clear) × 2` |
| **CHUỖI NGÀY** | Chuỗi ngày Daily | `streak × 280 + days × 30 + total_stars × 5` |

- **Điểm là khoá sắp xếp duy nhất**; bằng điểm thì xếp theo tên (bảng luôn ổn định, không nhảy lung tung).
- Mỗi bảng có **25 hạng = 24 đối thủ + người chơi**: bục vinh quang 3 hạng đầu (Gold giữa 240×200 · Silver trái 200×155 · Bronze phải 200×130, **đáy thẳng hàng**), danh sách cuộn hiển thị hạng 4 → 25 (7 hàng/lần, nhịp 105px).

### 11.2. Dữ liệu: kỷ lục thật + đối thủ mô phỏng

- **Người chơi — dữ liệu THẬT:** đọc từ `ArchivementManager.stat_value()`: `dungeon_best_floor`, `dungeon_best_score`, `levels_cleared`, `level_stars_total`, `fastest_clear`, `daily_streak`, `daily_days`, `daily_stars_total`. Chưa chơi ván nào → hàng hiện `CHƯA CÓ` + `0 ĐIỂM` và thanh đáy nhắc "hãy chơi một ván".
- **Đối thủ — dữ liệu MÔ PHỎNG (offline):** `RankingManager.RIVAL_POOL` gồm 24 mục `{name, flag, power}`; điểm sinh bằng `RandomNumberGenerator` với seed `hash("bảng|tên|khung-10-phút")` → **ổn định giữa các phiên**, chỉ đổi nhẹ mỗi khung 10 phút ⇒ mô phỏng "bảng xếp hạng sống" đúng như ghi chú chân trang mockup.
- Cờ quốc gia dùng asset có sẵn `assets/images/icons/flags/flag_{vi,en,ja,ko,zh_cn,fr,generic}.svg` (KHÔNG dùng emoji); cờ của người chơi suy từ ngôn ngữ đang chọn.
- **Khi nối Google Play Games** (xem `TODO.txt`): chỉ cần thay thân `RankingManager._build_board()` bằng dữ liệu server — scene, hàng, định dạng giữ nguyên.

### 11.3. Giao diện (đo từ scene thật)

Tờ giấy `rank_sheet.svg` **940×1570 tại (70,185)**, viền `#6EA0C8` 3.5px, lề đỏ x=75, lỗ bấm giấy mỗi 120px, dòng kẻ ô ly mỗi 80px; băng keo washi + kẹp giấy ở mép trên (như Sổ tay thành tựu).

| Thành phần | Vị trí trong tờ giấy | Ghi chú |
|---|---|---|
| 3 tab | (95, 52), rộng 240 · 235 · 245, cách 15 | tab đang chọn = nền `#3D83AE` + chữ trắng; tab còn lại = giấy + viền `#8FB9D2` |
| 2 đường kẻ nét đứt | y = 126 và y = 522, rộng 755 | dùng lại `assets/images/settings/divider_dashed.svg` (STRETCH_TILE) |
| Bục vinh quang | (95, 140), cao 370 | Gold (255,170) · Silver (20,215) · Bronze (525,240) — toạ độ trong cụm |
| Danh sách cuộn | (95, 545) 755×770 | `ScrollContainer` ẩn thanh cuộn (`vertical_scroll_mode = 3`), VBox cách 15px |
| Thanh "hạng của bạn" | (95, 1330) 755×110 | nền `#3D83AE` viền `#256286`, hạng màu `#FBBF24` |
| Ghi chú chân trang | y = 1480 / 1516 | 1 dòng nghiêng (làm mới 10 phút) + 1 dòng nhỏ (bảng offline demo) |

- Hàng danh sách: `nodes/ranking/rank_row.tscn` + `scripts/nodes/ranking/rank_row.gd` — `setup(entry, board)`; bố cục `#hạng (x=40) · cờ (x=96) · tên (x=152) · kỷ lục (phải, x=600) · điểm (phải, x=600)`; hàng của người chơi tự đổi sang art `rank_row_you.svg` (nền xanh nhạt).
- Theme variations mới: `RankTabLabel` · `RankRowIndex/Name/Record/Points` · `RankPodiumRank{Gold,Silver,Bronze}` · `RankPodiumPoints{Gold,Silver,Bronze}` · `RankPodiumName/Record` · `RankMyRank/Name/Sub/Record/Value` · `RankChip` · `RankFooter` · `RankFooterNote`.
- Chuỗi dịch mới nằm ở `resources/localization/string_extra.csv` (id,en,vi): `STR_RANK_TITLE`, `STR_RANK_SCOPE`, `STR_RANK_TAB_*`, `STR_RANK_RECORD_*`, `STR_RANK_POINTS`, `STR_RANK_YOU`, `STR_RANK_SUBTITLE`, `STR_RANK_NO_RECORD(_SHORT)`, `STR_RANK_FOOTER`, `STR_RANK_DEMO`.

### 11.4. File liên quan

| File | Vai trò |
|---|---|
| `scripts/manager/RankingManager.gd` | Autoload `RankingManager`: dựng 3 bảng · sắp hạng · cửa sổ làm mới 10 phút · `board_ids/entries/podium/rest/my_entry/my_rank/last_refresh_unix/refresh(force)` · signal `ranking_changed(board)` |
| `scripts/utils/ranking.gd` | Facade tĩnh `Ranking` (test-safe) + định dạng dùng chung: `display_name`, `record_text`, `points_text`, `rank_text`, `thousands` |
| `scenes/ranking.tscn` + `scripts/scenes/ranking.gd` | Màn hình (`class_name RankingScene`): 3 tab dựng bằng code · đổ bục · đổ danh sách · thanh hạng của bạn · Back → Main |
| `nodes/ranking/rank_row.tscn` + `scripts/nodes/ranking/rank_row.gd` | Component 1 hàng 755×90 (`class_name RankRow`, có cache texture cờ) |
| `assets/images/ranking/*.svg` | `rank_sheet` · `tab_active`/`tab_normal` · `medal_gold`/`silver`/`bronze` · `podium_gold`/`silver`/`bronze` · `rank_row` · `rank_row_you` · `my_rank_bar` · `chip_scope` |
| `scripts/test_case/test_ranking.gd` | 84 check: API dữ liệu · sắp hạng · người chơi · ổn định seed · cửa sổ làm mới · định dạng · scene (3 tab · bục · danh sách · thanh đáy · đổi tab) |

**Khác biệt so với mockup (có chủ đích):**

1. Chip góc phải ghi **"MÁY NÀY"** (`STR_RANK_SCOPE`) thay vì "TOÀN CẦU" — bảng hiện là offline/demo, khi nối Google Play sẽ đổi nhãn.
2. **Không dùng emoji** (👑🏆) trong UI thật — icon lấy từ `assets/images/` (quy ước chung của dự án); vương miện cạnh tên top 1 trong mockup được thay bằng huy chương vàng + bục vàng.
3. Bỏ dòng **"• • •"** vì danh sách đã **cuộn được** tới hạng 25 (giữ nguyên tinh thần "còn nữa" của mockup).
4. Chân trang thêm 1 dòng nhỏ ghi rõ **bảng ngoại tuyến (demo) — đối thủ là dữ liệu mô phỏng** để không gây hiểu nhầm là bảng online thật.


