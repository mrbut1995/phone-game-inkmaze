# REFACTOR INSTRUCTIONS — dành cho AI Agent

> Đặt file này ở gốc project (cạnh `project.godot`) cùng thư mục `tools/refactor/` (các công cụ kiểm tra kèm theo).
> Phiên bản này đã gộp: (a) xử lý bản vá `update_v1.7z`, (b) quy tắc **"khai báo trong `.tscn`/Theme, không hard-code trong script; nối signal trong `.tscn`"** (Phase 2B).
> Prompt khởi động gợi ý: **"Đọc `REFACTOR_INSTRUCTIONS.md` và thực hiện lần lượt từng Phase. Không hỏi lại trừ khi gặp mục 'Dừng và hỏi'."**

---

## 0. Sứ mệnh

Dọn dẹp và chuẩn hóa project Godot 4.5+ (GDScript, mobile, 2 hướng Portrait/Landscape) để:

1. **Chuẩn** — theo GDScript style guide chính thức và một cấu trúc thư mục nhất quán.
2. **Dễ nhìn** — scene gọn, tên rõ, script ngắn, một file một trách nhiệm.
3. **Không chắp vá** — không còn node ẩn vô nghĩa, file mồ côi, hàm DEPRECATED, comment kể lịch sử, đường dẫn cũ.

**Bất biến tuyệt đối: hành vi game và giao diện nhìn thấy KHÔNG ĐỔI.** Đây là refactor, không phải thêm/sửa tính năng.

---

## 1. Quy tắc bắt buộc (đọc trước khi làm gì)

1. **Git**: tạo nhánh `refactor/cleanup`. **Mỗi Phase (hoặc mỗi nhóm nhỏ trong Phase) = 1 commit** có thông điệp rõ. Nếu một bước hỏng và không sửa được trong 2 lần thử → `git revert` bước đó, ghi vào `REFACTOR_LOG.md` rồi đi tiếp.
2. **Giả định không có editor Godot**: bạn sửa `.tscn` bằng tay, nên phải cẩn thận:
   - Không tự bịa `uid=`, `unique_id=`, `id=`. Không sửa `parent_id_path`. Khi xóa node, các node còn lại giữ nguyên thuộc tính; `index=` lệch sau khi xóa là chấp nhận được (Godot tự chuẩn hóa khi nạp), nhưng nếu code dùng `get_child(i)` thì phải kiểm tra lại.
   - Khi xóa node: xóa luôn **toàn bộ node con**, `[connection]` liên quan, entry trong `node_paths=PackedStringArray(...)` + dòng `prop = NodePath(...)` tương ứng, và mọi `ext_resource` / `sub_resource` không còn ai dùng.
   - Sau khi sửa tay, cập nhật hoặc xóa `load_steps=` ở dòng đầu (Godot 4.5 không bắt buộc).
3. **Di chuyển/đổi tên file `.gd`**: luôn di chuyển **cùng file `.gd.uid`** (`git mv` cả hai). Sau đó cập nhật **mọi** tham chiếu `res://` trong: `.tscn`, `.gd`, `.tres`, `.cfg`, `project.godot` (autoload, `run/main_scene`, icon), `export_presets.cfg`, `.csv`. Dùng `tools/refactor/move_map.py`, không sửa tay từng chỗ.
4. **Không đổi** (trừ khi có bước migrate rõ ràng): tên autoload, key lưu save (`ConfigFile` section/key), key dịch `STR_*`, tên signal public mà `.tscn` đang nối, `class_name` dùng nhiều nơi (đổi thì đổi đồng bộ bằng thay thế toàn project).
5. **Mỗi lần chỉ xóa thứ bạn CHỨNG MINH được là thừa** (xem §4). Không chắc → giữ, ghi vào `REFACTOR_LOG.md` mục "Nghi ngờ".
6. **Chạy bộ kiểm tra sau mỗi commit** (§2). Không commit khi còn lỗi mới so với baseline.
7. **Không tạo thêm hard-code mới.** Mọi code bạn viết/di chuyển phải tuân thủ Phase 2B: giá trị tĩnh (tọa độ, kích cỡ, màu, font, texture, margin…) nằm ở `.tscn`/Theme; signal giữa node tĩnh nối trong `.tscn`. Không "vá" bằng cách gán đè trong `_ready()`/hàm `_apply_*` — sửa tận nguồn (scene/theme).
8. Không để lại **code bị comment-out** (`#@onready …`, `#var …`), comment kể lịch sử ("trước ~68", "đã gỡ"), hay file đặt sai chỗ khi áp bản vá. Git đã lưu lịch sử.
9. Comment/`##` doc trong code của project viết **tiếng Việt** — giữ nguyên ngôn ngữ đó; tên biến/hàm/file dùng tiếng Anh.

---

## 2. Bộ kiểm tra (chạy sau MỖI commit)

Công cụ nằm ở `tools/refactor/`:

| Lệnh | Mục đích |
|---|---|
| `python3 -I tools/refactor/check_integrity.py . --skip res://assets/` | Phát hiện `res://` chết, `NodePath`/`connection` trỏ node không tồn tại, `ext_resource`/`sub_resource` thừa |
| `python3 -I tools/refactor/audit_hidden.py . --json refactor_hidden.json` | Liệt kê & phân loại node `visible = false` (DEAD / BASE-DEAD / SPLIT-BASE / REVIEW / LIVE) |
| `python3 -I tools/refactor/audit_hardcode.py . --top 30` (thêm `--file scripts/scenes/main.gd` để xem từng dòng) | Đếm giá trị/kết nối đang hard-code trong script: **P** thuộc tính tĩnh, **T** theme/StyleBox trong code, **C** `const` kích cỡ/màu/texture, **S** `.connect` vào node tĩnh, **E** signal gọi bằng chuỗi |
| `godot --headless --path . --script res://tools/refactor/verify_scenes.gd` | Nạp + instantiate toàn bộ `.tscn` (cần Godot 4.5+; nếu máy chưa có, thử tải bản headless; nếu không được thì bỏ qua và ghi rõ vào log) |
| `godot --headless --path . --import` rồi `godot --headless --path . --quit-after 120` | Dò lỗi parse GDScript khi khởi động (tìm `SCRIPT ERROR` / `Parse Error`) |

**Baseline**: trước khi sửa gì, chạy tất cả và lưu kết quả vào `REFACTOR_LOG.md`.
Nếu project có bộ test (`scripts/test_case/` được nhắc trong `game_manager.gd`) → chạy luôn.

---

## 2B. PHASE 0 — Áp bản vá `update_v1.7z` rồi lấy baseline

`update_v1.7z` là bản vá 5 file đè lên project (giải nén bằng `7z x` hoặc `bsdtar -xf`, **giải ra thư mục tạm trước, so sánh, rồi mới chép**):

| File trong bản vá | Việc |
|---|---|
| `scripts/scenes/main.gd` | Chép đè. Có thêm `_apply_mobile_sizing()`, `_enlarge_chip()` và ~10 `const` kích cỡ — **đây chính là mẫu hard-code cần dọn ở Phase 2B** (xem ví dụ §5B.5) |
| `scripts/nodes/main/chest_widget.gd`, `nodes/main/chest_widget.tscn` | Chép đè. Sau đó kiểm tra hằng `RING_DIR`/đường dẫn `reward_disc_*` còn dùng không (bản vá bỏ đĩa tròn nền → có thể thành mã chết) |
| `nodes/main/profile_card.tscn` | Chép đè. Bản vá đã xóa 5/6 node ẩn của scene này (khớp mục REVIEW ở Phase 1) |
| `scripts/nodes/main/profile_card.gd` | ⚠️ **BẪY**: scene vẫn trỏ `res://scripts/nodes/profile_card.gd` (uid `c8cd4nb4704rv`), còn bản vá đặt file ở `scripts/nodes/main/`. Nếu chép nguyên → có **2 script cùng `class_name ProfileCard`** → lỗi parse "Class hides a global script class". **Cách làm**: ghi nội dung bản vá vào ĐÚNG `scripts/nodes/profile_card.gd` (giữ `.uid` cũ), **không** thêm bản ở `scripts/nodes/main/`. (Phase 3 sẽ chuyển nó về `nodes/main/` bằng `move_map.py`.) Sau đó **xóa các dòng `#@onready …` / `#if name_label…` bị comment-out** trong file (quy tắc 8) |

Sau khi áp: chạy `check_integrity.py` (không được có lỗi E mới), commit `chore: apply update_v1`, rồi **chạy toàn bộ bộ kiểm tra §2 để lấy baseline** (số node ẩn ở §3.4 sẽ giảm vì profile_card đã bớt node ẩn; chạy lại `audit_hidden.py` thay vì tin số cũ).

---

## 3. Hiện trạng (đã quét sẵn — hãy xác minh lại, đừng tin mù)

### 3.1 Quy mô
- ~260 script `.gd` (~48.000 dòng), 190 scene `.tscn`. Thư mục gốc: `scripts/`, `scenes/`, `nodes/`.
- Script lớn nhất: `nodes/game/board.gd` (2052), `core/game_manager.gd` (1256), `scenes/debug.gd` (1192), `core/controllers/game_controller.gd` (1136), `scenes/shop.gd` (911), `nodes/level_selection/level_map.gd` (860), `scenes/archivement.gd` (745), `manager/PlayerProfileManager.gd` (741).

### 3.2 Vấn đề cấu trúc đã thấy
| # | Vấn đề | Bằng chứng |
|---|---|---|
| S1 | **Node ẩn thay cho việc xóa** — đặc biệt trong scene KẾ THỪA, nơi Godot không cho xóa node của scene cha nên phải `visible = false` | `base_layout.tscn` có sẵn `TopBar/CoinChip` + `LifeChip`; 13/30 layout con ẩn chúng. `hud/*/game/game_hud.tscn` có sẵn `ModeInformation/Time`; 4/11 HUD con ẩn nó (×2 hướng). `popups/base.tscn`: `Dim`, `Panel/Art` bị ẩn ở 1 popup |
| S2 | Tên thư mục scene ≠ script | `nodes/tutorials/` ↔ `scripts/nodes/tutorial/`; `scripts/layout/{portrait,landscape}` ↔ `scripts/scenes/layout/` (tên file cũng lệch: `portrait/game.gd` vs `landscape/game_layout.gd` vs `scenes/layout/game_layout.gd`) |
| S3 | Lỗi chính tả xuyên suốt: `archivement` (→ `achievement`) | thư mục, class, manager, scene |
| S4 | Tên file manager PascalCase (`ShopManager.gd`) trong khi phần còn lại snake_case; `manager/LevelManager.gd` chỉ là `extends LevelManagerClass` của `core/level_manager.gd` (autoload trỏ tới file core) | |
| S5 | Cặp scene Portrait/Landscape nhân bản gần như 100% (`daily`, `title`, `ranking`, `tutorial_list`… mỗi bản tới ~1600 dòng), thêm `card_big`/`card_big_land`, `level_card`/`level_card_landscape`, `page`/`page_landscape`, `tab_button`/`tab_button_landscape` | |
| S6 | 184 lệnh `get_node_or_null("/root/<Manager>")` rải khắp nơi (GameManager 52, LevelManager 17, DailyManager 14, SceneManager 11…) | ghi chú trong `settings.gd`: "không tham chiếu autoload trực tiếp" (lý do có thể là chạy test `--script`) |
| S7 | God class: `board.gd`, `game_manager.gd`, `game_controller.gd`, `debug.gd`, `shop.gd`… | §3.1 |
| S8 | Hàm/comment kể lịch sử, DEPRECATED | `SceneManager.gd:154`, `core/game_manager.gd:941`, `utils/nav.gd:50` ("DEPRECATED — Levels đã GỘP vào Main"); comment "màn Levels riêng đã bị gỡ", "nhánh portrait_landscape_feature"; `sfx.gd:40` nhắc `res://optimizing_clean/duplicate/...` |
| S9 | `print()` còn sót (7), 60 chỗ gán `visible = false` bằng code, `get_node("...")` chuỗi (6), `$Path` (79) | |
| S10 | File thừa: `scenes/nodes/shop/coin_tile.tscn.depren`; scene có vẻ không ai tham chiếu theo đường dẫn (cần xác minh động — §5): `nodes/coin_chip.tscn` + `nodes/life_chip.tscn` (trùng bản trong `nodes/main/`?), `nodes/archivements/tab_button{,_landscape}.tscn`, `nodes/daily/daily_milestone.tscn` (có bản thứ 2 trong `nodes/popups/`), `nodes/hud/portrait/game/countdown_segment.tscn`, `nodes/level_selection/{level_card,level_card_landscape,page,page_dot,page_landscape}.tscn`, `nodes/main/chapter_chip.tscn`, `nodes/profiler/activity_row.tscn` | |
| S11 | **Hard-code trong script thay vì `.tscn`/Theme** và **signal nối bằng code** | `audit_hardcode.py`: ~280 gán thuộc tính tĩnh (P), ~35 override theme/StyleBox (T), ~100 `const` kích cỡ/màu/texture (C), ~20 `.connect` vào node tĩnh (S), ~77 signal gọi bằng chuỗi (E). Nặng nhất: `scenes/main.gd` (51, sau bản vá), `nodes/game/board.gd` (23), `popups/gameover*.gd`, `winning*.gd`, `shop/item_tile.gd`, `shop/noads_row.gd`, `main/chapter_gate.gd`, `main/event_button_column.gd`, `archivements/card.gd`, `tutorial/base_tutorial.gd`, `common/scene_transition.gd`. Ngoài ra còn ~1000 gán **động** (dựa vào biến runtime) — hợp lệ, không phải đối tượng dọn |

### 3.3 Lỗi toàn vẹn có sẵn (từ `check_integrity.py` trên bộ file được cung cấp)
- `scripts/utils/sfx.gd:42` — comment trỏ `res://optimizing_clean/duplicate/assets/sfx/` (đường dẫn cũ).
- `scripts/core/game_manager.gd:475` — comment trỏ `res://scripts/test_case/...` (kiểm tra thư mục có thật không).
- `scenes/layout/*/splash.tscn` — `res://company_logo.png` (có thể chỉ thiếu vì bộ file được gửi không có asset; kiểm tra trên project thật).
- 87 cảnh báo `ext_resource`/`sub_resource` khai báo nhưng không dùng → dọn ở Phase 2.

### 3.4 Quét node ẩn (heuristic tĩnh — kết quả thật chạy bằng `audit_hidden.py`)
208 node `visible = false`: **10 DEAD**, 0 BASE-DEAD, **36 SPLIT-BASE**, 63 REVIEW, 99 LIVE.

10 DEAD (không script / signal / bind / tên trong code):
- `nodes/main/daily_card.tscn` và `daily_card_compact.tscn`: `Content/Background/BackArt`
- `nodes/main/level_section.tscn`: `MapArea/FadeTop`, `MapArea/FadeBottom`
- `nodes/tutorials/base_tutorial.tscn`: `Dots/Dot1` … `Dot6` (nếu container `Dots` trở nên rỗng và không ai dùng → xóa luôn `Dots`)

---

## 4. PHASE 1 — XÓA NODE ẨN VÔ DỤNG (ưu tiên số 1)

Mục tiêu: **không còn node `visible = false` nào trong `.tscn` mà không có lý do chính đáng** (= được bật lúc runtime bởi code/animation).

### 4.1 Thuật toán cho MỖI node ẩn
Chạy `audit_hidden.py` lấy danh sách; với từng node, quyết định:

**Bước A — Node này có được bật lại lúc runtime không?** Nó là **LIVE (giữ)** nếu có BẤT KỲ điều nào:
1. Code gán `visible = true` / `.show()` / tween `modulate` tới node đó (qua tên, `%Unique`, `$Path`, `get_node("…")`, `find_child`, `get_node_or_null`).
2. Được bind bằng `@export` (có trong `node_paths=` của scene) **và** biến đó được dùng có tác dụng (không chỉ `if x: x.visible = false`).
3. Có `AnimationPlayer` track đổi `visible`/`modulate` của nó (`NodePath("<path>:visible")`).
4. Là **template/prototype** để `duplicate()`/`instantiate` (`CellTemplate`, `HistoryTemplate`, `WallTemplate`, `AnchorTemplate`, `DragGuide`, `ActiveTemplate`) → giữ (tùy chọn: chuyển thành `PackedScene` export ở Phase 5).
5. Tên được dựng động: `"Slot%d" % i`, `"Slot" + str(i)`, `get_child(i)`, `get_children()`. Ví dụ: `RiskFrame` dưới `PencilBox/Row/Slot1..5` được bật bởi `retry_pencils.gd` (`slot.get_node("RiskFrame").visible = …`) → **LIVE, giữ**.
6. Là con của node cha mà code bật/tắt cả nhóm.

> ⚠️ Đếm tham chiếu **theo tên** sai cả hai chiều: tên chung như `Badge`, `Time`, `Dim`, `Art` trùng nhiều nơi (false positive), còn tên dựng động thì không match (false negative). **Luôn mở script liên quan và đọc.** Tìm bằng: tên node, đường dẫn đầy đủ, tiền tố của tên dựng động (`"Slot"`, `"Dot"`), và export var tương ứng ở script/layout của scene.

**Bước B — Không LIVE ⇒ XÓA.** Cách xóa tùy loại:

| Loại node | Cách xử lý |
|---|---|
| **B1. Node thường trong scene gốc (không kế thừa)** | Xóa khối `[node …]` + mọi node con + `[connection]` + dòng `node_paths`/`NodePath` bind + ext/sub_resource mồ côi. Xóa biến `@export`/`@onready` tương ứng và nhánh code `if x != null` chỉ phục vụ node đó. |
| **B2. Override ẩn trong scene KẾ THỪA (stanza chỉ có `visible = false`, không có `type=`)** — nhóm S1 | **Không xóa được ở scene con.** Sửa tại **scene cha** theo B2a/B2b. |
| B2a. Ẩn ở **TẤT CẢ** scene con (`BASE-DEAD`) | Xóa node khỏi scene cha **và** xóa mọi stanza override ở scene con. |
| B2b. Ẩn ở **một số** scene con, hiện ở số khác (`SPLIT-BASE`) | **Tách base**: bỏ node khỏi scene cha, rồi thêm node (giữ nguyên instance, `custom_minimum_size`, `layout_mode`, `size_flags`, **thứ tự trong container**) vào đúng các scene con thực sự cần nó. Nếu số scene cần nó nhiều, tạo scene cha trung gian kế thừa base gốc (vd. `base_layout_currency.tscn` = `base_layout` + `CoinChip` + `LifeChip`) rồi cho các scene đó kế thừa từ trung gian. |

**Bước C — Hậu kiểm bắt buộc sau mỗi nhóm xóa:**
1. `check_integrity.py` → không lỗi E mới.
2. Node ẩn trong `Container` không chiếm chỗ nên xóa an toàn; nhưng nếu code dùng `get_child(i)`, `get_child_count()`, `move_child`, `index=` thì kiểm tra lại chỉ số.
3. Script chạy trên scene đó không còn tham chiếu node đã xóa (grep tên + export var). Xóa biến export mồ côi trong class layout (`*_layout.gd`) **và** dòng bind trong cả 2 bản Portrait/Landscape.
4. `verify_scenes.gd` (nếu có Godot).

### 4.2 Danh sách cần xử lý cụ thể (seed — xác minh rồi làm)

**Nhóm 1 — DEAD, xóa thẳng (B1):** 10 node ở §3.4. Riêng `LogoBlock` ở `scenes/layout/landscape/main.tscn:199`: ẩn nhưng con `Logo` được bind qua `logo` của `MainLayout`; đọc `main.gd`/`main_layout.gd` — nếu `logo` chỉ dùng cho khối đã bị ẩn thì xóa `LogoBlock` + `@export logo` ở cả hai hướng.

**Nhóm 2 — `CoinChip`/`LifeChip` ẩn ở 13 layout (B2b).** Ẩn ở: `landscape/event`, cả hai hướng của `profiler_popup`, `settings`, `splash`, `title`, `tutorial`, `tutorial_list`. Layout không ẩn (`archivement`, `credit`, `daily`, `debug`, `game`, `main`, `ranking`, `shop`, `portrait/event`…) đang dùng chip. Khuyến nghị: bỏ 2 chip khỏi `base_layout.tscn`; tạo `scenes/layout/base_layout_currency.tscn` kế thừa `base_layout` + 2 chip (đúng `custom_minimum_size = Vector2(111, 32)` / `(96, 32)`, `size_flags_vertical = 4`); layout nào đang hiện chip → đổi kế thừa sang bản trung gian. Lưu ý `base_layout.gd::_content_min_height` bỏ qua `CoinChip`/`LifeChip` theo type — giữ đúng hành vi; `archivement.gd:366` (`get_node_or_null("TopBar/CoinChip")`) phải vẫn hợp lệ.

**Nhóm 3 — `ModeInformation/Time` ẩn ở 8 HUD (B2b)** (`countdown_hud`, `dungeon_mode`, `fog_of_war_hud`, `sum_path_hud` × 2 hướng; base là `hud/<hướng>/game/game_hud.tscn`). Các HUD này dùng `Sheet` thay `Time`. Tách `Time` khỏi `game_hud.tscn` thành phần của các HUD cần (hoặc HUD trung gian); kiểm tra `base_hud.gd:21` (`Content/ModeInformation/Time/Value`) để biến `time_label` null-safe cho HUD không có Time.

**Nhóm 4 — `Dim` ẩn ở `memory_countdown.tscn`, `Panel/Art` ẩn ở `profiler_popup.tscn` (base `popups/base.tscn`, 14 con) (B2b).** Popup khác dùng `Dim` làm nền mờ → giữ ở base; `memory_countdown` không muốn nền mờ: đọc `memory_countdown.gd`. `Panel/Art`: chỉ `profiler_popup` ẩn, 13 popup còn lại hiện → `Art` thuộc nhóm 13 popup đó, chuyển sang base trung gian.

**Nhóm 5 — Cần đọc code để quyết định (REVIEW):** `board.tscn:NoMovesOverlay`; `daily_card*.tscn:BgGradient`; `dock_button.tscn:Badge`; `event_card*.tscn:Sub1/Sub2/CompletedOverlay/ProgressPanel`; `profile_card.tscn:Bg/Margin, NameRow, TierChip, Exp, Uid`; `item_tile.tscn:Note`; `tutorial_cell.tscn:Highlight`; `landscape/game.tscn:TopBar/HeaderRow/Bg`; `portrait/shop.tscn:Footer`; `sum_path_hud.tscn:ChipNeed`. `profile_card.tscn` (5 node ẩn) và `event_card*` đặc biệt đáng nghi là UI cũ còn sót.

**Nhóm 6 — LIVE nhưng đáng xem lại:** node ẩn do `@export` bind nhưng biến chỉ dùng để… ẩn lại (`FadeOverlay` ở splash/title, `TabLine`, `BottomSafe`, `TapeAmber`, `Dots`, `EmptyLabel`, `Warning`…). Nếu biến export chỉ được đọc trong nhánh chết → xóa node + export.

### 4.3 Các `visible = false` đặt bằng code (60 chỗ)
`grep -rn "visible = false" scripts` — nếu `_ready()` luôn ẩn một node mà scene để hiện (scene "nói dối" trạng thái ban đầu), chuyển trạng thái vào `.tscn` **chỉ khi** node thực sự được bật lại; node bị ẩn vĩnh viễn thì xóa node + code ẩn.

### 4.4 Tiêu chí hoàn thành Phase 1
- `audit_hidden.py` không còn `DEAD` / `BASE-DEAD` / `SPLIT-BASE`; mỗi `REVIEW`/`LIVE` còn lại có dòng giải thích trong `REFACTOR_LOG.md` (lý do giữ + file:dòng code bật nó).
- `check_integrity.py` không lỗi mới. Commit: `refactor(scene): remove dead hidden nodes`.

---

## 5. PHASE 2 — Dọn file/mã chết

1. **Scene mồ côi**: với mỗi scene ở S10, tìm tham chiếu theo (a) `res://đường/dẫn`, (b) `uid://…` (uid ở dòng đầu scene; grep toàn project **kể cả** `.tres`, `project.godot`, `.csv`), (c) chuỗi dựng động (`"res://nodes/%s.tscn" % …`), (d) `DirAccess` quét thư mục. Không ai tham chiếu ⇒ `git rm` scene **và** script đi kèm nếu script cũng mồ côi (nhớ `.uid`).
2. **Trùng lặp**: nếu `nodes/coin_chip.tscn` ≡ `nodes/main/coin_chip.tscn` (so nội dung) → giữ 1 bản đúng chỗ, sửa tham chiếu. Tương tự `daily_milestone.tscn` (2 bản).
3. Xóa mọi `*.depren`, `*.bak`, `*.orig`, `*.old`, `*~` (vd. `scenes/nodes/shop/coin_tile.tscn.depren`).
4. **Hàm DEPRECATED** (`SceneManager.gd:154`, `core/game_manager.gd:941`, `utils/nav.gd:50`): tìm mọi lời gọi, chuyển sang API mới (mở thẳng Main) rồi xóa hàm. Với migration `legacy` trong `DailyManager.gd:559`: chỉ xóa khi chắc không còn save cũ — không chắc thì giữ và ghi log.
5. **Mã chết GDScript**: hàm không ai gọi (grep tên trong `.gd` **và** `.tscn` — signal nối bằng tên hàm), `const`/`var`/`preload` không dùng, code sau `return`, nhánh `if false`, comment code bị vô hiệu. Hàm virtual của engine (`_ready`, `_process`, `_input`, `_draw`, `_notification`…) và hàm nối signal trong `.tscn` **không** phải mã chết. Đừng xóa hàm public của autoload nếu chưa kiểm tra `debug.gd`, test, hoặc gọi bằng chuỗi (`call("name")`, `Callable(self, "name")`, `has_method`).
6. Dọn mọi cảnh báo W1/W2 và các lỗi E1 ở §3.3.
7. Xóa `print()` gỡ lỗi (7): nếu thông tin đáng giữ thì thay bằng util log có cờ debug.

Commit từng nhóm nhỏ.

---

## 5B. PHASE 2B — Khai báo thay vì lập trình: đưa giá trị tĩnh về `.tscn`/Theme, nối signal trong `.tscn`

### 5B.1 Nguyên tắc
> **`.tscn` là nguồn sự thật của bố cục và mọi giá trị tĩnh. Theme/`.tres` là nguồn sự thật của style dùng chung. Script chỉ chứa hành vi và dữ liệu runtime.**
> Mở `.tscn` ra phải thấy đúng giao diện — không cần đọc `_ready()` để biết nút to bao nhiêu.

Tại sao: code gán đè (`_apply_mobile_sizing()`, `_enlarge_chip()`) khiến giá trị thật nằm 2 chỗ (scene nói 32, code đè thành 46), người chỉnh trong editor bị code ghi đè mất, và Portrait/Landscape bị lệch mà không ai thấy.

### 5B.2 Cái gì đặt ở đâu
| Loại giá trị | Đặt ở |
|---|---|
| Vị trí, kích thước, anchor, offset, margin, `separation`, `size_flags`, `custom_minimum_size`, `stretch_mode`/`expand_mode`/`ignore_texture_size`, `mouse_filter`, `z_index`, `rotation`/`pivot_offset`, `visible` ban đầu, `clip_contents`, alignment, autowrap | **`.tscn`** của node đó |
| Texture/icon cố định của node (kể cả `texture_normal/pressed/hover/disabled/focused` của nút — nút đã có sẵn 5 trạng thái, **không** nạp texture theo `% "normal"` trong code) | **`.tscn`** (ext_resource) |
| Text cố định | **`.tscn`** với key dịch (`text = "STR_…"`) |
| Font size, màu chữ, StyleBox (bo góc, viền, bóng, màu nền), theme constant dùng ≥ 2 node | **Theme** (`resources/settings/theme_default.tres` có sẵn) qua **Theme Type Variation** (`theme_type_variation = &"…"` — project đã dùng kiểu này: `EventCtaButton`, `TopProfileXP`). Không `add_theme_*_override`/`StyleBoxFlat.duplicate()` trong code |
| Khác biệt Portrait/Landscape/kích cỡ điện thoại | `.tscn` của **layout từng hướng**, hoặc scene kế thừa — không `if is_landscape`, không "phóng to sau" trong code |
| Giá trị tinh chỉnh mà logic đọc (thời lượng tween, khoảng cách, số lượng, ngưỡng) | `@export var` trong script (**đặt giá trị trong `.tscn`/Inspector**) hoặc `Resource` `.tres` cấu hình; chỉ để `const` khi là hằng nội bộ thuần thuật toán |
| Màu/skin đổi theo ThemeManager | giữ ở code nhưng lấy từ ThemeManager/Resource, **không** `Color("#…")`/`Color(0.x…)` literal rải rác |
| Node sinh nhiều lần lúc chạy (ô, hàng danh sách, level node, popup) | **Tạo `PackedScene`** với thuộc tính đặt trong `.tscn`, code chỉ `instantiate()` + gán dữ liệu. Quy tắc: `X.new()` rồi gán ≥ 3 thuộc tính tĩnh ⇒ phải thành scene |

**Giữ trong code (hợp lệ):** giá trị tính từ runtime (kích cỡ ô theo viewport, `SafeArea`, kích cỡ theo nội dung, vị trí theo dữ liệu màn chơi, màu theo dữ liệu), tween/animation, và node chưa tồn tại lúc thiết kế. Đánh dấu ngoại lệ không thể chuyển bằng `# keep-code: <lý do>` (công cụ sẽ bỏ qua dòng đó).

### 5B.3 Quy trình cho mỗi phát hiện P / T / C (`audit_hardcode.py`)
1. Xác định node đích có **tồn tại tĩnh trong scene** không (`@onready`/`@export`/`$Path`/`%Name`/`layout.x`).
   - Không (tạo bằng code) → áp quy tắc "sinh nhiều lần" ở bảng trên.
2. Đặt giá trị vào đúng tầng:
   - **Đặc trưng của chính component** (vd. chip Xu luôn cao 46, bo tròn) → sửa trong scene component (`coin_chip.tscn`, `dock_button.tscn`).
   - **Đặc trưng của một chỗ dùng** (chip chỉ to ở màn Main) → override ngay ở scene chứa instance: `[node name="CoinChip" parent="TopBar" instance=…]` + thuộc tính; với node sâu bên trong instance (`Icon`, `Value`, `Plus`) dùng *Editable Children* (stanza `[node name="Value" parent="TopBar/CoinChip/Row" index="…"]` + thuộc tính) **hoặc** thêm `@export` cho component và đặt giá trị ở scene cha.
   - **Style dùng chung** (pill bo 23, font 22, nút `+` bo 11) → Theme Type Variation trong `theme_default.tres`, node đặt `theme_type_variation`.
3. **Giữ hình ảnh y hệt từng màn.** Trước khi đổi, ghi lại giá trị hiệu dụng cuối cùng (gốc + code đè) — scene mới phải cho đúng giá trị đó, **ở đúng những màn đang bị code đè** (code chỉ chạy ở `MainScene` thì chỉ Main đổi, các màn khác dùng chip y như cũ — đây là lý do bản vá phải `duplicate()` StyleBox; dùng variation riêng cho Main thay vì sửa style chung).
4. Xóa dòng gán + `const` liên quan + nhánh `if x != null`; nếu hàm `_apply_*` rỗng thì xóa hàm và chỗ gọi.
5. Giá trị gốc ở scene cha/component bây giờ bị đè ở mọi nơi → sửa luôn giá trị gốc (đừng giữ 32 rồi ghi đè 46).
6. Chạy `check_integrity.py` + `audit_hardcode.py` (số P/T/C phải giảm).

### 5B.4 Signal: nối trong `.tscn`, không nối bằng code khi không cần
**Quy tắc:**
1. **Node tĩnh → handler tĩnh trong cùng scene**: dùng `[connection signal="pressed" from="Path/Btn" to="." method="_on_btn_pressed"]`. Handler đặt tên `_on_<TênNode>_<signal>`. Xóa `btn.pressed.connect(...)` tương ứng trong `_ready()`. (`audit_hardcode.py` mục **S**.)
2. **Từ layout lên màn hình**: các màn có `Portrait` và `Landscape` là **2 node con có sẵn trong `.tscn` của màn** (xem `scenes/main.tscn`). Layout **không** để màn chọc vào node bên trong (`layout.btn_settings.pressed.connect(...)`); thay vào đó class layout (`MainLayout`, `ShopLayout`…) khai **signal ngữ nghĩa** (`settings_pressed`, `shop_pressed`, `back_pressed`…), tự nối `[connection]` trong `.tscn` của layout từ nút → script layout (`_on_settings_pressed` → `settings_pressed.emit()`), và `.tscn` của **màn** nối `[connection signal="settings_pressed" from="Portrait" to="." method="_on_settings_pressed"]` + bản `from="Landscape"`. Nhờ vậy bỏ được việc "bind lại node khi đổi hướng" bằng code (hiện có 11 `orientation_changed.connect`).
3. **Component** (`CoinChip`, `ProfileCard`, `DockButton`, `EventCard`…): component tự nối nút bên trong nó trong `.tscn` của chính nó, và **chỉ phát signal ngữ nghĩa** (`pressed`, `plus_pressed`…). Chỗ dùng nối signal của component trong `.tscn` cha.
4. **Hợp lệ giữ trong code**: nối tới **autoload** (`GameManager.xxx_changed`, `LocalizationManager.locale_changed`, `ThemeManager.skin_changed`…); nối tới node **sinh lúc chạy** (ô, hàng, level node) — nhưng nối **một chỗ duy nhất** ngay khi tạo, bằng `signal.connect(callable)` (có `.bind()` khi cần dữ liệu); timer one-shot `await get_tree().create_timer(x).timeout`; `CONNECT_ONE_SHOT`/`CONNECT_DEFERRED` thực sự cần.
5. **Cú pháp có kiểu, không dùng chuỗi**: `obj.connect("name", cb)` → `obj.name.connect(cb)`; `emit_signal("name")` → `name.emit()`; `has_signal("x")`/`is_connected("x", …)` → `obj.x.is_connected(cb)`. Hiện ~77 chỗ dùng chuỗi (`m.connect("profile_changed", …)`, `layout.profile_card.connect(&"pressed", …)`, `card.connect("action_pressed", …)`). Chuỗi gõ sai chỉ lỗi lúc chạy; cú pháp có kiểu lỗi lúc parse. Nếu đối tượng là `Variant` (autoload lấy qua `/root`), sau Phase 5 (`Svc`) sẽ có kiểu để dùng cú pháp này.
6. **Không nối hai lần** (cả code lẫn `.tscn`) và không `is_connected` phòng thủ khi nối ở `_ready()` (chỉ chạy một lần).
7. Signal khai báo trong script: tên **thì quá khứ**, có kiểu tham số (`signal level_selected(level_id: int)`); signal không ai phát/không ai nghe → xóa.

### 5B.5 Ví dụ thực tế cần làm — `scripts/scenes/main.gd` (bản vá `update_v1`, 51 phát hiện)
| Đoạn code đang đè | Chuyển sang |
|---|---|
| `TOP_MARGIN`: `body.offset_top = maxf(…, 24)` | `offset_top` của node `Body` trong `scenes/layout/portrait/main.tscn` (và landscape nếu code đang đè cả hai — kiểm tra điều kiện) |
| `_enlarge_chip()`: min size `(x*1.3, 46)`, `Icon` rộng 32, `Value` font 22, `Plus` 32×32 + font 18 | `custom_minimum_size` của `CoinChip`/`LifeChip` ở layout Main; thuộc tính node con qua Editable Children hoặc `@export` của chip; font size 22/18 → Theme Variation (vd. `ChipValueLabel`, `ChipPlusButton`) |
| `pill = panel.duplicate()`; `set_corner_radius_all(23)`; `shadow_offset` | StyleBox `.tres` trong Theme variation `ChipPill`; chip ở Main đặt `theme_type_variation = &"ChipPill"` (các màn khác không đổi) |
| `Plus` bo góc 11 trên 3 trạng thái (`normal/pressed/hover`) | StyleBox `.tres` cho 3 trạng thái trong Theme variation `ChipPlusButton` |
| Nút Cài đặt: `texture_normal/hover/pressed`, `ignore_texture_size`, `stretch_mode`, `custom_minimum_size = 56×56`, `size_flags_vertical` | Thuộc tính của node `Settings` (TextureButton) trong `main.tscn` — 5 trạng thái đặt thẳng ở đó; xóa `SETTINGS_TEX` và `ResourceLoader.exists` |
| Rương: `CHEST_SIZE`, `offset_*` | node chest trong `nodes/main/level_section.tscn` (neo góc dưới-phải + offset) |
| Dock: `DOCK_HEIGHT`, `DOCK_ICON`, `DOCK_FONT`, `icon_node.offset_*`, `label_node.offset_*` | `nodes/main/dock_button.tscn` (cỡ icon, nhãn, font) + `custom_minimum_size.y` của panel dock trong layout Main |
| Nút Daily ở dock **tạo bằng code** (`_dock_daily`, `ICON_*`, `DOCK_COLORS`) | Thêm nút Daily vào dock trong `.tscn` như 3 nút kia; màu/icon của từng nút là `@export` của `DockButton` đặt trong `.tscn` |
| `m.connect("profile_changed", …)`, `layout.profile_card.connect(&"pressed", …)` | `Svc`/autoload có kiểu + cú pháp có kiểu; `profile_card.pressed` nối trong `.tscn` (`from="Portrait/TopBar/ProfileCard"` …) hoặc qua signal ngữ nghĩa của `MainLayout` |
Ghi chú trong bản vá: *"màn thật nhỏ hơn bản xem trên máy tính"* — nghĩa là các kích cỡ này đang **bù cho chênh lệch preview-máy-tính vs điện thoại**. Nếu nguyên nhân là cấu hình scale (stretch mode/aspect trong `project.godot`, `ui_scaler.gd`, `fit_stage.gd`), hãy chỉnh ở đó thay vì phóng to từng widget; nếu vẫn cần, ghi giá trị cuối vào `.tscn`. Không giữ cả hai.

### 5B.6 Thứ tự xử lý & ngân sách
1. Làm **từng file một**, bắt đầu từ danh sách "nặng nhất" ở S11; mỗi file (hoặc mỗi cụm scene) = 1 commit.
2. Chạy `audit_hidden.py` lại sau mỗi cụm (bỏ node ẩn mới phát sinh do chuyển trạng thái).
3. **Chỉ số phải giảm đơn điệu** (ratchet): ghi số P/T/C/S/E sau mỗi commit vào `REFACTOR_LOG.md`; không commit làm tăng.
4. **Đích**: `audit_hardcode.py` báo **S = 0, E = 0, T = 0**; **P và C ≈ 0**, mọi dòng còn lại có `# keep-code: <lý do>` hợp lệ (danh sách ngoại lệ ≤ ~5% số dòng ban đầu; ghi từng ngoại lệ vào log).

### 5B.7 Tiêu chí hoàn thành Phase 2B
- Màn Main trong editor hiển thị đúng như khi chạy (không còn hàm `_apply_*` đè kích cỡ).
- `audit_hardcode.py` đạt đích §5B.6; `check_integrity.py` sạch; mỗi màn Portrait + Landscape không đổi hình ảnh (xem danh sách test thủ công ở §11).
- Commit: `refactor(ui): move static layout values and signal wiring into scenes/theme`.

---

## 6. PHASE 3 — Chuẩn hóa cấu trúc & đặt tên

Chỉ làm sau Phase 1–2 (khỏi di chuyển file sắp xóa). Dùng `tools/refactor/move_map.py`: đọc bảng `cũ -> mới`, `git mv` cả `.uid`, thay thế `res://` trong mọi file text, rồi chạy `check_integrity.py`.

### 6.1 Cấu trúc đích (tham khảo; điều chỉnh nhỏ được nếu có lý do, nhưng phải NHẤT QUÁN)
```
scripts/
  autoload/        # was manager/ — singleton
  core/            # logic game thuần, KHÔNG phụ thuộc UI: game_state, maze_data, controllers/, score_calculator…
  modes/           # *_game_mode.gd
  data/            # was resources/ (Resource scripts)
  services/        # save backends
  utils/           # tiện ích tĩnh nhỏ
  ui/
    screens/       # was scenes/*.gd (main, shop, daily…)
    layouts/       # gộp scenes/layout/ + layout/, tên thống nhất <screen>_layout.gd
    hud/  popups/  tutorial/  widgets/ (card, chip, button…)  game/ (board, cell, cursor…)
  tools/           # script chạy trong editor/CLI (gen_*, nine_patch) — không chạy lúc runtime
scenes/ nodes/     # phản chiếu đúng cấu trúc scripts/ui/…
```
Nguyên tắc: **scene `x.tscn` ⇔ script `x.gd` cùng tên, cùng đường dẫn tương đối.**

### 6.2 Việc cụ thể
- Thống nhất `nodes/tutorials` ↔ `scripts/nodes/tutorial` (tên **số ít** cho thư mục tính năng).
- Gộp `scripts/layout/` vào thư mục layouts; một kiểu đặt tên duy nhất cho TẤT CẢ (hiện đang lẫn `portrait/game.gd`, `landscape/game_layout.gd`, `scenes/layout/game_layout.gd`).
- File `.gd`: `snake_case.gd`; `class_name`: `PascalCase`. Đổi `ShopManager.gd` → `shop_manager.gd`… (**tên autoload trong `project.godot` giữ nguyên; chỉ đổi `path`**). `manager/LevelManager.gd` + `core/level_manager.gd`: gộp thành một `autoload/level_manager.gd`, bỏ lớp trung gian `LevelManagerClass` nếu không còn ai dùng.
- **Sửa chính tả `archivement` → `achievement`**: đổi file/thư mục/class/hàm/biến/scene/node/comment, **nhưng KHÔNG đổi** key save, key dịch, hay tên asset nếu chưa migrate. Liệt kê mọi chuỗi `archivement` nằm trong dữ liệu (`.cfg`, `.tres`, `.csv`, key save); nếu đổi sẽ mất dữ liệu người chơi → thuộc mục "Dừng và hỏi", hoặc chỉ đổi phần code/đường dẫn và để key dữ liệu nguyên với 1 comment giải thích.
- Node trong scene: `PascalCase`, mô tả đúng vai trò, không đánh số mơ hồ (trừ danh sách thật như `Slot1..5`); dùng `unique_name_in_owner` hoặc `@export NodePath` thay `get_node("A/B/C/D")`.
- Biến thể hướng `card_big_land` / `tab_button_seg_land` / `*_landscape`: một quy ước duy nhất (xem Phase 4).

---

## 7. PHASE 4 — Giảm nhân bản Portrait/Landscape (tùy chọn, từng màn một)

1. So từng cặp `scenes/layout/portrait/X.tscn` ↔ `landscape/X.tscn` (`title`, `splash`, `settings`, `daily`, `tutorial_list`: dài 500–1700 dòng, khác nhau ít). Phần **giống hệt** (cùng cây node + thuộc tính) → tách thành scene con dùng chung trong `nodes/…` và instance ở cả hai hướng.
2. Phần khác thật (anchor, container, kích thước) giữ ở từng hướng.
3. Các cặp nhỏ (`card_big`, `level_card`, `tab_button_seg`…): khác vài thuộc tính → một scene + `@export` hoặc scene kế thừa; khác cấu trúc thật → giữ 2 bản nhưng cùng tiền tố, cạnh nhau.
4. Không dùng `if is_landscape:` rải rác trong script màn. Project đã có mô hình "Controllers + Board dùng chung; **mọi khác biệt hướng nằm ở layout**" (xem `layout/portrait/game.gd`) — giữ và mở rộng.

Cặp nào quá rủi ro để gộp khi không nhìn được trực quan → **bỏ qua, ghi log**.

---

## 8. PHASE 5 — Chất lượng script

### 8.1 Chuẩn code (GDScript style guide chính thức)
- Thứ tự file: `class_name` → `extends` → `##` doc → `signal` → `enum` → `const` → `@export` → biến public → biến private (`_x`) → `@onready` → `_init`/`_ready`/virtual → hàm public → hàm private → handler signal (`_on_<node>_<signal>`).
- **Gõ kiểu** cho mọi tham số, giá trị trả về, biến; dùng `:=` khi kiểu suy ra rõ.
- `signal` tên **thì quá khứ** (`level_completed`); hàm private bắt đầu `_`; hằng `SCREAMING_SNAKE_CASE`; enum `PascalCase`, giá trị `SCREAMING_SNAKE_CASE`.
- Không magic number/chuỗi lặp ≥ 2 lần: đưa vào `const`/enum/`Resource`. **Ngoại lệ quan trọng:** giá trị giao diện (kích cỡ, màu, margin, font, texture) KHÔNG đưa vào `const` trong script — chúng thuộc `.tscn`/Theme (Phase 2B).
- Hàm ≤ ~40 dòng, lồng ≤ 3 cấp (dùng guard clause). File mục tiêu ≤ ~400 dòng.
- Banner `## ====…` đầu file: giữ phong cách, **thống nhất 1 mẫu** (Mục đích · Phụ thuộc · Ai gọi). Comment chỉ mô tả **hiện trạng/lý do**, **không** kể lịch sử ("đã gỡ", "trước đây", "nhánh X", "bản cũ") → xóa/viết lại.

### 8.2 Truy cập autoload (S6)
1. Xác định **lý do** của `get_node_or_null("/root/X")` (ghi chú ở `settings.gd`, `tutorial.gd`, `ArchivementManager.gd` nhắc test chạy bằng `--script` nơi autoload chưa có nên gọi trực tiếp tên autoload sẽ lỗi parse).
2. Nếu có test như vậy: tạo **một** accessor tĩnh `scripts/utils/svc.gd` (`class_name Svc`) với hàm trả về có kiểu cho từng autoload (`static func game() -> GameManager`…), dùng `Engine.get_main_loop().root.get_node_or_null(...)`. Thay cả 184 chỗ bằng `Svc.game()`…
3. Nếu không còn cần → dùng tên autoload trực tiếp (`GameManager.xxx`).
4. Không để chuỗi `"/root/…"` nào ngoài `svc.gd`.

### 8.3 Tách god class (S7) — mỗi file 1 commit
Quy trình: (1) đọc toàn bộ file; (2) ghi kế hoạch ngắn vào `REFACTOR_LOG.md` (nhóm hàm → file mới); (3) tách; (4) chạy kiểm tra.
Gợi ý ranh giới (xác minh bằng đọc code):
- `nodes/game/board.gd` (2052): input (kéo/chạm), render (vẽ/pool/layers), hiệu ứng (ink, floating text)… Board chỉ giữ API công khai + điều phối.
- `core/game_manager.gd` (1256) và `controllers/game_controller.gd` (1136): tách theo vòng đời (session, lives/economy, level flow, scoring); kiểm tra chồng chéo trách nhiệm giữa hai file.
- `scenes/debug.gd` (1192): theo tab/chức năng debug; không tự đổi cơ chế loại debug khỏi bản release.
- `shop.gd`, `archivement.gd`, `level_map.gd`, `PlayerProfileManager.gd`: tách UI / logic / persistence.
**Giữ nguyên API công khai** hoặc cập nhật đồng bộ mọi chỗ gọi. Dùng composition (node con / `RefCounted` helper), không copy-paste.

### 8.4 Khác
- `get_node("A/B")` / `$A/B` dài → `@export` hoặc `%Unique`; `$X` trong `_ready` → `@onready var`.
- Signal: theo §5B.4 — node tĩnh nối trong `.tscn`; node sinh lúc chạy/autoload nối bằng code một chỗ, cú pháp có kiểu; không nối trùng.
- Xóa biến/tham số không dùng (cảnh báo `UNUSED_*`); tham số cố ý không dùng đặt tiền tố `_`.

---

## 9. PHASE 6 — Hoàn thiện

1. `grep` lần cuối: `DEPRECATED`, `legacy`, `TODO`, `FIXME`, `đã gỡ`, `trước đây`, `bản cũ`, `optimizing_clean`, `portrait_landscape_feature`, `"/root/`, `print(` — mỗi cái còn lại phải có lý do.
2. Bộ kiểm tra §2: **0 lỗi E, 0 W1/W2, 0 DEAD/BASE-DEAD/SPLIT-BASE**, và `audit_hardcode.py` đạt đích §5B.6 (S=E=T=0; P, C ≈ 0 với ngoại lệ `keep-code` có lý do).
3. Viết `REFACTOR_LOG.md` (§11) và `docs/STRUCTURE.md` (≤ 1 trang): cây thư mục đích, quy ước đặt tên, mô hình layout Portrait/Landscape, danh sách autoload & trách nhiệm.
4. **Không merge** — dừng ở commit cuối để người dùng review và test trong editor.

---

## 10. Dừng và hỏi (chỉ những trường hợp này)

- Muốn đổi **key lưu save / key dịch / tên autoload** (mất dữ liệu người chơi).
- Muốn xóa hàm/migration "legacy" mà không chắc còn save cũ.
- Gộp scene Portrait/Landscape có thể đổi hình ảnh mà không xác nhận được.
- Đổi tên `archivement` → `achievement` chạm dữ liệu persist.
- Chuyển giá trị hard-code sang `.tscn`/Theme mà **không xác định được giá trị hiệu dụng cuối cùng** ở một màn (nhiều nhánh code đè khác nhau) và không thể giữ hình ảnh y hệt.
- Phát hiện logic có vẻ là **bug** (không phải mùi code): ghi lại, **không** sửa trong refactor — chỉ báo.

Mọi quyết định còn lại: tự quyết, ghi vào `REFACTOR_LOG.md` kèm lý do.

---

## 11. Báo cáo cuối (`REFACTOR_LOG.md`)

(1) baseline vs kết quả bộ kiểm tra; (2) bảng node đã xóa (`scene — node — lý do an toàn`); (3) bảng file đã xóa/di chuyển (`cũ → mới`); (4) mục **Nghi ngờ/đã giữ** (node ẩn giữ lại + code bật nó); (5) việc bỏ qua và lý do; bảng **hard-code → vị trí mới** (`file:dòng → scene/theme`) và số P/T/C/S/E theo từng commit; danh sách ngoại lệ `keep-code`; (6) nghi ngờ bug; (7) danh sách người dùng cần test thủ công trong editor: Title, Splash, Main, Game từng mode (Standard, Countdown, Dungeon, Fog of War, Sum Path, Wall Builder, One Stroke, Fading Ink, Blind Memory, Minesweeper, Challenge), Daily, Shop, Ranking, Achievement, Settings, Tutorial, các popup Win/GameOver/Retry/OutOfLife/Pause — **cả Portrait và Landscape**.

---

## Phụ lục — Ghi chú kỹ thuật `.tscn` (Godot 4.5)

- Scene kế thừa: root có `instance=ExtResource("…")`; node của scene cha được override bằng stanza `[node name="X" parent="Y" …]` **không có `type=`**. Stanza chỉ gồm `visible = false` = ẩn node thừa kế — chính là mẫu cần dọn ở Phase 1.
- Thứ tự thuộc tính trong header `[node …]` không cố định (`instance=` có thể đứng trước/sau `parent=`) — script/regex phải parse từng thuộc tính.
- `NodePath` export trong `.tscn` **tương đối so với node chứa property**, không phải root scene.
- Track animation: `NodePath("Path/To/Node:property")`.
- `node_paths=PackedStringArray("a","b")` ở header: mỗi tên phải có dòng `a = NodePath("…")` bên dưới; xóa node → xóa cả hai.
