# Number Maze — Planning: Hệ thống Tutorial Scene tương tác (Onboarding)

|  |  |
| --- | --- |
| **Tài liệu** | Planning — Tutorial Scene tương tác (bổ sung cho Number Maze GDD) |
| **Phạm vi** | 8 scene: `first_time` · `how_to_play_move` · `how_to_play_checking_wall` · `how_to_play_writting_hint` · `how_to_play_minesweeper` · `how_to_play_one_stroke` · `how_to_play_sum_path` · `how_to_play_wall_builder` |
| **Khác gì với hệ đã có** | Game đã có **popup hướng dẫn tĩnh** (3 trang ảnh SVG, mở bằng nút "?", xem §10.2d trong GDD). Hệ **tutorial scene** này là lớp **onboarding chủ động, có tương tác thật** — chèn một bàn cờ mini để người chơi **tự thao tác đúng luật** trước khi vào màn thật. Hai hệ **song song tồn tại**: tutorial scene chỉ chạy **1 lần** (lần đầu), popup tĩnh luôn có sẵn để tra cứu lại bất cứ lúc nào. |
| **Cập nhật lần này** | Mục 3 được viết lại thành **storyboard chi tiết từng cảnh (beat)** — mỗi cảnh có hoạt cảnh (staging, thời lượng, hiệu ứng) và thoại nguyên văn kèm khoá chuỗi đề xuất, đủ để bàn giao cho người dựng scene/animation |

---

## 1. Nguyên tắc thiết kế chung

1. **Không chặn cứng người chơi cũ**: mỗi scene có nút **Bỏ qua** (trừ khi đang ở giữa 1 bước bắt buộc thao tác — xem mục 3). Người chơi có thể **Bỏ qua toàn bộ** nhóm lõi ngay từ `first_time` (dành cho tester / người chơi đã quen).
2. **Luyện tập không có rủi ro thật**: mọi bàn cờ mini trong tutorial là **bàn cách ly** (không tính Sao, không tính thời gian Daily, không trừ lượt UNDO/GỢI Ý/GỬI thật). Làm sai chỉ nhận phản hồi và **được thử lại vô hạn lần**.
3. **Dạy bằng hành động, không chỉ bằng chữ**: mỗi khái niệm mới đều có bước **"làm thử"** trên bàn mini ngay sau phần giải thích, không dồn hết chữ vào 1 màn hình rồi thoát.
4. **Tái dùng art & luật thật**: bàn mini dùng lại đúng node mẫu của bàn cờ thật (`nodes/game/board_layers.tscn` — ô / tường / neo / vệt mực, xem §v2.17 GDD) để người chơi làm quen đúng cảm giác chạm, không phải học lại giao diện khác.
5. **Đồng hồ màn thật luôn đứng yên** trong lúc overlay tutorial hiện ra — giống cơ chế đã có ở Blind Memory (`memory_countdown.tscn` không có nền mờ, đồng hồ đứng yên khi xem hướng dẫn).
6. **Chỉ dạy phần MỚI**: 4 scene theo chế độ (`minesweeper` / `one_stroke` / `sum_path` / `wall_builder`) **không dạy lại** thao tác kéo đường / đọc số tường cơ bản — giả định người chơi đã qua nhóm lõi. Nếu người chơi vào thẳng Daily Challenge mà **chưa từng qua nhóm lõi** (case hiếm, ví dụ đổi thiết bị/import save), scene chế độ tự chèn thêm 1 bước "Nhắc nhanh cách kéo đường" trước khi vào phần riêng.

---

## 2. Kiến trúc chung (đề xuất)

### 2.1 Thành phần scene

- **`nodes/tutorial/tutorial_overlay.tscn`** — lớp phủ toàn màn hình, gồm:
  - **Backdrop mờ có lỗ spotlight** (cắt vùng sáng quanh khu vực cần chú ý — ô, neo, nút HUD…).
  - **Bong bóng thoại `DialogBubble`** — cùng chất liệu "mẩu giấy" với HUD hiện tại (viền xanh `#6EA0C8`, dòng kẻ ngang `#9FC0D6`) để đồng bộ hình ảnh, không tạo mascot mới nếu chưa chốt (xem mục 7).
  - **`HandPointer`** — sprite bàn tay/ngón trỏ có animation trượt, dùng để minh hoạ thao tác kéo.
  - **Thanh điều hướng dưới**: chấm tiến độ (● ● ○ ○), nút **Tiếp tục**, nút **Bỏ qua**.
- **`scripts/tutorial/tutorial_controller.gd`** — nạp danh sách `TutorialStepData` theo `tutorial_id`, chạy tuần tự, lắng nghe input từ bàn mini, quyết định bước tiếp theo.
- **`resources/tutorial/<tutorial_id>/step_XX.tres`** — resource dữ liệu từng bước (giống triết lý `LevelData`), gồm các trường:

| Trường | Ý nghĩa |
| --- | --- |
| `message_key` | Khoá chuỗi hội thoại hiển thị trong `DialogBubble` |
| `highlight_target` | Toạ độ ô / neo / node HUD cần spotlight |
| `pointer_animation` | Kiểu animation của `HandPointer` (drag / tap / hold) hoặc rỗng nếu không cần |
| `required_action` | `NONE` · `DRAG_PATH` · `DRAG_ANCHOR` · `TAP_CELL` · `SUBMIT` |
| `success_condition` | Điều kiện coi là làm đúng (ô/cạnh cụ thể) |
| `fail_feedback_key` | Chuỗi hiển thị khi thao tác sai (không phải Game Over — chỉ là gợi ý thử lại) |
| `advance_mode` | `AUTO` (tự sang bước sau khi làm đúng) hoặc `MANUAL` (chờ bấm Tiếp tục) |

- **Bàn mini**: mỗi scene cần thao tác dùng lại `board_layers.tscn` nhưng nạp bằng 1 `TutorialBoardData` riêng (kích thước nhỏ, cấu hình tường/số/mìn/điểm cố định — **không random**, để đảm bảo luôn có đúng 1 kịch bản dạy được thiết kế trước).

### 2.2 Trình tự & điểm kích hoạt (trigger)

```
Tạo save mới
   └── first_time (bắt buộc, có thể "Bỏ qua tất cả")
          └── how_to_play_move (auto, liền mạch)
                 └── how_to_play_checking_wall (auto, liền mạch)
                        └── how_to_play_writting_hint (auto, liền mạch)
                               └── vào Play Mode — Chương 1 · Màn 1 (bàn thật)

Lần đầu MỞ mỗi chế độ Daily / màn campaign có mode_id tương ứng:
   Minesweeper   → how_to_play_minesweeper   (chỉ chạy 1 lần / thiết bị)
   One Stroke    → how_to_play_one_stroke
   Sum Path      → how_to_play_sum_path
   Wall Builder  → how_to_play_wall_builder
```

- 4 tutorial nhóm lõi (`first_time` → `how_to_play_writting_hint`) chạy **liền mạch, không quay lại Main Screen giữa chừng**, vì cùng phục vụ cho lần chơi màn 1 đầu tiên.
- 4 tutorial theo chế độ **độc lập với nhau**, kích hoạt đúng thời điểm người chơi **chạm vào chế độ đó lần đầu** — dù đó là Daily Challenge hôm nay hay một màn campaign có gắn `mode_id` (theo §v2.13 GDD, màn khai `mode_id` chạy chế độ Special trên đúng bàn màn thiết kế).
- Cờ hoàn thành lưu theo **thiết bị/tài khoản** (không theo từng màn) — xem schema ở mục 6.

### 2.3 Vòng lặp phản hồi dùng chung cho MỌI bước có thao tác

```
Người chơi thao tác
   ├─ Đúng theo success_condition
   │     → hiệu ứng tích xanh / pháo giấy nhỏ
   │     → advance_mode = AUTO ⇒ tự chuyển bước kế
   │     → advance_mode = MANUAL ⇒ hiện nút Tiếp tục
   └─ Sai (không khớp success_condition)
         → KHÔNG kết thúc/thua — chỉ rung nhẹ + hiện fail_feedback_key
         → giữ nguyên bước, cho thử lại vô hạn
         → sau 2 lần sai liên tiếp: tự thêm gợi ý mạnh hơn (hand pointer lặp lại rõ hơn)
```

### 2.4 Quy ước thời lượng hoạt cảnh dùng chung

Để mọi scene "cảm" đồng nhất, đề xuất dùng chung 1 bộ timing (có thể tinh chỉnh khi polish sau):

| Hiệu ứng | Thời lượng | Easing |
| --- | --- | --- |
| Overlay fade in/out | 0.3 – 0.4s | ease-out / ease-in |
| Spotlight mở/di chuyển sang mục tiêu mới | 0.4s | ease-out |
| `HandPointer` trượt 1 chặng | 0.5 – 0.6s | ease-in-out, lặp cách nhau 0.3 – 0.4s |
| Rung khi thao tác sai | 0.2 – 0.3s | 2–3 nhịp biên độ nhỏ |
| Pháo giấy khi đúng | 0.5 – 0.6s | rơi tự do + fade |
| Toast/chữ nổi cảnh báo (kiểu Wall Builder "CÒN LỆCH") | hiện 0.2s, giữ 0.6s, mờ 0.3s | — |
| Giữ màn hình chờ đọc thoại (khi `advance_mode = AUTO` và không cần thao tác) | 1.5 – 2s trước khi tự chuyển | — |

---

## 3. Storyboard chi tiết từng scene — hoạt cảnh & thoại

> Quy ước đọc bảng: **STT** = số thứ tự cảnh (beat) trong scene · **Hoạt cảnh** = mô tả hình ảnh/animation + thời lượng (dùng bảng 2.4 làm mặc định nếu không ghi riêng) · **Thoại** = nguyên văn hiển thị trong bong bóng, kèm khoá chuỗi đề xuất `STR_TUT_...` · **Thao tác chờ / điều kiện** = input cần validate và cách chuyển cảnh.

### 3.1 `first_time` — Chào mừng người chơi

**Kích hoạt:** ngay khi tạo save mới, trước khi vào Main Screen lần đầu. **Không có bàn mini** — chỉ 4 cảnh slide.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Overlay đen fade in 0.4s → nền giấy kem hiện, logo game scale từ 80%→100% kèm bounce nhẹ 0.5s, âm thanh "trang giấy lật" | `STR_TUT_FIRST_TIME_01`: **"Chào mừng đến với Number Maze!"** | Tự chuyển sau \~2s |
| 2 | Logo mờ dần, thay bằng khung minh hoạ bàn 1×3: nét bút tự vẽ đường từ S sang F trong 1.2s, để lại vệt mực xanh | `STR_TUT_FIRST_TIME_02`: **"Vẽ một đường đi từ điểm BẮT ĐẦU (S) tới điểm KẾT THÚC (F)."** | Nút **Tiếp tục** |
| 3 | Trên khung minh hoạ, các số 0..3 hiện lần lượt trái→phải kiểu "đóng dấu rơi xuống ô" (0.15s/ô, so le) | `STR_TUT_FIRST_TIME_03`: **"Những con số trên mỗi ô sẽ giúp bạn đoán ra đâu là tường vô hình."** | Nút **Tiếp tục** |
| 4 | Khung minh hoạ mờ đi; 2 nút hiện ra — nút lớn **"Bắt Đầu"** nảy nhẹ mỗi 1.5s để thu hút, nút nhỏ **"Bỏ qua tất cả"** mờ hơn ở góc dưới | `STR_TUT_FIRST_TIME_04`: **"Trước khi chơi thật, hãy cùng luyện 3 kỹ năng cơ bản nhé!"** | Bấm **Bắt Đầu** → sang `how_to_play_move`; bấm **Bỏ qua tất cả** → set cả 4 cờ nhóm lõi = true, vào thẳng Play Mode Màn 1 |

**Cờ lưu:** `tutorial_progress.first_time = true`.

---

### 3.2 `how_to_play_move` — Học kéo đường từ S đến F

**Bàn mini:** 1×3 nằm ngang `S — ô giữa — F`, không tường, không hiện số.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Spotlight mở tại ô **S** (0.4s ease-out), viền glow vàng nhạt nhấp nháy chậm | `STR_TUT_MOVE_01`: **"Đây là điểm BẮT ĐẦU (S). Hãy giữ và kéo sang ô bên cạnh."** | Tự sang cảnh 2 sau \~1s |
| 2 | `HandPointer` fade in tại S, trượt sang ô giữa (0.6s), biến mất, lặp lại mỗi 0.4s cho tới khi người chơi chạm | *(giữ nguyên bong bóng cảnh 1)* | **`DRAG_PATH`**: kéo S → ô liền kề. **Đúng**: ô giữa sáng xanh viền dày 0.2s, `HandPointer` biến mất → cảnh 3. **Sai** (kéo chéo/ra ngoài): ô rung 3 nhịp nhỏ (0.3s), bong bóng đổi tạm sang `STR_TUT_MOVE_FAIL_01`: **"Chỉ đi được sang ô NGAY BÊN CẠNH — trên, dưới, trái hoặc phải thôi nhé."** rồi quay lại text gốc sau 1.5s |
| 3 | Spotlight loang rộng trùm ô giữa + F (0.4s), `HandPointer` lặp lại animation trượt ô giữa → F | `STR_TUT_MOVE_02`: **"Giờ kéo tiếp tới F để hoàn thành đường đi."** | **`DRAG_PATH`** tiếp. **Đúng**: chạm F → cảnh 4. **Sai**: rung + `STR_TUT_MOVE_FAIL_02`: **"Gần rồi! Kéo tiếp sang ô liền kề để tới F nhé."** |
| 4 | Pháo giấy nhỏ (10–15 mảnh) bắn từ F 0.6s, đường S–giữa–F nhấp nháy sáng 2 lần, âm thanh "tick" vui | `STR_TUT_MOVE_03`: **"Tuyệt vời! Bạn vừa vẽ xong đường đi đầu tiên."** | Tự fade out overlay sau 1.5s → chuyển `how_to_play_checking_wall` |

**Cờ lưu:** `tutorial_progress.how_to_play_move = true`.

---

### 3.3 `how_to_play_checking_wall` — Đọc số & suy luận tường vô hình

**Bàn mini:** 2×2, S góc trên-trái, F góc dưới-phải, **1 tường vô hình cố định** (giữa 2 ô hàng trên) sao cho chỉ có đúng 1 lối đi không đâm tường.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Spotlight vào ô số **"2"**, số phóng to nhẹ (1→1.3→1, 0.4s) | `STR_TUT_WALL_01`: **"Con số trên mỗi ô cho biết có BAO NHIÊU cạnh quanh ô đó là tường vô hình."** | Tự chuyển sau \~2s |
| 2 | 4 cạnh của ô sáng viền cam mờ lần lượt theo chiều kim đồng hồ (0.3s/cạnh); 2 cạnh đúng giữ sáng cam đậm + hiện icon gạch chéo mờ, kèm số đếm nổi "1" rồi "2" bay lên tại mỗi cạnh | *(giữ nguyên bong bóng cảnh 1)* | Nút **Tiếp tục** |
| 3 | Con trỏ ảo thử kéo ngang qua 1 cạnh tường thật của bàn — đường kẻ chạm giữa cạnh thì "dội" ngược lại (0.3s) kèm rung nhẹ | `STR_TUT_WALL_02`: **"Tường vô hình sẽ CHẶN đường đi — kéo ngang qua đó, đường sẽ không vẽ được."** | Nút **Tiếp tục** |
| 4 | Spotlight mở rộng phủ toàn bàn 2×2, viền S/F nhấp nháy | `STR_TUT_WALL_03`: **"Giờ bạn hãy tự đi từ S tới F — nhớ dùng con số để đoán tường nhé!"** | **`DRAG_PATH`** đích F qua lối không đâm tường. **Sai** (trúng cạnh tường thật): icon tường hiện rõ nét liền đậm + rung 0.3s + `STR_TUT_WALL_FAIL_01`: **"Ối, đó là tường rồi! Thử hướng khác xem."** **Đúng, tới F**: pháo giấy 0.6s + `STR_TUT_WALL_04`: **"Chính xác! Bạn đã dùng con số để đoán đúng tường."** |
| 5 | Bong bóng thu nhỏ về góc dưới, tắt spotlight, giữ nguyên bàn để chuyển mượt sang scene sau | `STR_TUT_WALL_05`: **"Lưu ý: không phải chế độ nào cũng dùng số kiểu này — có chế độ số là mìn, có chế độ số là điểm. Mình sẽ học riêng khi chơi tới."** | Tự chuyển sau \~2s → `how_to_play_writting_hint` |

**Cờ lưu:** `tutorial_progress.how_to_play_checking_wall = true`.

---

### 3.4 `how_to_play_writting_hint` — Vẽ tường nghi ngờ để hỗ trợ suy luận

**Bàn mini:** tái dùng bàn 2×2 ở scene trước, làm rõ 4 điểm neo mỗi ô.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | 4 neo mỗi ô phóng to tạm thời (1.4x, 0.3s rồi về 1x); riêng 2 neo mục tiêu được khoanh tròn nét đứt vàng, nhấp nháy liên tục | `STR_TUT_HINT_01`: **"Bạn có thể kéo nối 2 điểm neo để tự đánh dấu 'tường nghi ngờ' — giúp ghi nhớ suy luận của mình."** | Tự chuyển sau \~1.5s |
| 2 | Không đổi hình | `STR_TUT_HINT_02`: **"Đánh dấu đúng hay sai đều KHÔNG ảnh hưởng tới kết quả màn chơi — đây chỉ là công cụ hỗ trợ riêng bạn."** | Nút **Tiếp tục** |
| 3 | `HandPointer` fade in tại 1 trong 2 neo khoanh tròn, trượt sang neo còn lại (0.5s), lặp lại | `STR_TUT_HINT_03`: **"Hãy thử kéo nối đúng 2 điểm đang được khoanh tròn nhé."** | **`DRAG_ANCHOR`**. **Đúng**: nét đứt "tường nghi ngờ" vẽ dần 0.3s + tích xanh nảy lên. **Sai** (neo khác, không phạt): 2 neo đúng nhấp nháy sáng hơn 1 nhịp + toast nhỏ `STR_TUT_HINT_FAIL_01`: **"Thử đúng 2 điểm đang khoanh tròn nhé."** |
| 4 | Giữ nét đứt vừa vẽ, `HandPointer` lặp lại đúng đường cũ để gợi ý thao tác xoá | `STR_TUT_HINT_04`: **"Kéo lại đúng 2 điểm đó lần nữa để XOÁ đánh dấu."** | **`DRAG_ANCHOR`** lần 2, cùng cặp neo. **Đúng**: nét đứt mờ dần biến mất 0.3s + `STR_TUT_HINT_05`: **"Xoá được rồi! Dễ dàng phải không nào."** |
| 5 | Overlay tối dần toàn màn (0.6s); 3 icon nhỏ (bút vẽ đường / con số / neo tường) bay vào giữa, xếp hàng rồi mờ đi; chuyển cảnh kiểu "lật trang vở" | `STR_TUT_HINT_06`: **"Giờ bạn đã biết đủ 3 kỹ năng cơ bản: vẽ đường — đọc số — đánh dấu nghi ngờ. Cùng vào chơi màn đầu tiên thôi!"** | Bấm nút **"Chơi ngay"** → đóng overlay, vào Chương 1 · Màn 1 |

**Cờ lưu:** `tutorial_progress.how_to_play_writting_hint = true` → khi cả 4 cờ nhóm lõi = true, set thêm `tutorial_progress.core_completed = true`.

---

### 3.5 `how_to_play_minesweeper` — Chế độ Minesweeper (lần đầu chơi)

**Bàn mini:** 3×3, không tường trong, **2 quả mìn cố định** đặt sao cho số quanh đó đủ suy luận ra đúng 1 đường an toàn duy nhất.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Spotlight vào 1 ô mẫu trung tâm, 8 ô lân cận viền vàng cam sáng/tắt theo nhịp thở (pulse 0.8s) | `STR_TUT_MINE_01`: **"Ở chế độ này, con số KHÔNG còn là số tường nữa — mà là SỐ MÌN trong 8 ô xung quanh!"** | Nút **Tiếp tục** |
| 2 | 1 ô minh hoạ (không thuộc bàn luyện) hiện icon bomb rồi "nổ": khói xám + rung màn 0.3s, chữ "BÙM!" nổi lên rồi mờ | `STR_TUT_MINE_02`: **"Đạp trúng ô có mìn ẩn là THUA NGAY LẬP TỨC."** | Nút **Tiếp tục** |
| 3 | Spotlight mở rộng phủ toàn bàn 3×3, S/F nhấp nháy viền xanh/đỏ | `STR_TUT_MINE_03`: **"Giờ hãy dẫn đường từ S tới F — nhớ suy luận từ số để né mìn nhé!"** | **`DRAG_PATH`**. **Sai** (đi vào ô mìn): khói mờ nhẹ (không rung mạnh như cảnh 2), đường vẽ tự lùi 1 ô (undo animation 0.3s) + `STR_TUT_MINE_FAIL_01`: **"Đây là ô có mìn rồi! Thử nhìn lại các số quanh đây xem sao."** **Đúng, tới F an toàn**: pháo giấy + `STR_TUT_MINE_04`: **"Chuẩn luôn! Bạn né được hết mìn."** |
| 4 | Bong bóng thu nhỏ góc dưới, tắt spotlight | `STR_TUT_MINE_05`: **"Bàn Minesweeper thật luôn có ít nhất 1 đường an toàn — cứ suy luận từ số là được."** | Nút **"Đã hiểu, vào chơi!"** → đóng overlay |

**Cờ lưu:** `tutorial_progress.how_to_play_minesweeper = true`.

---

### 3.6 `how_to_play_one_stroke` — Chế độ One Stroke (lần đầu chơi)

**Bàn mini:** 3×3 (lẻ, đảm bảo tồn tại đường Hamilton S→F như luật thật §5.12), tường hiện rõ 100%, không hiện số; có sẵn đúng 1 đường mẫu phủ kín.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Spotlight quét từ trên xuống dọc toàn bộ vách tường (viền tường sáng trắng chạy theo từng đoạn, 1s) | `STR_TUT_ONE_01`: **"Chế độ này KHÔNG có số — tường đã hiện rõ sẵn trên bàn."** | Nút **Tiếp tục** |
| 2 | 9 ô sáng lên lần lượt theo đúng đường mẫu Hamilton (0.25s/ô), để lại vệt xanh nhạt không biến mất, cho tới khi phủ kín | `STR_TUT_ONE_02`: **"Luật đặc biệt: bạn phải đi qua TẤT CẢ các ô, mỗi ô ĐÚNG 1 LẦN, rồi mới được dừng ở F."** | Nút **Tiếp tục** |
| 3 | Bàn reset trạng thái trống; con trỏ ảo thử kéo từ 1 ô đã "đi" (đánh dấu sẵn) quay lại — ô hiện gạch chéo đỏ + nhãn **"ĐÃ ĐI"**, rung nhẹ | `STR_TUT_ONE_03`: **"Đi đè lên ô đã đi qua là THUA NGAY, nên đi tới đâu chắc tới đó nhé."** | Nút **Tiếp tục**, bàn reset sạch để người chơi tự làm |
| 4 | Spotlight tắt, lộ toàn bàn, S nhấp nháy xanh | `STR_TUT_ONE_04`: **"Giờ đến lượt bạn — đi hết cả 9 ô rồi kết thúc ở F nhé!"** | **`DRAG_PATH`**, phủ kín 9 ô rồi dừng F. **Sai (đè ô cũ)**: gạch chéo + nhãn "ĐÃ ĐI" hiện trên ô định đi đè, nước đi bị từ chối + `STR_TUT_ONE_FAIL_01`: **"Ô này đi qua rồi! Chọn ô khác thử xem."** **Sai (chạm F sớm)**: ô F rung nhẹ, nước đi bị từ chối + `STR_TUT_ONE_FAIL_02`: **"Còn ô chưa đi kìa — F chỉ mở khi bạn đã đi hết cả bàn!"** **Đúng (phủ kín + chạm F)**: pháo giấy lớn hơn bình thường, toàn bàn nhấp nháy sáng 2 lần + `STR_TUT_ONE_05`: **"Bạn vừa hoàn thành một nét đầu tiên rồi đó!"** |

**Cờ lưu:** `tutorial_progress.how_to_play_one_stroke = true`.

---

### 3.7 `how_to_play_sum_path` — Chế độ Sum Path (lần đầu chơi)

**Bàn mini:** 3×3, không tường, điểm 1..9 mỗi ô cố định, HUD mini hiện **Tổng hiện tại — Toán tử — Mục tiêu** (ví dụ `0 — = — 8`).

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Spotlight quét từng ô (trái→phải, trên→dưới), điểm số phóng to nhẹ khi được chiếu tới | `STR_TUT_SUM_01`: **"Ở đây, con số là ĐIỂM của ô — không liên quan gì tới tường cả."** | Nút **Tiếp tục** |
| 2 | Spotlight chuyển sang cụm HUD mini, toán tử `=` phóng to nhấp nháy | `STR_TUT_SUM_02`: **"Tổng điểm đường đi của bạn phải khớp đúng điều kiện này."** | Nút **Tiếp tục** |
| 3 | 3 icon `<` `>` `=` hiện lần lượt, mỗi icon kèm chú thích ngắn bay lên rồi mờ (0.6s/icon): "nhỏ hơn" / "lớn hơn" / "bằng đúng" | *(giữ nguyên bong bóng cảnh 2, chỉ đổi hình minh hoạ)* | Nút **Tiếp tục** |
| 4 | Demo tĩnh: con trỏ ảo đi qua 1 ô điểm rồi quay lại đi qua lần 2 — lần đầu số bay lên cộng vào HUD, lần 2 số ô mờ xám không cộng nữa | `STR_TUT_SUM_03`: **"Mỗi ô chỉ tính điểm 1 LẦN, dù bạn có đi qua lại nhiều lần."** | Nút **Tiếp tục** |
| 5 | Spotlight tắt, lộ toàn bàn, S/F nhấp nháy | `STR_TUT_SUM_04`: **"Giờ bạn hãy tìm đường sao cho tổng điểm khớp đúng mục tiêu nhé!"** | **`DRAG_PATH`**. **Sai (tới F, tổng sai)**: khung "Tổng hiện tại" rung đỏ nhẹ, spotlight nháy vào nút UNDO + `STR_TUT_SUM_FAIL_01`: **"Tổng chưa đúng rồi — thử bấm UNDO rồi chọn đường khác xem!"** **Đúng**: pháo giấy + khung "Tổng hiện tại" sáng xanh viền đậm + `STR_TUT_SUM_05`: **"Chuẩn không cần chỉnh!"** |

**Cờ lưu:** `tutorial_progress.how_to_play_sum_path = true`.

---

### 3.8 `how_to_play_wall_builder` — Chế độ Wall Builder (lần đầu chơi)

**Bàn mini:** 3×3, không S/F, không nhân vật, không di chuyển; mọi ô hiện sẵn số tường cần có (kể cả số 0), thiết kế ít nghiệm để luôn suy luận ra đúng đáp án.

| STT | Hoạt cảnh | Thoại | Thao tác chờ / điều kiện |
| --- | --- | --- | --- |
| 1 | Toàn bàn mờ đi trừ khung HUD mini (không có nhân vật/đường đi trên bàn); chữ "không di chuyển" hiện mờ giữa bàn rồi biến mất | `STR_TUT_WB_01`: **"Chế độ này không di chuyển đâu — bạn sẽ TỰ VẼ TƯỜNG sao cho khớp với các con số."** | Nút **Tiếp tục** |
| 2 | Spotlight quét qua từng ô, số 0..4 mỗi ô nổi bật tạm thời | `STR_TUT_WB_02`: **"Mỗi con số là số tường cần có quanh ô đó — từ 0 tới 4."** | Nút **Tiếp tục** |
| 3 | `HandPointer` trượt qua lại giữa 1 cặp neo mẫu được khoanh tròn (0.5s/lượt, lặp) | `STR_TUT_WB_03`: **"Kéo nối 2 điểm neo kề nhau để bật một đoạn tường."** | **`DRAG_ANCHOR`** cặp neo mẫu. **Đúng**: đoạn tường xanh lá (`built`) vẽ dần nét đứt→liền (0.3s) + tích xanh |
| 4 | Spotlight chuyển sang khung HUD "đã vẽ x / y đoạn", số `x` chạy tăng 1 đơn vị đồng bộ đoạn tường vừa vẽ | `STR_TUT_WB_04`: **"Con số này cho biết bạn cần vẽ đủ bao nhiêu đoạn tường."** | Nút **Tiếp tục** |
| 5 | Spotlight tắt, lộ toàn bàn, nút **GỬI** ở thanh hành động nhấp nháy nhẹ gợi ý vị trí | `STR_TUT_WB_05`: **"Giờ hãy tự vẽ đủ tường rồi bấm GỬI nhé!"** | **`DRAG_ANCHOR`** lặp lại nhiều lần + **`SUBMIT`**. **Sai (Gửi khi còn lệch)**: bàn rung toàn bộ 0.3s, chữ đỏ nổi **"CÒN LỆCH n ĐOẠN!"** bay lên giữa bàn rồi mờ (hiện 0.2s, giữ 0.6s, mờ 0.3s) + `STR_TUT_WB_FAIL_01`: **"Chưa khớp hết — thử xem lại các ô còn thiếu tường."** **Đúng (Gửi khớp)**: pháo giấy to, mọi số trên bàn đổi xanh lá đồng loạt (0.4s) + `STR_TUT_WB_06`: **"Chính xác! Mọi con số đã khớp hết rồi."** |

**Cờ lưu:** `tutorial_progress.how_to_play_wall_builder = true`.

---

## 4. Bảng tổng quan nhanh

| Scene | Bàn mini | Số cảnh (beat) | Thao tác chính cần validate | Auto-chuyển tiếp theo |
| --- | --- | --- | --- | --- |
| `first_time` | Không có | 4 | Không | `how_to_play_move` |
| `how_to_play_move` | 1×3, không tường/số | 4 | Kéo đường S→F qua đúng ô liền kề | `how_to_play_checking_wall` |
| `how_to_play_checking_wall` | 2×2, 1 tường cố định | 5 | Kéo đường né đúng tường theo số | `how_to_play_writting_hint` |
| `how_to_play_writting_hint` | 2×2 (tái dùng) | 5 | Kéo nối đúng cặp neo được khoanh, rồi xoá lại | Vào Play Mode Màn 1 |
| `how_to_play_minesweeper` | 3×3, 2 mìn cố định | 4 | Kéo đường né mìn theo số | Đóng overlay, vào bàn thật |
| `how_to_play_one_stroke` | 3×3, tường hiện rõ | 4 | Vẽ đường phủ kín không đi đè | Đóng overlay, vào bàn thật |
| `how_to_play_sum_path` | 3×3, điểm 1..9 | 5 | Vẽ đường có tổng khớp mục tiêu | Đóng overlay, vào bàn thật |
| `how_to_play_wall_builder` | 3×3, không S/F | 5 | Vẽ tường khớp số + bấm Gửi | Đóng overlay, vào bàn thật |

---

## 5. Localization

Toàn bộ khoá chuỗi `STR_TUT_*` đã gắn trực tiếp cạnh từng dòng thoại trong mục 3 (ví dụ `STR_TUT_MOVE_01`, `STR_TUT_WALL_FAIL_01`…), theo quy ước:

- `STR_TUT_<TUTORIAL_ID_VIẾT_TẮT>_<STT>` — thoại chính theo đúng thứ tự cảnh.
- `STR_TUT_<TUTORIAL_ID_VIẾT_TẮT>_FAIL_<N>` — thoại phản hồi khi thao tác sai.
- `STR_TUT_COMMON_SKIP` / `STR_TUT_COMMON_NEXT` / `STR_TUT_COMMON_SKIP_ALL` — chuỗi dùng chung cho nút điều hướng (Bỏ qua / Tiếp tục / Bỏ qua tất cả).

Pipeline sinh chuỗi có thể tái dùng `build_instruction_data.py` (đổi prefix `STR_GI_` → `STR_TUT_`) để không phải viết tool mới từ đầu.

---

## 6. Dữ liệu lưu trạng thái (Save schema)

```jsonc
"tutorial_progress": {
  "first_time": false,
  "how_to_play_move": false,
  "how_to_play_checking_wall": false,
  "how_to_play_writting_hint": false,
  "core_completed": false,        // = true khi cả 4 dòng trên đều true
  "how_to_play_minesweeper": false,
  "how_to_play_one_stroke": false,
  "how_to_play_sum_path": false,
  "how_to_play_wall_builder": false
}
```

- Ghi cờ **ngay khi scene đóng lại** (hoàn tất hoặc bấm Bỏ qua), không đợi thoát app.
- Đề xuất thêm mục **"Xem lại hướng dẫn tương tác"** trong Cài đặt để người chơi **chủ động replay** bất kỳ scene nào trong 8 scene trên (không chỉ dựa vào popup tĩnh) — khi replay thủ công thì không ảnh hưởng cờ đã lưu.

---

## 7. Câu hỏi cần chốt trước khi lập trình

1. **Có nhân vật dẫn chuyện (mascot) hay không?** Hiện đề xuất dùng bong bóng thoại trơn kiểu "mẩu giấy" đồng bộ HUD — nếu muốn có 1 linh vật vẽ tay (bút chì biết nói? chú thỏ giấy?) cần thêm asset + rig animation riêng.
2. **Nhóm lõi có được phép "Bỏ qua tất cả" hay bắt buộc đi hết 3 bước thực hành?** Hiện đề xuất chỉ cho bỏ qua ở đúng `first_time` (trước khi bắt đầu thực hành), không cho bỏ giữa chừng 1 bước đang chờ thao tác.
3. **4 tutorial theo chế độ có bắt buộc hoàn thành mới vào bàn thật không, hay có nút "Bỏ qua" luôn sẵn?** Đề xuất: **luôn có nút Bỏ qua** (khác nhóm lõi) vì đây là Daily Challenge, không nên chặn cứng người chơi đã quen thể loại.
4. **Ngôn ngữ:** chỉ viết tiếng Việt trước hay làm song song VI/EN giống hệ `STR_GI_*` đã có bản dịch EN?
5. **Vị trí trigger `first_time`:** ngay khi tạo save mới (trước Main Screen) hay trì hoãn tới khi người chơi bấm PLAY lần đầu? (đề xuất trong tài liệu này là **trước Main Screen**, để tránh người chơi bấm lung tung trước khi hiểu luật).
6. **Có cần bản Landscape riêng cho tutorial overlay không?** Game đang làm nền tảng đa tỉ lệ 2 layout (Portrait/Landscape — §13.23 GDD); tutorial nên dùng chung khung `Portrait`/`Landscape` sẵn có, cần xác nhận layout HUD mini co giãn tốt ở tỉ lệ ngang.

---

## 8. Đề xuất thứ tự triển khai

| Giai đoạn | Nội dung | Vì sao ưu tiên |
| --- | --- | --- |
| **1** | Dựng khung chung: `TutorialOverlay` + `TutorialController` + `TutorialStepData` + `TutorialBoardData` tái dùng `board_layers.tscn` | Mọi scene sau đều phụ thuộc khung này |
| **2** | `first_time` + `how_to_play_move` | Scene đơn giản nhất, dùng để test luồng auto-chuyển bước + validate `DRAG_PATH` |
| **3** | `how_to_play_checking_wall` + `how_to_play_writting_hint` | Thêm validate `DRAG_ANCHOR`, hoàn thiện nhóm lõi bắt buộc |
| **4** | `how_to_play_minesweeper` + `how_to_play_sum_path` | 2 chế độ không có cơ chế mới ngoài đọc số kiểu khác — tận dụng lại `DRAG_PATH` đã có |
| **5** | `how_to_play_one_stroke` | Cần thêm state "ô đã đi/đã khoá" — phức tạp hơn |
| **6** | `how_to_play_wall_builder` | Cần thêm `SUBMIT` + validate cấu hình tường — phức tạp nhất, làm sau cùng |

---

**Ghi chú:** tài liệu này chỉ là **kế hoạch nội dung, hoạt cảnh & thoại**, chưa đụng tới code/scene thật. Sau khi chốt mục 7, có thể tách thành các task lập trình cụ thể theo đúng thứ tự ở mục 8, mỗi giai đoạn cập nhật lại GDD chính (mục 13.x) như quy trình đang dùng cho các tính năng khác.