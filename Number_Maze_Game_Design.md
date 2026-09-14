# Number Maze — Game Design Document

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

**Nguyên tắc quan trọng:** Chỉ có **Play Mode** và **Dungeon Mode** là 2 chế độ "thường trực" người chơi có thể vào chơi bất cứ lúc nào. **7 bộ luật còn lại** (Time Attack Maze, Minesweeper Maze, Area Maze, Sum Path, Countdown Cost, Blind Memory Maze, Fog of War Maze) **không tồn tại như mục chọn riêng** trên Main Screen — chúng chỉ xuất hiện **lần lượt, mỗi ngày 1 bộ luật**, thông qua màn hình Daily Challenge (mục 6).

---

## 5. Chi tiết từng bộ luật chơi

| Bộ luật | Thuộc cổng | Ý nghĩa con số trên ô | Xử lý khi đâm tường | Điều kiện Thắng / Mục tiêu |
|---|---|---|---|---|
| **Play Mode** | Play · Chọn màn | Số tường quanh ô (0..4) | **Game Over ngay** (hồi sinh: quay lại bước trước đó) | Đến F an toàn, xếp hạng theo thời gian nhanh nhất |
| **Dungeon Mode** | Dungeon | Số tường quanh ô (0..4) | Về lại S, trừ 1 bước | Vượt qua càng nhiều Floor càng tốt (chế độ DUY NHẤT có bộ đếm bước còn lại) |
| Time Attack Maze | Daily Challenge | Số tường quanh ô (0..4) | Về lại S, mất thời gian | Đến F trước khi đồng hồ đếm ngược về 0 |
| Minesweeper Maze | Daily Challenge | Số mìn quanh ô (0..8) | Đạp mìn: Nổ, lật ô, về S | Tránh các ô mìn ẩn, đến đích F an toàn |
| Area Maze | Daily Challenge | Điểm số của ô (1..9) | Không có tường | Kéo nối Anchor chia các Area đạt đúng Target Score và chứa S & F |
| Sum Path | Daily Challenge | Điểm số của ô (1..9) | Không có tường | Đến F với tổng điểm thỏa `SUM < / > / = Target` |
| Countdown Cost | Daily Challenge | **Chi phí bước** của ô (số riêng, KHÔNG liên quan tường) | Về lại S, trừ theo ô đích | Đến F với ngân sách bước hạn chế, tối ưu chi phí |
| Blind Memory Maze | Daily Challenge | Không có số (ẩn hoàn toàn) | Tùy chọn (về S hoặc thua ngay) | Ghi nhớ tường khi Countdown (3..2..1) rồi đi khi tường ẩn |
| Fog of War Maze | Daily Challenge | Số tường (chỉ hiện ô gần) | Tùy chọn (về S hoặc thua ngay) | Dò đường trong sương mù quanh vị trí nhân vật |
> **Quy ước "Số tường quanh ô":** chỉ tính **4 cạnh bên trong board** (kể cả tường vô hình). **Tường viền bao quanh board KHÔNG tính vào ô** — nếu tính thì mọi ô sát biên đều bị cộng thêm (ô góc +2) và con số mất ý nghĩa. Viền ngoài vẫn **chặn đường đi như cũ**, chỉ không được đếm.
> ⇒ Ô sát biên tối đa 3, ô giữa board tối đa 4, ô trống hoàn toàn = 0 (không hiện số).

> **Quy ước "Số bước":** **CHỈ Dungeon Mode có bộ đếm số bước còn lại** (thẻ **SỐ BƯỚC** + thẻ **TẦNG** trên HUD — xem `matchup_dungeon.svg`). **Mọi chế độ khác KHÔNG giới hạn và KHÔNG hiển thị số bước còn lại** — Play Mode chỉ hiện thẻ **THỬ THÁCH** + **THỜI GIAN** (`matchup_level.svg`), các bộ luật Daily hiện tài nguyên riêng của chúng (đồng hồ, điểm, số mìn...). *Ngoại lệ duy nhất:* **Countdown Cost** vẫn dùng **ngân sách bước**, vì đó chính là cơ chế cốt lõi của bộ luật này (xem 5.3–5.9).

> **Bố cục HUD màn chơi (theo 2 mockup match-up):** hàng thẻ cao **156–158px** nằm ngay dưới tiêu đề, rộng 980px (x = 50 → 1030):
> - **Play Mode** (`matchup_level.svg`): thẻ **THỜI GIAN** 250×138 bên trái + thẻ **THỬ THÁCH** 720×156 bên phải.
>   Thẻ THỬ THÁCH gồm cột tổng kết (**số Thử thách đã đạt** `x/3 ✓` + dòng `n ĐÃ HOÀN THÀNH`) và **3 dải thử thách** 490×42: **ô tích đỏ** = đã đạt (kèm nhãn đỏ `✓ ĐẠT`), **ô chờ tích** (nét đứt) = chưa đạt (kèm tiến độ ở góc phải).
> - **Dungeon Mode** (`matchup_dungeon.svg`): thẻ **THỜI GIAN** 250×138 + thẻ **SỐ BƯỚC** 440×158 (viền đỏ, con số lớn 72px — KHÔNG còn dạng `14/20`) + thẻ **TẦNG** 250×138.
> - Tiêu đề game: Dungeon = `DUNGEON MODE` (một dòng, số tầng đã chuyển xuống thẻ TẦNG); Play Mode = dòng phụ đỏ `PLAY MODE · CHƯƠNG n` + dòng lớn `MÀN xx`.
### 5.1. 🎯 Play Mode (Level Selection) *(đổi tên từ "Classic Maze" / "Level Maze")*

> Đây là **chế độ chính, cửa vào đầu tiên của game** — thay cho khái niệm "chọn độ khó Dễ/Vừa/Khó" ở bản thiết kế cũ.

- Theo mockup `level_selection.svg`: màn chơi được tổ chức thành **Chương (Chapter)**, mỗi Chương có kích thước lưới cố định (ví dụ *"CHƯƠNG 1: BÀN CỜ NHẬP MÔN (7×7)"*), gồm nhiều **Màn (Level)** đánh số tuần tự (Màn 01, 02, 03...).
- Người chơi chọn đúng 1 Màn cụ thể để chơi, không còn chọn độ khó tổng quát — độ khó tăng dần tự nhiên theo số thứ tự Màn và theo Chương.
- Có thanh tiến trình phần trăm hoàn thành theo Chương (ví dụ "65%"), nút "TIẾP TỤC MÀN 07" để chơi tiếp Màn dở dang gần nhất, và nút "ĐỔI CHƯƠNG" để chuyển giữa các Chương đã mở khóa.
- Mỗi Màn: **Đâm vào tường vô hình = Game Over ngay lập tức** — không có cơ hội quay về S thử lại (giữ nguyên tinh thần "một-lần-ăn-cả" của Classic Maze cũ). Người chơi có thể **hồi sinh bằng cách quay lại bước trước đó** (xem 5.10).
- **Không có giới hạn số bước:** Play Mode **không** dùng bộ đếm bước. HUD của màn chơi chỉ gồm thẻ **THỬ THÁCH** (3 thử thách + ô tích đỏ đã đạt) và thẻ **THỜI GIAN** — theo mockup `matchup_level.svg`; đã bỏ hẳn thẻ số bước và thẻ điểm của bản Dungeon cũ.
- Mỗi Màn có **3 Thử thách**; hoàn thành 1 Thử thách = **1 Sao** (tối đa 3 Sao) — xem 3.1. Tổng kết ở popup thắng màn `popup_win_level.svg`, còn popup thua là `popup_game_over_level.svg`.
- Bảng xếp hạng theo **Thời gian hoàn thành nhanh nhất (Fastest Clear Time)** cho từng Màn.

### 5.2. 🏰 Dungeon Mode

- Chế độ endless, chơi qua nhiều Floor liên tiếp — càng đi sâu càng khó.
- Áp dụng cơ chế **Endless Visible Wall**: tỉ lệ tường hiển thị (visible) giảm dần liên tục theo mỗi Floor càng lên cao, tiến tới 0% ở các floor sâu.
- Đâm tường vô hình: trừ 1 bước, lộ tường thật, rung bàn cờ và đưa nhân vật về điểm S.
- Đến đích F: cộng điểm (Base Score, Move Bonus, Time Bonus, Perfect Floor) và thưởng thêm số bước cho Floor tiếp theo.
- ⚠️ **Dungeon Mode là chế độ DUY NHẤT có bộ đếm số bước còn lại** (thẻ **SỐ BƯỚC** + thẻ **TẦNG** trên HUD, theo mockup `matchup_dungeon.svg`; thẻ chỉ hiện con số bước còn lại, không có `/max`). Hết bước = thua Tầng; **hồi sinh = nhận thêm +3 bước** để đi tiếp ở đúng Tầng hiện tại (popup `popup_game_over_dungeon.svg`, xem 5.10).
- Mỗi Tầng có **3 Thử thách**; hoàn thành 1 Thử thách = 1 Sao (tối đa 3 Sao) — xem 3.1.
- Theo mockup `matchup_dungeon.svg`: màn chơi có thêm nút **UNDO** (hoàn tác bước vừa đi) và **GỢI Ý** (Hint) bên cạnh thao tác "VẼ ĐƯỜNG" (kéo từ tâm ô) và "GHI NHỚ" (nối 2 Anchor để đánh dấu tường nghi ngờ) — bổ sung so với bản thiết kế UX trước đó (mục 9).

### 5.3–5.9. Bảy bộ luật chỉ chơi được qua Daily Challenge

Nội dung luật của từng bộ **giữ nguyên như bản thiết kế trước**, chỉ khác về **cách truy cập**: không còn là mục chọn độc lập trên Main Screen, mà là **nội dung xoay vòng theo ngày** trong Daily Challenge.

- **⏱️ Time Attack Maze** — Giới hạn thời gian tổng (60s/90s/120s) đếm ngược, không giới hạn số bước. Đâm tường về S mất thời gian. Hết giờ = Game Over.
- **💣 Minesweeper Maze** — Số trên ô = số mìn trong 8 ô lân cận. S/F luôn an toàn, luôn tồn tại ít nhất 1 đường BFS không mìn. Đạp mìn: nổ, lật ô, đưa về S (mất thời gian và cơ hội đạt Challenge).
- **📐 Area Maze** — Số trên ô là điểm (1..9). Kéo nối Anchor tạo Area khép kín đạt đúng Target Score, đúng số lượng Area yêu cầu, và có ít nhất 1 Area chứa cả S và F.
- **➕ Sum Path** — Không có tường. Số trên ô là điểm (1..9). Thắng khi tới F với tổng điểm thỏa `SUM < / > / = Target`. Mỗi ô chỉ tính điểm 1 lần. Luôn đảm bảo tồn tại ít nhất 1 nghiệm đúng.
- **⏳ Countdown Cost** — **Số trên ô = CHI PHÍ BƯỚC khi bước vào ô đó**, hoàn toàn **không liên quan tới số tường quanh ô** (khác Play / Dungeon / Fog of War). Mọi ô trừ S/F đều có số ≥ 1 và luôn hiện số. Bước vào ô nào thì trừ đúng chi phí của ô đó; đâm tường: về S và trừ chi phí của ô đích vừa đâm vào. Ngân sách bước được tính đủ cho **đường đi rẻ nhất + khoảng dự phòng**, nên màn luôn thắng được nếu chọn đúng đường ít tốn kém; đi lệch qua các ô đắt sẽ hết bước.

  | Độ khó | Lưới | Chi phí mỗi ô | Dự phòng | Ngân sách tối thiểu |
  |---|---|---|---|---|
  | Easy | 3×3 | 1..2 bước | +6 | 12 bước |
  | Medium | 4×4 | 1..3 bước | +4 | 14 bước |
  | Hard | 5×5 | 1..4 bước | +3 | 15 bước |

  > Ngân sách thực tế = `max(ngân sách tối thiểu, chi phí đường đi rẻ nhất + dự phòng)`, tính bằng Dijkstra trên trọng số là chi phí ô đích — xem `scripts/modes/countdown_cost_game_mode.gd` (`cheapest_path_cost()` / `_ensure_budget()`).
- **🧠 Blind Memory Maze** — Không số. Hiện toàn bộ tường thật kèm Countdown trực quan (3..2..1..GO!), khóa tương tác lúc đếm. Sau đó tường ẩn, người chơi đi bằng trí nhớ. Tùy chọn Thường (về S) / Hardcore (thua ngay).
- **🌫️ Fog of War Maze** — Có tường vô hình như Play Mode, nhưng chỉ hiện số ở các ô trong bán kính 1 quanh vị trí hiện tại; ô xa ẩn số. Tùy chọn Thường (về S) / Hardcore (thua ngay).

### 5.10. Popup kết quả & Hồi sinh khi thua (Revive)

| Cổng chơi | Mockup popup thua | Nội dung chính | Con dấu (stamp) | Nút HỒI SINH |
|---|---|---|---|---|
| **Play Mode** (Chọn màn) | `popup_game_over_level.svg` | Danh sách **3 Thử thách** kèm trạng thái ĐẠT / CHƯA ĐẠT | **Số Thử thách đã hoàn thành** (ví dụ `1 / 3 ★`) | **Quay lại bước trước đó** |
| **Dungeon Mode** | `popup_game_over_dungeon.svg` | Quãng đường đã đi · số lần va chạm tường vô hình · điểm an ủi tích lũy | **Bước còn lại** khi thua (ví dụ `HẾT BƯỚC — 00 / 20 BƯỚC`) | **Nhận thêm +3 bước để đi tiếp** |

- **Play Mode — hồi sinh = Quay lại bước trước đó:** Play Mode thua vì **đâm vào tường vô hình**; hồi sinh đưa nhân vật **về đúng ô ngay trước bước vừa rồi** (giữ nguyên đường đã vẽ, đồng hồ vẫn chạy). Play Mode **không cộng thêm bước** vì vốn không có giới hạn bước.
- **Dungeon Mode — hồi sinh = Thêm bước:** Dungeon thua vì **hết bước**; hồi sinh **cộng thêm +N bước** (`GameController.revive_bonus_steps`, mặc định **3** — dòng mô tả ở popup tự hiện đúng số này) và chơi tiếp ở **đúng Tầng hiện tại** (không reset về Tầng 1).

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

*(Cơ chế xoay vòng cụ thể — ví dụ thứ tự cố định lặp mỗi 7 ngày, hay random có kiểm soát không lặp liên tiếp — cần thiết kế chi tiết thêm, xem mục 8.)*

---

## 7. Hệ thống Điểm số & Xếp hạng (Scoring & Leaderboards)

- **Sao (Star) — áp dụng MỌI chế độ:** 1 match-up có **3 Challenge**, hoàn thành 1 Challenge = **1 Sao** (xem 3.1). Sao **KHÔNG** còn phụ thuộc thời gian còn lại.
- **Play Mode:** Xếp hạng theo **Thời gian hoàn thành nhanh nhất** cho từng Màn (không xếp theo số bước — Play Mode không giới hạn bước).
- **Dungeon Mode:** Xếp hạng theo **Floor cao nhất đạt được** và tổng điểm tích lũy (chế độ duy nhất có bộ đếm bước còn lại).
- **Time Attack Maze / Blind Memory Maze / Fog of War Maze:** Xếp hạng theo **Thời gian hoàn thành nhanh nhất** cho ngày Daily Challenge tương ứng.
- **Countdown Cost:** Xếp hạng theo **tổng chi phí bước đã dùng** (càng ít càng tốt, đúng tinh thần "tối ưu chi phí"), sau đó mới tới thời gian — hoặc theo cách server tổ chức ngày hôm đó.
- **Sum Path / Area Maze:** Xếp hạng theo **Điểm độ chính xác và thời gian**.
- Ngoài xếp hạng riêng từng bộ luật, Daily Challenge còn có **bảng xếp hạng theo tổng số sao tích lũy trong tháng** và **độ dài Streak**.

