# Number Maze — Planning: Hệ thống Tutorial Scene tương tác (Onboarding)

| | |
|---|---|
| **Tài liệu** | Planning — Tutorial Scene tương tác (bổ sung cho Number Maze GDD) |
| **Phạm vi** | 8 scene: `first_time` · `how_to_play_move` · `how_to_play_checking_wall` · `how_to_play_writting_hint` · `how_to_play_minesweeper` · `how_to_play_one_stroke` · `how_to_play_sum_path` · `how_to_play_wall_builder` |
| **Khác gì với hệ đã có** | Game đã có **popup hướng dẫn tĩnh** (3 trang ảnh SVG, mở bằng nút "?", xem §10.2d trong GDD). Hệ **tutorial scene** này là lớp **onboarding chủ động, có tương tác thật** — chèn một bàn cờ mini để người chơi **tự thao tác đúng luật** trước khi vào màn thật. Hai hệ **song song tồn tại**: tutorial scene chỉ chạy **1 lần** (lần đầu), popup tĩnh luôn có sẵn để tra cứu lại bất cứ lúc nào. |
| **Trạng thái tài liệu** | Bản planning — chưa lập trình, cần chốt vài quyết định ở mục 7 trước khi triển khai |

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
|---|---|
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

---

## 3. Chi tiết từng scene

### 3.1 `first_time` — Chào mừng người chơi

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Ngay khi tạo save mới, trước khi vào Main Screen lần đầu |
| **Có bàn mini không** | Không — chỉ slide giới thiệu |
| **Bắt buộc / có thể bỏ qua** | Có nút **"Bỏ qua tất cả"** duy nhất ở scene này — bỏ ở đây nghĩa là bỏ luôn 3 scene lõi tiếp theo |

**Các bước:**

1. **Slide 1** — Logo + hình vẽ tay kiểu vở ô ly. Thoại: *"Chào mừng đến với Number Maze!"*
2. **Slide 2** — Minh hoạ 1 bàn cờ nhỏ có đường S→F đã vẽ sẵn (animation vẽ tự động). Thoại: *"Vẽ một đường đi từ điểm BẮT ĐẦU (S) tới điểm KẾT THÚC (F)."*
3. **Slide 3** — Minh hoạ số trên ô mờ dần hiện lên. Thoại: *"Những con số trên mỗi ô sẽ giúp bạn đoán ra đâu là tường vô hình."*
4. **Slide 4** — Thoại: *"Trước khi chơi thật, hãy cùng luyện 3 kỹ năng cơ bản nhé!"* → nút **Bắt Đầu** (chuyển sang `how_to_play_move`) + nút nhỏ **Bỏ qua tất cả**.

**Cờ lưu khi hoàn tất hoặc bấm Bỏ qua tất cả:** `tutorial_progress.first_time = true` (và nếu bỏ qua tất cả thì set luôn 3 cờ còn lại của nhóm lõi = true).

---

### 3.2 `how_to_play_move` — Học kéo đường từ S đến F

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Tự động ngay sau `first_time` |
| **Bàn mini** | **1×3** nằm ngang: `S — ô giữa — F`, **không tường, không hiện số** (để không gây nhiễu, chỉ tập trung vào thao tác kéo) |

**Các bước:**

1. Spotlight vào ô **S**. Thoại: *"Đây là điểm BẮT ĐẦU. Hãy giữ và kéo sang ô bên cạnh."* `HandPointer` trượt từ S sang ô giữa, lặp lại.
2. **Chờ thao tác** (`required_action = DRAG_PATH`, `success_condition` = kéo đúng sang ô liền kề theo 4 hướng).
   - **Sai** (kéo chéo / bỏ qua ô / kéo ra ngoài board): rung nhẹ ô, thoại nhắc: *"Chỉ đi được sang ô NGAY BÊN CẠNH — trên, dưới, trái hoặc phải thôi nhé."*
   - **Đúng**: ô giữa sáng xanh, tự động sang bước 3.
3. Spotlight chuyển sang ô giữa → F, lặp lại animation `HandPointer`. Thoại: *"Giờ kéo tiếp tới F để hoàn thành đường đi."*
4. **Chờ thao tác** tương tự bước 2, đích lần này là **F**.
5. Chạm F: hiệu ứng pháo giấy nhỏ + thoại: *"Tuyệt vời! Bạn vừa vẽ xong đường đi đầu tiên."* → auto chuyển `how_to_play_checking_wall`.

**Cờ lưu:** `tutorial_progress.how_to_play_move = true`.

---

### 3.3 `how_to_play_checking_wall` — Đọc số & suy luận tường vô hình

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Tự động ngay sau `how_to_play_move` |
| **Bàn mini** | **2×2**, S ở góc trên-trái, F ở góc dưới-phải, có đúng **1 tường vô hình cố định** thiết kế sẵn (đặt giữa 2 ô trên) sao cho **chỉ có 1 lối đi không đâm tường** — luôn suy luận được từ số hiển thị, không đoán mò |

**Các bước:**

1. Spotlight vào ô có số **"2"**. Thoại: *"Con số trên mỗi ô cho biết có BAO NHIÊU cạnh quanh ô đó là tường vô hình."*
2. Animation: từng cạnh của ô nhấp nháy đếm **1 → 2**, rồi hiện icon tường mờ minh hoạ (chỉ để giải thích khái niệm, chưa phải tường thật đang chặn).
3. Thoại: *"Tường vô hình sẽ CHẶN đường đi — kéo ngang qua đó, đường sẽ không vẽ được."* Demo tĩnh: con trỏ thử kéo qua cạnh có tường → hiệu ứng bật lại.
4. Nhiệm vụ (`required_action = DRAG_PATH`, đích = F qua đúng lối không đâm tường): Thoại: *"Giờ bạn hãy tự đi từ S tới F — nhớ dùng con số để đoán tường nhé!"*
   - **Sai** (kéo trúng cạnh có tường): hiện icon tường thật + rung + thoại: *"Ối, đó là tường rồi! Thử hướng khác xem."* Cho thử lại từ vị trí hiện tại.
   - **Đúng, tới F**: pháo giấy + thoại: *"Chính xác! Bạn đã dùng con số để đoán đúng tường."*
5. Ghi chú nhanh trước khi chuyển bước: *"Lưu ý: không phải chế độ nào cũng dùng số kiểu này — có chế độ số là mìn, có chế độ số là điểm. Mình sẽ học riêng khi chơi tới."* → auto chuyển `how_to_play_writting_hint`.

**Cờ lưu:** `tutorial_progress.how_to_play_checking_wall = true`.

---

### 3.4 `how_to_play_writting_hint` — Vẽ tường nghi ngờ để hỗ trợ suy luận

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Tự động ngay sau `how_to_play_checking_wall` |
| **Bàn mini** | Dùng lại bàn **2×2** ở bước trước, lần này làm rõ **4 điểm neo mỗi ô** |

**Các bước:**

1. Spotlight khoanh tròn **2 điểm neo liền kề** cụ thể (không phải cạnh tường thật ở bước trước, để tránh nhầm là bắt buộc đúng/sai). Thoại: *"Bạn có thể kéo nối 2 điểm neo để tự đánh dấu 'tường nghi ngờ' — giúp ghi nhớ suy luận của mình."*
2. Nhấn mạnh: *"Đánh dấu đúng hay sai đều KHÔNG ảnh hưởng tới kết quả màn chơi — đây chỉ là công cụ hỗ trợ riêng bạn."*
3. Nhiệm vụ (`required_action = DRAG_ANCHOR`, `success_condition` = đúng cặp neo được khoanh tròn):
   - **Đúng**: nét đứt kiểu "tường nghi ngờ" xuất hiện giữa 2 neo + tích xanh.
   - **Không đúng cặp được khoanh** (kéo neo khác): không phạt, chỉ nhắc lại: *"Thử đúng 2 điểm đang được khoanh tròn nhé."*
4. Dạy thao tác xoá: Thoại: *"Kéo lại đúng 2 điểm đó lần nữa để XOÁ đánh dấu."* (`required_action = DRAG_ANCHOR` lần 2 trên cùng cặp neo).
   - **Đúng**: nét đứt biến mất, thoại xác nhận: *"Xoá được rồi! Dễ dàng phải không nào."*
5. Kết nhóm lõi: *"Giờ bạn đã biết đủ 3 kỹ năng cơ bản: vẽ đường — đọc số — đánh dấu nghi ngờ. Cùng vào chơi màn đầu tiên thôi!"* → đóng `TutorialOverlay`, mở thẳng **Chương 1 · Màn 1** (bàn thật).

**Cờ lưu:** `tutorial_progress.how_to_play_writting_hint = true` → khi cả 4 cờ nhóm lõi đều `true`, hệ thống set thêm cờ tổng hợp `tutorial_progress.core_completed = true` (dùng để các scene theo chế độ tự kiểm tra, xem mục 1.6).

---

### 3.5 `how_to_play_minesweeper` — Chế độ Minesweeper (lần đầu chơi)

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Lần đầu người chơi vào Minesweeper Maze — Daily Challenge hoặc màn campaign có `mode_id = minesweeper` |
| **Bàn mini** | **3×3**, không tường trong, **2 quả mìn cố định** thiết kế sẵn sao cho số ở các ô xung quanh đủ để suy luận ra đúng 1 đường an toàn duy nhất; S góc trên-trái, F góc dưới-phải |

**Các bước:**

1. Thoại: *"Ở chế độ này, con số KHÔNG còn là số tường nữa — mà là SỐ MÌN trong 8 ô xung quanh!"* Animation: 1 ô mẫu sáng lên, 8 ô lân cận viền vàng để minh hoạ cách đếm.
2. Thoại + demo tĩnh: *"Đạp trúng ô có mìn ẩn là THUA NGAY LẬP TỨC."* (hiện icon bomb nổ trên 1 ô minh hoạ, không phải ô thật trong bàn luyện).
3. Nhiệm vụ (`required_action = DRAG_PATH`, đích F qua đường an toàn):
   - **Đi vào ô có mìn**: hiệu ứng nổ nhẹ (chỉ hiệu ứng, KHÔNG kết thúc tutorial) + thoại: *"Đây là ô có mìn rồi! Thử nhìn lại các số quanh đây xem sao."* → lùi lại đúng 1 ô, cho thử tiếp (không giới hạn số lần trong tutorial).
   - **Tới F an toàn**: pháo giấy + thoại: *"Chuẩn luôn! Bạn né được hết mìn."*
4. Kết: *"Bàn Minesweeper thật luôn có ít nhất 1 đường an toàn — cứ suy luận từ số là được."*

**Cờ lưu:** `tutorial_progress.how_to_play_minesweeper = true`.

---

### 3.6 `how_to_play_one_stroke` — Chế độ One Stroke (lần đầu chơi)

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Lần đầu vào One Stroke — Daily Challenge |
| **Bàn mini** | **3×3** (lẻ, để đảm bảo tồn tại đường Hamilton S→F giống luật thật §5.12), **tường hiện rõ 100%**, **không hiện số**; có sẵn đúng 1 đường mẫu phủ kín |

**Các bước:**

1. Thoại: *"Chế độ này KHÔNG có số — tường đã hiện rõ sẵn trên bàn."* Spotlight quét quanh toàn bộ vách tường.
2. Thoại + animation: *"Luật đặc biệt: bạn phải đi qua TẤT CẢ các ô, mỗi ô ĐÚNG 1 LẦN, rồi mới được dừng ở F."* — 9 ô sáng lên lần lượt theo thứ tự mẫu để minh hoạ.
3. Demo: thử "đi đè" lên 1 ô đã tô sẵn → ô hiện gạch chéo + nhãn **"ĐÃ ĐI"**. Thoại: *"Đi đè lên ô đã đi qua là THUA NGAY, nên đi tới đâu chắc tới đó nhé."*
4. Nhiệm vụ (`required_action = DRAG_PATH`, `success_condition` = phủ kín 9 ô rồi dừng ở F):
   - **Đi đè ô cũ**: thoại: *"Ô này đi qua rồi! Chọn ô khác thử xem."* → tự lùi lại đúng 1 bước (như UNDO), không tính là thua thật.
   - **Chạm F khi còn ô chưa đi**: nước đi bị chặn + thoại: *"Còn ô chưa đi kìa — F chỉ mở khi bạn đã đi hết cả bàn!"*
   - **Phủ kín + chạm F**: pháo giấy + thoại: *"Bạn vừa hoàn thành một nét đầu tiên rồi đó!"*

**Cờ lưu:** `tutorial_progress.how_to_play_one_stroke = true`.

---

### 3.7 `how_to_play_sum_path` — Chế độ Sum Path (lần đầu chơi)

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Lần đầu vào Sum Path — Daily Challenge |
| **Bàn mini** | **3×3**, không tường, mỗi ô có điểm số **1..9** cố định, HUD mini hiện **Tổng hiện tại — Toán tử — Mục tiêu** (ví dụ mục tiêu `= 8`) |

**Các bước:**

1. Thoại: *"Ở đây, con số là ĐIỂM của ô — không liên quan gì tới tường cả."* Spotlight từng ô, số nổi bật lên.
2. Spotlight vào cụm HUD mini: Thoại: *"Tổng điểm đường đi của bạn phải khớp đúng điều kiện này."* (giải thích nhanh 3 ký hiệu `<` / `>` / `=`).
3. Thoại: *"Mỗi ô chỉ tính điểm 1 LẦN, dù bạn có đi qua lại nhiều lần."*
4. Nhiệm vụ (`required_action = DRAG_PATH`, `success_condition` = tổng điểm khớp đúng mục tiêu hiển thị khi tới F):
   - **Tới F nhưng tổng sai điều kiện**: thoại: *"Tổng chưa đúng rồi — thử bấm UNDO rồi chọn đường khác xem!"* (spotlight nhẹ vào nút UNDO minh hoạ).
   - **Tới F đúng điều kiện**: pháo giấy + thoại: *"Chuẩn không cần chỉnh!"*

**Cờ lưu:** `tutorial_progress.how_to_play_sum_path = true`.

---

### 3.8 `how_to_play_wall_builder` — Chế độ Wall Builder (lần đầu chơi)

| Trường | Nội dung |
|---|---|
| **Kích hoạt** | Lần đầu vào Wall Builder — Daily Challenge hoặc màn campaign có `mode_id = wall_builder` |
| **Bàn mini** | **3×3**, **không S/F, không nhân vật, không di chuyển**; mọi ô hiện sẵn số tường cần có (kể cả số 0), thiết kế **ít nghiệm** để luôn suy luận ra đúng đáp án |

**Các bước:**

1. Thoại: *"Chế độ này không di chuyển đâu — bạn sẽ TỰ VẼ TƯỜNG sao cho khớp với các con số."* Spotlight quét qua các số trên bàn.
2. Thoại: *"Mỗi con số là số tường cần có quanh ô đó — từ 0 tới 4."*
3. Demo (`required_action = DRAG_ANCHOR`): Thoại: *"Kéo nối 2 điểm neo kề nhau để bật một đoạn tường."* — spotlight khoanh sẵn 1 cặp neo cụ thể để làm mẫu.
   - **Đúng cặp neo**: đoạn tường xanh lá (kiểu `built`) hiện ra + tích xanh.
4. Spotlight vào HUD mini "đã vẽ x / y đoạn": Thoại: *"Con số này cho biết bạn cần vẽ đủ bao nhiêu đoạn tường."*
5. Nhiệm vụ chính (`required_action = DRAG_ANCHOR` lặp lại + `SUBMIT`, `success_condition` = cấu hình tường khớp toàn bộ số trên bàn): Thoại: *"Giờ hãy tự vẽ đủ tường rồi bấm GỬI nhé!"*
   - **Bấm GỬI khi còn sai**: rung bàn + chữ nổi **"CÒN LỆCH n ĐOẠN!"** (giống game thật) + thoại: *"Chưa khớp hết — thử xem lại các ô còn thiếu tường."* (tutorial không giới hạn lượt Gửi).
   - **Bấm GỬI đúng**: pháo giấy + thoại: *"Chính xác! Mọi con số đã khớp hết rồi."*

**Cờ lưu:** `tutorial_progress.how_to_play_wall_builder = true`.

---

## 4. Bảng tổng quan nhanh

| Scene | Bàn mini | Thao tác chính cần validate | Auto-chuyển tiếp theo |
|---|---|---|---|
| `first_time` | Không có | Không | `how_to_play_move` |
| `how_to_play_move` | 1×3, không tường/số | Kéo đường S→F qua đúng ô liền kề | `how_to_play_checking_wall` |
| `how_to_play_checking_wall` | 2×2, 1 tường cố định | Kéo đường né đúng tường theo số | `how_to_play_writting_hint` |
| `how_to_play_writting_hint` | 2×2 (tái dùng) | Kéo nối đúng cặp neo được khoanh, rồi xoá lại | Vào Play Mode Màn 1 |
| `how_to_play_minesweeper` | 3×3, 2 mìn cố định | Kéo đường né mìn theo số | Đóng overlay, vào bàn thật |
| `how_to_play_one_stroke` | 3×3, tường hiện rõ | Vẽ đường phủ kín không đi đè | Đóng overlay, vào bàn thật |
| `how_to_play_sum_path` | 3×3, điểm 1..9 | Vẽ đường có tổng khớp mục tiêu | Đóng overlay, vào bàn thật |
| `how_to_play_wall_builder` | 3×3, không S/F | Vẽ tường khớp số + bấm Gửi | Đóng overlay, vào bàn thật |

---

## 5. Localization (đề xuất khoá chuỗi)

Theo đúng quy ước hiện có của game (`STR_GI_*` cho hệ popup tĩnh), đề xuất namespace riêng cho hệ tutorial tương tác để không đụng hàng:

- `STR_TUT_<TUTORIAL_ID>_<STEP_INDEX>` — ví dụ `STR_TUT_HOW_TO_PLAY_MOVE_01`.
- `STR_TUT_<TUTORIAL_ID>_FAIL_<N>` — chuỗi phản hồi khi làm sai.
- `STR_TUT_COMMON_SKIP` / `STR_TUT_COMMON_NEXT` / `STR_TUT_COMMON_SKIP_ALL` — chuỗi dùng chung cho nút điều hướng.

Pipeline sinh chuỗi có thể tái dùng `build_instruction_data.py` (đổi prefix) để không phải viết tool mới từ đầu.

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
|---|---|---|
| **1** | Dựng khung chung: `TutorialOverlay` + `TutorialController` + `TutorialStepData` + `TutorialBoardData` tái dùng `board_layers.tscn` | Mọi scene sau đều phụ thuộc khung này |
| **2** | `first_time` + `how_to_play_move` | Scene đơn giản nhất, dùng để test luồng auto-chuyển bước + validate `DRAG_PATH` |
| **3** | `how_to_play_checking_wall` + `how_to_play_writting_hint` | Thêm validate `DRAG_ANCHOR`, hoàn thiện nhóm lõi bắt buộc |
| **4** | `how_to_play_minesweeper` + `how_to_play_sum_path` | 2 chế độ không có cơ chế mới ngoài đọc số kiểu khác — tận dụng lại `DRAG_PATH` đã có |
| **5** | `how_to_play_one_stroke` | Cần thêm state "ô đã đi/đã khoá" — phức tạp hơn |
| **6** | `how_to_play_wall_builder` | Cần thêm `SUBMIT` + validate cấu hình tường — phức tạp nhất, làm sau cùng |

---

**Ghi chú:** tài liệu này chỉ là **kế hoạch nội dung & luồng**, chưa đụng tới code/scene thật. Sau khi chốt mục 7, có thể tách thành các task lập trình cụ thể theo đúng thứ tự ở mục 8, mỗi giai đoạn cập nhật lại GDD chính (mục 13.x) như quy trình đang dùng cho các tính năng khác.
