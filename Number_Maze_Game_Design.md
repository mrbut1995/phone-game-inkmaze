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
> - **HUD mặc định `LevelHUD`** (THỜI GIAN + THỬ THÁCH) dùng cho **Play Mode** và **Fog of War** (`matchup_fog_of_war.svg`). **Time Attack** (2026-09-19) có HUD riêng `time_attack_hud.tscn` — **CHỈ thẻ THỜI GIAN 250×156 đặt GIỮA khung** (đếm ngược, dòng phụ "ĐẾM NGƯỢC"), **đã bỏ thẻ THỬ THÁCH**. Countdown Cost / Fading Ink / Sum Path / Blind Memory có HUD riêng (mục 10.2b).
> - **Chất liệu HUD (từ 2026-11):** mọi thẻ là **mẩu giấy trắng trên nền vở kẻ ngang** — viền màu (xanh `#6EA0C8` / xanh đậm `#3D83AE` / đỏ `#D84444`) + lề sổ tay cùng màu + **dòng kẻ ngang** `#9FC0D6` (opacity 0.5) như trang vở. Art dùng cho các HUD mới: `card_time_slip.svg` (250×138), `card_bomb.svg` (440×158), `card_sum.svg` (440×158), `card_op.svg` (112×112).
> - Tiêu đề game: Dungeon = `DUNGEON MODE` (một dòng, số tầng đã chuyển xuống thẻ TẦNG); Play Mode = dòng phụ đỏ `PLAY MODE · CHƯƠNG n` + dòng lớn `MÀN xx`.

> **Kiến trúc HUD (tách thành scene theo chế độ):** khung **Information** trong `scenes/game.tscn` không còn chứa sẵn mọi thẻ — mỗi chế độ có 1 scene HUD riêng, tất cả đều kế thừa `nodes/hud/base.tscn` (khung 980×249 tại `(50,175)`, script `scripts/nodes/hud/base.gd`):
> - `nodes/hud/level_mode.tscn` → `LevelHUD` — thẻ **THỬ THÁCH** + **THỜI GIAN** (Play Mode và các bộ luật không có thẻ riêng).
> - `nodes/hud/time_attack_hud.tscn` → `TimeAttackHUD` — **CHỈ thẻ THỜI GIAN phóng to GIỮA khung** (anchors tỉ lệ `0.352..0.648 × 0.085..0.911` của khung 980×249 ≈ 291×206 — số tự co theo thẻ), đếm ngược, dòng phụ `STR_HUD_TIME_COUNTDOWN` (2026-09-19).
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
| **HUD** | `nodes/hud/time_attack_hud.tscn` (`TimeAttackHUD`) — **CHỈ thẻ THỜI GIAN phóng to GIỮA khung** (anchors tỉ lệ, ≈291×206 — đếm ngược + dòng phụ "ĐẾM NGƯỢC", số tự co), **KHÔNG có thẻ THỬ THÁCH** (2026-09-19) · mockup `mockup/matchup_time_attack.svg` (đã sinh lại theo HUD này) |
| **Chi tiết** | ✨ **⏱ Time Attack Maze** — Giới hạn thời gian tổng (60s/90s/120s) đếm ngược, không giới hạn số bước. Đâm tường về S mất thời gian. Hết giờ = Game Over. HUD chỉ để **đồng hồ đếm ngược ở giữa** cho tập trung; 3 Thử thách vẫn được chấm và hiện đầy đủ ở popup kết quả. |

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
| **HUD** | `nodes/hud/sum_path_hud.tscn` (`SumPathHUD`) — **thiết kế mới 2026-02**: **THỜI GIAN** (250×156) + thẻ **CÂN BẰNG TỔNG ĐIỂM ĐƯỜNG ĐI** (715×156) gồm **TỔNG HIỆN TẠI — con dấu TOÁN TỬ — MỤC TIÊU PHẢI ĐẠT** + thanh tiến độ + chip trạng thái (**KHÔNG có thẻ THỬ THÁCH** — thử thách chốt ở popup kết quả) · mockup `mockup/matchup_sum_path.svg` |
| **Chi tiết** | ✨ **➕ Sum Path** — Không có tường. Số trên ô là điểm (1..9). Thắng khi tới F với tổng điểm thỏa `SUM < / > / = Target`. Mỗi ô chỉ tính điểm 1 lần. Luôn đảm bảo tồn tại ít nhất 1 nghiệm đúng. **HUD hiện 3 thẻ theo đúng thứ tự `TỔNG HIỆN TẠI — TOÁN TỬ — MỤC TIÊU`** (thẻ TOÁN TỬ nhỏ 112×112 nằm chính giữa, đè lên mép 2 thẻ kia; MỤC TIÊU chỉ hiện con số) thay cho panel MISSION cũ. **Không còn thắng được nữa** (tổng đã VƯỢT mục tiêu trong khi điều kiện là `<` hoặc `=` — đi thêm chỉ tăng điểm) → nút **CHƠI LẠI** tự hiện **DƯỚI hai nút Vẽ Đường / Ghi Nhớ** (2026-09-19); người chơi vẫn có thể **Undo** để lùi bước — tổng tính lại theo đường đã đi nên nút tự ẩn khi tổng về dưới mức chết. |

### 5.8. ⏳ Countdown Cost

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = countdown_cost` |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 (xem bảng chi phí/ngân sách bên dưới) |
| **Số trên ô** | **CHI PHÍ BƯỚC** khi bước vào ô đó (mọi ô trừ S/F đều có số ≥ 1) |
| **Di chuyển** | 4 hướng · bước vào ô nào trừ đúng chi phí ô đó · đâm tường về S và trừ chi phí ô đích |
| **Thắng** | Tới F trong ngân sách (ngân sách = đường rẻ nhất + dự phòng ⇒ luôn thắng được nếu chọn đường rẻ) |
| **Thua** | **Hết bước** |
| **HUD** | `nodes/hud/countdown_hud.tscn` (`CountdownHUD`) — **thiết kế mới 2026-02**: **THỜI GIAN** (250×156) + **SỔ THEO DÕI NGÂN SÁCH BƯỚC CHÂN** (715×156) gồm **NGÂN SÁCH CÒN** (`còn/tổng`) · **ĐÃ TIÊU TỐN** (`-N BƯỚC` + số ô đã đi) · **GIÁ CƯỚC MỖI Ô** (chip RẺ/ĐẮT theo độ khó + dự phòng) + **dải phân đoạn** (mỗi đoạn = 1 bước) — **KHÔNG có thẻ THỬ THÁCH** · mockup `mockup/matchup_countdown_cost.svg` |
| **Chi tiết** | ✨ **⏳ Countdown Cost** — **Số trên ô = CHI PHÍ BƯỚC khi bước vào ô đó**, hoàn toàn **không liên quan tới số tường quanh ô** (khác Play / Dungeon / Fog of War). Mọi ô trừ S/F đều có số ≥ 1 và luôn hiện số. Bước vào ô nào thì trừ đúng chi phí của ô đó; đâm tường: về S và trừ chi phí của ô đích vừa đâm vào. Ngân sách bước được tính đủ cho **đường đi rẻ nhất + khoảng dự phòng**, nên màn luôn thắng được nếu chọn đúng đường ít tốn kém; đi lệch qua các ô đắt sẽ hết bước. **Hết ngân sách (0 bước còn lại) thì KHOÁ DI CHUYỂN** — người chơi phải bấm **UNDO** (nút được NHẤN MẠNH: ám vàng + nhịp phồng) để hoàn lại **đúng chi phí bước vừa đi** rồi mới đi tiếp (2026-09-19). |

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
| **Di chuyển** | 4 hướng · **chỉ đi vào ô còn mực**; ô hết mực bị chặn (không mất bước), mất số và hiện **lớp gạch + huy hiệu CẠN**; ô còn đúng **1 mực** hiện **lớp SẮP PHAI** (nền hổ phách + chữ cảnh báo) |
| **Thắng** | Tới F trước khi mực phai hết — phải đi **đường ngắn nhất** |
| **Thua** | **Hết lối đi mà chưa tới F** → popup thua tiêu đề riêng `HẾT ĐƯỜNG ĐI!` (`STR_GAME_OVER_NO_PATH`) |
| **Hồi sinh** | Quay lại bước trước đó — **mực hồi lại** đúng 1 điểm cho mọi ô |
| **HUD** | `nodes/hud/fading_ink_hud.tscn` (`FadingInkHUD`) — **thiết kế mới 2026-02**: **THỜI GIAN** (250×156) + **TRẠM ĐO ĐỘ PHAI MỰC** (715×156) gồm **BƯỚC ĐÃ ĐI** (`N` + `-N MỰC`) · **QUANG PHỔ ĐẬM NHẠT CỦA MỰC** (4 mức) · cảnh báo **N Ô ĐÃ CẠN MỰC** (ẩn khi chưa có ô nào cạn) — **KHÔNG có thẻ THỬ THÁCH** · mockup `mockup/matchup_fading_ink.svg` |
| **Chi tiết** | * **💧 Fading Ink (Mực Phai)** — *(thay cho Area Maze — đã BỎ từ 2026-11)* **Không có tường trong bàn.** Con số trên ô **KHÔNG phải số tường** mà là **MỰC của riêng ô đó** (mực ban đầu 2..9). **Người chơi chỉ được đi vào ô còn mực**; ô đã phai hết mực coi như ô trống — không đi vào được (bị chặn, KHÔNG mất bước, ô đó mất số và hiện **lớp gạch ngang + huy hiệu CẠN**). **MỖI BƯỚC ĐI làm MỌI ô trên bàn nhạt đi đúng 1 điểm mực** (không riêng ô vừa đi), nên phải tìm **đường ngắn nhất** tới F trước khi lối đi biến mất; đi vòng sẽ tự bịt đường của chính mình. Bàn luôn được sinh sao cho **đường ngắn nhất có đủ mực để tới F** (các ô trên đường đi được cấp mực theo số bước cần tới chúng, ô ngoài đường nhận mực thấp làm lối tắt dự phòng). **Đồng hồ đếm thời gian như thường**, không giới hạn số bước. **Hết lối đi mà chưa tới F = THUA** (popup thua hiện tiêu đề riêng `HẾT ĐƯỜNG ĐI!`). Nút **UNDO** lùi 1 bước thì **mực hồi lại** đúng 1 điểm cho mọi ô (trạng thái mực được tính lại từ số bước đã đi, không cần lưu lịch sử). HUD dùng bản **thiết kế mới**: thẻ **THỜI GIAN** + **TRẠM ĐO ĐỘ PHAI MỰC** (số bước đã đi · số mực đã phai · quang phổ đậm nhạt · cảnh báo ô cạn mực) — xem 10.2b. |
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

### 5.11. Con dấu · icon nút · vuốt cuộn trong popup (2026-09)

**Quy tắc vàng về art SVG:** ThorVG (bộ nhập SVG của Godot) **KHÔNG render `<text>`** → mọi chữ trong game phải là **Label node**, art chỉ vẽ hình (vòng, khung, nét). Các file `stamp_*.svg` vì vậy chỉ có vòng nét đứt, **chữ nằm ở 2 Label con của node `Stamp`**:

| Popup | StampTitle | StampSub | Khung con dấu |
|---|---|---|---|
| Thắng màn (`winning.tscn`) | `STR_WIN_STAMP_TITLE` — "{0} / {1} THỬ THÁCH" | `STR_WIN_STAMP_SUB` — "★ ĐẠT {0} SAO ★" | (622, 88) 156×90 · đỏ, chữ `PopupStampTextDanger`/`PopupStampSubDanger` |
| Thông qua tầng (`next_floor.tscn`) | `STR_RESULT_STAMP_PASSED` — "ĐÃ QUA" | `STR_RESULT_STAMP_FLOOR` — "TẦNG {0} ✔" (`"%02d"`) | (592, 47) 116×116 · xanh lục, chữ `PopupStampText`/`PopupStampSub` |

- **Icon nút CHƠI LẠI** (`winning.tscn` → `Panel/Content/ReplayBtn/TextureRect`) = `assets/images/popups/icon_replay.svg`, **cùng hình mũi tên vòng với nút Restart trên HUD** (`assets/images/game/btn_restart_*.svg`): cung `M 50 25 A 15 15 0 1 0 52 42` + mũi tên `42,20 52,24 50,34` (theo `mockup/matchup_level.svg`). Trước đây icon Restart bị vẽ **mũi tên gãy nằm lệch ngoài cung** nên trông như lỗi.
- **Popup ngôn ngữ** (`language.tscn`): nút HỦY BỎ = **180×96** và ÁP DỤNG = **390×96** (đúng mockup `popup_language.svg`) + khung nội dung rộng **600px** (`Content` offsets 110 / -70) → hàng nút 180 + 30 + 390 = 600 **vừa khít**, không tràn.
- **QUY ƯỚC ART NÚT (quan trọng):** `TextureButton` mặc định **`stretch_mode = STRETCH_KEEP (2)`** — art được vẽ **ĐÚNG kích thước gốc**, KHÔNG tự co theo node (khác `TextureRect`). Vì vậy **art nút phải khớp 1:1 với kích thước node**; nếu art to hơn thì hình **thò ra ngoài** (đã từng bị: nút 390×96 nhưng gán `btn_popup_wide_*` art **630×96** → vệt xanh thò tới mép màn hình).

| Nút popup ngôn ngữ | Art | Cỡ | Kiểu |
|---|---|---|---|
| HỦY BỎ | `popups/btn_lang_cancel_{normal,pressed,focus,disabled}.svg` | **180×96** | giấy `#FEFDFA` + viền xám `#BAC7CF` 2.5, rx 16 |
| ÁP DỤNG | `popups/btn_lang_apply_{normal,pressed,focus,disabled}.svg` | **390×96** | mực `#3D83AE` + viền `#256286` 3.5, rx 18 |

> Các popup khác đã khớp 1:1: `winning` (CHƠI LẠI 192×108 = `btn_paper_secondary_*`; MÀN KẾ TIẾP 437×108 = `btn_paper_primary_*`), `next_floor` (art 425×96 nằm trong node 437×108 — nhỏ hơn nên canh giữa, không tràn), `pause` (checkbox art 50×50 trong node 44×44 nhưng `stretch_mode = 0` nên tự co).
- **Vuốt cuộn danh sách ngôn ngữ:** hàng là `TextureButton` nên "ăn" hết sự kiện kéo → `language_popup.gd` tự xử lý kéo ở `_input` (giống màn Cửa hàng): ngưỡng 14px mới tính là vuốt, `set_input_as_handled()` khi cuộn, và **khoá bấm hàng 0.35s** sau khi vuốt để không chọn nhầm ngôn ngữ.
- **Bảng 19 ngôn ngữ** (`LocalizationManager.LOCALE_INFO`): mỗi mã trong `string.csv` phải có **tên bản địa + phụ đề tiếng Anh + cờ riêng**. Thiếu khoá ở đây thì popup sẽ hiện **mã thô** (vd "MS", "PT_BR") và cờ dự phòng `flag_generic.svg` — đúng lỗi đã gặp.

| Mã | Tên hiển thị | Phụ đề | Cờ |
|---|---|---|---|
| `en` | English | United States | `flag_en.svg` |
| `vi` | Tiếng Việt | Mặc định hệ thống | `flag_vi.svg` |
| `zh_TW` | 繁體中文 | Traditional Chinese | `flag_zh_tw.svg` |
| `zh_CN` | 简体中文 | Simplified Chinese | `flag_zh_cn.svg` |
| `es` | Español | Spanish | `flag_es.svg` |
| `ar` | العربية | Arabic | `flag_ar.svg` |
| `de` | Deutsch | German | `flag_de.svg` |
| `fr` | Français | French | `flag_fr.svg` |
| `hi` | हिन्दी | Hindi | `flag_hi.svg` |
| `id` | Bahasa Indonesia | Indonesian | `flag_id.svg` |
| `it` | Italiano | Italian | `flag_it.svg` |
| `ja` | 日本語 | Japanese | `flag_ja.svg` |
| `ko` | 한국어 | Korean | `flag_ko.svg` |
| `ms` | Bahasa Melayu | Malay | `flag_ms.svg` |
| `pt` | Português | Portuguese | `flag_pt.svg` |
| `pt_BR` | Português (Brasil) | Brazilian Portuguese | `flag_pt_br.svg` |
| `ru` | Русский | Russian | `flag_ru.svg` |
| `th` | ไทย | Thai | `flag_th.svg` |
| `tr` | Türkçe | Turkish | `flag_tr.svg` |

- Cờ dùng chung khuôn: viewBox **38×28**, nền bo góc `rx=3` + viền `#224C6D` 1.8; các dải màu vẽ bằng path bo góc theo viền (không dùng `<clipPath>`). Còn `flag_generic.svg` (quả cầu nét đứt) chỉ là dự phòng.
- **Logo `main/logo_doodle_maze.svg`**: chữ **S** (điểm bắt đầu, xanh) và **F** (đích, hổ phách) đã đổi từ `<text>` sang **path vẽ tay** — trước đây biến mất trong game vì ThorVG bỏ qua `<text>`.
- Kiểm thử: `scripts/test_case/test_popup_ui.gd` (**54 check**) — icon Restart 4 trạng thái · con dấu 2 popup (kích thước + chữ đúng dữ liệu) · icon nút CHƠI LẠI căn giữa · popup ngôn ngữ (đủ hàng, hàng nút không tràn, **art nút khớp 1:1**, vuốt cuộn được, không chọn nhầm khi vừa vuốt) · quét art còn `<text>` · bảng 19 ngôn ngữ (tên + cờ riêng, không dùng cờ generic).

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
| Time Attack Maze | `time_attack` | `nodes/hud/time_attack_hud.tscn` (TimeAttackHUD) | `mockup/matchup_time_attack.svg` | **CHỈ THỜI GIAN** (đếm ngược, đặt giữa khung — 2026-09-19) |
| Minesweeper Maze | `minesweeper` | `nodes/hud/minesweep_hud.tscn` (MinesweepHUD) | `mockup/matchup_minesweeper.svg` | THỜI GIAN + BOM CÒN LẠI |
| Blind Memory Maze | `blind_memory` | `nodes/hud/blind_memory_hud.tscn` (BlindMemoryHUD) | `mockup/matchup_blind_memory.svg` | THỜI GIAN + GHI NHỚ VỊ TRÍ TƯỜNG (+ popup đếm ngược) |
| Fog of War Maze | `fog_of_war` | `nodes/hud/level_mode.tscn` | `mockup/matchup_fog_of_war.svg` | THỜI GIAN + THỬ THÁCH |
| Sum Path | `sum_path` | `nodes/hud/sum_path_hud.tscn` (SumPathHUD) | `mockup/matchup_sum_path.svg` | THỜI GIAN + CÂN BẰNG TỔNG ĐIỂM (TỔNG — TOÁN TỬ — MỤC TIÊU + tiến độ) |
| Countdown Cost | `countdown_cost` | `nodes/hud/countdown_hud.tscn` (CountdownHUD) | `mockup/matchup_countdown_cost.svg` | THỜI GIAN + SỔ NGÂN SÁCH BƯỚC CHÂN |
| Fading Ink | `fading_ink` | `nodes/hud/fading_ink_hud.tscn` (FadingInkHUD) | `mockup/matchup_fading_ink.svg` | THỜI GIAN + TRẠM ĐO ĐỘ PHAI MỰC |

> 2 chế độ (`time_attack`, `fog_of_war`) **dùng chung `LevelHUD`** nên mockup của chúng chỉ khác phần bàn cờ + chú thích luật; `matchup_level.svg` (Play) vẫn là mockup gốc cho layout này. **3 chế độ `sum_path` · `countdown_cost` · `fading_ink` đã chuyển sang HUD thiết kế mới (2026-02)** — mỗi chế độ 1 scene HUD riêng, không còn dùng `LevelHUD` và **không hiện thẻ THỬ THÁCH trên HUD** (thử thách/Sao vẫn được tính đủ và hiện ở popup thắng/thua).

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

### 10.2b. HUD thiết kế mới — Sum Path · Countdown Cost · Fading Ink (2026-02)

3 chế độ này dùng **cùng một khung HUD mới**: 2 thẻ cao **156px** đặt tại `y = 178` trong khung `Information` `(50,175)-(1030,424)` (thẻ thời gian ở trái, thẻ chế độ rộng 715 ở phải).

| Thẻ | Kích thước | Vị trí (trong khung) | Art | Nội dung động |
|---|---|---|---|---|
| **THỜI GIAN** | 250 × 156 | (0, 3) | `card_time_tall.svg` | `Time/Value` + dòng phụ theo chế độ (`STR_HUD_TIME_SUPPORT` “Phụ trợ xếp hạng” · `STR_HUD_TIME_FREE` “Không giới hạn”) |
| **SỔ NGÂN SÁCH BƯỚC CHÂN** | 715 × 156 | (265, 3) | `card_budget_sheet.svg` + `chip_price_cheap/pricey.svg` + `budget_segment_on/off.svg` | NGÂN SÁCH CÒN `còn/tổng` · ĐÃ TIÊU TỐN `-N` (+ số ô đã đi) · GIÁ CƯỚC MỖI Ô (chip RẺ/ĐẮT theo độ khó + dự phòng) · **dải phân đoạn** (`CountdownHUD`) |
| **TRẠM ĐO ĐỘ PHAI MỰC** | 715 × 156 | (265, 3) | `card_ink_meter.svg` + `bar_ink_warning.svg` | BƯỚC ĐÃ ĐI (`NN` + `(-N MỰC)`) · quang phổ 4 mức · cảnh báo `N Ô ĐÃ CẠN MỰC` (tự ẩn khi chưa có ô nào cạn) (`FadingInkHUD`) |
| **CÂN BẰNG TỔNG ĐIỂM ĐƯỜNG ĐI** | 715 × 156 | (265, 3) | `card_sum_balance.svg` + `bar_sum_fill.svg` + `bar_sum_ticks.svg` | TỔNG HIỆN TẠI (+ số ô) · con dấu TOÁN TỬ `< > =` · MỤC TIÊU · chip `CẦN THÊM / CÒN ĐƯỢC / ĐANG VƯỢT / ĐÃ ĐỦ` · thanh tiến độ (`SumPathHUD`) |

- Cả 3 thẻ đều theo ngôn ngữ **sổ tay**: viền màu theo chế độ (cam `#C2410C` · mực `#1D4E72` · xanh `#3D83AE`), lề dọc, dòng kẻ ô ly mờ; số liệu dùng theme variation `Hud*` trong `theme_text.tres`.
- **Dải phân đoạn ngân sách**: mỗi bước = 1 phân đoạn (đã dùng = xám `#E2E8F0`, còn lại = cam `#EA580C`); bề rộng phân đoạn **tự co** để cả dải luôn vừa 654px khi ngân sách > 16 bước.
- 3 chế độ này **không hiện thẻ THỬ THÁCH** trên HUD (thử thách/Sao vẫn tính đủ, hiện ở popup kết quả) — thay hẳn bố cục cũ `THỜI GIAN 250×138 + THỬ THÁCH 720×246`; các chế độ còn lại vẫn dùng bảng 10.2.
- **Time Attack (2026-09-19)** — biến thể của khung này: `nodes/hud/time_attack_hud.tscn` (`TimeAttackHUD`) **CHỈ 1 thẻ THỜI GIAN phóng to đặt GIỮA khung** — thẻ dùng **anchors tỉ lệ** (`0.352..0.648 × 0.085..0.911`) nên ≈291×206 tại tâm khung, số dùng `resize_font_to_fit` tự co; dòng phụ `STR_HUD_TIME_COUNTDOWN` “Đếm ngược”; không có thẻ Thử thách. Mockup `mockup/matchup_time_attack.svg` sinh lại theo đúng HUD này (bỏ thẻ THỬ THÁCH khỏi mockup).

### 10.2c. Panel HƯỚNG DẪN LUẬT CHƠI (Hint Guide)

| Thành phần | Vị trí | Ghi chú |
|---|---|---|
| `HintGuide` (`Control`) trong `scenes/game.tscn` | (50, 1424) 980×90 | nằm **dưới mép giấy bàn cờ** (~1414) và **trên thanh nút** (1528); khai báo `index="6"` để vẫn nằm dưới `Popups` |
| `Bg` | full thẻ | `assets/images/game/panel_hint_guide.svg` (giấy + viền `#6EA0C8` + lề đỏ) |
| `Icon` | (46, 23) 44×44 | `assets/images/icons/icon_bulb.svg` — bóng đèn nét cam (**không dùng emoji 💡**) |
| `Text` | (106, 0) 844×90 | 1 dòng · variation `HintGuideText` (22px Be Vietnam Pro ExtraBold `#244E6E`) |

- Nội dung đổi theo chế độ: `scripts/nodes/game/hint_guide.gd` → `HintGuide.show_mode()` tra khoá `STR_HINT_<MODE_ID>` (9 chế độ, `string_extra.csv`); chế độ chưa có khoá thì fallback `BaseGameMode.mode_description`. `GameScene.switch_mode()` gọi `_refresh_hint_guide()` mỗi lần đổi chế độ.
- Chuỗi gợi ý phải **vừa đúng 1 dòng** trong 844px — test `scripts/test_case/test_hud_modes.gd` đo bằng **font thật của theme** (không đếm ký tự).

### 10.2d. Popup HƯỚNG DẪN theo từng chế độ (2026-09)

Nút **"?"** trên HUD mở popup hướng dẫn **riêng cho chế độ đang chơi** — 9 scene độc lập dựng đúng theo bộ mockup `mockup/instruction/*.svg`; mỗi popup 3 trang (P1 quy tắc cơ bản · P2 cơ chế phụ · P3 bí quyết).

| Chế độ | Scene (đều là instance của `base.tscn`) |
|---|---|
| Play · Daily Classic | `normal_maze.tscn` |
| Dungeon | `dungeon.tscn` |
| Minesweeper | `minesweeper.tscn` |
| Sum Path | `sumpath.tscn` |
| Countdown Cost | `countdowncost.tscn` |
| Blind Memory | `blindmemory.tscn` |
| Fog of War | `fog_of_war.tscn` |
| Fading Ink | `fadingink.tscn` |
| Time Attack | `time_attack.tscn` |

- **Bố cục mỗi scene** (toạ độ "paper-local" của tờ giấy 920×1480, Panel override về (80,200)–(1000,1680)): chrome **DÙNG CHUNG cho cả 3 trang** nằm trực tiếp trong `Guide`: `Washi` (350,-22) · `Paper` viền accent 3.5px rx26 · `PaperDetail` (`guide_paper_detail.svg`) · `Close` 56×56 (830,24) · `Chip` 190×30 (110,48) + chữ 13px · `Tabs/Tab1..3` 245×48 (y=142, x=105/360/615) kèm vòng số vẽ bằng node · `Prev`/`Next` ‹ › 52×52 (105/305, y=1100 — trạng thái khoá **nướng sẵn**: prev mờ xanh `#224C6D/#6EA0C8`, next mờ xám `#718B9E/#BACEDC` như mockup) · `Dots/Dot1..3` · `Index` "TRANG x / 3" canh phải x=860. Phần **NỘI DUNG riêng từng trang** nằm trong `Pages/Page1..3`: ảnh minh hoạ `Img` tại (90,200) 785×535 (viewBox `-15 -10 785 535` khớp khung 755×510 tại (105,210)) · các Label chữ trên ảnh · `Title` 38px Black baseline (110,118) · `Mục` 16px baseline 779 · 3 hàng luật `Row1..3` 755×76 (y=797/885/973, vòng số r16, chữ 18/16px) · `Cta` 755×100 (105,1180) · `Link` 18px ~1322. **Cta/Link để trong từng trang** vì mockup vẽ khác nhau mỗi trang (trang cuối CTA đậm hơn, link "bỏ qua" khác "xem lại").
- **Số/ký hiệu trên grid ghi TRỰC TIẾP** khỏi khoá dịch: chuỗi không có chữ cái (1 · 2 · 15 · 04 · 01:24 · = · ? · < · >) + `S`/`F` nướng thẳng vào Label (`is_literal_text()` trong `tools/mockup/instruction_mockup.py`) — chỉ chữ có nghĩa mới dùng khoá `STR_GI_*`.
- **Tab & dots dùng chung** đổi trạng thái bằng script qua `@export` (generator nướng 2 bộ StyleBoxFlat + màu chữ vào root scene): tab đang chọn = accent + chữ/vòng trắng, tab thường = `#F0F7FB` viền `#BACEDC` chữ `#718B9E`; dot đang chọn = viên thuốc 38×18 accent, dot thường = chấm tròn 16×16 `#D1E2ED` — hàng dots canh trái từ mép dot đầu (x=185, cách nhau 12px), script dàn lại vị trí theo trang (khớp mockup cả 3 trang, generator tự cảnh báo nếu lệch > 2.5px).
- **Hành vi** — `scripts/nodes/popups/instruction_popup.gd` (class `InstructionPopup`, chỉ lo logic, KHÔNG sinh nội dung): vuốt ngang (ngưỡng 14px/quãng 90px) · lăn chuột · phím ←→ · bấm tab/dots để nhảy trang · đổi trang thì script cập nhật: style tab đang chọn · `Prev` khoá ở trang 1 & `Next` khoá ở trang 3 · dàn lại dots · format `Index` từ `STR_GI_PAGE_INDEX` · **nút X (`Close` 56×56) = đóng popup** · CTA trang cuối = đóng popup · link trang cuối = về trang 1, link các trang trước = bỏ qua (đóng) · sfx `BTN_WOOD_TAP`/`PAGE_TURN`/`BTN_CLICK`.
  - **GOTCHA đã sửa (2026-09-19):** `Close` là **`TextureButton`** — `TextureButton` kế thừa **`BaseButton`** chứ KHÔNG phải `Button`, nên cast cũ `get_node(...) as Button` trả về **null** → nút X không bao giờ được nối signal (bấm không đóng). Đã đổi `close_button() -> BaseButton`.
- **Ảnh minh hoạ ThorVG-safe**: Godot/ThorVG **không vẽ** `<text>`/`<use>` — `tools/mockup/prepare_guideline_images.py` nhúng cầu thang `<use>` và chuyển số/ký hiệu (✓, ➔→•) thành **path glyph thật** (Be Vietnam Pro Black + fallback Noto Sans JP); ảnh gốc sao lưu ở `mockup/instruction/_extracted_source/`. Chữ ①②③ trên tab thay bằng **vòng số vẽ bằng node** (font game không có các glyph này).
- **Chuỗi dịch**: chữ có nghĩa dùng khoá `STR_GI_*` (vi = đúng chữ trong mockup, en = `tools/content/guide_text_en.py`): chrome theo trang `STR_GI_<MODE>_P<n>_TITLE/SECTION/CTA/LINK/TAB#/R#T/R#D`, chip `STR_GI_<MODE>_CHIP`, chữ trên ảnh dedupe `STR_GI_X###`, nhãn trang `STR_GI_PAGE_INDEX`. Sinh khoá + ghi CSV: `tools/content/build_instruction_data.py` (kèm `tools/content/_guide_keys.json` cho generator scene) — bỏ qua token số/ký hiệu.
- **Sinh scene**: `tools/mockup/gen_instruction_popups.py` — đọc mockup qua `tools/mockup/instruction_mockup.py` (toạ độ tuyệt đối + style kế thừa), nướng thẳng mọi Label/Button/StyleBoxFlat vào `.tscn`, giữ nguyên uid + `unique_id` của scene placeholder cũ.
- **Nối dây**: `GameController.INSTRUCTION_SCENES` (play/daily_classic → `normal_maze`, fallback `normal_maze`) → `Popups.open_path("res://nodes/popups/instruction/<mode>.tscn")`; đồng hồ đứng trong lúc xem hướng dẫn, đóng popup thì chạy lại. Đã gỡ `"instruction"` khỏi `PopupManager.POPUPS` và xoá bộ file cũ (`nodes/popups/instruction.tscn`, `scripts/nodes/popups/instruction.gd`, `scripts/utils/instruction.gd`).
- **Kiểm thử**: `scripts/test_case/test_instruction.gd` — 294 check: bảng mode→scene · đủ khoá dịch vi+en quét từ file `.tscn` · cấu trúc 3 trang · chrome dùng chung không lặp trong từng trang · số/ký hiệu ghi trực tiếp · tab/dots/nav hoạt động · **nút X đóng popup** · CTA/link đúng hành vi · tích hợp nút "?" mở đúng scene (dungeon/play/time_attack).

### 10.3. Sinh lại mockup

```bash
python tools/mockup/gen_matchup.py            # sinh lại 7 mockup matchup_<mode>.svg
python tools/mockup/gen_matchup.py --list     # danh sách mode sẽ sinh
python tools/mockup/gen_matchup.py --dump     # in toạ độ node thật của các scene HUD
```

- Tool đọc **toạ độ thật** từ `nodes/hud/*.tscn` + `scenes/game.tscn` (Board `(41,420)-(1061,1440)`, thanh nút `(73,1528)-(1031,1688)`, Status `(50,85)`).
- Hằng `HAND_DRAWN` trong tool liệt kê **5 mockup art tay của user** (`matchup_level` · `matchup_dungeon` · `matchup_sum_path` · `matchup_countdown_cost` · `matchup_fading_ink`) → chạy tool sẽ **BO QUA** 5 file này, chỉ sinh lại 4 mockup còn lại (time_attack · minesweeper · blind_memory · fog_of_war). Riêng **time_attack** sinh theo HUD mới (chỉ thẻ THỜI GIAN đặt giữa — 2026-09-19).
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
| Danh sách cuộn | (95, 545) 755×770 | `ScrollContainer` ẩn thanh cuộn (`vertical_scroll_mode = 3`), VBox cách 15px — **vuốt dọc để cuộn** (2026-09-19) |
| Thanh "hạng của bạn" | (95, 1330) 755×110 | nền `#3D83AE` viền `#256286`, hạng màu `#FBBF24` |
| Ghi chú chân trang | y = 1480 / 1516 | 1 dòng nghiêng (làm mới 10 phút) + 1 dòng nhỏ (bảng offline demo) |

- Hàng danh sách: `nodes/ranking/rank_row.tscn` + `scripts/nodes/ranking/rank_row.gd` — `setup(entry, board)`; bố cục `#hạng (x=40) · cờ (x=96) · tên (x=152) · kỷ lục (phải, x=600) · điểm (phải, x=600)`; hàng của người chơi tự đổi sang art `rank_row_you.svg` (nền xanh nhạt).
- **Vuốt/cuộn danh sách (2026-09-19):** hàng xếp hạng là `Control` (mouse_filter STOP) nên "ăn" hết sự kiện kéo → `ScrollContainer` không tự cuộn được. `ranking.gd` tự xử lý ở `_input` (chạy TRƯỚC GUI): ngưỡng **14px** mới tính là vuốt (trục dọc → `scroll_vertical = int(_drag_scroll − delta.y)`), `set_input_as_handled()` khi cuộn; kéo bắt đầu **ngoài** vùng cuộn thì bỏ qua; đổi tab reset `scroll_vertical = 0`.
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
| `scripts/test_case/test_ranking.gd` | 95 check: API dữ liệu · sắp hạng · người chơi · ổn định seed · cửa sổ làm mới · định dạng · scene (3 tab · bục · danh sách · thanh đáy · đổi tab · **vuốt dọc cuộn được, kéo ngắn/kéo ngoài vùng không cuộn**) |

**Khác biệt so với mockup (có chủ đích):**

1. Chip góc phải ghi **"MÁY NÀY"** (`STR_RANK_SCOPE`) thay vì "TOÀN CẦU" — bảng hiện là offline/demo, khi nối Google Play sẽ đổi nhãn.
2. **Không dùng emoji** (👑🏆) trong UI thật — icon lấy từ `assets/images/` (quy ước chung của dự án); vương miện cạnh tên top 1 trong mockup được thay bằng huy chương vàng + bục vàng.
3. Bỏ dòng **"• • •"** vì danh sách đã **cuộn được** tới hạng 25 (giữ nguyên tinh thần "còn nữa" của mockup).
4. Chân trang thêm 1 dòng nhỏ ghi rõ **bảng ngoại tuyến (demo) — đối thủ là dữ liệu mô phỏng** để không gây hiểu nhầm là bảng online thật.

---

## 12. Màn CHỌN CHƯƠNG (Chapter Selection)

Thêm 2026-02 (tinh chỉnh 2026-09-15). Mockup: `mockup/chapter_selection.svg`. Luồng màn hình:

```
Main ──[CHƠI]──▶ Chọn màn ──[bấm BANNER chương ở trên]──▶ CHỌN CHƯƠNG
                    ▲                                          │
                    └──────[VÀO CHƠI / bấm thẻ / Back]─────────┘
```

- Màn **Chọn màn** là màn chính khi bấm CHƠI (vào thẳng, không qua Chọn Chương).
- Bấm **bất kỳ chỗ nào trên banner chương** ở màn Chọn màn → màn Chọn Chương (không bắt bấm đúng chữ "ĐỔI CHƯƠNG").
- Back ở màn Chọn Chương → Chọn màn; Back ở màn Chọn màn → Main.

### 12.1. Dữ liệu: `ChapterData` + quan hệ với `LevelData`

- Mỗi chương = **1 file `resources/chapters/chapter_<id>.tres`** (`script_class="ChapterData"`, schema `scripts/resources/chapter_data.gd`): `chapter_id` · `title` · `subtitle` · `size_label` (rỗng = ẩn chip) · `star_cost` (0 = mở sẵn).
- **Quan hệ là NGƯỢC:** `LevelData.chapter` (int) trỏ tới chương của màn — "thêm màn vào chương" = ghi `chapter = N` cho file màn đó (nhờ vậy màn chỉ thuộc **đúng 1** chương, không sợ danh sách chương lệch dữ liệu).
- `ChapterData.icon` = **tên icon riêng của chương** (`intro` · `logic` · `trap` · `master` — rỗng thì UI tự chọn theo số chương, ngoài phạm vi thì fallback theo cỡ bàn). Icon thật nằm ở `assets/images/chapters/icon_<tên>.svg`, mỗi chương một doodle mê cung khác nhau:

| Chương | Icon | Hình |
|---|---|---|
| 1 · NHẬP MÔN | `icon_intro` | lưới 3×3 + đường chữ L đơn giản |
| 2 · SUY LUẬN | `icon_logic` | lưới 5×5 + đường zigzag nhiều khúc |
| 3 · BẪY ẨN | `icon_trap` | lưới 7×7 + 2 dấu X nét đứt (bẫy) |
| 4 · BẬC THẦY | `icon_master` | lưới 9×9 + đường xoắn dài + ngôi sao |
| ≥ 5 / chưa đặt | `maze_small`/`medium`/`large` | theo cỡ bàn lớn nhất của chương |
- 4 chương hiện có: 1 · **NHẬP MÔN** (3×3–5×5, mở sẵn, 9 màn) · 2 · **SUY LUẬN** (4×4–11×11, 25 sao, 5 màn) · 3 · **BẪY ẨN** (8×8, 45 sao) · 4 · **BẬC THẦY** (9×9, 70 sao).

| API `LevelManager` | Vai trò |
|---|---|
| `get_chapters()` / `get_chapter(id)` / `chapter_count()` / `has_chapter(id)` | Đọc dữ liệu chương |
| `chapter_of_level(id)` / `levels_in_chapter(id)` | Gom màn theo chương |
| `chapter_star_total(id)` · `chapter_cleared_count(id)` · `chapter_stars(id)` | Số liệu tiến độ của chương |
| `current_chapter_id()` | Chương chứa `GameManager.current_level` |

### 12.2. Bốn trạng thái thẻ chương

| Trạng thái | Điều kiện | Thẻ hiện |
|---|---|---|
| **ĐANG CHƠI** | Chương chứa màn đang chơi (`current_chapter_id()`) | Viền xanh · ruy băng "ĐANG CHƠI" · thanh Sao **trong chương** + nút **VÀO CHƠI** (`Màn n ›`) |
| **ĐÃ MỞ** | Đã mở khóa nhưng không phải chương đang chơi | Như trên, ruy băng "ĐÃ MỞ" || **ĐÃ ĐỦ ĐIỀU KIỆN** | Chưa mở + `total_stars >= star_cost` | Viền hổ phách + hào quang nét đứt · chip "✓ ĐÃ ĐỦ: `có` / `cần` SAO" · nút **MỞ KHÓA** (nền hổ phách, icon Sao) |
| **ĐANG KHÓA** | Chưa mở + thiếu Sao | Giấy xám + ổ khóa trên doodle · thanh tiến độ **mở khóa** (`total / cost`) · chip đỏ "CÒN THIẾU n SAO" · nút xám "CẦN n SAO · Chưa đủ sao" |
| **SẮP RA MẮT** | Đã mở nhưng chương **chưa có màn nào** | Nút xám "SẮP RA MẮT" |

Doodle icon mê cung (nhỏ/vừa/lớn theo bàn lớn nhất của chương) là art **trắng** rồi `modulate` theo trạng thái: `#3D83AE` (đang chơi) · `#C4843A` (đủ điều kiện) · `#7A8F9B` (khóa).

### 12.3. Mở khóa bằng Sao (`GameManager`)

- `unlocked_chapters: Array[int] = [1]` (chương 1 luôn mở) + `current_chapter: int = 1`; cả hai được lưu trong save (`export_progress`/`import_progress`) và xoá khi `reset_progress()`.
- `total_stars()` = tổng Sao **toàn bộ** màn · `chapter_star_cost(id)` = `star_cost` của chương · `can_unlock_chapter(id)` · `unlock_chapter(id)` → phát signal `chapter_unlocked` + `Save.queue_save()`.
- Sao dùng để mở khóa là **tổng Sao tích lũy** (không tiêu mất) — mở chương 2 (25) xong vẫn còn nguyên Sao để tiến tới chương 3 (45).

**Khóa theo chương (chống nhảy chương):**

- `record_level_clear()` chỉ mở màn kế tiếp khi màn đó **tồn tại** *và* **chương của nó đã mở** → xong màn cuối chương 1 **không** tự mở màn 10 khi chương 2 còn khóa.
- `next_level_in_chapter(level_id)` = màn kế tiếp **trong cùng chương** (−1 nếu là màn cuối chương) · `can_play_level(level_id)` = tồn tại + chương đã mở + đã mở theo tiến trình.
- `has_unlockable_chapter()` = có chương **đủ Sao để mở** mà chưa mở (dùng cho banner focus ở màn Chọn màn).

### 12.3b. Tiếp tục sau khi thắng màn (popup kết quả)

- Nút phải của popup thắng: **"MÀN KẾ TIẾP"** khi còn màn trong cùng chương **và** chương đó đã mở; nếu đây là **màn cuối của chương** (hoặc chương kế chưa mở) thì đổi thành **"CHỌN CHƯƠNG"** và bấm sẽ mở màn Chọn Chương.
- Dữ liệu popup có thêm cờ `next_available` (do `GameController._complete_floor()` tính) — `winning.gd` đổi nhãn theo cờ này; cả hai trường hợp đều đi qua `continue_requested` → `GameController._on_continue_requested()` (đi tiếp trong chương nếu được, ngược lại `go_to_chapters()`).
- Màn **Chọn màn**: nút chân trang cũng theo cùng luật — hiện "TIẾP TỤC MÀN n" với n = **màn chưa đạt sao đầu tiên của chương**, và đổi thành **"CHỌN CHƯƠNG"** khi đã xong hết màn của chương; mở màn cũng nhảy tới trang chứa màn đó.
- **Ô đếm Sao ở màn Chọn màn** hiện `chapter_stars(current) / chapter_star_total(current)` (sao TRONG chương đang xem) — trước đây cộng Sao mọi chương nhưng chia cho tối đa 1 chương nên ra số vô lý ("30/27").
- **Banner chương có trạng thái FOCUS**: khi `has_unlockable_chapter()` → đổi art `level_selector/chapter_banner_focus.svg` (viền nét đứt hổ phách), nhấp nháy nhẹ (`UIAnim.play_pulse`) và dòng dưới đổi thành `STR_CHAPTER_UNLOCKABLE` ("Có Chương mới có thể mở khóa — bấm để xem!") với variation `LevelsChangeChapterFocus`.

### 12.4. Giao diện (đo từ scene thật)

`scenes/chapters.tscn` (script `scripts/scenes/chapters.gd`, `class_name ChaptersScene`):

| Thành phần | Vị trí | Ghi chú |
|---|---|---|
| TopBar/Back + Title | y ≈ 85 · tiêu đề giữa | "CHỌN CHƯƠNG" (`STR_CHAPTER_SCREEN_TITLE`) |
| Ví Sao | (775, 90) 250×70 | `wallet_chip.svg` + icon Sao + số Sao + "SAO CÓ" |
| Băng hướng dẫn | (55, 185) 970×72 | `banner_rule.svg` + icon bóng đèn + `STR_CHAPTER_BANNER` (xuống dòng được) |
| Danh sách chương | (55, 280) 970×1310 | `ScrollContainer` ẩn thanh cuộn → `VBox` cách 30px (mỗi thẻ cao 285px) |
| Nút chân trang | (140, 1610) 800×120 | art `common/btn_paper_cta_*` + "TIẾP TỤC CHƯƠNG n (MÀN m)" |

Thẻ chương (`nodes/chapters/chapter_card.tscn`, `class_name ChapterCard`, 970×285): nền giấy · hào quang (chỉ khi đủ điều kiện) · doodle 180×180 tại (68,48) · ổ khóa 72×72 tại **(122,91)** — đặt sao cho **thân khóa trùng tâm doodle** · ruy băng (780,0) 190×48 · chip kích thước (280,44) 260×34 · tiêu đề "CHƯƠNG n: Tên" (280,80) · mô tả (280,128) · thanh Sao 380×14 (280,174) + "(x/y màn)" · chip "còn thiếu/đã đủ" · nút hành động **250×100** tại (700,88).

**Nút hành động** (250×100) có chỗ cho icon bên trái (20,32) 36×36 rồi tới tiêu đề/phụ (66→244):

| Trạng thái | Nút | Icon | Tiêu đề / phụ |
|---|---|---|---|
| ĐANG CHƠI · ĐÃ MỞ | xanh `btn_play_*` | **tam giác PLAY** | `VÀO CHƠI` / `Màn n ›` |
| ĐÃ ĐỦ ĐIỀU KIỆN | hổ phách `btn_unlock_*` | ngôi sao TRẮNG | `MỞ KHÓA` / `CẦN n SAO` |
| ĐANG KHÓA | xám `btn_locked` | ổ khóa (xám) | `CẦN n SAO` / `Chưa đủ sao` |
| SẮP RA MẮT | xám `btn_locked` | — | `SẮP RA MẮT` |

Cỡ chữ trên thẻ đã tăng cho dễ đọc: tiêu đề 40 · mô tả 22 · thanh Sao 23 · chip 17–19 · nút 24–26 · ruy băng 17 · ví Sao 40 (xem `theme_text.tres`, nhóm `Chapter*`).

Màn **Chọn màn** (`scripts/scenes/levels.gd`) nay **chỉ hiện màn của `current_chapter`** (chương rỗng → hiện tất cả để không chặn người chơi), banner trên cùng hiện "CHƯƠNG n: Tên" (30px) + dòng **ĐỔI CHƯƠNG** (24px); **bấm cả panel banner** (node `ChapterBanner`, đã nối `gui_input`) → màn Chọn Chương; nút Back → Main.

### 12.5. Asset · theme · chuỗi dịch

- `assets/images/chapters/` (25 SVG): 3 nền thẻ (`card_open`/`card_ready`/`card_locked`) · `halo_ready` · `ribbon` · `chip_size`/`chip_need`/`chip_have` · `bar_track`/`bar_fill` · `wallet_chip` · `banner_rule` · 3 nút 250×100 (`btn_play_*`, `btn_unlock_*`, `btn_locked`) · **4 icon riêng theo chương** (`icon_intro`/`logic`/`trap`/`master`) · 3 doodle theo cỡ (`maze_small`/`medium`/`large`) · `icon_star_white` · `lock_overlay`.
- Theme variations (`resources/settings/theme_text.tres`): `ChapterCardTitle(Locked)` · `ChapterCardSubtitle(Locked)` · `ChapterChipSize(Amber/Muted)` · `ChapterRibbon` · `ChapterStars(Muted/Sub)` · `ChapterNeedChip`/`ChapterHaveChip` · `ChapterAction(Sub/SubAmber/Locked/LockedSub)` · `ChapterWalletCount`/`ChapterWalletLabel` · `ChapterBannerText`.
- Chuỗi mới trong `string_extra.csv`: `STR_CHAPTER_SCREEN_TITLE` · `STR_CHAPTER_TITLE_FORMAT` · `STR_CHAPTER_RIBBON_{PLAYING,OPEN,READY,LOCKED,COMING}` · `STR_CHAPTER_SIZE_FORMAT` · `STR_CHAPTER_STARS_FORMAT` · `STR_CHAPTER_LEVELS_FORMAT` · `STR_CHAPTER_NEED_FORMAT` · `STR_CHAPTER_REQUIRE_FORMAT` · `STR_CHAPTER_HAVE_FORMAT` · `STR_CHAPTER_PLAY(_SUB)` · `STR_CHAPTER_UNLOCK` · `STR_CHAPTER_NOT_ENOUGH` · `STR_CHAPTER_STARS_HELD` · `STR_CHAPTER_BANNER` · `STR_CHAPTER_CONTINUE_FORMAT`.

### 12.6. File liên quan

| File | Vai trò |
|---|---|
| `scripts/resources/chapter_data.gd` + `resources/chapters/chapter_*.tres` | Schema + dữ liệu chương |
| `scripts/core/level_manager.gd` | Quét chương · gom màn theo chương · số liệu Sao/màn |
| `scripts/core/game_manager.gd` | `unlocked_chapters`/`current_chapter` · điều kiện + mở khóa · `total_stars`/`next_level_in_chapter`/`can_play_level`/`has_unlockable_chapter` · `go_to_chapters()` |
| `scripts/nodes/chapters/chapter_card.gd` + `nodes/chapters/chapter_card.tscn` | Thẻ chương 5 trạng thái (component) |
| `scripts/scenes/chapters.gd` + `scenes/chapters.tscn` | Màn Chọn Chương (dựng thẻ theo dữ liệu + xử lý mở khóa) |
| `scripts/scenes/levels.gd` | Lọc màn theo chương · banner chương · ĐỔI CHƯƠNG |
| `scripts/utils/nav.gd` · `scripts/manager/SceneManager.gd` | `SCENE_CHAPTERS` + `goto_chapters()` (Debug Console có mục "Select Chapter") |
| `tools/level_designer/` | Tool Python: menu **Chương** (quản lý chương + gán màn vào chương) — xem 12.7 |
| `scripts/test_case/test_chapters.gd` | **192 check**: dữ liệu chương · gom màn · mở khóa bằng Sao · lưu/tải/xoá tiến trình · 5 trạng thái thẻ · scene · lọc theo chương ở màn Chọn màn · nối dây điều hướng |

### 12.7. Tool Level Designer (Python) — hỗ trợ chương

- `app/models/chapter.py` (`ChapterModel`) · `app/services/chapter_io.py` (đọc/ghi `.tres` **cùng định dạng game**) · `app/models/chapter_repository.py` (`ChapterRepository`).
- Menu **Chương**: *Quản lý chương…* (Ctrl+Shift+C) · *Tạo chương theo dữ liệu màn* · *Gán màn đang mở vào chương…* · *Mở thư mục chapters*; thanh công cụ có nút **Chương…**.
- Hộp thoại quản lý chương (`app/views/chapter_dialog.py`): danh sách chương (số · tiêu đề · phí sao · **danh sách màn**) · sửa tiêu đề/mô tả/nhãn kích thước/phí sao/**icon** (combobox `intro · logic · trap · master`, để trống = game tự chọn) · **Chương mới** · **Tạo chương theo dữ liệu màn** · **Xoá file chương** · gán màn vào chương bằng danh sách (`1, 2, 3`) hoặc nút **Gán MÀN ĐANG MỞ** · **Gợi ý nhãn kích thước theo màn**.
- Danh sách màn ở panel trái hiện thêm cột chương (`#7  C2  5x5  Level 2-7`); màn tạo mới nằm cùng chương với màn đang mở.
- Test: `tools/level_designer/tests/test_chapters.py` + phần **CHƯƠNG** trong `python main.py --selftest` (kiểm tra luôn dữ liệu chương thật của game).

---

## 13. CỬA HÀNG (SHOP) — TIỆM VĂN PHÒNG PHẨM

### 13.1. Vai trò & lối vào

- Nút **CỬA HÀNG** ở màn Main (`Panel/Other/Shop`) → `main.gd::_on_shop_pressed()` → `Nav.goto_shop()`.
- Cửa hàng bán 4 nhóm: **ngòi bút**, **giấy vở (chủ đề)**, **dụng cụ**, **gói nạp Xu**. Mọi thứ mua bằng **Xu Mực** — dùng CHUNG một ví với Sổ tay thành tựu (`ArchivementManager.coins`), nhờ vậy Xu kiếm được khi chơi/hoàn thành nhiệm vụ đều tiêu được ở đây.
- `ShopManager` là autoload (`project.godot`) + facade tĩnh `Shop` (`scripts/utils/shop.gd`) để test/UI gọi qua `/root` mà không cần identifier autoload.

### 13.2. Bốn ngăn hàng

`ShopManager.CATEGORIES = [pen, theme, tool, coin]`; `EQUIP_CATEGORIES = [pen, theme]` (chỉ 2 nhóm này mới "mặc" được).

| Ngăn (tab) | Số món | Cách bán | Ghi chú |
|---|---|---|---|
| **BÚT & MỰC** (`pen`) | 10 | mở khoá vĩnh viễn | xếp lưới 2 cột, 4 thẻ/trang → 3 trang; chỉ 1 ngòi "đang dùng" |
| **GIẤY VỞ** (`theme`) | 8 | mở khoá vĩnh viễn | xếp lưới 2 cột, 4 thẻ/trang → 2 trang; mỗi chủ đề có `paper` + `line` (bảng màu) |
| **DỤNG CỤ** (`tool`) | 6 | **dùng theo lượt** | mua lại được (cộng dồn), mỗi món có `amount` = số lượt |
| **NẠP XU** (`coin`) | 6 | IAP (STUB) | hàng VIP “Xoá quảng cáo” trên cùng + 5 gói Xu xếp lưới 2 cột; nút ghi giá **VNĐ**; `bonus` = Xu Mực tặng thêm; mỗi gói 1 **icon cấp Xu** (`coin_t1`→`coin_t5`) |

Danh mục (giá tính bằng Xu Mực, trừ ngăn NẠP XU tính bằng VNĐ):

| id | Tên | Giá | Ghi chú |
|---|---|---|---|
| `pen_blue` | Mực Xanh Học Trò | 0 | **mặc định** (đã có sẵn) |
| `pen_purple` | Mực Tím Hoa Cà | 0 | đã mở khoá sẵn (quà tân thủ) |
| `pen_pencil_2b` | Bút Chì Gỗ 2B | 350 | hiệu ứng sột soạt |
| `pen_red_teacher` | Bút Đỏ Giáo Viên | 500 | nét chấm bài |
| `pen_highlighter` | Bút Dạ Quang | 450 | |
| `pen_gold_ink` | Mực Ánh Kim | 1200 | VIP |
| `pen_green_tea` | Mực Xanh Trà | 400 | |
| `pen_pink_diary` | Mực Hồng Nhật Ký | 380 | |
| `pen_graphite_4b` | Chì Than 4B | 600 | |
| `pen_navy_night` | Mực Đêm Xanh | 800 | |
| `theme_gride_4ly` | Vở Ô Ly 4 Ly | 0 | **mặc định** |
| `theme_blackboard` | Bảng Đen Phấn Trắng | 700 | giấy `#1E293B` · kẻ `#94A3B8` |
| `theme_campus` | Vở Kẻ Ngang Campus | 500 | |
| `theme_bullet` | Bullet Journal | 550 | |
| `theme_tech_grid` | Giấy Kẻ Toán Kỹ Thuật | 800 | |
| `theme_kraft` | Giấy Kraft Cổ Điển | 900 | |
| `theme_pastel_caro` | Caro Pastel Hàn Quốc | 1000 | |
| `theme_exam` | Tờ Giấy Thi Học Trò | 1200 | |
| `tool_undo_x10` | Gôm Tẩy 4B (x10 Lượt) | 150 | hoàn tác không bị tính lỗi |
| `tool_hint_x5` | Kính Lúp Soi Lối (x5) | 200 | |
| `tool_reveal_x3` | Bút Xoá Tường Mờ (x3) | 320 | |
| `tool_time_x3` | Đồng Hồ Cát Lật Nhanh (x3) | 280 | +30 giây |
| `tool_revive_x1` | Kẹp Giấy Giữ Mạng (x1) | 450 | |
| `tool_shield_x2` | Băng Dính Vá Giấy (x2) | 600 | |
| `coin_500` | Túi Xu 500 | 19.000 VNĐ | icon cấp 1 `coin_t1` (xu đơn) |
| `coin_2000` | Rương Xu 2,000 | 69.000 VNĐ | bonus +200 · icon cấp 2 `coin_t2` (cọc xu) |
| `coin_3500` | Hộp Bút Xu 3,500 | 99.000 VNĐ | bonus +500 · icon cấp 3 `coin_t3` (đống xu) |
| `coin_8000` | Cặp Sách Xu 8,000 | 199.000 VNĐ | bonus +1,600 · icon cấp 4 `coin_t4` (túi tiền) |
| `coin_20000` | Kho Xu Khổng Lồ 20,000 | 399.000 VNĐ | bonus +5,000 · icon cấp 5 `coin_t5` (rương vàng) |
| `coin_no_ads` | Gói Xoá Quảng Cáo | 49.000 VNĐ | mua 1 lần, kèm skin bút, nằm RIÊNG 1 HÀNG trên cùng

### 13.3. Trạng thái thẻ & nút

- **Thẻ dọc** (`nodes/shop/item_row.tscn`, 980×180) dùng cho DỤNG CỤ: Badge · Icon · Tên · Mô tả (**2 dòng**, ellipsis) · dòng phụ · nút 270×75.
- **Thẻ ô** (`nodes/shop/item_tile.tscn`, **475×294** — rút gọn chiều cao từ **315 → 294** để cả lưới vừa khung nhìn, giữ đúng tỉ lệ mockup `shopping_pencil.svg`) dùng cho BÚT & MỰC + GIẤY VỞ:
  lề trái màu món · **nhãn góc trên-trái** (bề ngang tự co theo chữ) · **vòng icon** (`IconCircle`, alpha 0.16) + icon + **nét mực vẽ thử** (`ink_stroke`) · tên (24) · mô tả · dòng trạng thái · nút **200×46**.
  Lưới 2 cột × 3 hàng = **6 ô/trang** (10 bút → 2 trang; 8 giấy vở → 2 trang). **Khe lưới: ngang 30 (475×2 + 30 = 980 khít khung) · dọc 24** — cố ý chọn để mọi tab **VỪA khung nhìn 1200px, không cần vuốt dọc** (bàn nháp 215 + khe list 20 + lưới 3×294+2×24 = 1165 ≤ 1200).
- **Thẻ gói nạp** (`nodes/shop/coin_tile.tscn`, **475×240**) dùng cho tab NẠP XU: vòng icon + **icon cấp Xu** (art riêng, không modulate) · tên 24 · mô tả · dòng ưu đãi (hổ phách) · nút giá VNĐ 419×56.
- **Hàng VIP** (`nodes/shop/noads_row.tscn`, **980×200**) cho gói Xoá quảng cáo: nhãn đỏ `chip_red` · tiêu đề 32 · mô tả 17 · nút đỏ 230×80 (mua rồi → `ĐÃ SỞ HỮU` và khoá nút).
- Nút đổi theo trạng thái: **giá Xu** (hổ phách + icon Xu; món VIP dùng nút hổ phách đặc chữ trắng) · **SỬ DỤNG** (đã sở hữu, art TRẮNG + `modulate` màu món hàng) · **ĐANG DÙNG ✓** (đang mặc, nút xanh lá, khoá) · **MUA THÊM N** (dụng cụ) · **giá VNĐ** (gói nạp) · chưa đủ Xu → **nút mờ + note "Chưa đủ Xu Mực"**.
- Dòng phụ: dụng cụ → `Đang có: N lượt`; gói nạp có `bonus > 0` → `Tặng thêm +N xu mực` (không có bonus thì ẩn).

### 13.4. Kinh tế Xu Mực

- Xu vào: thưởng màn chơi + nhiệm vụ trong Sổ tay thành tựu (`claim()`) + gói nạp; Xu ra: mua bút/chủ đề/dụng cụ.
- Ví trên góc phải (775,85) 255×70 — icon Xu + số (định dạng `1,250`, `Shop.thousands()`) + nút **+** (nhảy sang ngăn NẠP XU).
- Banner chân trang `GÓC TIẾP SỨC HỌC TẬP`: xem bài giảng ngắn mỗi ngày nhận +50 Xu (nút `+50 XU ▶`).
- `purchase_log` ghi lại id đã mua (phục vụ thống kê/test); nút **+** và gói nạp hiện là **STUB IAP** (`purchase_coin_pack`) — khi ghép Google Play Billing thì chỉ cần thay thân hàm này.
- API ví: `coins/can_afford/buy/purchase_coin_pack/is_consumable/use_tool/tool_count/equip/is_owned/is_equipped`.

### 13.5. Chủ đề & ngòi bút: ĐÃ CHUẨN BỊ nhưng CHƯA áp dụng

Theo yêu cầu "chuẩn bị sẵn việc Apply Theme và Pen, chưa cần apply vội":

- `scripts/manager/ThemeManager.gd` (autoload) + facade `scripts/utils/theme_skin.gd` (`class_name ThemeSkin`):
  `sync_from_shop()` · `theme_id()` · `pen_id()` · `pen_color()` · `palette()` (paper/paper_alt/line/margin/ink/ink_soft/accent) · `color(key)` · `apply_theme(id)` · `apply_pen(id)` · signal `skin_changed(theme_id, pen_id)`.
- Công tắc **`apply_enabled := false`** — mọi thứ đã nối (chọn là lưu + phát signal + cập nhật `ThemeManager`), chỉ còn `_apply_now()` là stub TODO: khi bật sẽ đổi nền giấy/đường kẻ/màu mực của màn chơi theo `palette()`.
- LƯU Ý ĐẶT TÊN: ban đầu file facade đặt `class_name Skin` → **trùng class native của Godot** (`Skin`) nên parse lỗi; đã đổi thành `ThemeSkin`.

### 13.6. Giao diện (đo từ scene thật)

`scenes/shop.tscn` (script `scripts/scenes/shop.gd`, `class_name ShopScene extends BaseScene`):

| Thành phần | Vị trí | Ghi chú |
|---|---|---|
| TopBar/Back | (50, 85) 70×70 | `btn_header_back_*` → về Main |
| Eyebrow + Title | giữa, y ≈ 92/119 | "TIỆM VĂN PHÒNG PHẨM" (đỏ) + "CỬA HÀNG" (`STR_SHOP_*`) |
| Ví Xu | (775, 85) 255×70 | icon Xu + số + nút **+** |
| 4 tab nhãn vở | y=185 (tab chọn, 240×65) / y=195 (tab thường, 240×55) | dựng **bằng code** (TextureButton + Label), art `tab_active/tab_inactive`; vạch đáy `TabLine` y=250 |
| Content (cuộn) | (50, 270) 980×**1200** | lưới 2 cột 6 ô/trang (bút/giấy) · thẻ gói nạp 2 cột + hàng VIP trên cùng (nạp xu) · danh sách thẻ dọc (dụng cụ) — **mọi tab vừa khung nhìn**, không cần cuộn (dụng cụ: 6×180+5×20 = 1180) |
| Pager | y ≈ 1500 | "TRANG x / y" + chấm + 2 mũi tên (ẩn khi 1 trang) |
| GiftBanner | (50, 1545) 980×115 | viền đỏ + icon quà + nút `+50 XU` |
| Footer | y ≈ 1710 | câu đề tựa chân trang |

**Vuốt / cuộn** (tự xử lý ở `_input` — nút trên thẻ "ăn" sự kiện kéo nên `ScrollContainer` không tự cuộn được):
vuốt **ngang** → đổi trang (khi tab có >1 trang) · vuốt **dọc** → cuộn danh sách món · chọn trục theo hướng di chuyển đầu tiên
(ngưỡng 14px) · vuốt đủ xa (≥70px) mới đổi trang · sau mỗi lần vuốt **KHOÁ bấm nút 0.35s** (`clicks_locked()`) để không mua nhầm.
**Từ 2026-09-19:** cả 4 tab đều **vừa khung nhìn** nên vuốt dọc không còn cần thiết — handler dọc vẫn giữ làm dự phòng (nội dung ngắn hơn khung thì `scroll_vertical` đứng yên).

Mọi node gốc của scene đều có `index="1".."8"` để node `Popups` của `base.tscn` vẫn nằm TRÊN CÙNG.

### 13.7. Asset · theme · chuỗi dịch

- `assets/images/shop/` (30 SVG): `tab_active`/`tab_inactive` · `card_row` (980×180) · **`card_tile` (475×294 — thẻ ô)** · **`card_coin` (475×240)** · **`card_noads` (980×200)** · `chip_price` · `chip_red` (nhãn đỏ no-ads) · `btn_action_{normal,pressed,amber}` · `btn_equipped` · **`btn_tile_{normal,done,price,price_vip}` (200×46)** · **`btn_coin` (419×56)** · **`btn_noads` (230×80)** · `wallet_chip` · `banner_gift` · `btn_plus` · `gift_box` · `icon_box` · **`icon_circle`** · `ink_stroke` · `icon_{pen,ink,paper,coin}` · `icon_tool_{undo,hint,reveal,time,revive,shield}` (art TRẮNG → `modulate`) · **`icon_coin_t1..t5`** (icon cấp Xu: xu đơn · cọc xu · đống xu · túi tiền · rương vàng — lấy từ `mockup/coin_tiers.svg`).
- Theme variations (`theme_text.tres`, nhóm `Shop*`, 27 cái): `ShopTitle` · `ShopEyebrow` · `ShopTabLabel(Active)` · `ShopName(Tile)` · `ShopDesc` · `ShopStock` · `ShopPrice(Amber)` · `ShopBadge(Danger)` · `ShopBonus` · `ShopNoads{Title,Desc,Price}` · `ShopBtnText(Amber/Done)` · `ShopWalletCount/Label` · `ShopBannerTitle/Desc/Btn` · `ShopPageLabel` · `ShopFooter`.
- Chuỗi mới (`string_extra.csv`): `STR_SHOP_TITLE/EYEBROW` · `STR_SHOP_TAB_{PEN,THEME,TOOL,COIN}` · `STR_SHOP_PAGE_FORMAT` · `STR_SHOP_STOCK_FORMAT` + `STR_SHOP_UNIT_{PACK,TURN,COIN}` · `STR_SHOP_BONUS_TAG` · `STR_SHOP_USE` · `STR_SHOP_BUY_MORE` · `STR_SHOP_EQUIPPED` · `STR_SHOP_OWNED_BTN` · `STR_SHOP_NOT_ENOUGH` · `STR_SHOP_PRICE_FORMAT` · `STR_SHOP_BANNER_*` · 23 nhãn `STR_SHOP_BADGE_*` · 60 khoá tên/mô tả món hàng (`STR_SHOP_ITEM_*`, `STR_SHOP_THEME_*`, `STR_SHOP_TOOL_*`, `STR_SHOP_COIN_*`).
- Mockup: `mockup/shopping_pencil.svg` · `shopping_tool.svg` · `shopping_coin.svg` (hàng VIP + lưới 5 gói Xu có icon cấp) · `shopping_theme_page_1/2.svg` (**thẻ ô, 6 thẻ/trang**) · `coin_tiers.svg` (5 cấp icon, số Xu = 500/2,000/3,500/8,000/20,000 khớp gói nạp thật) — **cùng một bộ khung** (status bar · Back (50,85) · eyebrow + CỬA HÀNG · ví 255×70 tại (775,85) · 4 tab nhãn vở với tab đang chọn nổi lên + vạch đáy y=250 · banner (50,1545) · chân trang y≈1710 · thanh gesture home).

### 13.8. File liên quan & kiểm thử

| File | Vai trò |
|---|---|
| `scripts/manager/ShopManager.gd` | Autoload: catalog 30 món · ví Xu (dùng chung Xu Mực) · mua/mặc/dùng · `export/import/reset_progress` |
| `scripts/utils/shop.gd` (`class_name Shop`) | Facade tĩnh: `items/item/buy/equip/use_tool/coins/tool_count/thousands/vnd_text`… |
| `scripts/manager/ThemeManager.gd` + `scripts/utils/theme_skin.gd` (`ThemeSkin`) | Chuẩn bị việc áp chủ đề/ngòi bút (`apply_enabled = false`) |
| `scripts/manager/ArchivementManager.gd` | Thêm `notify_coins_changed()` + `spend_coins(amount)` để ví Xu dùng chung |
| `scripts/manager/SaveManager.gd` | Đăng ký `ShopManager` là provider (autosave khi `item_purchased`) |

### 13.9. Skin ngòi bút (con trỏ + chất liệu nét mực) + Bàn nháp thử bút — 2026-09

**Nguồn sự thật:** `scripts/utils/pen_skins.gd` (`class_name PenSkin`) — bảng `SKINS` map 1-1 mỗi món `category = "pen"` trong ShopManager với
`{ cursor: assets/images/game/player_cursor/*.svg · icon: assets/images/game/pen_type/*.svg · ink: màu mực · style: chất liệu }`:

| Bút | Con trỏ trong game | Hình ngòi bút (shop/thẻ) | Màu mực | Chất liệu nét |
|---|---|---|---|---|
| `pen_blue` (mặc định) | `player_cursor_1` | `pen_fountain_pen_nib` | `#2575A7` | ink |
| `pen_purple` | `player_cursor_7` | `pen_fountain_pen_nib` | `#7C3AED` | ink |
| `pen_pencil_2b` | `player_cursor_2` | `pen_pencil` | `#4B5563` | pencil (nét đứt) |
| `pen_red_teacher` | `player_cursor_3` | `pen_fountain_pen_nib` | `#DC2626` | ink |
| `pen_highlighter` | `player_cursor_4` | `pen_stabilo_highlighter` | `#F59E0B` | highlighter (rộng 1.75× · đầu vuông · alpha thấp) |
| `pen_gold_ink` | `player_cursor_6` | `pen_calligraphy_brush` | `#B45309` | gold (quầng sáng 2.3×) |
| `pen_green_tea` | `player_cursor_8` | `pen_art_brush` | `#15803D` | brush |
| `pen_pink_diary` | `player_cursor_9` | `pen_felt-tip_marker` | `#DB2777` | marker |
| `pen_graphite_4b` | `player_cursor_5` | `pen_drafting_pencil` | `#374151` | graphite (nét đứt + quầng nhẹ) |
| `pen_navy_night` | `player_cursor_10` | `pen_needle_point_gel` | `#1E3A8A` | gel (mảnh 0.85× + quầng nhẹ) |

**Chất liệu** (`PenSkin.STYLES`): `width` (× bề rộng nét gốc) · `alpha` · `cap` · `dash/gap` · `glow_width/glow_alpha`.
Nét đứt = **texture lặp sinh trong code** (`dash_texture_for(period_px, height)`), BẮT BUỘC bật `texture_repeat = ENABLED` trên Line2D
(không bật thì Godot kẹp mép texture → nét gần như vô hình; Line2D cũng KHÔNG sinh UV khi không có texture nên shader-theo-UV không dùng được).
Quầng sáng = Line2D con (`name = "Glow"`, blend CỘNG) nằm dưới nét chính.

**Nối vào game:** `nodes/game/moving_line.tscn` gắn script `scripts/nodes/game/ink_stroke.gd` (`class_name InkStroke`):
`apply_pen(pen_id)` + `set_base_width(w)` + `set_stroke(points)`; `Board.apply_pen_skin()` (gọi trong `setup_maze()` và khi `ThemeManager.skin_changed`)
đổi icon con trỏ (`PlayerCursor.apply_pen`), nét `moving_line`, vệt bút mờ lịch sử (`InkStroke.style_plain`) và vết bước chân theo màu/icon bút.

**Cỡ con trỏ người chơi (2026-09-19):** `nodes/game/player_cursor.tscn` đặt **132×132** — **gấp 3 lần cỡ cũ 44×44** (bằng 3/4 cỡ ô 176 nên nổi rõ giữa ô).
`board.gd` đọc cỡ thật từ scene (`_read_scene_size(PLAYER_CURSOR_SCENE, FALLBACK_CURSOR_SIZE)` với `FALLBACK_CURSOR_SIZE = 132`) rồi co theo `_fit_scale` của board (sàn `MIN_CURSOR_SIZE = 18px`), pivot luôn ở tâm để chạy giữa 2 ô đúng vị trí.

**Bàn nháp thử bút** (mockup `shopping_pencil.svg` khu 5): `nodes/shop/doodle_pad.tscn` + `scripts/nodes/shop/doodle_pad.gd` (`class_name ShopDoodlePad`),
kích thước **980×215**, chỉ hiện ở tab BÚT & MỰC, nằm **TRÊN lưới thẻ**. Vẽ thử bằng ngón tay (mỗi nét là 1 `InkStroke` cùng chất liệu với game),
có nét mẫu tự vẽ khi đổi ngòi, ngòi bút chạy theo tay, thẻ **ĐANG XEM THỬ** (tên bút + icon con trỏ + con dấu `DÙNG THỬ ✓` / `ĐANG DÙNG ✓`).
Chạm vào THÂN thẻ bút → xem thử ngòi đó (nút hành động trên thẻ vẫn là mua/dùng); vùng bàn nháp **chặn cuộn/vuốt trang** (`blocks_scroll_at`).
Thẻ bút trong lưới hiện đúng icon con trỏ của chính nó. Art: `assets/images/shop/doodle_pad.svg` + `doodle_badge.svg` (sinh bằng `tools/mockup/gen_doodle_pad.py`).
Chuỗi mới: `STR_SHOP_TRY_{TITLE,HINT,BADGE,STAMP,USING}`.

**Kiểm thử:** `scripts/test_case/test_pen_skin.gd` (89 check: bảng skin + con trỏ/nét mực thật trong màn chơi theo từng bút) và mục bàn nháp trong `test_shop.gd` (243 check).
| `scripts/nodes/shop/item_row.gd/.tscn` · `item_tile.gd/.tscn` · `coin_tile.gd/.tscn` · `noads_row.gd/.tscn` | 4 loại thẻ: thẻ dọc (dụng cụ) · thẻ ô 475×294 (bút/giấy vở) · thẻ gói nạp 475×240 · hàng VIP 980×200 |
| `scripts/scenes/shop.gd` + `scenes/shop.tscn` | Màn Cửa hàng: dựng 4 tab bằng code, đổi ngăn, phân trang 6 ô/trang, mua/mặc/dùng, **vuốt ngang đổi trang + vuốt dọc cuộn danh sách** |
| `scripts/utils/nav.gd` · `scripts/manager/SceneManager.gd` | `SCENE_SHOP` + `goto_shop()` (Debug Console có mục mở Cửa hàng) |
| `scripts/test_case/test_shop.gd` | **247 check**: catalog (đủ 30 món, giá, icon, khoá dịch) · ví Xu · dụng cụ (cộng dồn lượt) · trang bị bút/chủ đề (`ThemeSkin`) · lưu/tải/xoá · scene (4 tab, thẻ ô 475×294 + nút 200×46, hàng VIP no-ads trên cùng, icon cấp Xu của từng gói, mua thật qua nút thẻ) · **mọi tab vừa khung nhìn — không cần cuộn · vuốt ngang đổi trang · không mua nhầm khi vừa vuốt** · nối dây điều hướng |

---

### 13.10. Hỗ trợ MỌI TỈ LỆ MÀN HÌNH — portrait & landscape (2026-09-19)

**Yêu cầu:** app chạy chuẩn ở mọi tỉ lệ điện thoại/máy tính bảng — 9:16 · 9:18 · 9:19.5 · 9:21 · 3:4 · 4:3 · 16:9 · 18:9 · 19.5:9 (CẢ dọc lẫn ngang).

**Cơ chế — 1 chỗ duy nhất, mọi màn tự hưởng** (`scripts/scenes/base.gd`, root của `scenes/base.tscn` — mọi màn hình đều instance base):
- Giữ `stretch/mode = "canvas_items"` + `stretch/aspect = "expand"` (canvas giãn theo màn hình).
- Root Control tự co thành **CỘT NỘI DUNG 1080px CANH GIỮA**: `size = (1080, canvas_height)`, `position.x = (canvas_width − 1080) / 2`.
  · Màn DỌC cao (9:18 → 9:21): cột đúng bề rộng thiết kế, giãn DỌC (phần tử neo đáy bám đáy màn hình).
  · Màn RỘNG hơn 9:16 (3:4 · 4:3 · 16:9 · 18:9… kể cả LANDSCAPE): nội dung nằm gọn trong cột giữa — **không bị kéo giãn ngang, không lệch vị trí**.
- `Background` (index 0, nằm DƯỚI mọi nội dung) giữ đúng cột (lề đỏ ở lề cột) + 2 dải `SideL`/`SideR` con của Background tô màu giấy `#FAF5EB` phủ hai bên → nhìn như trang vở trải rộng, **không có thanh đen letterbox**.
- Đặt trong `_enter_tree()` + `_notification(READY/RESIZED)` + `viewport.size_changed` — vì mọi màn con override `_ready()` (không gọi super) nên `_ready` của BaseScene không chạy.
- Popup (`scripts/nodes/popups/base.gd`): thẻ popup canh giữa theo cột, `Dim` phủ **toàn màn hình** (cả 2 bên cột); tính lại khi mở popup/đổi cỡ.
- Android: `display/window/handheld/orientation = 6` (**Sensor** — xoay tự do 2 chiều).

**Đổi cả mockup HUD Time Attack theo tỉ lệ:** thẻ THỜI GIAN của `time_attack_hud.tscn` dùng **anchors tỉ lệ** (0.352..0.648 × 0.085..0.911 của khung 980×249 ≈ 291×206, canh giữa) + số `resize_font_to_fit`; mockup `matchup_time_attack.svg` sinh lại tương ứng.

**Công cụ kiểm thử (Windows/Android, cần render thật):**
```bash
godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_aspects.gd
# tuỳ chọn: --shots=1  --only=main,game  --sizes=1920x1080  --modes=play
```
- Quét **10 tỉ lệ × (12 màn + 9 chế độ game + popup pause)** = 220 lượt kiểm tra: cột canh giữa · nền giấy phủ kín · KHÔNG node nào tràn màn hình · board/HUD/thanh nút trong cột · popup Dim phủ canvas & thẻ giữa tâm. **Kết quả 220/220 PASS.**
- `--shots=1` lưu PNG nửa phân giải vào `tmp_aspect/<WxH>/<id>.png` để soi bằng mắt.

**Bug thật phát hiện khi quét (đã sửa):** `nodes/daily/calendar.tscn` — hàng thứ `DayTitle` để `offset_right = 1366` (lệch **380px** so với lưới ngày `Days` 76..986) → 7 nhãn T2..CN bị lệch khỏi cột ngày và nhãn CN **tràn ra ngoài màn hình 1080** ở MỌI tỉ lệ (lỗi có sẵn từ trước). Sửa `offset_right = 986` = khớp đúng 7 cột × 130px của lưới ngày.

**Kiểm chứng trên MÁY ẢO ANDROID THẬT** (tablet `Medium_Tablet_API_28`, 2560×1600 dpi 320 — APK debug ~422MB):
```bash
emulator -avd Medium_Tablet_API_28 -no-snapshot-load -no-snapshot-save -no-boot-anim \
         -gpu host -feature GLESDynamicVersion -memory 4096
adb install -r -d build/inkmaze_tablet_debug.apk
adb shell settings put secure immersive_mode_confirmations confirmed   # bỏ overlay "GOT IT"
adb shell monkey -p com.invisiblegear.inkmaze -c android.intent.category.LAUNCHER 1
```
- **`-gpu host` là bắt buộc trên máy này:** `swiftshader_indirect` + `GLESDynamicVersion` cho app khởi động nhưng **SIGSEGV ngay trong GLThread** (crash render của SwiftShader → màn hình xám). Thiếu `GLESDynamicVersion` thì guest chỉ có ES 2.0 → `eglCreateContext EGL_BAD_CONFIG: no ES 3 support`. Dùng `-gpu host` (thẳng NVIDIA RTX 3060, GLES 3.0 trên driver 4.5 + Vulkan 1.3) → chạy ổn định, không crash.
- Ảnh chụp máy ảo (lưu ngoài project `d:\godot-phone-game\inkmaze_shots_android\`): splash · main · game (Play) · popup Tạm dừng · Cài đặt — **mỗi màn ở CẢ landscape 2560×1600 lẫn portrait 1600×2560**: cột 1080 canh giữa, 2 dải giấy `#FAF5EB` hai bên, xoay máy reflow tức thì, Dim popup phủ kín toàn màn hình.

---

### 13.11. Sửa lỗi LỆCH HƯỚNG CỬA SỔ ↔ MÀN HÌNH trên Android (2026-09-19)

**Triệu chứng user báo (chơi trên máy ảo tablet):**
- Đâm vào tường → ván kết thúc nhưng **popup Game Over không hiện**, không đi tiếp được (thực chất popup đang nằm NGOÀI vùng nhìn thấy, lớp Dim vẫn chặn input).
- Popup "Phiếu thông qua tầng" (Dungeon) hiển thị **lệch/trôi**, mép phải giao diện bị cắt.
- **Màn hình loading bị lỗi** (không phủ đúng).

**Nguyên nhân gốc (đo được bằng log tạm in lên màn hình):** app có thể giữ cửa sổ ở **hướng cũ trong khi màn hình đã xoay hướng khác** —
`window_get_size()=(2560,1600)` (ngang) nhưng màn hình đang `1600×2560` (dọc) ⇒ canvas = **3072×1920 ngang** trong khi vùng nhìn thấy chỉ là 1600×2560 ⇒
- nội dung vẽ tràn ra ngoài mép phải (thấy đúng như ảnh user chụp: hộp stats thứ 3 và nút cuối bị cắt),
- popup canh giữa canvas 3072 ⇒ tâm popup nằm ngoài màn hình ⇒ "không thấy popup",
- lớp loading (CanvasLayer full-rect) cũng vẽ theo canvas sai ⇒ "màn loading lỗi".

Hoàn cảnh gây lệch: xoay màn hình bằng **khoá xoay / `settings put user_rotation`** (cảm biến không đổi nên app kiểu Sensor không tự xoay theo), hoặc mở app lúc máy đang xoay.

**Cách sửa (tự chữa, không cần người dùng làm gì):**
- `scripts/manager/AppManager.gd` → `sync_window_orientation()`: watchdog 0,5s — nếu `window_get_size()` **khác hướng** `screen_get_size()` (một bên ngang, một bên dọc) thì gọi `DisplayServer.window_set_size(screen_size)` để cửa sổ khớp màn hình thật.
  (Chỉ chạy khi `OS.has_feature("mobile")` — desktop không bị ảnh hưởng.)
- `scripts/manager/PopupManager.gd` → `get_host()` **không dùng lại host đã cache nếu host không còn thuộc scene hiện tại** (scene vừa đổi ⇒ host cũ sắp bị xoá ⇒ popup sẽ nằm trong scene chết và người chơi không thấy gì).
- `scripts/scenes/base.gd`: `_enter_tree()` gọi `set_anchors_preset(PRESET_TOP_LEFT, true)` để Root tự quản size/position (hết cảnh báo "non-equal opposite anchors").

**Kiểm chứng trên máy ảo:** đặt màn hình dọc rồi mở app ⇒ app tự về dọc (canvas 1200×1920, cột canh giữa 60), mọi màn/popup hiển thị đủ, không còn cắt mép; xoay ngang ⇄ dọc nhiều lần popup vẫn đúng tâm.

### 13.12. Hotfix 7 lỗi layout khi test trên máy ảo ĐIỆN THOẠI 1080×2424 (Pixel_9_API_35) — 2026-09-17

Bối cảnh: các màn được thiết kế cho canvas **1080×1920**; trên máy ảo điện thoại canvas cao **2424** nên mọi khối neo theo OFFSET
thiết kế bị trôi/lệch, còn khối neo theo TỈ LỆ thì giãn đúng. Danh sách user gửi (`hotfix/need_to_fix.txt` + 5 ảnh):

**1. Popup "Game Over" NHÁY HIỆN RỒI BIẾN MẤT (Ảnh 1)** — thủ phạm là **đua tween + mở trùng id**, không phải lỗi vẽ:
`UıController.show_game_over()` gọi `Popups.close_all()` rồi mở lại **cùng id** ngay khi tween đóng của popup cũ còn chạy;
callback `_finish_close()` của tween cũ chạy sau đó và **xoá popup vừa mở**. Ngoài ra `GameController._game_over()` bị gọi
2 lần trong cùng khung hình (đâm tường + hết giờ). Sửa:
- `scripts/nodes/popups/base.gd`: giữ `_tween`, thêm `_kill_tween()` huỷ tween cũ trước khi chạy hiệu ứng mới;
  `close()` chặn đóng trùng (`if _closing: return`); `_finish_close()` chỉ giải phóng khi **vẫn đang đóng**
  (`if not _closing: return`) ⇒ mở lại giữa lúc đang đóng thì popup mới không bị xoá oan.
- `scripts/core/controllers/game_controller.gd`: `_game_over()` mở đầu bằng `if not _run_active: return`.
- Kiểm chứng: `dev_popup_repro.gd` thêm ca *"gọi 2 lần liên tiếp"* + *"mở lại giữa lúc đang đóng"* → **4 PASS · 0 FAIL**;
  trên emulator: kéo vào tường vô hình ⇒ popup "ĐÂM VÀO TƯỜNG VÔ HÌNH!" vẫn hiện ổn định, bấm được nút.

**2. Lưới ô bị đẩy LÊN, không giữa thẻ bàn (Ảnh 2):** `BoardView._panel_insets` lưu insets của ảnh `card_board.svg`
theo PIXEL nhưng được dùng như đơn vị panel-local; panel cao 1288 (màn 2424) ⇒ vùng lưới tính thiếu ⇒ tâm lưới lệch lên ~160px.
Sửa: insets đổi sang **TỈ LỆ 0..1**, `panel_inner_rect()` nhân với `panel.size` ⇒ tâm lưới = tâm panel (đo lại: 623,7 = 623,7).

**3. HUD lệch lên trên:** gốc `Hud` neo offset thiết kế (y=175) nên trên màn cao dính sát status bar.
Sửa `nodes/hud/base.tscn`: `anchor_top = anchor_bottom = 0.072` + offset giữ **37px** khoảng cách dưới status bar ở mọi tỉ lệ.

**4. Popup không ở giữa:** `BasePopup._apply_canvas_layout()` chỉ canh giữa NGANG (theo cột nội dung), chiều dọc vẫn theo
offset thiết kế ⇒ màn 2424 thẻ nằm cao hơn tâm 262px. Sửa: canh giữa **cả hai chiều** theo canvas (`Dim` vẫn phủ kín canvas).

**5. Text nút công cụ "Vẽ đường" / "Ghi nhớ" dùng STR_ID + có dòng phụ:** `scenes/game.tscn` chuyển `Button/Tool` →
`STR_TOOL_DRAW_PATH`, `Button/Wall` → `STR_TOOL_MARK_WALL`, thêm node `Sub` (`STR_TOOL_DRAW_PATH_DESC` /
`STR_TOOL_MARK_WALL_DESC`, alpha 0.72) + LabelSettings mới `resources/settings/text/text_game_button_sub.tres`
(BeVietnamPro-Black 22). Nhãn chính canh giữa, dòng phụ nằm dưới.

**6. Màn DAILY: Mission lệch & ĐÈ LÊN NHAU (Ảnh 4):** `Calendar` bị anchor giãn thành 1275px (đè 350px lên `Missions`)
và để lại 692px trống dưới trên màn dọc. Sửa `scenes/daily.tscn`: Calendar cao **cố định 1010**, `Missions` đặt
`expand_mode = 1` (ảnh 1020×592 trước đây CHẶN không cho node co nhỏ — đúng bẫy "TextureRect clamp size").
`scripts/scenes/daily.gd::_layout_responsive()` (chạy khi READY/RESIZED + `size_changed`): nút CHƠI neo đáy 60px;
`Missions` nằm giữa Calendar và nút CHƠI (cách 24px); hàng nhiệm vụ co lại khi màn thấp, giãn nhẹ (≤1.35×) khi màn cao;
hàng tiến độ dời theo chiều cao panel. Đo lại: dọc 1080×2424 Missions 1251..2220 (nút CHƠI 2243), ngang 2400×1080 Missions cao 520.

**7. Màn SHOP: khoảng trống dưới + phân trang theo màn (Ảnh 5):**
- `scenes/shop.tscn`: `Content` (ScrollContainer) kéo tới **đáy canvas**; `Pager`, banner "NHẬN XU MIỄN PHÍ", `Footer`
  neo vào đáy (banner luôn nằm CUỐI như user yêu cầu).
- `scripts/scenes/shop.gd`: số ô mỗi trang **tính từ chiều cao thật của khung cuộn** (`_grid_per_page()`:
  trừ `doodle_pad` khi ở tab BÚT & MỰC, `rows = floor((cao + SEP) / (ô + SEP))`, ×2 cột) ⇒ 10 cây bút vừa **8 ô/trang, 2 trang**
  trên điện thoại, 6 ô/trang trên màn ngang — không sinh trang thừa.
  Khi xoay màn hình: `_on_viewport_resized()` → `_refresh_pagination_if_needed()` dựng lại lưới nhưng **giữ trang theo item
  đang xem** (`_page_first_id`).

**8. Công cụ & kiểm thử:** thêm `scripts/test_case/dev_back_probe.gd` (kiểm tra Back/Esc với popup);
`dev_aspects.gd` nay gán `current_scene` khi thêm scene vào cây — vì `PopupManager.get_host()` tìm host theo `current_scene`,
nếu không gán thì popup rơi vào host tạm ngoài scene và 10 check "bấm pause không mở được popup" FAIL **oan**.
Kết quả sau sửa: **29/29 suite PASS** · harness tỉ lệ **220/220 PASS** · APK debug build lại và xác nhận trên Pixel_9_API_35
(grid giữa thẻ, HUD đúng, nút có dòng phụ, popup Game Over giữ nguyên, Daily không đè, Shop hết khoảng trống + banner cuối trang).

**9. Ghi nhận còn lại (chưa sửa, chờ quyết định):**
- Nút **Back trên Android đang thoát app** khi màn chơi đang mở popup (project để mặc định `quit_on_go_back = true`;
  trên Windows phải bấm Esc **2 lần** mới đóng popup — lần 1 bị xử lý ở chỗ khác). Popup vẫn đóng bình thường bằng nút trên màn hình.
- Màn chính còn khoảng trống dưới thanh điều hướng trên màn dọc cao (nav ở y≈1800 trong canvas 2424).
- Còn `print()` debug của user: `Close Popup …`, `Show Game Over because …`, `GAME_OVER because …`.


