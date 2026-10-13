# Đặc tả cho Agent — Đổi giao diện Main Screen & thêm Event System

> **Đối tượng đọc:** agent lập trình Godot (build Godot 4.7, InkMaze / Number Maze).
> **Nguồn sự thật cuối cùng vẫn là code** — tài liệu này là *yêu cầu thay đổi*. Mọi tên file/class dưới đây là **đề xuất theo quy ước hiện có của project**; agent phải mở project, đối chiếu tên thật (VD autoload, class lưu dữ liệu, helper `ui()`), nếu khác thì **theo project** và ghi chú lại sự khác biệt trong báo cáo.
> **Ngôn ngữ làm việc:** tiếng Việt. Chuỗi hiển thị phải qua hệ dịch (§0.3), không viết cứng.

---

## 0. Đọc trước khi làm

### 0.1. Mockup đính kèm (là "bản vẽ" — không phải code)

| File | Dùng để làm gì |
|---|---|
| `mainscreen.svg` (1080×1920) | **Bố cục DỌC** chuẩn của Main Screen mới |
| `mainscreen_landscape.svg` (1920×1080) | **Bố cục NGANG** chuẩn của Main Screen mới |
| `event_themes_sheet.svg` | Bảng 8 theme thẻ sự kiện + giải phẫu 1 thẻ (kích thước **340×504**) |
| `card_mode_normal.svg` (art có sẵn của user) | Kiểu **thẻ giấy** dùng cho nút **Play** và **Dungeon** |

Mockup chỉ để **đo bố cục & màu**. Chữ trong mockup là `<text>` SVG chỉ để người xem; trong game phải là `Label` (ThorVG của Godot **không render `<text>`** — xem “Quy tắc vàng về art SVG” ở §5.11 của GDD). Số liệu trong thẻ (tên event, số xu, ngày…) là **dữ liệu giả để minh hoạ**.

### 0.2. Việc cần làm — tóm tắt

1. **Đổi Main Screen** (cả 2 hướng): bỏ tờ giấy lớn, sắp lại thẻ/nút/avatar, thêm **danh sách Sự kiện** (carousel thẻ dọc) — **Daily Challenge nằm CHUNG trong danh sách này, ghim đầu**.
2. **Nút Play & Dungeon** đổi sang **thẻ giấy** (`card_mode_normal`), chừa **khoảng trống rộng** giữa danh sách Sự kiện và 2 thẻ này.
3. **Thêm Event System**: dữ liệu (`.tres`), theme theo từng event, quản lý thời gian/tiến độ/phần thưởng, thẻ UI, luồng chơi, Debug Console, test, cập nhật GDD.

Hai chế độ chơi thường trực vẫn là **Play (chọn màn)** và **Dungeon (endless)**. 8 luật Special vẫn **không** có nút riêng — chúng chỉ xuất hiện qua **Daily** và qua **Event** (event dùng lại chính các luật này).

### 0.3. Quy ước bắt buộc của project (đã có trong GDD — KHÔNG được phá)

| Quy ước | Nội dung |
|---|---|
| **Đa tỉ lệ (§13.10, §13.23)** | Mỗi màn = root `BaseScene` + 2 layout con **cùng cấp** `Portrait` / `Landscape` (kế thừa `scenes/orientation/{portrait,landscape}/*.tscn`). Lấy node bằng `ui("Tên")` / `ui_child("Cha","Con")` ⇒ **2 layout PHẢI dùng CÙNG TÊN node** (không dùng `%UniqueName`). Cột dọc = `clamp(canvas.x,1080,1440)`; canvas ngang cao **1920** ⇒ số px của mockup landscape (cao 1080) nhân **×1,778** *hoặc* (tốt hơn) dùng **anchor/ratio + container**. |
| **Không hard-code cỡ trong script (§13.14)** | Cỡ/khe/bố cục lấy từ `.tscn`/art. Script chỉ giữ hệ số co giãn + chính sách min/max. |
| **Node UI lúc chạy phải có scene + script (§13.15)** | Chỉ `instantiate()` → `add_child()` → `setup()`. Cấm `.new()` cho lớp UI (test `test_ui_scenes` sẽ FAIL). Nhớ: node con của root phải ghi `parent="."`; `@onready` chỉ có sau `add_child()`. |
| **Tab / thành phần lặp khai sẵn trong scene (§10.2g)** | Cái gì khai được trong scene thì khai ở scene, không dựng bằng code. |
| **Đa ngôn ngữ (§14)** | Mọi chữ qua khoá `STR_<NHÓM>_<TÊN>` trong `resources/localization/string_extra.csv` (en/vi tối thiểu; bảng chính 19 ngôn ngữ nếu đủ). Chuỗi có tham số dùng `.format()` với `{0}`,`{1}`, **không cộng chuỗi**. Chạy `tools/content/audit_localization.py`, `test_localization` phải xanh. |
| **Không emoji trong UI thật** | Icon là SVG vẽ tay trong `assets/images/icons/`. (Mockup cũ có 🔥🎁⭐ — **đã thay bằng icon vẽ**, đừng đưa emoji trở lại.) |
| **Data-driven** | Theo mẫu Thành tựu (§8.1: mỗi danh hiệu = 1 `.tres`) → mỗi **event = 1 `.tres`**, mỗi **theme = 1 `.tres`**. Thêm event mới không được phải sửa script. |
| **Màu nền UI** | Giấy `#FAF5EB`, lưới 40px `#8FB9D2`, lề đỏ `#D84444`, mực `#224C6D`/`#163A58`, nhãn phụ `#718B9E`. |

---

## PHẦN A — ĐỔI GIAO DIỆN MAIN SCREEN

### A1. Bỏ / giữ / thêm

| | Mục |
|---|---|
| **BỎ** | Tờ giấy lớn (`NinePatchRect` `main_menu_paper.svg`) + lỗ bấm sổ còng + kẹp giấy kim loại + băng washi đỉnh tờ giấy |
| **BỎ** | Thẻ **DAILY CHALLENGE** riêng (thẻ chế độ lớn thứ 3) — Daily chuyển vào danh sách Sự kiện |
| **BỎ** | Khối Hero cũ (logo + tag "LOGIC & PUZZLE" + con dấu + nút DANH HIỆU 224×224) và hàng 3 nút nhỏ (`btn_menu_utility_*`) |
| **GIỮ** | Nền `Background` (giấy kem + lưới ô ly + lề đỏ + 2 dải `SideL/SideR`), logic điều hướng sang Play/Dungeon/Shop/Ranking/Badge/Settings, hiệu ứng bấm nút |
| **THÊM** | Thanh hồ sơ (avatar·cấp·XP) + ví **Xu** + **Sao** + nút **Cài đặt** (bánh răng) trên cùng |
| **THÊM** | **Khối Sự kiện** (tiêu đề + carousel thẻ dọc + chấm phân trang) |
| **ĐỔI** | **Play** & **Dungeon** → thẻ giấy `ModeCard` |
| **ĐỔI** | Nút phụ → **dock 4 nút**: Cửa hàng · Xếp hạng · Danh hiệu · Luật chơi (Cài đặt **dời lên thanh trên**) |

> ⚠ Cần chốt (xem §Câu hỏi mở): **"Luật chơi"** mở màn nào; **cấp/XP/Xu/Sao** có sẵn trong dữ liệu người chơi chưa.

### A2. `ModeCard` — thẻ giấy cho Play & Dungeon

Dùng art `card_mode_normal.svg` (giấy kem `#FFFCF0`, viền `#B7B8AA`, lớp lót `#E4E2D5`, **góc gập trên-phải**, **mép răng cưa dưới-phải**, **gáy sổ + 3 lỗ bấm** bên trái, vạch kẻ ngang, **con dấu tròn** dưới-phải).

**Làm đúng bài (đừng để art bị kéo méo — lỗi đã gặp ở §13.23 mục 5):**
- Chuyển sang `StyleBoxTexture` **9-slice** (hoặc `NinePatchRect`). Patch margin đo lại trên art thật; ước lượng: **trái ≈56** (gáy + lỗ bấm), **phải ≈56** (góc gập 40 + răng cưa 48), **trên/dưới ≈ 8–16**. Phần giữa mới được kéo giãn.
- Làm đủ **4 trạng thái** như các nút khác (`card_mode_{normal,pressed,focus,disabled}.svg`): pressed = lún 3px + giấy sậm hơn; focus = viền nét đứt cam; disabled = bạc màu. Nếu chỉ có bản `normal`, agent **vẽ thêm 3 bản còn lại** theo cùng mẫu `btn_menu_*`.
- 1 scene `nodes/main/mode_card.tscn` + script `ModeCard` (`class_name`), dùng cho cả 2 thẻ, cấu hình bằng `@export`/`setup(data)`.

Bố cục bên trong (rộng 850, cao ≈256 + 6 răng cưa):

| Phần | Vị trí | Nội dung |
|---|---|---|
| `Tape` | góc trên-trái, nghiêng −4°, 100×24 | băng dính màu nhận diện: **Play xanh `#9CCBE8`**, **Dungeon vàng `#F6C453`** |
| `IconBox` | (78,62) 112×112 bo 22 | Play: ô mê cung + đường đỏ · Dungeon: icon lâu đài (SVG) |
| `Chip` | (214,30) cao 28 | Play: `CHƯƠNG 2 • BÀN 7×7` · Dungeon: `CHẾ ĐỘ VÔ TẬN` |
| `Title` | baseline y≈112, cỡ 42 | "Màn chơi" / "Dungeon" |
| `Subtitle` | y≈144, cỡ 18 | "Chọn màn theo chương" / "Leo càng sâu càng khó" |
| `InfoRow` | y≈188 | Play: ⭐ `76 / 90 sao` · Dungeon: cờ `Số bước hữu hạn` |
| `StatLabel` + `StatValue` | khối phải, x = W−290 | Play: `ĐANG CHƠI` / **`Màn 28`** · Dungeon: `KỶ LỤC` / **`Tầng 42`** |
| `ActionButton` | x=W−290, y≈130, 226×64, bo 20 | Play: `TIẾP TỤC` (xanh `#256C96`, viền `#164663`) · Dungeon: `BẮT ĐẦU` (cam `#F59E0B`, viền `#B45309`) |

Dữ liệu: Play lấy **màn/chương đang chơi dở + tổng sao** từ `GameManager` (xem §12); Dungeon lấy **kỷ lục tầng** từ nơi đang lưu điểm Dungeon (§7/§11). **Không có thanh tiến độ** trên Play. Cả thẻ bấm được (vào chế độ); nút bên trong chỉ là điểm nhấn — bấm đâu trong thẻ cũng cùng hành vi (hoặc theo hành vi hiện tại của nút Play/Dungeon nếu khác).

### A5. Thanh trên & Dock

| Thành phần | Hành vi |
|---|---|
| `ProfileCard` (300×88) | avatar tròn viền cam nét đứt + badge `LV.xx` + tên + thanh XP mini + chữ `x / y XP`. Bấm → **Hồ sơ** (nếu chưa có màn hồ sơ: để `disabled`/toast "sắp có", **không tự bịa màn**) |
| `CoinChip` (222×88) | icon giọt mực vàng + số **Xu Mực** + nút `+` → mở **Cửa hàng** (tab nạp/xu) |
| `StarChip` (190×88) | icon sao + **tổng Sao** + chữ "sao" (nguồn: `GameManager`, cùng số dùng mở khoá chương §12.3) |
| `SettingsButton` (88×88) | bánh răng → Settings (như hiện tại) |
| `DockShop` | → Cửa hàng; **chấm đỏ số `1`** khi có quà/ưu đãi chưa nhận (nguồn: banner xem-quảng-cáo-nhận-xu nếu có, ngược lại ẩn) |
| `DockRanking` | → Bảng xếp hạng (§11) |
| `DockBadges` | → Sổ tay thành tựu (§8); icon huy chương hiện `đã mở/28` |
| `DockRules` | → xem §Câu hỏi mở (đề xuất: màn **Tutorial** 7 bài §9.2) |

### A6. Việc code cho Phần A

1. Dựng `main.tscn` ở cả `portrait/` và `landscape/` theo cây node ở A2/A3 (bỏ node tờ giấy, hero, thẻ Daily, hàng nút cũ).
2. Tạo các scene con (mỗi cái có script `class_name`): `nodes/main/{profile_card,coin_chip,star_chip,mode_card,dock_button,event_header,event_dots}.tscn`.
3. `scripts/scenes/main.gd`: rebind theo `ui("…")`; nối `pressed` của Play/Dungeon/Dock/Settings/Coin(+)/Profile; **không** còn tham chiếu node đã bỏ. Chỗ nào đang chờ Daily card → chuyển qua `EventManager` (Phần B).
4. Cập nhật art: thêm `assets/images/main/card_mode_*.svg`, icon dock/top-bar vào `assets/images/icons/`. Có thể xoá `main_menu_paper.svg` & `btn_menu_utility_*` sau khi không còn tham chiếu (kiểm tra bằng grep + test).
5. Cập nhật `test_main_layout` theo node mới; chạy harness `dev_aspects.gd -- --only=main` — **10/10 tỉ lệ OK** (xem ảnh `tmp_aspect/<WxH>/main.png`); đặc biệt kiểm 9:16, 9:21, 3:4, 4:3, 16:9, 19.5:9.
6. Kiểm tra: không còn emoji; không `.new()` UI; mọi chữ có khoá dịch.

---

## PHẦN B — EVENT SYSTEM

### B1. Khái niệm

**Event** = nội dung có **thời hạn** (trừ Daily), hiện thành **1 thẻ dọc 340×504** trong carousel Main Screen, có **theme riêng** (nền, màu, trang trí). Một event thuộc đúng 1 loại:

| `event_type` | Mô tả | Cách đo tiến độ (hiện bằng CHỮ, **không dùng thanh**) | Ví dụ trong mockup |
|---|---|---|---|
| `SPECIAL_SERIES` | Chuỗi màn dùng **luật Special** (mỗi màn khai `mode_id` trong `LevelData`, §10.2f) | `màn đã xong / tổng màn` + đơn vị `chế độ` hoặc `màn` | Halloween (5 chế độ) · Mộ Cổ (4) · Biệt Thự (6 màn dò đường) |
| `STANDARD_SERIES` | Chuỗi màn **chuẩn** (luật Play), có thể có biến thể luật | `đã xong / tổng` + `màn` | Mùa Đông (10 màn) · Cá Tháng Tư (6 màn, luật biến thể) |
| `DUNGEON` | Sự kiện trên **Dungeon**: hệ số thưởng + mốc tầng | `tầng cao nhất trong event / tầng mốc cuối` + `tầng` | Tuần Lễ Dungeon (x2 xu mỗi tầng, mốc 5·10·15·20·25) |
| `LOGIN_STREAK` | Đăng nhập/chơi mỗi ngày trong N ngày | `ngày đã đạt / N` + `ngày` | Năm Mới (7 ngày, lì xì) |
| `DAILY` | **Daily Challenge** — event ảo, **ghim đầu**, không hết hạn theo ngày lịch mà làm mới 00:00 giờ máy | `sao hôm nay / 3` hoặc `thử thách xong / 3` + `thử thách` | Thẻ lá lịch đỏ |

> **Daily KHÔNG được viết lại.** `EventManager` chỉ tạo một `EventData` ảo (không phải file `.tres`) từ logic Daily có sẵn: luật hôm nay = `GameManager.DAILY_MODES[(N-1) % 8]` (§6), 3 thử thách, streak. Bấm nút của thẻ Daily → mở đúng luồng Daily hiện tại.

### B2. Dữ liệu (Resource, data-driven)

Thư mục: `resources/events/` (mỗi event 1 `.tres`) và `resources/events/themes/` (mỗi theme 1 `.tres`). Script ở `scripts/resources/`.

```gdscript
# scripts/resources/event_data.gd
class_name EventData extends Resource
enum Type { SPECIAL_SERIES, STANDARD_SERIES, DUNGEON, LOGIN_STREAK, DAILY }

@export var id: StringName                 # duy nhất, dùng làm khoá lưu & tra chuỗi
@export var type: Type
@export var theme: EventTheme
@export var sort_order: int = 100          # nhỏ hơn = đứng trước (Daily luôn đầu, không phụ thuộc)
@export var enabled: bool = true

# Chữ — CHỈ khoá dịch, không chữ cứng
@export var chip_key: StringName           # "HALLOWEEN"
@export var title_key_1: StringName        # dòng tiêu đề 1 ("Đêm Mực")
@export var title_key_2: StringName        # dòng tiêu đề 2 ("Ma Quái")
@export var sub_key_1: StringName          # phụ đề 2 dòng
@export var sub_key_2: StringName
@export var unit_key: StringName           # "chế độ" / "màn" / "tầng" / "ngày"
@export var cta_key: StringName            # "CHƠI TIẾP", "VÀO HẦM", "NHẬN LÌ XÌ"…

# Thời hạn (UTC, ISO-8601 hoặc unix int; DAILY bỏ qua)
@export var start_utc: String
@export var end_utc: String

# Nội dung theo loại
@export var levels: Array[LevelData]       # SPECIAL_/STANDARD_SERIES: thứ tự chơi
@export var dungeon_coin_multiplier: float = 1.0   # DUNGEON
@export var dungeon_milestones: PackedInt32Array   # DUNGEON: [5,10,15,20,25]
@export var login_days_required: int = 0           # LOGIN_STREAK

# Phần thưởng hoàn thành — thẻ chỉ hiện TỐI ĐA 2 phần
@export var rewards: Array[EventReward]
```

```gdscript
# scripts/resources/event_reward.gd
class_name EventReward extends Resource
enum Kind { COIN, PEN_SKIN, AVATAR_FRAME, COIN_MULTIPLIER }
@export var kind: Kind
@export var amount: int = 0                # COIN: số xu · COIN_MULTIPLIER: hệ số (2 = x2)
@export var item_id: StringName            # PEN_SKIN / AVATAR_FRAME: id vật phẩm trong shop/profile
@export var label_key: StringName          # nhãn ngắn: "500 Xu", "Bút Ma Trơi", "Khung Hoa Mai"
```

```gdscript
# scripts/resources/event_theme.gd
class_name EventTheme extends Resource
@export var id: StringName
@export var bg_stops: PackedColorArray      # gradient dọc (2–3 màu) — vẽ bằng GradientTexture2D
@export var grid_overlay: StringName        # "white" (nền tối) | "dark" (nền sáng): lưới ô ly mờ phủ lên nền
@export var back_art: Texture2D             # SVG lớp SAU chữ: trăng, kim tự tháp, pháo hoa…
@export var front_art: Texture2D            # SVG lớp TRƯỚC (đồi, tuyết, hàng rào…) — nằm dưới chữ
@export var art_offset_y: float             # dịch cả 2 lớp art lên/xuống (xem cột `dy` bảng dưới)
@export var accent: Color
@export var accent2: Color
@export var title_color: Color
@export var title_outline: Color            # viền chữ tiêu đề (dày 10px khi vẽ)
@export var sub_color: Color
@export var label_color: Color
@export var panel_color: Color              # kèm alpha (panel_opacity)
@export var panel_stroke: Color
@export var cta_fill: Color
@export var cta_stroke: Color
@export var cta_text: Color
@export var chip_fill: Color
@export var chip_text: Color
```

**Mã màu 8 theme — lấy ĐÚNG từ mockup** (đã đồng bộ với `event_themes_sheet.svg`):

| `theme_id` | Event | Nền (trên → dưới) | `accent` | `accent2` | Tiêu đề | Viền tiêu đề | Phụ đề | Nhãn | `dy` |
|---|---|---|---|---|---|---|---|---|---|
| `daily` | Daily Challenge (ghim đầu) | `#FFFDF8 → #FFF3EE` | `#D84444` | `#F59E0B` | `#163A58` | `#FFFDF8` | `#718B9E` | `#163A58` | `-45` |
| `halloween` | Halloween | `#1B0B33 → #3B1668 → #220B3F` | `#FF8A1F` | `#FFC857` | `#FFFFFF` | `#2A0F4F` | `#E7D6FF` | `#F3E8FF` | `-60` |
| `mansion` | Biệt Thự Ma Ám | `#0F2A2E → #0C1C20 → #070D0F` | `#5BD99A` | `#BFFFDC` | `#BFFFDC` | `#04100F` | `#A9D9C8` | `#DDFBEF` | `-55` |
| `tomb` | Thám Hiểm Mộ Cổ | `#FFE2A0 → #E7A95A → #3A210E` | `#F2B84B` | `#FFE9B0` | `#FFE9B0` | `#3A210E` | `#F3D9A8` | `#FFF1D0` | `-55` |
| `newyear` | Năm Mới | `#C62828 → #B71C1C → #6D0E12` | `#FFC83D` | `#FFE082` | `#FFE082` | `#6D0E12` | `#FFD9D0` | `#FFF3E0` | `-50` |
| `april` | Cá Tháng Tư | `#FFF176 → #FFC4EA → #FF9ADD` | `#E91E8C` | `#00B3A4` | `#3B0A45` | `#FFFFFF` | `#5B2A6B` | `#3B0A45` | `-50` |
| `winter` | Mùa Đông | `#E3F4FF → #9CCDF4 → #6FA8E0` | `#1E6FD0` | `#FFFFFF` | `#0F2F5C` | `#FFFFFF` | `#1F4A80` | `#0F2F5C` | `-55` |
| `dungeon` | Tuần Lễ Dungeon | `#2A1E12 → #17120D` | `#F59E0B` | `#FDE68A` | `#FDE68A` | `#17120D` | `#E7D3B0` | `#F3E3C3` | `-50` |

| `theme_id` | Panel / độ mờ | CTA nền | CTA viền | CTA chữ | Chip nền (mờ 0.85) | Chip chữ |
|---|---|---|---|---|---|---|
| `daily` | `#FEE2E2` / 0.6 | `#D84444` | `#A12B2B` | `#FFFFFF` | `#D84444` | `#FFFFFF` |
| `halloween` | `#12061F` / 0.58 | `#FF8A1F` | `#B45309` | `#2A0F4F` | `#12061F` | `#FFE9C2` |
| `mansion` | `#000000` / 0.45 | `#5BD99A` | `#2E8F66` | `#04281B` | `#000000` | `#BFFFDC` |
| `tomb` | `#1E0F05` / 0.55 | `#F2B84B` | `#9A6A12` | `#2A1608` | `#1E0F05` | `#FFE9B0` |
| `newyear` | `#3A0608` / 0.5 | `#FFC83D` | `#B8860B` | `#6D0E12` | `#3A0608` | `#FFE082` |
| `april` | `#FFFFFF` / 0.58 | `#E91E8C` | `#9D1260` | `#FFFFFF` | `#3B0A45` | `#FFF176` |
| `winter` | `#FFFFFF` / 0.5 | `#1E6FD0` | `#124C94` | `#FFFFFF` | `#0F2F5C` | `#E3F4FF` |
| `dungeon` | `#000000` / 0.38 | `#F59E0B` | `#B45309` | `#2A1A05` | `#000000` | `#FDE68A` |

*(`dy` = độ dịch dọc của lớp art so với toạ độ vẽ gốc; vùng art nằm ở nửa trên thẻ, y≈52–230, chữ tiêu đề bắt đầu y≈232. Art không được chạm hàng chip y=16–52.)*


### B3. Art cho theme (SVG, không emoji)

Mỗi theme cần **2 file SVG** trong `assets/images/events/`:
`<theme_id>_back.svg` · `<theme_id>_front.svg`, khổ **340 × 230** (vùng art), nền trong suốt; nền gradient + lưới ô ly do code phủ từ `EventTheme` (không nhúng vào SVG).
Thứ tự vẽ trong thẻ (dưới → trên): **gradient nền → lưới ô ly mờ → `back_art` → `front_art` → chip → tiêu đề/phụ đề → panel tiến độ → CTA**.
Gợi ý trang trí (đã có trong mockup, agent vẽ lại thành SVG): `halloween` trăng + dơi + ma + đồi tối + bí ngô · `mansion` biệt thự + sương + hàng rào + trăng xanh · `tomb` mặt trời + 2 kim tự tháp + chữ ankh + cồn cát tối · `newyear` pháo hoa vàng + 2 lồng đèn + hoa mai/đào + dải đỏ viền vàng · `april` mũ hề + mặt cười xoáy + confetti · `winter` núi tuyết + bông tuyết lớn + thông + nền tuyết trắng · `dungeon` tường gạch + cổng vòm có bậc thang sáng + 2 đuốc + sàn đá · `daily` trang vở kẻ dòng + lề đỏ + **lá lịch** (ngày/tháng/thứ lấy từ giờ máy — ngày & thứ là `Label`, không nhúng vào SVG).
Phải đọc được chữ trên mọi theme (tương phản tiêu đề ≥ 4.5:1): theme sáng (`april`, `winter`, `daily`) dùng viền chữ **trắng**; theme tối dùng viền **tối** + chữ sáng.

### B4. Thẻ sự kiện UI — `EventCard`

Scene `nodes/main/event_card.tscn` + script `EventCard` (`class_name`), **cỡ thiết kế 340×504** (lấy từ scene, §13.14). Giải phẫu (toạ độ thiết kế, gốc góc trên-trái thẻ):

| Node | Vị trí / cỡ | Nội dung |
|---|---|---|
| `BgGradient` + `BgGrid` | phủ 340×504, bo 28 | gradient `bg_stops` + lưới mờ |
| `BackArt` / `FrontArt` | y=0..230 (+`art_offset_y`) | 2 lớp SVG của theme |
| `ThemeChip` | (16,16) cao 36, bo 18, rộng theo chữ | chấm `accent` + chữ chip (cỡ 14, cách chữ 1,2) |
| `TimerChip` | (W−16−140,16) 140×36 | icon đồng hồ + `Còn N ngày/giờ/phút` (cỡ 13) |
| `Title1`, `Title2` | baseline y=262 và 302, cỡ 36 đậm | **2 dòng**, có viền `title_outline` dày 10 |
| `Sub1`, `Sub2` | baseline y=328 và 348, cỡ 14 | phụ đề 2 dòng |
| `ProgressPanel` | (14,356) 312×82, bo 20 | nền `panel_color`; **KHÔNG thanh tiến độ** |
| ├ `ProgressText` | (32, baseline 390), cỡ 26 đậm, màu `accent2`/`accent` | `{0} / {1}` + đơn vị (cỡ 15) bên phải số |
| └ `Reward1`, `Reward2` | icon tại y=417; x=40 và x=188 | icon (xu / bút / khung / x2) + nhãn cỡ 14 |
| `CtaButton` | (14,448) 312×44, bo 20 | nút `cta_fill`, viền `cta_stroke` 3px, chữ `cta_text` cỡ 20 + tam giác play |

Yêu cầu hành vi:
- `setup(data: EventData)` áp theme + chữ + tiến độ; **không** tạo node mới lúc chạy (§13.15).
- Đếm ngược: định dạng `≥48h → "Còn {0} ngày"` · `<48h → "Còn {0} giờ"` · `<1h → "Còn {0} phút"`; cập nhật bằng `Timer` 30–60s (**không** dùng `_process`). Hết hạn khi đang xem → phát `event_expired`, thẻ mờ đi rồi gỡ khỏi carousel.
- Trạng thái thẻ: `normal` · `pressed` (lún 3px) · `completed` (đã xong hết → CTA đổi thành `NHẬN QUÀ`; đã nhận → CTA xám "ĐÃ NHẬN") · `locked` (nếu event yêu cầu sao tối thiểu — tuỳ chọn).
- Daily dùng **biến thể** `EventCard` (cùng khung 340×504): trang trí = lá lịch + chuỗi streak; `ProgressText` = `sao/3`.

### B5. Carousel — `EventCarousel` + `EventDots`

- `nodes/main/event_carousel.tscn`: `ScrollContainer` ngang (ẩn thanh cuộn) → `HBoxContainer` (khe 18) → các `EventCard`. **Snap theo trang** khi thả tay (vuốt có quán tính nhẹ), thẻ gần giữa/trái nhất là "trang hiện tại".
- `EventDots` chỉ chấm theo trang hiện tại (chấm dài 46 màu xanh `#256C96`, các chấm khác 30 màu `#D8E2E8`); số chấm = số thẻ.
- Tiêu đề khối: badge cam hiện **số event đang mở (kể cả Daily)**. Link "Xem tất cả": **giai đoạn 1** có thể ẩn; giai đoạn 2 mở `EventListScreen` (lưới tất cả + event đã kết thúc).
- Thứ tự: **Daily luôn đầu** → còn lại theo `sort_order` rồi theo thời điểm hết hạn gần nhất. Trong gameplay, event chưa tới lịch/hết hạn/`enabled=false` **không hiện**. Để kiểm thử nội dung, Main có cờ `show_all_events_for_preview` bật tạm thời, hiển thị mọi EventData bất kể lịch hoặc `enabled`; thẻ inactive chỉ ẩn chip thời gian, không bị làm mờ/phát `event_expired`. Tắt cờ để khôi phục lọc gameplay. Không giới hạn số thẻ; số chấm phải khớp số thẻ.
- Trạng thái rỗng: chỉ có Daily → 1 thẻ, **canh giữa**; ẩn dấu chấm.
- Cuộn tự động về thẻ Daily khi mở Main lần đầu trong ngày; nhớ vị trí trang khi quay lại từ màn khác (trong cùng phiên).

### B6. `EventManager` (autoload)

Đăng ký autoload `EventManager` (script `scripts/autoload/event_manager.gd` hoặc theo thư mục autoload thật của project).

```gdscript
signal events_changed
signal event_progress_changed(event_id: StringName)
signal event_expired(event_id: StringName)

func get_active_events() -> Array[EventData]   # Daily đầu, lọc theo thời gian + enabled, sắp xếp như B5
func get_event(id: StringName) -> EventData
func get_progress(id: StringName) -> Dictionary     # {done:int, total:int, unit_key:StringName, completed:bool, claimed:bool}
func seconds_left(id: StringName) -> int
func on_level_won(event_id: StringName, level: LevelData, stars: int) -> void
func on_dungeon_floor_cleared(floor_idx: int) -> void      # cập nhật event DUNGEON đang chạy
func on_app_day_started() -> void                           # đánh dấu ngày cho LOGIN_STREAK
func can_claim(id: StringName) -> bool
func claim_reward(id: StringName) -> bool                   # idempotent: gọi 2 lần chỉ phát quà 1 lần
```

Quy tắc:
- **Nguồn thời gian:** giai đoạn 1 dùng giờ thiết bị (UTC) **nhưng bọc trong 1 hàm duy nhất** `EventManager.now_utc()` để sau thay bằng giờ server. Chống chỉnh giờ máy là việc giai đoạn 2 (ghi chú trong code, đừng tự chế).
- **Nạp event:** quét `resources/events/*.tres` lúc khởi động (đọc thư mục, **không** liệt kê cứng từng file). Event lỗi (thiếu `theme`, `levels` rỗng với loại series, `end < start`) → **bỏ qua + `push_warning`**, không làm game crash.
- **Lưu tiến độ:** dùng đúng cơ chế lưu mà Daily/Thành tựu đang dùng (agent tìm nơi lưu thật). Cấu trúc đề xuất: `events: { "<id>": { done_levels: [level_id…], best_floor: int, login_days: [ngày…], claimed: bool } }`. Lưu **ngay** sau mỗi thay đổi; dọn bản ghi event đã hết hạn quá 30 ngày.
- Phát quà qua API tiền tệ/vật phẩm hiện có (Xu Mực §13.4; skin bút §13.9). Item chưa tồn tại (`Bút Ma Trơi`, `Khung Hoa Mai`…) → **tạo `.tres` shop/profile tối thiểu** hoặc để `COIN` cho giai đoạn 1 và ghi vào danh sách việc còn lại — **không** bịa item không có asset.

### B7. Luồng chơi từng loại

| Loại | Bấm CTA | Trong game | Xong |
|---|---|---|---|
| `SPECIAL_SERIES` / `STANDARD_SERIES` | Vào màn chưa xong **đầu tiên** của event (nếu đã xong hết → mở popup nhận quà). Có thể mở màn **chọn màn của event** dùng lại `LevelsPage`/thẻ (§12) cho người muốn chơi lại | Chạy bằng chính `game.tscn`; `LevelData.mode_id` quyết định luật (đã hỗ trợ §10.2f). Đặt `GameManager.current_event_id` | Popup kết quả (§5.10) thêm nút **TIẾP TỤC EVENT** → màn kế; gọi `EventManager.on_level_won()`; hết series → popup **nhận quà** |
| `DUNGEON` | Vào Dungeon bình thường | `GameManager` đọc `dungeon_coin_multiplier` của event đang chạy để nhân xu mỗi tầng; HUD không đổi (có thể thêm nhãn nhỏ "x2" — tuỳ chọn) | Qua mốc tầng → ghi `best_floor`; đạt mốc cuối → nhận quà |
| `LOGIN_STREAK` | Mở popup **lịch N ngày** (ô ngày đã/ chưa/ hôm nay), nút **NHẬN LÌ XÌ** | — | Đủ N ngày liên tiếp → nhận quà; lỡ 1 ngày thì theo quy tắc chốt ở §Câu hỏi mở (mặc định: **không reset**, tính tổng số ngày) |
| `DAILY` | Mở luồng Daily hiện tại (đúng như bấm thẻ Daily cũ) | Không đổi | Không đổi |

Tạo màn cho event series bằng tool `tools/level_designer` (§12.7, §10.2f): màn khai `mode_id`; đặt trong thư mục `resources/levels/events/<event_id>/`. **Không** lẫn vào danh sách chương thường (không ảnh hưởng mở khoá bằng Sao).

### B8. Chuỗi dịch cần thêm (`string_extra.csv`, tối thiểu en + vi)

`STR_EVENT_HEADER` ("Sự kiện đang mở") · `STR_EVENT_VIEW_ALL` ("Xem tất cả") · `STR_EVENT_TIMER_DAYS` ("Còn {0} ngày") · `STR_EVENT_TIMER_HOURS` ("Còn {0} giờ") · `STR_EVENT_TIMER_MINUTES` ("Còn {0} phút") · `STR_EVENT_PROGRESS_FORMAT` ("{0} / {1}") · `STR_EVENT_UNIT_MODES|LEVELS|FLOORS|DAYS|CHALLENGES` · `STR_EVENT_CTA_PLAY|CONTINUE|ENTER_DUNGEON|CLAIM_LUCKY_MONEY|CLAIMED` · `STR_EVENT_REWARDS_TITLE` · `STR_MODECARD_*` (chip/title/subtitle/stat label/button cho Play & Dungeon) · `STR_MAIN_DOCK_SHOP|RANKING|BADGES|RULES` · và **nhóm theo từng event**: `STR_EVENT_<ID>_CHIP`, `_TITLE_1`, `_TITLE_2`, `_SUB_1`, `_SUB_2`, `_CTA`, `_REWARD_1`, `_REWARD_2`. Chạy `audit_localization.py` — không được còn chuỗi cứng hay khoá chết.

### B9. Debug Console (F9) — thêm mục **EVENTS** (cùng kiểu §9)

Danh sách event (đang chạy / sắp tới / đã hết) · nút **Bắt đầu ngay** / **Kết thúc ngay** · **+1 ngày / −1 ngày** (dịch `now_utc` giả) · **Hoàn thành màn kế** · **Đặt tiến độ = n** · **Reset tiến độ & cờ đã nhận** · **Nhận quà** · "Test mode" không ghi tiến trình thật. Mục này **chỉ có ở bản dev**.

### B10. Kiểm thử bắt buộc

`scripts/test_case/test_event_manager.gd` (mới), tối thiểu:
- Lọc theo thời gian: trước `start` ẩn · trong khoảng hiện · sau `end` ẩn · `enabled=false` ẩn.
- Sắp xếp: Daily **luôn đầu**; các event còn lại theo `sort_order` rồi hạn gần nhất.
- Tiến độ: thắng 1 màn → `done` +1, **thắng lại màn cũ không cộng thêm**; đủ màn → `completed=true`.
- `claim_reward` **idempotent**; chưa hoàn thành thì `false`.
- `DUNGEON`: hệ số xu áp đúng chỉ trong thời hạn; mốc tầng ghi `best_floor` đúng.
- `LOGIN_STREAK`: ngày mới cộng đúng 1 lần/ngày dù mở app nhiều lần.
- Event lỗi dữ liệu → bị bỏ qua, không crash.
- Lưu/nạp lại: tiến độ giữ nguyên sau khi khởi động lại.

Cập nhật/chạy: `test_main_layout` · `test_ui_scenes` (không `.new()` UI; cấu trúc con của `EventCard`/`ModeCard`) · `test_localization` · harness đa tỉ lệ `dev_aspects.gd -- --only=main` (**10/10**) · toàn bộ suite hiện có **không được xanh→đỏ** (2 suite đỏ cũ Sum Path/Fading Ink HUD là lỗi có từ trước — không tính).

### B11. Cập nhật tài liệu (GDD) — bắt buộc cuối mỗi đợt

- **§4 "Ba cổng vào chính"** → viết lại thành **"Hai cổng chính + Danh sách Sự kiện"**: bảng chỉ còn Play & Dungeon là 2 thẻ chế độ; Daily là **event ghim đầu** trong danh sách; mô tả 8 luật Special chỉ vào qua Daily/Event.
- **§4.1** → thanh trên (hồ sơ · Xu · Sao · Cài đặt) + dock 4 nút (Cửa hàng · Xếp hạng · Danh hiệu · Luật chơi); bỏ mô tả nút DANH HIỆU 224×224 và hàng 3 nút `btn_menu_utility_*`.
- **§13.23** → ghi lại bố cục Main mới 2 hướng + cách xử lý art thẻ giấy bằng 9-slice (đóng mục "CÒN LẠI" số 5).
- **Thêm mục mới "Event System"** (đề xuất §15): B1–B7 rút gọn + bảng theme + quy trình thêm event mới (xem B12).
- Tăng phiên bản ở bảng đầu tài liệu (v2.21), ghi ngày + tóm tắt thay đổi theo đúng định dạng các dòng phiên bản cũ.

### B12. Quy trình thêm 1 event mới (để ghi vào GDD & kiểm chứng "không cần sửa script")

1. Vẽ 2 SVG art → `assets/images/events/<theme_id>_{back,front}.svg`.
2. Tạo `resources/events/themes/<theme_id>.tres` (màu + art + `art_offset_y`).
3. (Nếu là series) tạo các `LevelData` bằng level designer → `resources/levels/events/<event_id>/`.
4. Tạo `resources/events/<event_id>.tres` (loại, theme, khoá chữ, thời hạn, màn, quà).
5. Thêm các khoá dịch `STR_EVENT_<ID>_*`.
6. Chạy game: thẻ **tự xuất hiện** đúng thời hạn. **Nếu phải sửa `.gd` để thêm event ⇒ thiết kế sai.**
