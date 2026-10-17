# Number Maze — Planning: Tinh giản hệ thống Daily Challenge (1 Màn + 1 Challenge)

| | |
|---|---|
| **Tài liệu** | Planning — Cải tiến & Tinh giản Giao diện / Tính năng Daily Challenge |
| **Phiên bản GDD tương ứng** | v2.28 — 2026-10-17 |
| **Phạm vi** | `scenes/daily.tscn` · `scenes/layout/portrait/daily.tscn` · `scenes/layout/landscape/daily.tscn` · `scripts/scenes/daily.gd` · `scripts/scenes/layout/daily_layout.gd` · `scripts/managers/daily_manager.gd` · `nodes/daily/calendar.tscn` |
| **Mockup tham chiếu** | `mockup/daily_challenge.svg` (Dọc 1080×1920) · `mockup/landscape/scenes/daily_challenge_landscape.svg` (Ngang 1920×1080) |
| **Trạng thái** | Kế hoạch triển khai kỹ thuật chi tiết (Implementation Guide) |

---

## 1. Mục tiêu & Tầm nhìn thiết kế (Design Vision)

### 1.1. Vấn đề của thiết kế cũ
- Bảng danh sách 4 nhiệm vụ (3 nhiệm vụ thường + 1 nhiệm vụ đặc biệt) chiếm quá nhiều diện tích, giao diện dày đặc chữ và dễ gây quá tải thông tin cho người chơi di động.
- Nút CTA to dưới đáy màn hình bị tách rời khỏi thông tin nhiệm vụ, luồng trải nghiệm rời rạc (người chơi không rõ bấm nút nào để chơi chế độ nào).
- Cơ chế % tiến độ ngày (ví dụ "50% (2/4 Hoàn thành)") không tạo đủ động lực tích lũy lâu dài trong tháng.

### 1.2. Giải pháp thiết kế mới (v2.28 — Tinh chỉnh hoàn thiện)
1. **Cấu trúc 1 Màn + 1 Challenge:**
   - **Màn chính của ngày (Play):** 1 màn maze tiêu chuẩn theo ngày. Người chơi bấm nút **CHƠI** để vào màn. Hoàn thành nhận **1 Sao**.
   - **Challenge của ngày:** 1 trải nghiệm thử thách khác biệt (Special Mode xoay vòng hoặc Màn với Thử thách). Người chơi bấm nút **CHALLENGE** để chơi. Hoàn thành nhận thêm **1 Sao** (tối đa **2 Sao / ngày**).
2. **Thanh tiến độ Sao tháng — ĐƯA LÊN TRÊN ĐẦU (ngay dưới Top Bar):**
   - Tách khỏi panel hành động bên dưới, đưa lên vị trí trang trọng ngay dưới Top Bar.
   - Thẻ giấy trắng ô ly cao cấp viền `#6EA0C8`, lề đỏ, đổ bóng chuẩn `#sh` như `mainscreen.svg`.
   - Hiển thị trực quan: "TIẾN ĐỘ SAO THÁNG • 14/30 ★", thanh bar vàng hổ phách và 4 mốc thưởng (7★, 14★, 21★, 30★).
   - **Tuyệt đối không dùng văn bản giải thích dài dòng** như "Hoàn thành Challenge..." hay "Màn số 15...".
3. **Lịch tháng sạch đẹp (Day cell KHÔNG chứa sao):**
   - Ô ngày sạch sẽ, số ngày to rõ, chuẩn phong cách vở ô ly học sinh InkMaze.
   - Các ngày đã hoàn thành chỉ đóng **dấu tích mực đỏ (✓)** vẽ tay tự nhiên của học sinh (như cô giáo chấm bài).
   - Ô ngày hôm nay được làm nổi bật viền hổ phách `#C4843A` cùng tag "HÔM NAY".
4. **Ngôi sao (★) nằm trực tiếp trên Button:**
   - Ngôi sao không nằm rải rác trên lịch mà được gắn trực tiếp trên 2 nút hành động:
     - Nút **[CHƠI]**: Huy hiệu capsule chứa icon sao vàng `+1 ★` (hoặc `✓ ĐÃ ĐẠT` khi hoàn thành).
     - Nút **[CHALLENGE]**: Huy hiệu capsule chứa icon sao vàng `+1 ★` và subtitle ngắn gọn thể hiện kiểu chơi (ví dụ "💣 Minesweeper").
   - 2 nút nằm ngang trên cùng một hàng (ở bản dọc), bo góc 24px, đổ bóng 3D chân thực theo đúng ngôn ngữ thiết kế của `mainscreen.svg` và `shopping_pencil.svg`.

---

## 2. Kiến trúc Dữ liệu & Quản lý State (`DailyManager`)

### 2.1. Cấu trúc lưu trữ dữ liệu ngày (`DailyDayRecord`)
Trước đây:
```gdscript
# Cũ:
{
    "day": 10,
    "month": 9,
    "year": 2026,
    "missions": [
        {"id": "no_wall", "completed": true},
        {"id": "steps_max", "completed": true},
        {"id": "time_max", "completed": false},
        {"id": "special_mode", "completed": false}
    ]
}
```

Nay tinh giản thành:
```gdscript
# Mới:
{
    "day": 10,
    "month": 9,
    "year": 2026,
    "play_completed": true,         # Đã hoàn thành Màn chính của ngày
    "challenge_completed": false,   # Đã hoàn thành Challenge của ngày
    "stars": 1                      # Tổng sao đạt được trong ngày (0..2)
}
```

### 2.2. Dữ liệu sao tích lũy tháng & mốc thưởng (`DailyMonthRecord`)
```gdscript
{
    "month_key": "2026_09",
    "total_stars": 14,              # Tổng sao đã tích lũy trong tháng
    "claimed_milestones": [7, 14]   # Các mốc sao đã nhận thưởng
}
```

### 2.3. Bảng mốc thưởng (Milestone Config)
Khai báo hằng số trong `DailyManager`:
```gdscript
const STAR_MILESTONES: Array[Dictionary] = [
    {"stars": 7,  "type": "hint",  "amount": 1, "label": "7★ • Hint ×1"},
    {"stars": 14, "type": "coins", "amount": 50, "label": "14★ • +50 Xu"},
    {"stars": 21, "type": "hint",  "amount": 2, "label": "21★ • Hint ×2"},
    {"stars": 30, "type": "chest", "amount": 150, "label": "30★ • +150 Xu + Cúp"}
]
```

### 2.4. Phương thức bổ sung trong `DailyManager`
- `get_daily_level_data(date: Dictionary) -> LevelData`: Trả về dữ liệu màn chính của ngày.
- `get_daily_challenge_info(date: Dictionary) -> Dictionary`:
  - Trả về: `{ "mode_id": "minesweeper", "title": "💣 Minesweeper Maze", "subtitle": "Dò mìn 5x5", "level_data": ... }`.
- `record_daily_win(date: Dictionary, is_challenge: bool) -> void`:
  - Đánh dấu hoàn thành `play_completed` hoặc `challenge_completed`.
  - Tăng `stars` của ngày và tăng `total_stars` của tháng.
  - Kiểm tra nếu vừa vượt qua mốc sao mới thì phát tín hiệu `milestone_unlocked(stars)`.
- `claim_milestone(star_threshold: int) -> bool`:
  - Nhận phần thưởng của mốc, thêm vào ví người chơi và đánh dấu `claimed_milestones`.

---

## 3. Kiến trúc UI Scene

### 3.1. Bố cục Màn dọc (`scenes/layout/portrait/daily.tscn`)
```
DailyLayout (VBoxContainer)
├── TopHeader (HBoxContainer)
│   ├── BtnBack (Button - 70x70 StyleBox giấy trắng viền #6EA0C8)
│   ├── TitleContainer ("MỖI NGÀY MỘT MÀN SUY LUẬN" / "THỬ THÁCH HẰNG NGÀY")
│   └── StreakBadge (HBoxContainer - "🔥 7 NGÀY")
├── StarProgressCard (PanelContainer - 980x140 px ĐƯA LÊN TRÊN ĐẦU)
│   └── VBoxContainer
│       ├── HeaderRow (HBoxContainer)
│       │   ├── StarIcon + Title ("TIẾN ĐỘ SAO THÁNG 10")
│       │   └── StarCountBadge ("14 / 30 ★")
│       └── ProgressBarContainer (Control - rãnh bar 18px)
│           ├── FillBar (Gradient vàng cam #F59E0B -> #FBBF24)
│           └── MilestoneMarkers (7★, 14★ [Nhận], 21★, 30★ kèm icon rương/sao)
├── CalendarArea (Control / AspectRatio - 980x980 px)
│   └── CalendarBoard (nodes/daily/calendar.tscn)
│       ├── MonthNav (HBoxContainer: Prev, "THÁNG 10 • 2026", Next)
│       ├── WeekdayRow (T2 .. CN)
│       └── DayGrid (7x5 ô ngày: CHỈ hiện số ngày + Dấu tích mực đỏ ✓ khi xong; KHÔNG CÓ SAO Ở CELL)
└── ActionButtonsRow (HBoxContainer - NẰM NGANG TRÊN CÙNG HÀNG)
    ├── BtnPlay (Button - 475x120 px, Gradient xanh mực #3A8BC0 -> #1E5D87)
    │   ├── PlayIcon (Tam giác trắng)
    │   ├── Label ("CHƠI")
    │   └── StarRewardBadge (Capsule: Icon sao vàng ★ + "+1 ★")
    └── BtnChallenge (Button - 475x120 px, Gradient hổ phách #E88A22 -> #B85908)
        ├── LightningIcon (Tia sét)
        ├── VBox (Tiêu đề "CHALLENGE" + Subtitle ngắn gọn "💣 Minesweeper")
        └── StarRewardBadge (Capsule: Icon sao vàng ★ + "+1 ★")
```

### 3.2. Bố cục Màn ngang (`scenes/layout/landscape/daily.tscn`)
Sử dụng bố cục 2 cột (HBoxContainer):
- **Cột Trái (Left Column, x=60, rộng 1020, cao 940 px):**
  - Chứa toàn bộ `CalendarBoard` (khổ 1020×940 px): Lịch tháng sạch đẹp, ô ngày chuẩn vở ô ly với dấu tích mực đỏ ✓.
- **Cột Phải (Right Column, x=1120, rộng 740, cao 940 px):**
  - **Khối 1 (Trên cùng):** `StarProgressCard` (rộng 740, cao 180 px) với thanh tiến độ sao tháng & mốc thưởng.
  - **Khối 2:** 2 Nút hành động lớn xếp dọc:
    - `BtnPlay` (rộng 740, cao 134 px) kèm huy hiệu sao `+1 ★`.
    - `BtnChallenge` (rộng 740, cao 134 px) kèm subtitle kiểu chơi và huy hiệu sao `+1 ★`.
  - **Khối 3:** Bảng danh sách các mốc quà tháng (7★, 14★, 21★, 30★).

---

## 4. Kế hoạch Refactor Script (`daily.gd` & `daily_layout.gd`)

### 4.1. `daily_layout.gd` (Base Layout cho cả 2 hướng)
- **Khai báo `@onready` / `@export` node references:**
  - `btn_play: Button`
  - `btn_challenge: Button`
  - `lbl_play_title: Label`, `lbl_play_sub: Label`
  - `lbl_challenge_title: Label`, `lbl_challenge_sub: Label`
  - `badge_challenge_type: Control`
  - `star_progress_bar: ProgressBar`
  - `lbl_progress_stars: Label`
  - `milestone_container: Control`
  - `lbl_today_status: Label`
- **Signals:**
  - `play_pressed(date)`
  - `challenge_pressed(date, mode_id)`
  - `milestone_claim_requested(star_count)`
  - `day_selected(date)`
- **Methods:**
  - `setup_daily_view(day_data: Dictionary, month_data: Dictionary, challenge_info: Dictionary)`:
    - Cập nhật text, icon và trạng thái của 2 nút (nếu đã xong thì hiện dấu tích/chuyển trạng thái).
    - Cập nhật thanh tiến độ sao (`total_stars / 30`).
    - Cập nhật các mốc thưởng (đã nhận / có thể nhận / chưa mở).

### 4.2. `daily.gd` (Scene Controller)
- Lắng nghe signal từ Layout:
  - `_on_play_pressed()`:
    - Lấy `LevelData` của ngày hôm đó từ `DailyManager`.
    - Gọi `GameManager.start_daily_level(date, level_data)`.
    - Điều hướng sang `scenes/game.tscn`.
  - `_on_challenge_pressed()`:
    - Lấy `challenge_info` của ngày hôm đó.
    - Gọi `GameManager.start_daily_challenge(date, challenge_info.mode_id)`.
    - Điều hướng sang `scenes/game.tscn`.
  - `_on_milestone_claim_requested(star_count)`:
    - Gọi `DailyManager.claim_milestone(star_count)`.
    - Phát hiệu ứng nhận quà, âm thanh coin/fanfare, cập nhật UI.

### 4.3. Cải tiến `nodes/daily/calendar.tscn` (`calendar.gd`)
- Cập nhật hàm vẽ / render ô ngày `CalendarCell`:
  - Đọc `stars` (0, 1 hoặc 2) của ngày tương ứng.
  - Hiển thị 1 hoặc 2 icon ngôi sao nhỏ (★) ở góc dưới ô ngày thay vì nhãn "4/4 XONG" hoặc "2/4 XONG".
  - Giữ lại nhãn "HÔM NAY" nổi bật cho ngày hiện tại.

---

## 5. Lộ trình thực hiện từng bước (Step-by-Step Execution Plan)

### Bước 1: Chuẩn bị Asset & StyleBox
- Tạo/cập nhật StyleBox cho 2 nút Play (`#3D83AE`) và Challenge (`#C4843A`).
- Đảm bảo các icon SVG (Play triangle, Lightning/Star/Chest) sẵn sàng trong `assets/images/icons/`.

### Bước 2: Cập nhật `DailyManager` (`scripts/managers/daily_manager.gd`)
- Thêm cấu trúc lưu trữ `play_completed`, `challenge_completed`, `stars` và `monthly_stars`.
- Viết hàm xác định Challenge của ngày (Special Mode luân phiên 8 ngày).
- Thêm cơ chế nhận thưởng mốc sao.

### Bước 3: Dựng lại Layout Portrait (`scenes/layout/portrait/daily.tscn`)
- Thay thế `MissionList` cũ bằng cụm 2 nút ngang + `StarProgressBar`.
- Đảm bảo layout khớp chuẩn theo mockup `mockup/daily_challenge.svg`.

### Bước 4: Dựng lại Layout Landscape (`scenes/layout/landscape/daily.tscn`)
- Cấu hình lại cột phải cho layout ngang theo mockup `mockup/landscape/scenes/daily_challenge_landscape.svg`.

### Bước 5: Cập nhật Script kết nối (`daily_layout.gd` & `daily.gd`)
- Nối các nút bấm và hàm cập nhật dữ liệu.
- Xử lý chuyển scene khi bấm CHƠI hoặc CHALLENGE.

### Bước 6: Cập nhật Ô lịch (`calendar.gd` / `calendar_cell.gd`)
- Vẽ hiển thị số sao (★) cho từng ô ngày.

### Bước 7: Kiểm thử & Hoàn thiện
- Chạy thử nghiệm trên cả hai hướng màn hình (Portrait & Landscape).
- Kiểm tra tính tương thích dữ liệu save cũ (migration an toàn nếu người chơi đã có tiến trình).
- Đảm bảo không còn lỗi runtime hoặc debugger warning.
