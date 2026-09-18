# HƯỚNG DẪN KIẾN TRÚC & KẾ HOẠCH HỖ TRỢ ĐA TỈ LỆ MÀN HÌNH (PORTRAIT & LANDSCAPE)
## INKMAZE — RESPONSIVE UI ARCHITECTURE & ADAPTIVE LAYOUT SYSTEM

> **Tài liệu tham chiếu thiết kế:** `mockup/aspect/scene/` & `mockup/aspect/game/`  
> **Phiên bản Godot:** Godot 4.x (Mobile / Canvas Items stretch mode)  
> **Mục tiêu:** Đáp ứng trọn vẹn 10 tỉ lệ màn hình (6 Portrait + 4 Landscape), loại bỏ hoàn toàn việc hard-code tọa độ/kích thước trong script, tối đa hóa sức mạnh của hệ thống Container, NinePatch, Anchors và Vector SVG của Godot Engine.

> ### TRẠNG THÁI TRIỂN KHAI (cập nhật 2026-02)
> - **Hạ tầng ĐÃ XONG:** `scripts/scenes/base.gd` tự nhận diện hướng + phát `orientation_changed(is_landscape)`;
>   mỗi màn khai 2 layout con **cùng cấp**: `Portrait` (kế thừa `scenes/orientation/portrait/portrait.tscn`)
>   và `Landscape` (kế thừa `scenes/orientation/landscape/landscape.tscn`) — BaseScene tự bật/tắt theo hướng canvas.
>   Khung nội dung: màn DỌC = cột `clamp(canvas.x, 1080, 1440)` canh giữa · màn NGANG có layout ngang = phủ kín canvas ·
>   màn chưa tách layout = giữ nguyên cột 1080 như cũ.
> - **Helper ĐÃ XONG:** `scripts/utils/auto_fit_label.gd` (AutoFitLabel) cho chữ tự co vừa khung.
> - **Màn đã chuyển sang 2 layout:** Main Screen (`nodes/layout/main_{portrait,landscape}.tscn`).
> - **ĐO CANVAS THẬT** (quan trọng khi đọc bảng spec — spec ghi px theo màn hình thật, còn layout chạy theo canvas):
>   `9:16→1080×1920 · 9:18→1080×2160 · 9:19.5→1080×2340 · 9:21→1080×2520 · 3:4 (1080×1440 & 1200×1600)→1440×1920 ·
>   4:3→2560×1920 · 16:9→3413×1920 · 18:9→3840×1920 · 19.5:9→4160×1920`.
>   ⇒ Màn NGANG canvas CAO ĐÚNG **1920** nên cỡ chữ/khung trong layout ngang phải lấy **× 1.778** so với số px trong spec.
> - **CÒN LẠI:** các màn khác (splash/title/levels/chapters/daily/settings/shop/ranking/archivement/game…) chưa tách layout ngang;
>   art thẻ chế độ ở Main bị kéo ngang khi thẻ ngang (cần art ngang hoặc StyleBoxTexture 9-slice); chưa áp safe-area tai thỏ.

---

## 1. NGUYÊN TẮC THIẾT KẾ CỐT LÕI (CORE PRINCIPLES)

```
                       ┌───────────────────────────────┐
                       │  Viewport Canvas (Expand)     │
                       └──────────────┬────────────────┘
                                      │
               ┌──────────────────────┴──────────────────────┐
               ▼                                             ▼
     [Portrait: aspect < 1.0]                      [Landscape: aspect >= 1.0]
┌──────────────────────────────┐              ┌──────────────────────────────┐
│  BỐ CỤC 1 CỘT DỌC            │              │  BỐ CỤC 2 CỘT NGANG          │
│  - Top Header (Safe Area)    │              │  ┌────────────┬────────────┐ │
│  - HUD / Thông tin chính     │              │  │ Cột Trái   │ Cột Phải   │ │
│  - Board / Nội dung (1:1)    │              │  │ Board/Hero │ HUD/Tools  │ │
│  - Tool/Action Footer        │              │  └────────────┴────────────┘ │
└──────────────────────────────┘              └──────────────────────────────┘
```

1. **Tuyệt đối không hard-code tọa độ `position` hay kích thước `size` pixel trong GDScript:**
   - Mọi kích thước và vị trí phải được tính toán tự động thông qua **Godot UI Containers** (`HBoxContainer`, `VBoxContainer`, `AspectRatioContainer`, `MarginContainer`, `FlowContainer`, `GridContainer`).
   - Script chỉ đảm nhận việc cập nhật dữ liệu, bắt tín hiệu (signals), kích hoạt hoạt ảnh (tween) và đổi layout template nếu cần.

2. **Tách biệt Layout (Giao diện hiển thị) và Controller (Logic nghiệp vụ):**
   - Scene Logic (`game.gd`, `main.gd`, `settings.gd`) không cần quan tâm màn hình đang xoay ngang hay dọc; logic kết nối với các UI elements thông qua **%Unique Names** hoặc các Slot Node chuẩn.

3. **Cơ chế co giãn tự nhiên (Elastic & Scalable Layout):**
   - **Tờ giấy menu/bàn cờ (Sheet/Panel):** Dùng `NinePatchRect` hoặc `StyleBoxTexture` với 9-slice để giữ nguyên chi tiết viền vẽ tay (doodle), trong khi thân giấy co giãn mượt mà.
   - **Bàn cờ vuông 1:1:** Dùng `AspectRatioContainer` với tỉ lệ `1.0` để tự động vừa vặn dù màn hình cao (9:21) hay vuông (3:4).
   - **Khoảng lề và notch/camera:** Dùng `MarginContainer` kết hợp hàm đọc `DisplayServer.get_display_safe_area()`.

4. **Tự động co chữ (Auto-Fit Text):**
   - Không để text tràn khung hoặc bị cắt cụt bằng cách kết hợp `autowrap_mode`, `clip_text`, và helper node `AutoFitLabel` tự giảm font size khi vượt quá khung.

5. **SVG Vector Assets:**
   - Sử dụng đồ họa SVG làm Texture gốc cho UI, thiết lập cấu hình 9-slice rõ ràng để không suy giảm chất lượng trên màn hình độ phân giải siêu cao (Retina, 2K, 4K).

---

## 2. PHÂN TÍCH 10 TỈ LỆ MÀN HÌNH TỪ SPEC

Dựa trên toàn bộ bộ spec trong thư mục `mockup/aspect/`:

### A. Nhóm Màn Hình Dọc (Portrait — 6 Tỉ Lệ)
| Tỉ lệ | Độ phân giải chuẩn | Đặc điểm nhận dạng | Thách thức & Giải pháp Container |
| :--- | :--- | :--- | :--- |
| **9:16** | 1080 × 1920 | **Base Portrait** (chuẩn thiết kế gốc) | Chuẩn quy chiếu cho toàn bộ font và margin. |
| **9:18** | 1080 × 2160 | Tương đối dài | Tăng khoảng đệm dọc (Top/Bottom Margin), mở rộng HUD. |
| **9:19.5** | 1080 × 2340 | Chuẩn iPhone / Android hiện đại | Chú trọng Top Safe Area (Dynamic Island / Notch) $\ge 110\text{px}$. |
| **9:21** | 1080 × 2520 | Rất dài (Sony Xperia, Fold gập) | Dùng `VBoxContainer` có khoảng cách dãn đều (`separation` co giãn). |
| **3:4** | 1080 × 1440 | Máy tính bảng vuông (iPad, Tablet) | Chiều cao rất chật: Thu nhỏ Board (800×800) qua `AspectRatioContainer`. |
| **3:4** | 1200 × 1600 | Tablet độ phân giải cao | Rộng rãi bề ngang hơn: Padding ngang tăng lên 60px. |

### B. Nhóm Màn Hình Ngang (Landscape — 4 Tỉ Lệ)
| Tỉ lệ | Độ phân giải chuẩn | Đặc điểm nhận dạng | Thách thức & Giải pháp Container |
| :--- | :--- | :--- | :--- |
| **4:3** | 1600 × 1200 | Tablet xoay ngang | Chiều ngang hẹp cho 2 cột: Cột phải Sidebar hẹp ($\approx 420\text{px}$). |
| **16:9** | 1920 × 1080 | **Base Landscape** (chuẩn ngang) | Chia đôi: Cột Trái 960px (Board), Cột Phải 820px (Sidebar). |
| **18:9** | 2160 × 1080 | Điện thoại dài xoay ngang | Cột Phải mở rộng ($\approx 1000\text{px}$), nút bấm dàn ngang. |
| **19.5:9** | 2340 × 1080 | Màn hình siêu dài ngang có tai thỏ | Cần `MarginContainer` tránh tai thỏ mép trái/phải ($\ge 100\text{px}$). |

---

## 3. BỘ CÔNG CỤ GODOT ENGINE CHO RESPONSIVE UI

### 3.1. Cấu hình Dự Án (`project.godot`)
Đảm bảo các thiết lập sau luôn có hiệu lực:
```ini
[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=6 ; ORIENTATION_SENSOR (xoay tự do)
```
- Khi dùng `expand`, kích thước canvas thực tế của Viewport sẽ thay đổi tương ứng theo cửa sổ hoặc độ phân giải máy, giữ nguyên tỉ lệ pixel 1:1, không bị kéo dẹt (stretch distortion).

### 3.2. Quy Tắc Ứng Dụng Từng Loại Container

```
┌────────────────────────────────────────────────────────────────────────┐
│ MarginContainer (Safe Area Margin)                                     │
│  └─ NinePatchRect (Trang giấy sổ Menu / Khung nền có ghim còng)         │
│      └─ BoxContainer (VBox hoặc HBox tùy theo Orient)                  │
│          ├─ AspectRatioContainer (ratio = 1.0 -> Bàn cờ vuông vắn)    │
│          ├─ FlowContainer (Dàn huy hiệu, tags, danh sách nút)          │
│          └─ ScrollContainer (Đảm bảo không bao giờ bị cắt ở màn lùn)  │
└────────────────────────────────────────────────────────────────────────┘
```

1. **`AspectRatioContainer` (Cố định tỷ lệ vàng):**
   - Cực kỳ quan trọng cho Bàn cờ game (`ratio = 1.0`), Nút vuông Danh hiệu (`ratio = 1.0`), Khung Lịch Tháng.
   - Khi màn hình bị co hẹp theo bất kỳ chiều nào, Bàn cờ tự động co lại mà không bị méo hình.
   - Thiết lập: `stretch_mode = STRETCH_FIT`, `alignment_horizontal = ALIGNMENT_CENTER`, `alignment_vertical = ALIGNMENT_CENTER`.

2. **`NinePatchRect` / `StyleBoxTexture` (Khung giấy & Nút vẽ tay):**
   - Khung giấy nền `main_menu_paper.svg`, `panel_hint_guide.svg`, thẻ game `card_mode_level_normal.svg`.
   - Cần thiết lập `patch_margin_left`, `patch_margin_top`, `patch_margin_right`, `patch_margin_bottom` đúng với độ dày viền vẽ nét chì (thường từ 24px đến 48px).
   - `axis_stretch_horizontal = AXIS_STRETCH_MODE_TILE_FIT` hoặc `STRETCH`.

3. **`HFlowContainer` / `VFlowContainer`:**
   - Dùng cho: Dòng Tags huy hiệu màn chơi (`MÀN 04`, `CHƯƠNG 01`), danh sách bút trong Shop, các điều kiện thử thách (1/3 ✓).
   - Khi chiều ngang không đủ (ví dụ màn hình 4:3 ngang hoặc 3:4 dọc), các thẻ phụ tự động rớt xuống dòng thay vì đè lên nhau.

4. **`BoxContainer` (`HBoxContainer` & `VBoxContainer`):**
   - Tuyệt đối dùng `size_flags_horizontal` và `size_flags_vertical`:
     - `SIZE_EXPAND_FILL` (3): Chiếm trọn không gian trống còn lại.
     - `SIZE_SHRINK_CENTER` (4): Canh giữa mà không bị phình to.
   - Thiết lập `theme_override_constants/separation` theo token hoặc dùng Node `Control` đóng vai trò Spacer với `size_flags_vertical = SIZE_EXPAND_FILL`.

5. **`MarginContainer` (Xử lý Safe Area động):**
   - Tự động lấy kích thước vùng tai thỏ / notch trên điện thoại:
   ```gdscript
   func update_safe_area() -> void:
       var safe_area := DisplayServer.get_display_safe_area()
       var window_size := DisplayServer.window_get_size()
       # Áp dụng margins tương ứng vào MarginContainer
   ```

---

## 4. CHIẾN LƯỢC QUẢN LÝ TEXT: RESIZE FONT TO FIT

Trong các màn hình hẹp (3:4) hoặc khi bản dịch ngôn ngữ dài (tiếng Đức, tiếng Nga, tiếng Tây Ban Nha), text cố định size sẽ làm vỡ khung.

### 4.1. Node Helper: `AutoFitLabel`
Tạo một script dùng chung `res://scripts/utils/auto_fit_label.gd` (hoặc class `AutoFitLabel extends Label`):

```gdscript
class_name AutoFitLabel
extends Label

@export var max_font_size: int = 40
@export var min_font_size: int = 16
@export var step_down: int = 2

func _ready() -> void:
	clip_text = true
	resized.connect(_fit_font_size)
	_fit_font_size()

func set_adaptive_text(new_text: String) -> void:
	text = new_text
	_fit_font_size()

func _fit_font_size() -> void:
	if text.is_empty() or size.x <= 0 or size.y <= 0:
		return
	
	var font := get_theme_default_font()
	if font == null:
		return
		
	var current_size := max_font_size
	while current_size >= min_font_size:
		var string_size := font.get_string_size(text, horizontal_alignment, -1, current_size)
		if string_size.x <= size.x and string_size.y <= size.y:
			break
		current_size -= step_down
	
	add_theme_font_size_override("font_size", current_size)
```

### 4.2. Cấu hình Label Chuẩn trong Godot 4:
- `autowrap_mode`: Bật `AUTOWRAP_WORD_SMART` cho các đoạn mô tả dài (mô tả thẻ chế độ chơi, mẹo hướng dẫn).
- `text_overrun_behavior`: Bật `OVERRUN_TRIM_ELLIPSIS` để thêm dấu `...` nếu bất khả kháng.

---

## 5. KIẾN TRÚC SCENE LAYOUT: TEMPLATE ADAPTIVE PATTERN

Để tránh việc phải viết lại logic cho từng màn hình khi đổi giữa Portrait và Landscape, áp dụng kiến trúc **Slot-based Layout Templates**:

### 5.1. Cấu Trúc Scene
Mỗi Scene sẽ có 1 Root Script điều phối (`Controller`), chứa 2 nhánh Layout (hoặc nạp động 2 tscn template):

```
Scene Root (Ví dụ: Game.tscn) [Script: game.gd]
├── LayoutHolder (Control, Full Rect)
│   ├── PortraitLayout (tscn instance) [%PortraitTree]
│   └── LandscapeLayout (tscn instance) [%LandscapeTree]
└── Controllers (GameController, GridController, TimerController...)
```

> **CÁCH ĐANG DÙNG TRONG DỰ ÁN (đơn giản hơn — không cần export PackedScene):**
> root khai 2 con **trực tiếp** cùng cấp tên là `Portrait` và `Landscape` — mỗi màn 1 scene trong
> `scenes/orientation/portrait/` · `scenes/orientation/landscape/` (KẾ THỪA scaffold `portrait.tscn` / `landscape.tscn`
> của chính thư mục đó). `BaseScene` tự tìm 2 node
> theo TÊN và bật/tắt theo hướng canvas, phát `orientation_changed(is_landscape)` khi xoay.
> Màn con lấy node bằng `ui("Tên")` / `ui_child("Cha", "Con")` của `BaseScene`
> (KHÔNG dùng `%Unique` vì 2 layout sẽ trùng tên unique — tên node bên trong 2 layout phải GIỐNG NHAU).

Hoặc nạp động (Dynamic Instantiation) để tiết kiệm bộ nhớ:
```gdscript
# base_adaptive_screen.gd
class_name BaseAdaptiveScreen
extends Control

@export var portrait_layout_scene: PackedScene
@export var landscape_layout_scene: PackedScene

var current_layout: Node = null
var is_landscape: bool = false

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_resized)
	_check_and_apply_orientation(true)

func _on_viewport_resized() -> void:
	_check_and_apply_orientation(false)

func _check_and_apply_orientation(force: bool) -> void:
	var vp_size := get_viewport_rect().size
	var landscape_now := vp_size.x > vp_size.y
	
	if landscape_now != is_landscape or force:
		is_landscape = landscape_now
		_switch_layout()

func _switch_layout() -> void:
	if current_layout != null:
		current_layout.queue_free()
		
	var target_scene := landscape_layout_scene if is_landscape else portrait_layout_scene
	if target_scene != null:
		current_layout = target_scene.instantiate()
		%LayoutHolder.add_child(current_layout)
		_bind_ui_elements(current_layout)
```

### 5.2. Chuẩn Hóa Tên Node (Unique Name Binding)
Dù ở Portrait hay Landscape, các node tương tác chức năng phải có cùng Unique Name `%`:
- `%BoardContainer`: Nơi chứa Bàn cờ game.
- `%BtnPause`, `%BtnRestart`, `%BtnUndo`, `%BtnHint`: Các nút điều khiển.
- `%TimerLabel`, `%ChallengeLabel`: Hiển thị thông số HUD.
- `%CardPlay`, `%CardDungeon`, `%CardDaily`: Thẻ màn hình chính.

Nhờ vậy, logic trong Script điều khiển (`game.gd`, `main.gd`, v.v.) chỉ cần gọi:
```gdscript
%BtnPause.pressed.connect(_on_pause_pressed)
```
Không phụ thuộc vào việc nút này nằm ở Cột Phải (Landscape) hay Cột Dưới (Portrait).

---

## 6. THIẾT KẾ CHI TIẾT TỪNG MÀN HÌNH

### 6.1. Main Screen (`scenes/main.tscn`)
- **Tài liệu đặc tả:** `mockup/aspect/scene/mainscreen_layout_spect.md`
- **Tài liệu wireframe:** `mainscreen_portrait_wireframe_guide.svg` & `mainscreen_landscape_wireframe_guide.svg`
- **Bố cục Portrait:**
  - `MarginContainer` lề X: 65px (chuẩn 9:16) đến 40px (3:4).
  - Khung giấy `NinePatchRect` chứa 1 `VBoxContainer`:
    1. `LogoBox` + Nút Danh Hiệu (`HBoxContainer`).
    2. `VBoxContainer` chứa 3 Thẻ Chế Độ Chơi (`CardLevel`, `CardDungeon`, `CardDaily`).
    3. `HBoxContainer` chứa 3 Nút Công Cụ (Xếp Hạng, Cửa Hàng, Cài Đặt).
    4. Con dấu Version (`MarginContainer` căn phải/giữa).
- **Bố cục Landscape:**
  - Khung giấy mở rộng theo chiều ngang (1500px đến 2140px).
  - Dùng `HBoxContainer` chia làm 2 cột:
    - **Cột Trái (Hero Column - W: 650px đến 800px):** Logo Khung Lớn, Nút Danh Hiệu to, Con Dấu Version.
    - **Cột Phải (Menu Column - W: 1040px đến 1180px):** 3 Thẻ Chế Độ Chơi (VBox) + 3 Nút Công Cụ dàn ngang phía dưới (HBox).

### 6.2. Settings Screen (`scenes/settings.tscn`)
- **Tài liệu đặc tả:** `mockup/aspect/scene/settings_screen_layout_spect.md`
- **Bố cục Portrait:**
  - 1 `ScrollContainer` chứa 1 cột dọc: Safe Area $\to$ Top Header (Back + Title) $\to$ Mục Âm Thanh $\to$ Mục Điều Khiển $\to$ Mục Hệ Thống (Dropdown, Cloud, ID) $\to$ Thao Tác (Luật chơi, Reset) $\to$ Con Dấu.
- **Bố cục Landscape:**
  - Header trải rộng trên cùng.
  - Thân chia 2 cột `HBoxContainer`:
    - **Cột Trái (Audio & Controls):** Sliders BGM, SFX và 3 Checkboxes (Rung, Gạch an toàn, Dạ quang).
    - **Cột Phải (System & Actions):** Dropdown Ngôn ngữ, Đám mây Cloud, Nút 9 Luật Chơi, Nút Reset mặc định.

### 6.3. Daily Challenge Screen (`scenes/daily.tscn`)
- **Tài liệu đặc tả:** `mockup/aspect/scene/daily_challenge_layout_spect.md`
- **Bố cục Portrait:**
  - 1 Cột dọc: Top Bar (Back + Tiêu đề + Thẻ Streak) $\to$ Khung Lịch Tháng (Calendar Grid 7 cột) $\to$ Khung Thử Thách Ngày (4 Nhiệm vụ) $\to$ Nút Chơi Lớn Chân Trang.
- **Bố cục Landscape:**
  - Chia 2 cột:
    - **Cột Trái:** Khung Lịch Tháng (Calendar Board) cố định 1:1 hoặc 4:3.
    - **Cột Phải:** Thẻ Streak + Dialog 4 Nhiệm Vụ Ngày + Nút Bắt Đầu Chơi.

### 6.4. Chapter Selection & Level Selection (`scenes/chapters.tscn`, `scenes/levels.tscn`)
- **Tài liệu đặc tả:** `mockup/aspect/scene/chapter_selection_layout_spect.md`
- **Bố cục Portrait:**
  - Header $\to$ Thẻ Chương / Grid Danh Sách Màn (Scroll dọc) $\to$ Bottom Action Bar.
- **Bố cục Landscape:**
  - Header gọn bên trên hoặc tích hợp vào thanh sidebar.
  - Sử dụng `GridContainer` tăng số cột (từ 3-4 cột ở Portrait lên 6-8 cột ở Landscape) hoặc `HFlowContainer`.

### 6.5. Shop Screen (`scenes/shop.tscn`) & Ranking Screen (`scenes/ranking.tscn`)
- **Tài liệu đặc tả:** `mockup/aspect/scene/shopping_pencil_layout_spect.md` & `ranking_layout_spect.md`
- **Bố cục Landscape:**
  - Bảng xếp hạng / Chi tiết bút hiển thị dạng Master-Detail (Cột Trái danh sách mục chọn, Cột Phải hiển thị thông số chi tiết & nút Mua/Trang bị).

---

## 7. THIẾT KẾ CHI TIẾT GAMEPLAY & 9 CHẾ ĐỘ CHƠI

### 7.1. Cấu Trúc Bố Cục Toàn Diện Của Màn Chơi (`scenes/game.tscn`)

```
========================= BỐ CỤC DỌC (PORTRAIT) =========================
┌────────────────────────────────────────────────────────┐
│ Status Bar: [Pause]  MÀN 04 (Chương 01)  [Help] [Reset] │
├────────────────────────────────────────────────────────┤
│ HUD Container: [Thời gian: 01:24] [Thử thách: 1/3 ✓]    │
├────────────────────────────────────────────────────────┤
│                                                        │
│             BÀN CỜ VUÔNG (Board Container)             │
│            AspectRatioContainer (Tỉ lệ 1:1)            │
│                 (800x800 đến 980x980)                  │
│                                                        │
├────────────────────────────────────────────────────────┤
│ Banner Hướng Dẫn / Mẹo Lời Khuyên (Hint Guide)         │
├────────────────────────────────────────────────────────┤
│ Controls: [ VẼ ĐƯỜNG / GHI NHỚ ]   [UNDO]   [GỢI Ý]    │
└────────────────────────────────────────────────────────┘

======================== BỐ CỤC NGANG (LANDSCAPE) ========================
┌──────────────────────────────┬─────────────────────────────────────────┐
│                              │ Status: [Pause] MÀN 04 [Help] [Reset]   │
│                              ├─────────────────────────────────────────┤
│                              │ HUD: [Thời gian 01:24] [Thử thách 1/3 ✓]│
│        BÀN CỜ VUÔNG          ├─────────────────────────────────────────┤
│    AspectRatioContainer      │ Banner Mẹo / Luật Chơi (Tip Panel)      │
│        (Tỉ lệ 1:1)           ├─────────────────────────────────────────┤
│    (960x960 đến 1040x1040)   │ Nút Chính: [ VẼ ĐƯỜNG / GHI NHỚ ]       │
│                              ├─────────────────────────────────────────┤
│                              │ Nút Phụ:   [ UNDO ]      [ GỢI Ý ]      │
└──────────────────────────────┴─────────────────────────────────────────┘
```

### 7.2. Đặc Thù Của 9 Chế Độ Chơi (Game Modes)

Toàn bộ 9 chế độ chơi đều kế thừa khung chuẩn trên và chỉ thay đổi nội dung bên trong **HUD Container**:

1. **Matchup Level (Màn Chơi Cơ Bản):**
   - HUD gồm: Đồng hồ thời gian + Thẻ 3 thử thách sao (3 mục tiêu tích dấu xanh ✓).
   - Nút công cụ: Nút Vẽ Đường, Nút Tường chắn, Undo, Hint.
2. **Blind Memory (Ghi Nhớ Mù):**
   - HUD có thêm thanh đếm ngược thời gian ghi nhớ (Memorize Phase) trước khi sương đen che phủ.
   - Nút chính chuyển đổi trạng thái giữa `GHI NHỚ` và `BẮT ĐẦU VẼ`.
3. **Countdown Cost (Đếm Ngược Năng Lượng / Số Bước):**
   - HUD: Thẻ Cost Counter hiển thị số bước còn lại (Segments Bar hoặc Vạch năng lượng).
4. **Dungeon Mode (Hầm Ngục Mê Cung):**
   - HUD: Hiển thị Tầng hiện tại (`TẦNG B2/B10`), Túi đồ chìa khóa / đuốc, Máu (HP hearts).
5. **Fading Ink (Mực Phai Màu):**
   - HUD: Bình mực (Ink Gauge Meter) hiển thị % mực còn lại giảm dần theo chiều dài đường vẽ.
6. **Fog of War (Sương Mù Chiến Trận):**
   - HUD: Bán kính tầm nhìn (Torch Range), Radar quét khu vực.
7. **Minesweeper (Dò Mìn Mê Cung):**
   - HUD: Số cờ còn lại, số ô an toàn đã mở.
8. **One Stroke (Một Nét Vẽ):**
   - HUD: % Độ phủ mê cung (Coverage Progress: `85% / 100%`), Cảnh báo đi trùng đường.
9. **Sum Path / Wall Builder (Đường Tổng Số & Xây Tường):**
   - HUD: Giá trị tổng mục tiêu (Target Sum vs Current Sum), Số tường gạch còn trong tay.

---

## 8. KẾ HOẠCH TRIỂN KHAI THEO GIAI ĐOẠN (ROADMAP)

### Giai Đoạn 1: Xây Dựng Hạ Tầng Nền Tảng (Core Infrastructure)
- [x] **1.1.** Cập nhật `scripts/scenes/base.gd`: Bỏ cơ chế ép chết `DESIGN_WIDTH = 1080` khi ở màn hình ngang; thay thế bằng logic phát hiện hướng màn hình và phát tín hiệu `orientation_changed(is_landscape)`.
  *→ ĐÃ XONG: base.gd bật/tắt `Portrait`/`Landscape`, phát `orientation_changed`, cột dọc nở tối đa 1440; thêm `ui()` / `ui_child()` để lấy node theo layout đang hiển thị.*
- [x] **1.2.** Tạo helper script `res://scripts/utils/auto_fit_label.gd` hỗ trợ co font chữ tự động.
  *→ ĐÃ XONG (`class_name AutoFitLabel`, có `max/min_font_size`, `step_down`, `set_adaptive_text()`).*
- [x] **1.3.** Chuẩn hóa các tài nguyên `StyleBoxTexture` và `NinePatchRect` cho nền giấy, thẻ bài, popup để đảm bảo biên độ co giãn 9-slice không bị lệch nét vẽ.
  *→ ĐÃ XONG CHO MAIN SCREEN: tờ giấy `NinePatchRect` (patch 115/96/64/64) + **thẻ chế độ và nút công cụ = `Button` + `StyleBoxTexture` 9-slice**
  (`resources/settings/styles/menu/*.tres`, sinh bằng `tools/ui/menu_buttons_9slice.py`: thẻ patch 277/60/227/60 — tag/badge/mũi tên không bị kéo méo; nút patch 40).*
  *→ CÒN: các màn khác (levels/daily/shop/ranking…) còn dùng `TextureButton` kéo giãn.*
- [ ] **1.4.** Bổ sung trình quản lý Safe Area (`DisplayServer.get_display_safe_area()`) vào `ScreenManager.gd` hoặc `AppManager.gd`.

### Giai Đoạn 2: Chuẩn Hóa Template Layout Cho Màn Hình Chính & Hệ Thống
- [x] **2.1. Main Screen (`scenes/main.tscn`):**
  Tách/tổ chức layout: Tạo template Dọc và Ngang (hoặc dùng `AdaptiveSplit` container).
  Đảm bảo 3 thẻ Game Mode và 3 nút Utility co giãn nhịp nhàng.
  *→ ĐÃ XONG: `scenes/orientation/portrait/main.tscn` (giữ nguyên bố cục dọc) + `scenes/orientation/landscape/main.tscn`
  (tờ giấy `NinePatchRect` + 2 cột Hero/Menu, dùng `VBoxContainer`/`HBoxContainer`/`CenterContainer`, chữ dùng `AutoFitLabel`;
  thẻ chế độ + nút công cụ đã chuyển sang **`Button` + `StyleBoxTexture` 9-slice**) ·
  tool sinh 9-slice: `tools/ui/menu_buttons_9slice.py`.*
- [ ] **2.2. Settings Screen (`scenes/settings.tscn`):**
  - Dựng layout 2 cột cho Landscape; 1 cột Scroll cho Portrait.
- [ ] **2.3. Chapter & Level Selection (`scenes/chapters.tscn`, `scenes/levels.tscn`):**
  - Áp dụng Grid/Flow Container tự động tăng số cột khi sang Landscape.
- [ ] **2.4. Daily Challenge, Shop, Ranking (`scenes/daily.tscn`, `scenes/shop.tscn`, `scenes/ranking.tscn`):**
  - Cấu trúc lại Lịch tháng và danh sách Bút theo bố cục Master-Detail khi xoay ngang.

### Giai Đoạn 3: Chuẩn Hóa Layout Gameplay & Bàn Cờ Mê Cung
- [ ] **3.1. Game Screen Base (`scenes/game.tscn`):**
  - Đặt Bàn cờ vào `AspectRatioContainer` (tỷ lệ 1:1) để tự căn giữa và không bao giờ bị biến dạng.
  - Tạo cấu trúc 2 cột cho Landscape: Cột trái Bàn cờ, Cột phải Sidebar (Header, HUD, Tip, Controls).
- [ ] **3.2. HUD Hệ Thống (`nodes/hud/`):**
  - Triển khai các biến thể Landscape trong thư mục `nodes/hud/landscape/`.
  - Kết nối dữ liệu từ các Controller (`timer_controller.gd`, `challenge_controller.gd`) độc lập với layout hiển thị.
- [ ] **3.3. Tích hợp 9 Game Modes:**
  - Lần lượt tinh chỉnh các HUD: Blind Memory, Countdown, Dungeon, Fading Ink, Fog of War, Minesweeper, One Stroke, Sum Path, Wall Builder.

### Giai Đoạn 4: Kiểm Thử & Tối Ưu Hóa (QA & Verification)
- [ ] **4.1. Kiểm thử giả lập 10 tỉ lệ màn hình:**
  - Portrait: 9:16 (1080×1920), 9:18 (1080×2160), 9:19.5 (1080×2340), 9:21 (1080×2520), 3:4 (1080×1440, 1200×1600).
  - Landscape: 4:3 (1600×1200), 16:9 (1920×1080), 18:9 (2160×1080), 19.5:9 (2340×1080).
- [ ] **4.2. Kiểm thử xoay máy thời gian thực (Runtime Orientation Switch):**
  - Đảm bảo xoay màn hình trong khi đang chơi không làm mất tiến độ ván cờ, không tạo giật lag hay rò rỉ bộ nhớ.
- [ ] **4.3. Đa ngôn ngữ (Localization verification):**
  - Kiểm tra các ngôn ngữ chữ dài (tiếng Đức, tiếng Nga, tiếng Tây Ban Nha) trên `AutoFitLabel`.

---

## 9. QUY TẮC DÀNH CHO DEVELOPER (CHECKLIST TRƯỚC KHI COMMIT)

1. [ ] Node có bị đặt tọa độ cố định (`position = Vector2(...)`) trong script không? $\to$ **Nếu có, chuyển sang dùng Container hoặc Anchor.**
2. [ ] Bàn cờ có nằm trong `AspectRatioContainer` không? $\to$ **Bắt buộc có để giữ tỉ lệ vuông 1:1.**
3. [ ] Label tiêu đề/nội dung quan trọng có bị che khuất khi chạy ở tỉ lệ 3:4 không? $\to$ **Dùng `AutoFitLabel` hoặc `autowrap_mode`.**
4. [ ] Nền trang giấy có bị vỡ nét ở 4 góc không? $\to$ **Kiểm tra `NinePatchRect.patch_margin`.**
5. [ ] Đã test xoay thử màn hình từ Dọc sang Ngang chưa? $\to$ **Giao diện phải tự động tái cấu trúc mượt mà.**
