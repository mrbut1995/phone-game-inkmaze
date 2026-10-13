# Agent Spec — SỬA LỖI GIAO DIỆN MAIN SCREEN (rev 2 — đã đối chiếu code thật)

> **Đối tượng:** agent lập trình Godot (InkMaze). **Việc:** sửa lỗi bố cục / cỡ / cỡ chữ của Main Screen mới (portrait + landscape) và thẻ sự kiện.
> **Căn cứ:** screenshot game ở cửa sổ 540×~920 + file thật: `project.godot`, `base.gd/tscn`, `main_layout.gd`, `mode_card.gd`, `profile_card.gd`, `event_carousel.gd`, `event_header.gd`, `theme_default.tres`, `card_mode_normal.png`, các `.tscn` của `nodes/main/*` và 2 `main.tscn` layout.
> **Chỉ sửa phần Main Screen mới.** Không đụng gameplay, không đụng màn khác. Quy ước project (scene + script, không hard-code cỡ trong script, chuỗi qua khoá dịch, không emoji) vẫn áp dụng.
> **Cột "Xác minh":** ✅ = đã đọc thẳng trong file đính kèm · ⚠ = suy luận, **phải kiểm tra bằng cách chạy/đọc script chưa có** (ghi rõ trong báo cáo).

---

## 0. Sự thật đã xác minh từ `project.godot` / `base.gd`

| Mục | Giá trị | Hệ quả |
|---|---|---|
| Viewport | **540 × 920** (`viewport_width/height`) | Mockup 1080×1920 ⇒ **K = 0,5 theo chiều rộng**. Cao 920 (không phải 960) ⇒ ngân sách dọc thấp hơn ~40px |
| Stretch | `mode = "viewport"`, `aspect = "expand"` | Game **render ở độ phân giải 540 rồi phóng lên** (mờ trên máy 1080px). GDD §13.10 ghi `canvas_items` — **lệch với project.godot** → xem §8 (quyết định của user, KHÔNG tự đổi) |
| Orientation | `6` (sensor, xoay tự do) | Cả 2 hướng đều phải đúng |
| `base.gd` | `DESIGN_WIDTH = 540`; cột dọc = `clamp(canvas.x, 540, 1440)`; màn ngang có layout riêng ⇒ root phủ kín canvas | Portrait: canvas **540×920** (9:15,3); 9:19,5 → 540×1170; 9:21 → 540×1260; 3:4 → ~690×920 |
| **Canvas NGANG** | với `expand`, chiều cao **giữ 920**, bề rộng = 920 × tỉ lệ | 16:9 → **~1636×920**; 19,5:9 → ~1993×920. **KHÔNG phải 960×540** ⇒ xem §2.4 và lỗi **#17** |

Bước đầu tiên của agent: xác nhận lại bảng trên (đặc biệt canvas ngang bằng cách in `get_viewport_rect().size` ở layout ngang) rồi mới sửa.

---

## 1. CHẨN ĐOÁN — lỗi → nguyên nhân → cách sửa

| # | Lỗi trong screenshot | Nguyên nhân | Xác minh | Sửa |
|---|---|---|---|---|
| **1** | Tiêu đề **"Sự kiện đang mở"** biến mất, chỉ còn badge cam `5` | `event_header.tscn`: `Title` là `Label` có `clip_text = true` trong `HBoxContainer`, không expand ⇒ bề rộng tối thiểu ≈ 0 | ✅ | Bỏ `clip_text` ở `Title` (hoặc `size_flags_horizontal = 0` + min size). **Quy tắc chung:** `clip_text=true` chỉ dùng khi node có bề rộng CỐ ĐỊNH; trong Box container phải kèm `size_flags_horizontal = 3` hoặc `custom_minimum_size.x` |
| **2** | **Logo biến mất** (chỉ còn dòng LOGIC & PUZZLE) | `portrait/main.tscn` → `Logo`: min `(0,24)` + `expand_mode = 1` (IGNORE_SIZE) + `size_flags_horizontal = 4` ⇒ rộng 0 | ✅ | `expand_mode = 5` (**Fit Height Proportional**), min `(0, 40)`. Landscape cũng đặt `expand_mode = 5` |
| **3** | **Thanh cuộn xám** dưới hàng thẻ | `event_carousel.tscn`: `horizontal_scroll_mode = 2` (SHOW_ALWAYS) | ✅ | Đổi thành **`3` (SHOW_NEVER)** |
| **4** | Nội dung dồn lên trên, **trống ~250–280px** giữa Dungeon và dock; chữ `VER` lơ lửng giữa màn | Cỡ khối nhỏ hơn mockup×0,5 (§2) + `Stamp` nằm trong `Column` + không có khoảng đệm co giãn | ✅ | Làm đúng §2; thêm `SectionGap`/`BottomGap` (§3); **chuyển `Stamp` ra cuối `Body`, dưới `Dock`** |
| **5** | Thẻ **Play/Dungeon bẹt**, chữ **cắt**: "ÊN TẠI: 1", "KỶ LỤC: TẦNG 0", "CHỌN MÀ…" | `mode_card.tscn`: cao min 75/85 (mockup 131); `Right` rộng min 65 (cần 113); `StatValue` nhận chuỗi dài từ `setup({stat_value})` (nguồn chuỗi nằm ở `main.gd`, chưa xem); mọi nhãn bật `clip_text` ⇒ `Texts` co về ~0 | ✅ (cỡ) · ⚠ (nguồn chuỗi) | §2.2. `StatValue` chỉ `Màn {0}` / `Tầng {0}`; `Title` dùng **AutoFitLabel** (min font 14) thay vì cắt |
| **6** | Chip Xu/Sao/Cài đặt **quá nhỏ** so với hồ sơ | `coin_chip` 63×26, `star_chip` 48×26, `Settings` 32 — mockup 111×44, 95×44, 44×44 | ✅ | §2.1 |
| **7** | Chữ phụ trong thẻ sự kiện, dock **li ti** | Theme: `EventSubLabel/RewardLabel/TimerLabel/ChipLabel/DailyMonth/DailyWeekday = 7`, `DockLabel/ModeCardChip/ModeCardStatLabel/TopProfileXP/EventUnitLabel/EventViewAll = 8` | ✅ | §4 (nâng nhóm 7 → 8, vài mục khác) |
| **8** | Thẻ **Daily**: ô hồng to, trống; `thử thách` nằm giữa ô, xa số `0/3` | `UnitLabel` rộng 98px, canh **giữa**; dữ liệu Daily ảo không có quà | ✅ (UnitLabel trong scene) · ⚠ (quà: cần `EventManager`/`event_card.gd`) | `UnitLabel.horizontal_alignment = 0` + đặt sát số; Daily phải trả 2 quà (`120 Xu`, `Chuỗi 7 ngày`) hoặc **ẩn hàng quà + co `ProgressPanel`**. *(Ghi chú: 3 export `Progress Unit / Cta Label / Reward Container` đang `Assign…` trống trong Inspector là của **màn chi tiết Event** `event.tscn → EventLayout`, KHÔNG phải Main — gán nốt riêng)* |
| **9** | **Chip chủ đề** rộng cố định 70px — chữ dài bị cắt/chạm chip giờ | `event_card.tscn`: `ThemeChip` offset cứng 8→78, `ChipLabel` có `clip_text` | ✅ (scene) · ⚠ (script `event_card.gd` chưa xem) | Script đặt `ThemeChip.size.x = ChipLabel.get_minimum_size().x + 19` (bỏ `clip_text` ở `ChipLabel`); `TimerChip` rộng **78** (offset_left 84) |
| **10** | Nội dung **đè lên lề đỏ** của nền | `Body` margin trái/phải chỉ 6px; lề đỏ nằm trong `nodes/common/parallax_background.tscn` (`SceneBackground`, chưa xem) | ✅ (margin) · ⚠ (vị trí lề đỏ) | §3.1 |
| **11** | Dock: icon **DANH HIỆU là hình tròn trống** | `DockBadges` chưa có icon | ⚠ | Gán icon huy chương (số `x/28` là `Label` con, không nhúng chữ vào ảnh); chưa có asset → vẽ SVG `icon_badge_medal` vào `assets/images/icons/` |
| **12** | (rủi ro) **Vuốt ngang trên thân thẻ có thể không cuộn** | `EventCard` root `mouse_filter = 0 (STOP)`; `BgGradient`, `ProgressPanel` mặc định STOP ⇒ nuốt sự kiện kéo của `ScrollContainer` | ✅ (scene) · ⚠ (hành vi thật) | Root `EventCard.mouse_filter = 1 (PASS)`; `BgGradient`/`ProgressPanel`/`CompletedOverlay` = `2 (IGNORE)`; chỉ `CtaButton` giữ STOP. **Phải thử kéo chuột/touch trên thân thẻ** |
| **13** | Vệ sinh scene | `event_card.tscn`, `event_carousel.tscn` có `uid="uid://event_card_node"` / `"uid://event_carousel_node"` **tự đặt tay (không hợp lệ)**; `event_dots.tscn` dùng CRLF; asset `card_mode_*` chia 2 thư mục (`common/` vs `main/`) | ✅ | Xoá `uid=` tự đặt (Godot tự sinh); chuẩn hoá LF; gom `card_mode_disabled.png` về `common/` |
| **14** | **Chip "CHƯƠNG 2 • BÀN 7×7" không hiện** trên thẻ Play/Dungeon | `mode_card.tscn`: `Chip` là `Panel` min `(0,14)`, `size_flags_horizontal = 0`; `ChipLabel` neo full + `clip_text` ⇒ `Panel` không tự giãn theo chữ ⇒ **rộng 0** | ✅ | Đổi `Chip` thành **`PanelContainer`** (StyleBox có `content_margin_left/right = 7`), `ChipLabel` bỏ neo + bỏ `clip_text` ⇒ tự rộng theo chữ. `setup()` vẫn chỉ đổi màu/chữ |
| **15** | **Chấm phân trang cuối không bao giờ sáng** | `event_carousel.gd::_on_scroll_changed`: `page = round(scroll / (170+9))`, nhưng khi thấy ~2,5 thẻ thì cuộn tối đa chỉ tới ≈ trang `n-2` | ✅ | Khi `scroll_horizontal >= max_scroll - 1` ⇒ `page = n-1`; ngược lại tính như cũ. `snap_to_nearest()` clamp target về `max_scroll` |
| **16** | Một nguồn sự thật bị nhân đôi | `event_carousel.gd`: `CARD_GAP := 9` và `170.0` hard-code **trong khi** scene đã khai khe 9 + cỡ thẻ 170 | ✅ | Đọc từ scene: `hbox.get_theme_constant("separation")`, `_cards[0].size.x` / `custom_minimum_size.x` (đúng quy ước §13.14) |
| **17** | **LANDSCAPE rất có thể bị nhỏ ~59%** (chưa có ảnh) | Canvas ngang cao **920** (§0) nhưng layout ngang đang viết bằng số `K=0,5` (cao 540: TopBar 36, Carousel 270, Right 390, Play 115…) | ⚠ **VERIFY NGAY** | Chụp ảnh ở cửa sổ ngang 1280×720 và 1560×720. Nếu UI chiếm ~59% chiều cao ⇒ áp §2.4 |

---

## 2. BẢNG CỠ CHUẨN (khung 540 = mockup × 0,5) — "hiện tại → cần đặt"

> Đặt trong **`.tscn`**. Không hard-code cỡ trong script.

### 2.1. Portrait (`scenes/layout/portrait/main.tscn`)

| Node | Hiện tại | Cần đặt |
|---|---|---|
| `Body` margin | L6 T5 R-6 B-6 | L = (x lề đỏ) + 8, R = 12, T = 6, B = 6 — §3.1 |
| `TopBar` | min cao 34, khe 4 | cao **44**, khe **8** |
| `ProfileCard` | min 90×35 | **(150, 44)**, `size_flags_horizontal = 3`; **dịch lại offset nội bộ cho cao 44**: `Frame` 36×36, `Name` cao 14, `XPBar` cao 6 (script không đổi) |
| `CoinChip` | 63×26 | **(111, 44)** — icon 24, nút `+` **(22,22)** |
| `StarChip` | 48×26 | **(95, 44)** — icon 22 |
| `Settings` | 32×32 | **(44, 44)**, icon inset 8 |
| `Logo` | (0,24), expand_mode 1 | min **(0, 40)**, `expand_mode = 5` |
| `EventHeader` | min cao 17 | **22**; `Badge` 16×13 → **(18, 15)** |
| `EventCarousel` | min cao 270 | giữ **270**; khe thẻ **9** ✓ |
| **`SectionGap` (MỚI)** | — | `Control` min cao **62**, `size_flags_vertical = 3`, `stretch_ratio = 3` — giữa `EventCarousel` và `Modes` |
| `Modes` | khe 6 | khe **19** |
| `Play` / `Dungeon` | min cao 85 | **132** (= chiều cao art sau khi crop, xem §2.2) |
| **`BottomGap` (MỚI)** | — | `Control` min cao 0, `size_flags_vertical = 3`, `stretch_ratio = 2` — sau `Modes` |
| `Stamp` | cuối `Column` | **ra cuối `Body`, dưới `Dock`**, cao 14, canh giữa |
| `Dock` | min cao 50 | **75**; `DockButton` min `(0, 72)`, `Icon` **32×32** (offset ±16, top 8), `Label` cao 14 sát đáy −6, `Badge` 14×14 |

### 2.2. `ModeCard` (`nodes/main/mode_card.tscn` + `mode_card.gd`)

| Node | Hiện tại | Cần đặt |
|---|---|---|
| root min cao | 75 | **132** (sau crop PNG — xem 9-slice) |
| `Content` | offset L15 T6 R-13 B-6, khe 7 | **L39 T14 R-32 B-18**, khe **10** (chừa gáy sổ + lỗ bấm trái; góc gập/răng cưa phải) |
| `IconBox` | 34×34 | **56×56** (icon inset 8) |
| `Texts` | khe 2 | khe **3**, `size_flags_horizontal = 3`; `Title`/`Subtitle` **bỏ `clip_text`** → dùng `AutoFitLabel` (min font 14 / 8) |
| `Chip` | `Panel` rộng 0 (lỗi #14) | `PanelContainer` tự rộng theo chữ, cao 14 |
| `Right` | min rộng 65 | min rộng **113**, `size_flags_horizontal = 0` |
| `StatValue` | chuỗi dài | `Màn {0}` / `Tầng {0}` (sửa khoá dịch + nơi gọi `.format()`) |
| `ActionButton` | min cao 23 | **32** |
| **Style nút trong `_cta_style()`** | `border 3`, `radius 18`, `content_margin 6±sink` (số của khung 1080 nằm trong script) | **Chuyển thành StyleBox khai trong `mode_card.tscn`** (`sb_cta_normal/pressed`); script chỉ `duplicate()` + đổi `bg_color`/`border_color`. Giá trị 540: **border 2, radius 10, content_margin 4 (±sink 2)** |
| `Tape` | 50×12 | giữ ✓ |

**9-slice của `card_mode_normal.png` — số đo thật (ảnh 402×155 = đúng 804×310 ÷ 2 ✓):**

| Thành phần trong ảnh | Vị trí (px, gốc ảnh 402×155) |
|---|---|
| Vùng đặc (opaque) | x 5→394, y 14→145 ⇒ **viền trong suốt: trái 5, phải 8, trên 14, dưới 10** |
| Gáy sổ (vạch dọc) | x ≈ 30 · lỗ bấm x ≈ 18 |
| Góc gập | x 374→394, y 14→34 (20×20) |
| Răng cưa + con dấu tròn | góc dưới-phải, rộng ≈ 48 |

Margin hiện tại `20 / 15 / 30 / 12` **nhỏ hơn** các chi tiết trên ⇒ gáy sổ, góc gập, răng cưa nằm trong vùng bị kéo giãn. Làm một trong hai:
- **A (khuyến nghị):** **crop viền trong suốt** của cả 4 PNG trạng thái về **390×132**, rồi đặt `patch_margin` **L 32 · T 24 · R 52 · B 10**, min cao **132**. (Tape dán đè mép trên bằng node `Tape` — không cần padding trong ảnh.)
- **B:** giữ PNG 402×155, `patch_margin` **L 37 · T 38 · R 60 · B 20**, min cao **155** (card trông cao hơn mockup 24px — chỉnh khe/`SectionGap` bù lại).
Kiểm: ở bề rộng 405 → 445 góc gập vẫn vuông, lỗ bấm tròn, răng cưa không giãn.

### 2.3. Thẻ sự kiện (`nodes/main/event_card.tscn`) — 170×252 **đúng**, chỉnh chi tiết

| Node | Hiện tại | Cần đặt |
|---|---|---|
| `ThemeChip` | offset 8→78 cố định | rộng **theo chữ** (#9), cao 18 |
| `TimerChip` | 92→162 | **84→162** (rộng 78); `TimerLabel` bỏ `clip_text`, canh trái sau icon |
| `UnitLabel` | rộng 98, canh giữa | canh **trái**, sát số `ProgressText` |
| `Reward1/2` | offset cứng | giữ; nếu quà rỗng → `visible=false`, co `ProgressPanel` (min 28) + dời `CtaButton` lên |
| Chuột | root STOP | #12 |
| Art nền | `BackArt` 170×252, SVG `viewBox 340×504, width=170 height=252` | **giữ import scale 1** (project render ở 540 — `svg/scale = 2` chỉ có ý nghĩa nếu chuyển sang `canvas_items`, xem §8) |

### 2.4. Landscape (`scenes/layout/landscape/main.tscn`) — ⚠ **làm sau khi xác minh #17**

Canvas ngang cao **920**. Có 2 cách (chọn **B** trừ khi project đã có cơ chế riêng — đối chiếu `base_layout.gd`/`base_ui.gd` và cách các màn ngang khác như Shop/Levels đang làm):
- **A. Viết số thật cho canvas cao 920:** nhân mọi số ở bảng dưới với **s = 920/540 ≈ 1,70** (và tăng cỡ chữ theo s — khó vì theme dùng chung).
- **B. Khung thiết kế 540 cao + phóng đều (đề xuất):** giữ nguyên các số "design 540" dưới đây, đặt `Landscape.scale = Vector2(s, s)` và `Landscape.size = canvas / s` với `s = canvas.y / 540.0`, tính trong `_after_responsive_layout` (hoặc `BaseLayout`) khi hướng ngang bật. Mọi anchor/container bên trong tự dàn theo `size`.

Số "design 540 cao" (dùng cho cả A×s lẫn B):

| Node | Hiện tại | Cần đặt |
|---|---|---|
| `Body` margin | L7 T5 R-7 B-6 | L/R ≈ 10, T 6, B 6; tránh lề đỏ (§3.1) |
| `TopBar` | cao 36 | **44**; `ProfileCard` **(150,44)**; chip/nút như §2.1 |
| `Logo` | (80,26) | `expand_mode = 5`, min cao **40** |
| `Mid` khe | 12 | **16** |
| `Left` | khe 4 | khe **6**; `EventCarousel` min cao **270** ✓ |
| `Right` | min rộng 390 | min rộng **405** |
| `Modes` | khe 8 | khe **8** |
| `Play`/`Dungeon` | min cao 115 | **132** ⇒ 132×2+8 = **272 ≈ cao carousel 270** (thẳng đáy) |
| `Dock` | min cao 50, khe 8 | **65**, khe **12**; `DockButton` min `(0,62)` (tuỳ chọn biến thể icon-trái/nhãn-phải như mockup) |

---

## 3. CẤU TRÚC DỌC & KHOẢNG TRỐNG

### 3.1. Lề đỏ
1. Tìm x lề đỏ trong `nodes/common/parallax_background.tscn` (đơn vị 540).
2. `Body` margin trái = `x_lề_đỏ + 8`. Nếu carousel còn **< 2,3 thẻ** (~400px) thì cho riêng `EventCarousel` ló ra mép phải (`offset_right` âm bằng margin phải) để thấy 2 thẻ + một phần thẻ 3.
3. Đối chiếu cách Shop/Settings/Levels xử lý lề đỏ rồi làm **giống**.

### 3.2. Phân phối chiều cao (portrait, **540×920**)

Cố định ≈ margin 12 + TopBar 44+4 + [Logo 40+6, Tagline 14+6, Header 22+6, Carousel 270+6, Gap 62+6, Modes 132×2+19] + 4 + Dock 75 + 4 + Stamp 14 ≈ **878** ⇒ dư ≈ **40px ở 920**, nhiều hơn ở 9:19,5 / 9:21. Phần dư chia cho `SectionGap`/`BottomGap` theo **3:2**: khoảng Event↔Play **luôn ≥ 62px** và thoáng dần khi màn cao; dock luôn bám đáy. Màn thấp hơn ~880 ⇒ `Scroll` cuộn dọc, **TopBar và Dock cố định**. `Column` trong `Scroll` cần `size_flags_vertical = 3` để spacer có chỗ giãn.

---

## 4. CỠ CHỮ — `resources/settings/theme_default.tres` (hiện tại → đề xuất)

Project đã dùng 7–8px cho nhiều nhãn phụ (vd `AchCardDesc 8`, `DockLabel 8`) — **sàn mới = 8** cho thông tin chính của thẻ; **không** đặt dưới 8 cho nội dung người chơi cần đọc.

| Variation | Hiện tại | Đề xuất | Lý do |
|---|---|---|---|
| `EventChipLabel` | 7 | **8** | chip chủ đề |
| `EventTimerLabel` | 7 | **8** | đồng hồ đếm ngược — thông tin chính |
| `EventSubLabel` | 7 | **8** | phụ đề 2 dòng (rút ngắn chuỗi nếu tràn) |
| `EventRewardLabel` | 7 | **8** | quà |
| `EventDailyMonth` / `EventDailyWeekday` | 7 / 7 | **8 / 8** | lá lịch |
| `ModeCardStatValue` | 15 | **18–20** | mockup: số "Màn 28"/"Tầng 42" là chữ to nhất của khối phải |
| `ModeCardTitle` | 20 | giữ 20 (AutoFit ≥ 14) | |
| `ModeCardSub`, `ModeCardInfo` | 10, 9 | giữ | |
| `ModeCardChip`, `ModeCardStatLabel`, `DockLabel`, `EventUnitLabel`, `EventViewAll`, `TopProfileXP` | 8 | giữ | đã bằng sàn |
| `EventTitle` 13 · `EventProgressValue` 13 · `EventCtaLabel` 10 · `EventDailyDay` 22 · `EventHeaderTitle` 12 · `TopChipValue` 13 · `TopProfileName` 12 | | giữ | |

Nếu chữ sau khi nâng không vừa: **rút ngắn chuỗi (khoá dịch)** hoặc dùng `AutoFitLabel` — không giảm dưới 8.

---

## 5. KIỂM THỬ & NGHIỆM THU

**Ảnh bắt buộc** (harness `dev_aspects.gd -- --only=main --shots=1` hoặc chụp tay), xem `tmp_aspect/<WxH>/main.png`:
- Dọc: `540×920` · `540×1170` · `540×1260` · `720×960` (3:4).
- Ngang: `1280×720` (16:9) · `1560×720` (19,5:9) · `1440×1080` (4:3).

**Checklist (phải thấy trên ảnh):**
- [ ] Thấy **logo**, tiêu đề **"Sự kiện đang mở"** + badge; **không** thanh cuộn xám dưới thẻ.
- [ ] Carousel: **2 thẻ đầy đủ + 1 phần thẻ 3**; **kéo trên thân thẻ** cuộn được; chấm cuối **sáng được** khi cuộn tới thẻ cuối.
- [ ] Khoảng Event ↔ Play **≥ 62px** (thoáng dần ở màn cao); dock bám đáy; `VER` dưới dock.
- [ ] Play/Dungeon: **chip · tiêu đề · phụ đề · info · nhãn+số · nút** đủ, không chữ cắt (thử en, de, ru); góc gập/răng cưa/lỗ bấm của art **không méo**.
- [ ] TopBar: hồ sơ + Xu + Sao + Cài đặt **cùng cao 44**; số lớn (≥ 6 chữ số) không tràn.
- [ ] Chip chủ đề không cắt chữ ở 5 theme mẫu; thẻ Daily có lá lịch, quà không trống, `thử thách` sát số.
- [ ] Dock có 4 icon thật; chấm đỏ Cửa hàng hoạt động.
- [ ] Nội dung không đè lề đỏ.
- [ ] **Landscape: UI chiếm đúng tỉ lệ như mockup (không nhỏ ~59%)**; 2 cột thẳng đáy; không chữ cắt.
- [ ] Xoay màn nhiều lần: không lỗi, không node mồ côi.

**Test:** `test_main_layout`, `test_ui_scenes`, `test_localization`, `test_event_manager` + toàn suite — không có test nào xanh→đỏ. Test đang khoá giá trị cũ (85, 65, 34…) thì **cập nhật theo §2, không nới assert**.

## 6. KHÔNG ĐƯỢC LÀM
- Không phóng cả `Main` bằng `scale` để chữa cháy portrait (riêng landscape §2.4-B là cơ chế có chủ đích).
- Không hard-code cỡ/offset/style trong script; không `.new()` UI.
- Không emoji; không đặt cỡ chữ < 8.
- Không đổi nghĩa khoá dịch hiện có ngoài `StatValue` — đổi khoá thì cập nhật `string_extra.csv` + chạy `audit_localization.py`.
- **Không tự đổi `stretch/mode`** (xem §8).

## 7. BÁO CÁO CUỐI
Liệt kê: canvas thực tế mỗi hướng · mỗi mục §1 đã sửa (file + node + giá trị) · mục ⚠ đã kiểm ra sao · ảnh trước/sau ở ≥ 3 kích thước (có 1 ảnh ngang) · mục chưa làm được và vì sao.

## 8. VIỆC CẦN USER QUYẾT (agent KHÔNG tự làm)
1. **`stretch/mode`:** project.godot đang `"viewport"` (render 540 rồi phóng ⇒ chữ/SVG mờ trên máy 1080), còn GDD ghi `canvas_items`. Đổi sang `canvas_items` ⇒ nét hơn nhưng ảnh hưởng **mọi màn** → cần kiểm lại toàn game; làm thành ticket riêng.
2. **Crop PNG thẻ giấy (phương án A §2.2)** — cần xuất lại 4 trạng thái cùng một khung crop.
3. Chuỗi hiển thị cuối cùng của Play/Dungeon: giữ "PLAY • CHỌN MÀN" / "DUNGEON MODE" (dài, cần AutoFit) hay dùng "Màn chơi" / "Dungeon" như mockup.
