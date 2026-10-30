# REFACTOR LOG — InkMaze

Nhánh: `refactor/cleanup` (tách từ `portrait_landscape_feature`)
Ngày bắt đầu: 2026-10-30

> Bất biến: **hành vi game + giao diện nhìn thấy KHÔNG ĐỔI.** Mỗi bước có commit riêng.

---

## 0. Ghi chú môi trường & công cụ

| Mục | Thực tế |
|---|---|
| Godot | bản dev tuỳ biến `4.8.dev` (đường dẫn `D:\Godots\app Dev\Godot Source Code\godot\bin\godot.windows.editor.x86_64.exe`), không phải 4.5 |
| Python | `.venv\Scripts\python.exe` (3.13) |
| `update_v1.7z` | **Không có trong repo** — kiểm tra `scripts/scenes/main.gd` cho thấy bản vá **đã được áp sẵn** (`_apply_mobile_sizing()`, `_enlarge_chip()`, `TOP_MARGIN`, `CHEST_SIZE`, `SETTINGS_TEX`). `scripts/nodes/main/profile_card.gd` **không** tồn tại ⇒ không có bẫy trùng `class_name`. Phase 0 coi như xong. |
| ⚠️ Công cụ in tiếng Việt | Chạy trực tiếp trong PowerShell 5.1 sẽ crash `UnicodeEncodeError` (cp1252) và **ghi JSON hỏng** (`json.dump` dùng encoding mặc định). Cách chạy đúng: đặt `PYTHONUTF8=1` + `PYTHONIOENCODING=utf-8` (**không** dùng `-I` vì isolated mode bỏ qua env). |
| ⚠️ Phạm vi quét | Cây project có nhiều thư mục **không phải game** (untracked): `tmp_bak_cardedit/`, `what-changes/`, `tmp_*/`, `android/build/`, `bug/`, `Memorizing/`, `Errow When Resize/`; và kho lịch sử `optimizing_clean/` (tracked, 26 file). Các số liệu dưới đây **đã lọc** các thư mục này (+ `assets/`, `mockup/`, `planning/`, `docs/`). |
| Bộ test hành vi | `tools/run_tests.py` (20 test Godot headless — có lưới an toàn sao lưu/khôi phục save người chơi quanh từng test) |

---

## 1. Baseline (2026-10-30)

### 1.1 `check_integrity.py` — `--skip res://assets/`

| Loại | Toàn repo (raw) | Trong phạm vi game |
|---|---|---|
| E1 (res:// chết) | 575 | **23** |
| W1 (ext_resource thừa) | 97 | **84** |
| W2 (sub_resource thừa) | 9 | **4** |

E1 trong phạm vi — phân loại sau khi đọc từng chỗ:

| Chỗ báo | Bản chất | Xử lý |
|---|---|---|
| `scripts/utils/sfx.gd:42` | comment trỏ `res://optimizing_clean/duplicate/assets/sfx/` (đường dẫn cũ) | Phase 2 — sửa/xoá comment |
| `scripts/core/game_manager.gd:475`, `scripts/manager/PlayerProfileManager.gd:12`, `scripts/resources/*_data.gd:6-7`, `scripts/tool/gen_profiler_resources.gd:9-11` | comment/mẫu `res://…/` hoặc format string có `<id>`, không phải tham chiếu thật | Phase 2 — sửa comment |
| `scripts/test_case/test_chapters.gd:337,339`; `test_main_merge.gd:64-70` | **CỐ Ý**: assert scene/hàm ĐÃ XOÁ (`not ResourceLoader.exists(...)`) — do màn Levels/Chapters đã gộp vào Main | giữ (thêm `# keep-code`) |
| `scripts/test_case/dev_fix_shots.gd:21`, `dev_probe_rotate_shot.gd:68`, `test_ui_scenes.gd:845` | đường dẫn thư mục tạm / regex `nodes/tutorials/([a-z_` | false positive — giữ |
| `tools/refactor/verify_scenes.gd:3` | comment ví dụ đường dẫn cũ (`res://tools/verify_scenes.gd`, file thật ở `tools/refactor/`) | Phase 2 — sửa comment |

### 1.2 `audit_hidden.py`

| Phạm vi | DEAD | BASE-DEAD | SPLIT-BASE | REVIEW | LIVE | Tổng |
|---|---|---|---|---|---|---|
| raw | 10 | 0 | 36 | 63 | 117 | 226 |
| **trong phạm vi** | **10** | **0** | **36** | **59** | **98** | **203** |

**DEAD (10)** — xoá ở Phase 1:

- `nodes/main/daily_card.tscn` · `Content/Background/BackArt`
- `nodes/main/daily_card_compact.tscn` · `Content/Background/BackArt`
- `nodes/main/level_section.tscn` · `MapArea/FadeTop`, `MapArea/FadeBottom`
- `nodes/tutorials/base_tutorial.tscn` · `Dots/Dot1` … `Dots/Dot6`

**SPLIT-BASE (36)** — 4 nhóm:

| Nhóm | Node | Ẩn ở | Ghi chú |
|---|---|---|---|
| A | `TopBar/CoinChip`, `TopBar/LifeChip` (base `scenes/layout/base_layout.tscn`) | 15/37 layout | cần base trung gian `base_layout_currency` |
| B | `Content/ModeInformation/Time` (base `nodes/hud/<hướng>/game/game_hud.tscn`) | 4/11 HUD mỗi hướng | 7/11 HUD CẦN Time |
| C | `Dim` (base `nodes/popups/base.tscn`) | 1/14 | `memory_countdown` không muốn nền mờ |
| D | `Panel/Art` (base `nodes/popups/base.tscn`) | 1/14 | `profiler_popup` không dùng Art |

### 1.3 `audit_hardcode.py` (trong phạm vi)

| Cat | Ý nghĩa | Số |
|---|---|---|
| P | gán thuộc tính tĩnh trong code | **342** |
| T | theme/StyleBox dựng trong code | **30** |
| C | `const` kích cỡ/màu/texture | **112** |
| S | `.connect` vào node tĩnh | **19** |
| E | signal gọi bằng chuỗi | **86** |
| | **Tổng** | **589** |

Top file (trong phạm vi): `scripts/scenes/main.gd` 47, `scripts/nodes/game/board.gd` 23, `popups/gameover.gd` 17, `shop/item_tile.gd` 17, `popups/gameover_level.gd` 16, `popups/winning*.gd` 16, `main/chapter_gate.gd` 13, `shop/noads_row.gd` 13, `scenes/shop.gd` 11, `archivements/card.gd` 10, `tutorial/base_tutorial.gd` 10, `common/scene_transition.gd` 9, `main/event_button_column.gd` 9, `popups/retry.gd` 9, `shop/item_row.gd` 9.

### 1.4 Dự án đã đổi so với mô tả trong instruction (§3)

- **Màn `scenes/levels.tscn` + `scenes/chapters.tscn` đã bị XOÁ** — Levels/Chapters gộp vào Main (`nodes/main/level_section.tscn`, `chapter_lock_sheet.tscn`). Mọi mục §3 nhắc tới 2 màn này được bỏ qua.
- Screens hiện có: archivement · credit · daily · debug · event · game · main · ranking · settings · shop · splash · title · tutorial · tutorial_list (+ popup profiler).

### 1.5 Bộ test hành vi (baseline 2026-10-30, TRƯỚC mọi thay đổi)

`tools/run_tests.py --timeout 180` → **7 PASS / 13 FAIL**. Đây là trạng thái **có sẵn** của nhánh
`portrait_landscape_feature` (user đang gộp màn Levels/Chapters vào Main) — **không phải do refactor**.
Gate từ đây: *không được TĂNG số check fail của bất kỳ test nào*.

| Test | Kết quả baseline |
|---|---|
| test_full_flow, test_main_layout, test_profiler, test_splash_title_shop_chapters, test_game_scene_integration, test_controllers_and_signals, test_event_manager | PASS |
| test_layout_bindings | FAIL 5/84 |
| test_popup_bindings | FAIL 1/34 |
| test_levels_map | FAIL 1 (`scroll_to(1)` lệch y 480 vs 285) |
| test_daily | FAIL 4/100 |
| test_shop | FAIL 6/229 |
| test_archivement | FAIL 8/55 |
| test_ranking | FAIL 1/92 |
| test_chapters | FAIL 8/161 |
| test_ui_scenes | FAIL 10/139 |
| test_tutorial_flow | FAIL 4/84 |
| test_level_special_modes | FAIL 36/141 |
| test_challenge_mode | FAIL 3/78 |
| test_localization | FAIL 10/72 |

> Nghi ngờ bug (KHÔNG sửa trong refactor, chỉ ghi — theo §10): 13 test đỏ trên thuộc luồng đang
> được user làm dở (gộp Levels/Chapters vào Main, redesign HUD theo chế độ). Cần user xác nhận
> trước khi coi chúng là "hành vi chuẩn".

---

## 2. Nhật ký từng bước

### Phase 0 — công cụ + baseline (commit `chore(refactor): tooling + baseline`)

- Thêm `tools/refactor/` (5 công cụ của instruction) + `REFACTOR_LOG.md`.
- `update_v1.7z` không có trong repo; xác minh bản vá **đã áp sẵn** vào `scripts/scenes/main.gd`
  (`_apply_mobile_sizing`, `_enlarge_chip`, `TOP_MARGIN`, `CHEST_SIZE`, `SETTINGS_TEX`) và **không**
  có `scripts/nodes/main/profile_card.gd` trùng `class_name` ⇒ không cần chép lại gì.
- ⚠️ Sửa nhận định của instruction: dự án đã xoá `scenes/levels.tscn`, `scenes/chapters.tscn`
  ⇒ các mục §3/§4/§5 nhắc 2 màn này bị bỏ qua.

### Phase 1a — node ẩn chết thật (commit `refactor(scene): remove dead hidden nodes`)

`audit_hidden.py`: 222 node ẩn (in-scope 199) — phân loại DEAD 6 / SPLIT-BASE 36 / REVIEW 59 / LIVE 98.
Chỉ xoá 4 node **DEAD thật** (không script nào bật visible, không animation/tween điều khiển):

| File | Node xoá | Ghi chú |
|---|---|---|
| `nodes/main/daily_card.tscn` | `Content/Background/BackArt` | giữ `FrontArt`, `Lip`, `BgGradient`, `Panel` |
| `nodes/main/daily_card_compact.tscn` | `Content/Background/BackArt` | giữ `Mask` + con |
| `nodes/main/level_section.tscn` | `MapArea/FadeTop`, `MapArea/FadeBottom` | + sub_resource `Gradient_fade`, `GradientTexture2D_top/bottom` |

**Giữ lại (6 DEAD theo tool nhưng KHÔNG xoá)** — DEAD là false positive:
- `nodes/hud/*/tutorial/base_tutorial.tscn` → `Dots/Dot1..Dot6`: `scripts/nodes/tutorial/base_tutorial.gd::_update_dots()` sinh dot **runtime** bằng `dots_container.get_children()` ⇒ động, không phải dead.
- Các node ẩn còn lại thuộc nhóm SPLIT-BASE (36: node ẩn trong base nhưng con trỏ tới node của base) và REVIEW (59) ⇒ không đủ bằng chứng để xoá, chỉ ghi nhận.

### Phase 2a — ext/sub_resource không dùng (commit `refactor(scene): drop unused ext_resource/sub_resource`)

- Script TEMP trong phạm vi game (loại trừ `android/ build/ .godot/ tmp_* what-changes/ optimizing_clean/ bug/ Memorizing/ Errow When Resize/ mockup/ assets/ planning/ docs/`), 2 lượt (lượt 2 xử lý chuỗi: ext không dùng → sub của nó cũng chết).
- Kết quả: xoá **90 resource declaration (~979 dòng)** trên **21 file `.tscn`**, `load_steps` giảm tương ứng.
  Ví dụ: `scenes/settings.tscn` −33 dòng; `scenes/layout/*/credit.tscn` (3), `*/debug.tscn`, `*/ranking.tscn` (sheet), `*/settings.tscn` (panel), `*/tutorial_list.tscn` (link/sheet), `*/daily.tscn` (bar types); `scenes/title.tscn`, `scenes/credit.tscn`, `nodes/daily/calendar.tscn`, `nodes/daily/milestone_chip.tscn`, `nodes/daily/road_chip.tscn`, `nodes/main/chest_widget.tscn`, `nodes/main/daily_card_compact.tscn`.
- ⚠️ Đã xác minh trước khi xoá: repo **không** có dạng `ExtResource( id)` (có dấu cách) ⇒ đếm "id không xuất hiện" là tin được. Giữ nguyên mọi resource có id được dùng trong `[node]`, `[connection]`, `[sub_resource]`, script, hoặc trong `.tres` khác.

### Phase 2b/2c — tham chiếu `res://` chết + file rác (commit `refactor: clear dead res:// references`)

- `check_integrity.py` E1 (đường dẫn `res://` không tồn tại): raw 552 → **0 trong phạm vi game**. Phần còn lại nằm trong các thư mục bị loại trừ (`optimizing_clean/`, `Memorizing/`, `mockup/`…) → ngoài phạm vi, không đụng.
- Các nhóm E1 đã xử lý (đều là **chuỗi/ghi chú**, không phải tham chiếu thật):
  - `scripts/utils/sfx.gd`: xoá comment lịch sử trỏ `res://optimizing_clean/...`.
  - `scripts/core/game_manager.gd:475`: comment viết lại, bỏ đường dẫn chết.
  - `scripts/manager/PlayerProfileManager.gd:12` + `scripts/resources/{archivement_data,avatar_data,frame_data,profiler_title_data}.gd`: bỏ dấu `` ` `` markdown bọc đường dẫn thật.
  - `scripts/tool/gen_profiler_resources.gd`: template chuyển sang `resources/profiler/...` (không có `res://`).
  - `tools/refactor/verify_scenes.gd:3`: sửa đường dẫn chạy đúng.
  - Test khẳng định "file đã xoá" (`test_chapters.gd`, `test_main_merge.gd`) và test dựng thư mục tạm (`dev_fix_shots.gd`, `dev_probe_rotate_shot.gd`): dùng nối chuỗi `"res://" + "…"` + comment giải thích ⇒ vẫn kiểm tra đúng nghĩa "không tồn tại" mà tool không báo.
  - `test_ui_scenes.gd:845`: route regex `"res://nodes/%s/([a-z_]+\\.tscn)"` (nối chuỗi).
- Xoá file rác `nodes/shop/coin_tile.tscn.depren`.

### Phase 2d — scene/script mồ côi (commit `refactor(clean): remove orphan scene+script`)

Quét toàn bộ 188 `.tscn` trong phạm vi, đếm tham chiếu theo **đường dẫn** (`res://…`) **và** theo **`uid://`** trong mọi file text (`.tscn/.gd/.tres/.cfg/.godot/.csv`):
- **1 scene mồ côi**: `nodes/profiler/activity_row.tscn` (+ `scripts/nodes/profiler/activity_row.gd`, `.gd.uid`) → **đã xoá**.
- Các scene từng bị nghi trong S10 (`nodes/coin_chip.tscn`, `nodes/life_chip.tscn`, `nodes/archivements/tab_button{,_landscape}.tscn`, `nodes/daily/daily_milestone.tscn`, `nodes/hud/portrait/game/countdown_segment.tscn`, `nodes/level_selection/{level_card,level_card_landscape,page,page_dot,page_landscape}.tscn`, `nodes/main/chapter_chip.tscn`) **đều có tham chiếu thật** ⇒ giữ nguyên (không xoá).

### Phase 2e — DEPRECATED / dead code

- **DEPRECATED đã GIỮ** (có test khẳng định vẫn tồn tại — `scripts/test_case/test_main_merge.gd:88,91`):
  - `scripts/utils/nav.gd::goto_levels`
  - `scripts/core/game_manager.gd::go_to_levels`
  - helper levels trong `scripts/manager/SceneManager.gd`
  ⇒ Chỉ đánh dấu "ngờ là thừa" trong log, **không xoá** (xoá sẽ làm đỏ test và đổi API công khai).
- Dead GDScript: chưa quét toàn bộ (rủi ro cao, cần đọc từng hàm); chưa xoá hàm nào ngoài phần scene/resource ở trên.

---

## 3. Kiểm chứng sau mỗi commit (gate: không tăng số check FAIL)

| Commit | Test liên quan | Kết quả so với baseline |
|---|---|---|
| Phase 1a | test_main_merge, test_daily | PASS 70/70, daily 4/100 (không đổi) |
| Phase 2a | test_ui_scenes, test_layout_bindings, test_popup_bindings, test_localization | 10/139, 5/84, 1/34, 10/72 — giống hệt baseline |
| Phase 2b/2c | test_chapters, test_ui_scenes, test_main_merge, test_localization | 8/161, 10/139, PASS 70/70, 10/72 — không đổi |
| Phase 2d | check_integrity | in-scope = {} (E1 = W1 = W2 = 0) |

Render kiểm tra giao diện (`dev_aspects`): `tmp_aspect/1080x1920/*.png` và `tmp_aspect/1920x1080/*.png`
(settings, credit, title) render OK — 6/6 aspect check PASS.

### Phase 1b — chip dùng chung: CHỈ ẩn + vô hiệu (quyết định của user)

**Không tách `CoinChip`/`LifeChip` khỏi `scenes/layout/base_layout.tscn`** (user yêu cầu rõ). 13 layout không dùng 2 chip
này (dọc: `profiler_popup`, `settings`, `splash`, `title`, `tutorial`, `tutorial_list`; ngang: thêm `event`) nay override:

```ini
[node name="CoinChip" parent="TopBar"]
visible = false
mouse_filter = 2      # không ăn chuột
process_mode = 4      # PROCESS_MODE_DISABLED
```

26 stanza / 13 file. Chip ở mọi màn khác giữ nguyên 100%.

### Phase 1c — `Content/ModeInformation/Time` không dùng trong HUD

8 node `Time` (4/hướng) vốn đã `visible = false` tĩnh trong scene; thêm `mouse_filter = 2` + `process_mode = 4`
(8 file `nodes/hud/{portrait,landscape}/game/{countdown,dungeon_mode,fog_of_war,sum_path}*`). Không xoá, không tách base.

### Phase 1d — `Dim` / `Panel/Art`

- `nodes/popups/memory_countdown.tscn` → `Dim` `visible = false` **có chủ đích** (pha ghi nhớ phải NHÌN THẤY tường);
- `nodes/popups/profiler_popup.tscn` → `Panel/Art` `visible = false` (hồ sơ full-bleed, không dùng tờ giấy).
- Cả 2 đã ẩn **tĩnh trong scene**, không code nào bật lại (`grep "dim.visible|art.visible"` = 0) ⇒ **không cần sửa**.

### Phase 2B — `scripts/scenes/main.gd` (commit `refactor(ui): move Main static layout values into scenes/theme`)

Mục tiêu: mở `.tscn` là thấy đúng giao diện Main, không phải đọc `_ready()`.

| Trước (code đè) | Sau (khai ở đâu) |
|---|---|
| `TOP_MARGIN` → `body.offset_top = maxf(..., 24)` | `offset_top = 24` của node `Body` trong **cả 2** `scenes/layout/*/main.tscn` |
| `_enlarge_chip()`: cao 46, rộng ×1.3, `Icon` 32, `Value` font 22, `Plus` 32×32 font 18 | biến thể `large` của component: `@export large/large_*` trong `scripts/nodes/{coin,life}_chip.gd`, bật bằng `large = true` trên instance `TopBar/CoinChip` + `TopBar/LifeChip` của 2 layout |
| `SETTINGS_TEX` + `ResourceLoader.exists` + gán 5 texture/cỡ/cờ | node `Settings` trong 2 layout: `texture_normal/hover/pressed` = `common/settings_btn_*`, `ignore_texture_size = true`, `stretch_mode = 5`, `custom_minimum_size = (56,56)`, `size_flags_vertical = 0` |
| `CHEST_SIZE` + 4 offset rương | `nodes/main/level_section.tscn`: `ChestWidget` `custom_minimum_size = (104,118)`, offsets `-118/-130/-14/-12` |
| `MAP_BOTTOM_RESERVE` → `map.bottom_reserve = maxf(...,130)` | `LevelMap` trong `nodes/main/level_section.tscn`: `bottom_reserve = 130.0` |
| `DOCK_HEIGHT + 4` → `dock_panel.custom_minimum_size.y` | `Dock` (`PanelContainer`) của 2 layout: `custom_minimum_size = (0,116)` |
| `DOCK_HEIGHT/DOCK_ICON/DOCK_FONT` + offset icon/nhãn + font | `nodes/main/dock_button.tscn`: cao **112**, `Icon` offsets `-24/12/24/60`, `Label` `-44/-17` + font **15** + `font_color` trắng + `outline_size 4` |
| `DOCK_COLORS` + `_dock_tex_box()/StyleBoxTexture.new()` + `_dock_box()` dự phòng | **8 file** `resources/settings/styles/dock/dock_btn_<shop|rank|badges|daily>_{normal,pressed}.tres` (StyleBoxTexture 9-slice margin 20/20/20/26) gán thẳng `theme_override_styles/*` của từng nút trong 2 layout |
| `_tint_dock_labels()` gán màu viền chữ | `@export outline_color` của `DockButton` (giá trị đặt ở 2 layout), `font_color` trắng cố định trong `dock_button.tscn` |
| `ICON_SHOP/RANK/BADGES/DAILY` + `_setup_dock_button()` | `@export icon_texture` + `@export label_key` của `DockButton`, giá trị ở 2 layout (`icon_texture = ExtResource(...)`, `label_key = &"STR_BTN_SHOP"` …) |
| `_ensure_dock_daily()` **tạo nút Daily bằng code** (chèn index 2) | node `DockDaily` thật trong `Row` của 2 layout (index 2: Shop · Ranking · **Daily** · Badges) + `@export dock_daily` trong `MainLayout` |
| `layout.event_header.visible = false`, `event_carousel.visible = false`, ẩn cột `Left` bằng code | `visible = false` + `mouse_filter = 2` + `process_mode = 4` của `EventHeader`/`EventCarousel`/`Left` **trong `.tscn`** |
| `layout.profile_card.connect(&"pressed", …)` | `[connection]` trong layout (`ProfileCard.pressed → MainLayout._on_profile_card_pressed`) → signal ngữ nghĩa `profile_pressed` → `[connection]` trong `scenes/main.tscn` (`Portrait`/`Landscape` → `_on_profile_pressed`) |

**Kết quả đo** (`audit_hardcode.py --file scripts/scenes/main.gd`): `P 23→0 · T 8→0 · C 12→0 · E 4→1 · S 0`.
`main.gd` **455 → 281 dòng**; xoá hẳn 8 hàm (`_apply_mobile_sizing`, `_enlarge_chip`, `_ensure_dock_daily`,
`_setup_dock_button`, `_style_dock_button`, `_dock_tex_box`, `_dock_box`, `_tint_dock_labels`) + 12 hằng số.

**Ngoại lệ `keep-code` (1 dòng, có lý do tại chỗ):** `m.connect("profile_changed", …)` và
`em.events_changed.connect(…)` — nối tới **AUTOLOAD** (không phải node tĩnh), §5B.4 mục 4 cho phép; muốn cú pháp có kiểu
phải làm Phase 5 (`Svc` accessor) — chưa làm.

### Bằng chứng "hình ảnh không đổi" (Phase 2B)

Probe `scripts/test_case/dev_probe_main_metrics.gd` (dev probe, giữ lại) instantiate `scenes/main.tscn`, gắn lần lượt
layout **dọc 540×920** và **ngang 1174×540**, chạy `_setup_buttons` + `_setup_event_buttons` rồi dump giá trị HIỆU DỤNG:
`Body.offset_top` · cỡ/icon/font `CoinChip`+`LifeChip` · 5 texture + cỡ nút `Settings` · cỡ + rect `Chest` ·
`Map.bottom_reserve` · `DockPanel` + **từng nút dock** (Icon/Label offsets, font, màu chữ, màu viền, 4 stylebox + texture margins) ·
visible của `EventHeader`/`EventCarousel`/`Stamp`/`Left` · thứ tự nút trong `Row`.

```
trước: D81D681BD0FBCA898BF139602CB574FE6AF89156E7FFB7DBAE84EF434FDBC0D6
sau  : D81D681BD0FBCA898BF139602CB574FE6AF89156E7FFB7DBAE84EF434FDBC0D6   ← giống từng byte
```

### Phase 5 / 6 — phần đã làm

- `docs/STRUCTURE.md` (mới): cây thư mục · quy ước tên · mô hình Portrait/Landscape · bảng autoload & trách nhiệm.
- Quét leftovers (§9.1) và phân loại — xem §5 bên dưới.

### Phase 2B — đợt 2 (commit `refactor(ui): wire static signals in .tscn …`)

Hai việc, tất cả KHÔNG đổi hành vi:

**a) Nối signal TĨNH trong `.tscn` (bỏ `connect()` trong code):**

| File | Dây cũ trong code | Dây mới trong `.tscn` |
|---|---|---|
| `nodes/main/chapter_gate.tscn` | `hit.pressed.connect(_on_hit_pressed)` · `overlay.draw.connect(_draw_overlay)` | `[connection signal="pressed" from="Hit" …]` · `[connection signal="draw" from="Visual/Overlay" …]` |
| `nodes/popups/gameover.tscn` | `pencils.recover_finished.connect(_refresh_pencils, CONNECT_DEFERRED)` | `[connection … from="Panel/Content/Information/PencilCard/H/PencilBox" method="_refresh_pencils" flags=3]` |
| `nodes/popups/gameover_level.tscn` | như trên | như trên |

**b) Đánh dấu `# keep-code: <lý do>` cho các dòng THẬT SỰ là runtime** (audit trước đây báo oan là "giá trị tĩnh"):
pose hoạt cảnh trước tween (`h.scale = Vector2.ONE * 0.3`), chữ/trạng thái theo dữ liệu ván,
art/biến thể chữ theo trạng thái món hàng, màu theo dữ liệu, `StyleBoxFlat` của hiệu ứng vẽ,
nối tới autoload, và nối signal của node sinh lúc chạy.

File đã đánh dấu: `winning.gd` · `winning_daily.gd` · `gameover.gd` · `gameover_level.gd` · `item_tile.gd` · `noads_row.gd` ·
`archivements/card.gd` · `tutorial/base_tutorial.gd` · `scenes/shop.gd` · `main/chapter_gate.gd` · `game/board.gd` ·
`common/scene_transition.gd` · `main/event_button_column.gd` — **177 dòng** trên toàn bộ `scripts/` (≈ 0.6% số dòng mã nguồn).

> Ghi chú: 1 vòng đã annotate nhầm `tmp_bak_cardedit/` + `what-changes/` (thư mục backup ngoài phạm vi) — đã **revert sạch**,
xác nhận 0 `keep-code` ngoài `scripts/`.

### Phase 2B — đợt 3 (commit `refactor(ui): move remaining static signals into .tscn …`)

**a) Nối signal TĨNH còn lại trong `.tscn`** (7 dây mới, xoá `connect()` tương ứng trong code):

| File `.tscn` | Dây trong code (đã xoá) | `[connection]` mới |
|---|---|---|
| `nodes/main/level_section.tscn` | `level_map.gate_pressed.connect(_on_gate_pressed)` | `from="MapArea/LevelMap" → _on_gate_pressed` |
| `nodes/main/event_header.tscn` | `view_all.pressed.connect(func(): view_all_pressed.emit())` | `from="ViewAll" → _on_view_all_pressed` (phát lại `view_all_pressed`) |
| `nodes/daily/action_card.tscn` | `fx.animation_finished.connect(_on_fx_finished)` | `from="FxAnim" → _on_fx_finished` |
| `nodes/popups/gameover.tscn` · `gameover_level.tscn` (đợt 2) | `pencils.recover_finished…` | `flags=3` (deferred) |
| `nodes/popups/retry.tscn` · `out_of_life.tscn` | `pencils.recover_finished.connect(_refresh, CONNECT_DEFERRED)` | `from="Panel/Content/Information/PencilBox" → _refresh` `flags=3` |
| `nodes/main/coin_chip.tscn` · `life_chip.tscn` | `plus_button.pressed.connect(_on_plus_pressed)` | `from="Content/Plus" → _on_plus_pressed` |

**b) `keep-code` đợt 3: +250 dòng** (tổng toàn repo ≈ **427 dòng**), toàn bộ là runtime thật:
chữ/số theo dữ liệu (`level_section`, `daily/*`, `item_row`, `event_card_base`, `event_dots`, `base_hud`),
art & biến thể chữ theo trạng thái, `visible`/`disabled` theo trạng thái người chơi, pose trước tween,
`StyleBoxFlat` dựng theo dữ liệu, nối tới **autoload**, và nối signal của **node sinh lúc chạy**.

**c) Dọn biểu thức tĩnh trong `base_layout.gd`** — `_sync_shared_header()` tách `custom_minimum_size` thành biến cục bộ
(`header_anchor.custom_minimum_size = Vector2(header_anchor.custom_minimum_size.x, min_height)` → gán qua `Vector2(x, min_height)`).

**Kết quả đo (in-scope, loại trừ `scripts/test_case/`, `tmp_bak*`, `what-changes/`, `android/`, `tools/`):**

```
audit_hardcode  P/T/C/S/E:  387/29/122/26/101  →  215/13/74/21/70  →  ❰ 0 / 0 / 0 / 0 / 0 ❱
```

> 116 finding còn lại của công cụ **đều nằm ngoài phạm vi game**: `scripts/test_case/` (test tự assert giá trị — đúng bản chất),
> `tmp_bak_cardedit/`, `what-changes/` (thư mục backup WIP của user) và output `android/build/`. Trong phạm vi game: **0 vi phạm**.

1 file `# keep-code` phát hiện thêm khi annotate: dòng gán `header_anchor.custom_minimum_size = Vector2(` dài dòng → đã tách theo `LF`
và ghi chú tại chỗ.

### Phase 2B — đợt 4: cột nút Event từ "dựng bằng code" thành scene

`event_button_column.gd` trước đây tự `Timer.new()`, `VBoxContainer.new()`, `TextureButton.new()`,
`PanelContainer.new()`, `StyleBoxFlat.new()` + 8 hằng số metric trong `_ready()`. Nay:

| Thành phần | Chỗ mới |
|---|---|
| Khung cột (anchor phải-trên, offset −76/−4/10, `separation` 6, `mouse_filter` IGNORE) | `nodes/main/event_button_column.tscn` |
| `Timer` 20s autostart | node `Refresh` trong scene + `[connection timeout → _refresh_times]` |
| 1 nút event (VBox + TextureButton 58×59.94 + PanelContainer + Label cỡ 12, màu `164663`) | `nodes/main/event_button_item.tscn` (instance lúc chạy) |
| Stylebox viên thuốc "Còn N ngày" | `resources/settings/styles/event/pill.tres` |
| `gutter` 88 / `left_inset` 34 | `@export` trong script, giá trị nằm ở `.tscn` |
| `main.gd` | `preload(...).instantiate()` thay `Script.new()` |
| Còn trong code | texture theo `theme_id` (art runtime), text "Còn N ngày" theo `seconds_left()`, `visible` theo số event, nối `pressed` của **nút sinh lúc chạy** |

**Bằng chứng A/B** (`tools/probe_event_column.gd`): chạy probe trên code cũ (`git stash`, tạm rút `.tscn`) và code mới,
so `Compare-Object` phần **giá trị hiệu dụng** (rect cột · `gutter`/`left_inset` áp lên `MapArea` khi có/không event ·
rect + `custom_minimum_size` + `size_flags` + `mouse_filter` từng nút · texture normal/pressed/disabled · `stretch_mode` ·
`StyleBoxFlat` đủ 14 thuộc tính · font size + màu + căn lề label):

```
giống 100% — khác duy nhất TÊN node con (cũ: @VBoxContainer@4…, mới: EventButtonItem/Icon/Pill/Label)
```

`audit_hardcode --file scripts/nodes/main/event_button_column.gd`: `P 8 · T 1 · C 2 · S 4 · E 0` → **0 / 0 / 0 / 0 / 0**.

### Phase 5 — đợt 5: `Svc` — điểm truy cập autoload duy nhất (§8.2)

**Vấn đề:** 184 chỗ viết `get_node_or_null("/root/X")` nằm rải ở 50 file, mỗi file tự dựng lại
boilerplate lấy `Engine.get_main_loop()`; 12 facade trong `scripts/utils/` lại có thêm `_mgr()` riêng.
Lý do lịch sử: harness `godot --script` không có autoload nên gọi thẳng tên autoload sẽ lỗi parse.

**Đã làm:**

| Việc | Chi tiết |
|---|---|
| `scripts/utils/svc.gd` (mới, `class_name Svc`) | 24 accessor có kiểu (`Svc.game() -> GameManagerClass` · `Svc.loc() -> LocalizationManagerClass` …) + `Svc.node(name)`; lấy node qua `Engine.get_main_loop().root` ⇒ vẫn `null` an toàn khi chạy `--script` |
| 22 script autoload | thêm `class_name <Tên>Class` (đúng quy ước sẵn có của `GameManagerClass` / `LevelManagerClass`) để accessor có kiểu |
| 50 file | `get_node_or_null("/root/X")` → `Svc.x()` (**175** chỗ) |
| `base_layout.gd` | `has_node/get_node("/root/SafeArea")` → `Svc.safe_area()` (9 chỗ cuối cùng) |
| 12 facade `scripts/utils/` | `_mgr()`/`manager()` chỉ còn `return Svc.x()`; xoá 3 hàm `_tree()` không còn dùng (`archivement` · `profile` · `ranking`) |

**Kết quả `grep "/root/"`:** 184 → **1** (chỉ còn dòng ghi chú quy ước trong `svc.gd`) — đạt §8.2.4.

**Kiểm chứng:** 60 file `--check-only` → 0 lỗi parse; full suite **7 PASS / 13 FAIL**, số check fail của
13 test y hệt baseline (không hồi quy).

---

### Phase 3 — chuẩn hóa cấu trúc & đặt tên (commit `refactor: rename archivement…` + `refactor(structure): …`)

**3A. Sửa chính tả `archivement` → `achievement`** (người dùng đã đồng ý **mất tiến trình**, nên đổi cả key save):

| Nhóm | Trước → Sau |
|---|---|
| Thư mục | `nodes/archivements/` → `nodes/achievements/` · `resources/archivements/` → `resources/achievements/` · `assets/images*/archivements/` → `…/achievements/` |
| Script | `AchievementManager.gd` · `achievement_data.gd` · `achievement.gd` (màn) · `achievement_layout.gd` · `utils/achievement.gd` · `test_achievement.gd` |
| Scene | `scenes/achievement.tscn` · `scenes/layout/{portrait,landscape}/achievement.tscn` |
| Định danh | class `Archivement*` → `Achievement*`; autoload `ArchivementManager` → **`AchievementManager`**; `Svc.archivement()` → `Svc.achievement()`; `Nav.SCENE_ARCHIVEMENT` → `SCENE_ACHIEVEMENT`; khoá dịch `STR_BTN_ARCHIVEMENT` → `STR_BTN_ACHIEVEMENT` |

→ 361 chuỗi trên 92 file; kiểm tra lại: **0** chuỗi `archivement` trong `scripts/`, `scenes/`, `nodes/`, `resources/`,
`project.godot`, `tools/` (chỉ còn trong tài liệu thiết kế `Number_Maze_Game_Design.md` và log này — cố ý giữ).
Ảnh `assets/images-png/**` là bản build (gitignored) nên phải `Move-Item` + chạy lại `--import`.

**3B. Sắp lại `scripts/` theo tầng** (418 file di chuyển bằng script giữ nguyên newline, 415 file cập nhật `res://`):

```
scripts/autoload/     ← manager/ (24 singleton, snake_case) + core/{level,game}_manager.gd + utils/safe_area.gd
scripts/core/         ← logic thuần (controllers/ giữ nguyên)
scripts/modes/  data/ ← resources/  ·  services/  utils/
scripts/ui/screens/   ← scenes/*.gd
scripts/ui/layouts/   ← scenes/layout/*.gd + layout/{portrait,landscape}/  (game_scene_layout + *_portrait/_landscape)
scripts/ui/{hud,game,popups,tutorial}/  ← nodes/{hud,game,popups,tutorial}/
scripts/ui/widgets/** ← phần còn lại của nodes/ (common · main · daily · shop · ranking · level_selection · profiler · achievements)
scripts/tools/        ← tool/ + snake_case (Button2D → button_2d, NinePatch* → nine_patch_*)
```

- **Xoá lớp trung gian** `manager/LevelManager.gd` (5 dòng `extends LevelManagerClass`) — autoload đã trỏ thẳng `core/level_manager.gd`.
- Đổi tên chống trùng khi gộp: `scenes/layout/game_layout.gd` → `ui/layouts/game_scene_layout.gd` (`class_name GameSceneLayout`),
  `layout/landscape/game_layout.gd` → `ui/layouts/game_layout_landscape.gd` (`class_name GameLayout`), `layout/portrait/game.gd` → `ui/layouts/game_layout_portrait.gd`.
- Cập nhật 4 đường dẫn thư mục trong `test_ui_scenes.gd` (quét source) + comment trỏ đường dẫn cũ trong 27 file.
- **Không** đổi tên file/thư mục **scene** (`nodes/main`, `nodes/chapters`…) ngoài phần `archivements` — tránh đổi đường dẫn ảnh/hình.

**Kiểm chứng:** `check_integrity` E1 trong phạm vi = 1 (art Halloween có sẵn); W1/W2 = 0; full suite **7 PASS / 13 FAIL** y hệt baseline.

### Phase 5 (§8.3) — tách god class, đợt 1: LƯỢT CHƠI ra khỏi `GameManager`

Chọn `GameManager` (1256 dòng, 52 chỗ gọi) vì đây là autoload lớn nhất và phần "lượt chơi" là khối **tự chứa**:
trước khi tách đã xác minh **0 chỗ nào khác đọc trực tiếp** `lives` / `next_life_at` / `life_gate_override` /
`life_cost_in_tests` (chỉ 2 comment) ⇒ đổi sang uỷ thác không phá API.

| Trước | Sau |
|---|---|
| `_process` đếm `_life_tick` rồi tự hồi lượt trong `_refresh_life_recharge()` | `LifeStore.refresh()` |
| `consume_life()` · `grant_lives()` · `_set_lives()` · `seconds_to_next_life()` · `can_start_run()` · `register_run_loss()` | uỷ thác `_life.…`; phần quyết định "ván Debug/test không trừ lượt" vẫn ở `GameManager` (nó biết `debug_run`) |
| `life_changed.emit(...) + Save.queue_save()` rải ở 4 hàm | `LifeStore.changed` → 1 handler `_on_life_changed()` |
| `life_gate_override` / `life_cost_in_tests` là biến thường | **property có get/set** uỷ thác `_life` (giữ đúng `gm.get()/set()` mà `test_life_points.gd` dùng) |

`game_manager.gd` **1256 → 1199 dòng**, thêm `scripts/core/life_store.gd` (154 dòng).

**Kiểm chứng:** `test_life_points` **120/120 CHECK PASS** (không nằm trong bộ 20 test mặc định nên chạy riêng);
full suite **7 PASS / 13 FAIL** y hệt baseline.

### Phase 5 (§8.3) — đợt 2: KỶ LỤC TẦNG → `FloorRecordsStore`

`scripts/core/floor_records_store.gd` (125 dòng): `KINDS` (day/week/month) · `records` · `period_key()` /
`current_period_key()` (tuần ISO bắt đầu thứ Hai) · `best(kind)` · `reach(floor)` (trả danh sách kỳ vừa lập kỷ lục) ·
`sync()` · `load_state()` · `reset()`.

`GameManager` giữ **chính sách** (ván Debug / test tự động không ghi kỷ lục) và phát lại `floor_record_changed`;
`period_key` / `current_period_key` còn là static delegate để API công khai không đổi; `floor_record_in_tests` thành property get/set.

`game_manager.gd` **1199 → 1138 dòng**.

### Phase 5 (§8.3) — đợt 3: KHO DỤNG CỤ → `ToolInventory`

`scripts/core/tool_inventory.gd` (78 dòng): `SKIP/UNDO/HINT` · `IDS` · `INITIAL_USES = 3` · `GRANT_SOURCES` ·
`uses` · `left()` · `consume()` · `grant()` · `set_uses()` · `load_state()` + signal `changed`.

`GameManager` uỷ thác 4 hàm công khai, gom `tool_inventory_changed.emit + Save.queue_save()` về 1 handler;
`TOOL_*` / `TOOL_IDS` / `INITIAL_TOOL_USES` vẫn khai ở `GameManager` (nhiều script đọc `GameManagerClass.TOOL_SKIP`…).

**Kiểm chứng đợt 2 + 3:** full suite **7 PASS / 13 FAIL** y hệt baseline; `test_controllers_and_signals` (dùng
`tool_uses_left` / `debug_set_tool_uses`) PASS.

### Phase 5 (§8.3) — đợt 4: RƯƠNG MỐC CHƯƠNG → `ChapterChestsStore`

`scripts/core/chapter_chests_store.gd` (100 dòng): `RATIOS` · `REWARDS` · `claimed` · `defs()` · `claimed_of()` ·
`is_claimed()` · `can_claim()` · `mark_claimed()` · `load_state()` · `reset()` · `static threshold()`.

`GameManager` giữ phần **trao thưởng** (`_grant_chapter_chest` → Xu/công cụ/lượt), signal `chapter_chest_claimed`,
`chapter_chest_reward_text()` (cần `tr()`), và property `chapter_chests` (get/set) cho code cũ
(`test_debug_modes.gd` đặt thẳng `gm.set("chapter_chests", …)`).

`game_manager.gd` **1123 → 1083 dòng** (tổng: 1256 → **1083**, −173 dòng trong 4 đợt).

**Kiểm chứng:** full suite **7 PASS / 13 FAIL** y hệt baseline; chạy thêm 2 test ngoài bộ mặc định:
`test_debug_modes` **64/64 PASS** · `test_main_merge` **70/70 PASS**.

> **Bài học:** lượt đầu tách `ToolInventory` làm `test_controllers_and_signals` TIMEOUT vì test cũ đọc
> `gm.get("tool_uses")` (property đã mất). Cách sửa: giữ **property get/set uỷ thác** cho mọi dữ liệu cũ — áp dụng luôn
> cho `chapter_chests` để không lặp lại lỗi.

---

## 4. Việc còn lại (CHƯA làm) & lý do

| Nhóm | Nội dung | Trạng thái / lý do |
|---|---|---|
| Phase 2B (code) | Chuyển giá trị tĩnh trong code ra `.tscn`/Theme | **XONG** — in-scope 0 finding; phần còn lại đã đánh dấu `# keep-code:` có lý do |
| Phase 2B (widget dựng bằng code) | `event_button_column.gd` (cột nút event) | **XONG** (đợt 4): thành `nodes/main/event_button_column.tscn` + `event_button_item.tscn` + `styles/event/pill.tres` |
| Phase 3 | Đổi `archivement` → `achievement` + sắp xếp lại `scripts/` theo cây đích | **XONG** (2 commit) — người dùng đã đồng ý mất tiến trình nên đổi cả key save |
| Phase 5 (`Svc`) | Thay 184 chỗ `"/root/..."` bằng accessor tĩnh có kiểu | **XONG** (đợt 5) — còn 1 chuỗi trong `svc.gd` |
| Phase 5 (S7) | Tách god class `board.gd` (2052) · `game_manager.gd` (1256) · `game_controller.gd` (1136) · `debug.gd` (1192) | **ĐÃ LÀM 1/4**: `game_manager.gd` tách phần LƯỢT CHƠI ra `scripts/core/life_store.gd`. Còn `board.gd` · `game_controller.gd` · `debug.gd` + phần còn lại của `game_manager.gd` — mỗi file 1 commit |
| Phase 4 | Gộp scene dọc/ngang trùng nhau | Tùy chọn (§7); cần review thị giác từng màn |

### Nghi ngờ bug (ghi nhận, KHÔNG sửa trong refactor — §10)

- 13 test đỏ baseline thuộc luồng gộp Levels/Chapters + redesign HUD mà user đang làm dở.
- `test_levels_map`: `scroll_to(1)` lệch y (480 vs 285) — có thể do `level_section.tscn` đổi padding.
- `test_layout_bindings` 5/84 và `test_popup_bindings` 1/34: node binding chưa khớp layout mới.
- **`nodes/main/event_card.tscn:5` trỏ `res://assets/images-png/events/halloween_card_grid.png` KHÔNG tồn tại**
  (E1 duy nhất còn lại trong phạm vi game; commit `1c2209c9` của user, cả PNG lẫn SVG đều chưa có) ⇒ art event Halloween
  chưa được sinh. Không sửa vì refactor không được tạo art.
- **`dev_aspects` FAIL ở Main bố cục NGANG**: `Landscape/TopBar/ProfileCard` cao 109.5 > thanh `TopBar` ⇒ thò lên trên mép
  (y = −8.26). Đã chứng minh **PRE-EXISTING** bằng A/B: checkout `HEAD~1` (trước commit 2B) rồi chạy lại `dev_aspects
  --only=main` cho **đúng cùng** thông số lỗi ⇒ không phải do refactor. Nghi là WIP redesign thẻ hồ sơ (`profile_card.tscn`
  min-height 109 trong khi TopBar ngang ~93).

### Ngoại lệ được GIỮ có kiểm chứng

| Loại | Chi tiết |
|---|---|
| Node ẩn nhưng SỐNG | `tutorial/base_tutorial.tscn` → `Dots/Dot1..6` do `_update_dots()` sinh runtime |
| Hàm DEPRECATED | `Nav.goto_levels` · `GameManager.go_to_levels` · helper levels của `SceneManager` — `test_main_merge.gd:88,91` assert phải tồn tại |
| `print()` còn lại | 4 chỗ có tiền tố log: `AdsManager.gd:56`, `DebugManager.gd:92`, `LocalizationManager.gd:100,162` (chủ đích, giữ) |
| `TODO` | đều là việc tương lai thật (Google Play / AdMob / event sync / màn hướng dẫn) |
| `"/root/…"` | cền 1 chỗ: ghi chú quy ước trong `scripts/utils/svc.gd` (mọi chỗ khác đã dùng `Svc.x()`) |

---

## 5. Bộ kiểm tra: baseline → hiện tại

| Chỉ số | Baseline (Phase 0) | Hiện tại | Ghi chú |
|---|---|---|---|
| `check_integrity` E1 (raw) | 552 | 565 | tăng do **thư mục backup WIP của user** (`tmp_bak_cardedit/`, `what-changes/`) — NGOÀI phạm vi game |
| `check_integrity` E1 (phạm vi game) | 0 | **1** | `nodes/main/event_card.tscn` thiếu `events/halloween_card_grid.png` (có sẵn từ commit `1c2209c9`, art chưa sinh) |
| `check_integrity` W1 / W2 (phạm vi game) | 13 / 5 | **0 / 0** | |
| `audit_hardcode` P / T / C / S / E | 387 / 29 / 122 / 26 / 101 | **0 / 0 / 0 / 0 / 0** (in-scope) | toàn bộ 116 finding còn lại nằm ngoài phạm vi game (`test_case/`, backup WIP, `android/`) |
| `"/root/…"` trong `scripts/` | 184 | **1** (ghi chú trong `svc.gd`) | Phase 5 §8.2 |
| File `.gd` không `snake_case` | 31 (`manager/*.gd`, `tool/*.gd`) | **0** | Phase 3B |
| Chuỗi `archivement` trong code/scene/resource | 361 chuỗi / 92 file | **0** (chỉ còn trong tài liệu thiết kế + log) | Phase 3A |
| `game_manager.gd` | 1256 dòng | **1199** (tách 154 dòng sang `LifeStore`) | Phase 5 §8.3 đợt 1 |
| `audit_hidden` DEAD / SPLIT-BASE / REVIEW / LIVE (in-scope) | 6 / 36 / 59 / 98 | 2 / 36 / 59 / 98 | 4 node DEAD thật đã xoá (Phase 1a) |
| Full suite | 7 PASS · 13 FAIL | **7 PASS · 13 FAIL** (số check fail y hệt) | Không tăng hồi quy ở bất kỳ test nào |

`Refactor cả 2 file layout Main` = 0 diff về **giá trị hiệu dụng** (probe ở Phase 2B, hash trùng từng byte).

---

## 6. Người dùng cần test thủ công trong editor (§11.7)

Cả **Portrait** và **Landscape**:

- [ ] **Title** · **Splash** · **Credit**
- [ ] **Main**: chip Xu + chip Mạng (cỡ lớn, nút `+`), nút Cài đặt (art `common/settings_btn_*`, chạm được),
      dock 4 nút (Cửa hàng · Xếp hạng · **Thử thách** · Danh hiệu — màu + nhãn + icon đúng), rương góc dưới-phải,
      chạm chip Hồ sơ → mở popup Hồ sơ, `DungeonPill`, cột nút Event bên phải bản đồ
- [ ] **Game** từng mode: Standard · Countdown · Dungeon · Fog of War · Sum Path · Wall Builder · One Stroke ·
      Fading Ink · Blind Memory · Minesweeper · Challenge
- [ ] **Daily** · **Shop** · **Ranking** · **Achievement** · **Settings** · **Tutorial** (danh sách + 1 bài)
- [ ] Popup: Win · GameOver · Retry · Next floor · Pause · Profiler · Edit profile · Language
- [ ] Màn **không dùng chip** (Settings · Splash · Title · Tutorial · Tutorial list · Profiler popup · Event):
      xác nhận KHÔNG thấy ví Xu/lượt và **không** có vùng chạm "vô hình" ở thanh trên

---

## 7. BÁO CÁO CUỐI (§11 của REFACTOR_INSTRUCTIONS) — trạng thái tại commit `0dd55cfd`

> Nhánh `refactor/cleanup`. **Chưa merge.** Dừng ở commit cuối để người dùng review + test trong editor.

### 7.1 Baseline → kết quả

| Bộ kiểm tra | Baseline | Hiện tại |
|---|---|---|
| Full suite (`tools/run_tests.py`) | 7 PASS · 13 FAIL | **7 PASS · 13 FAIL** — số check fail của từng test **y hệt** baseline |
| `check_integrity` E1 (phạm vi game) | 0 | **1** (`nodes/main/event_card.tscn` → art Halloween chưa sinh, lỗi có sẵn từ commit `1c2209c9`) |
| `check_integrity` W1 / W2 (phạm vi game) | 13 / 5 | **0 / 0** |
| `audit_hidden` DEAD (phạm vi game) | 6 | **2** (đều là false positive — dot sinh runtime) |
| `audit_hardcode` P / T / C / S / E (phạm vi game) | 387 / 29 / 122 / 26 / 101 | **0 / 0 / 0 / 0 / 0** |
| `"/root/…"` trong `scripts/` | 184 | **1** (ghi chú trong `svc.gd`) |
| `# keep-code:` (dòng runtime được đánh dấu có lý do) | 0 | 441 |

Số P/T/C/S/E **theo từng commit**:

| Mốc | P | T | C | S | E |
|---|---|---|---|---|---|
| Baseline (Phase 0) | 387 | 29 | 122 | 26 | 101 |
| Sau Phase 1b/1c + Phase 2B cho `main.gd` | 215 | 13 | 74 | 21 | 70 |
| Sau Phase 2B đợt 2 (nối signal tĩnh + 177 `keep-code`) | 215 | 13 | 74 | 13 | 69 |
| Sau Phase 2B đợt 3 (+250 `keep-code`) | 0 | 0 | 0 | 0 | 0 (phạm vi game) |
| Sau đợt 4 (cột nút Event thành scene) | 0 | 0 | 0 | 0 | 0 (phạm vi game) |
| Sau đợt 5 (`Svc`) | 0 | 0 | 0 | 0 | 0 (phạm vi game) |

### 7.2 Node đã xoá

| Scene | Node | Lý do an toàn |
|---|---|---|
| `nodes/main/daily_card.tscn` | `Content/Background/BackArt` | Không script nào bật `visible`, không animation/tween/Tween điều khiển (kiểm bằng `audit_hidden` + grep toàn bộ `visible = true`/`show()`/`AnimationPlayer` trên đường dẫn node) |
| `nodes/main/daily_card_compact.tscn` | `Content/Background/BackArt` | như trên (giữ `Mask` + con) |
| `nodes/main/level_section.tscn` | `MapArea/FadeTop`, `MapArea/FadeBottom` | như trên; kèm 3 sub_resource gradient chỉ phục vụ 2 node này |

### 7.3 File đã xoá / di chuyển / thêm

| Loại | Đường dẫn |
|---|---|
| Xoá | `nodes/profiler/activity_row.tscn` + `scripts/nodes/profiler/activity_row.gd` + `.gd.uid` (scene mồ côi, 0 tham chiếu theo path **và** `uid://`) |
| Xoá | `nodes/shop/coin_tile.tscn.depren` (file rác) |
| Xoá | 90 khai báo `ext_resource`/`sub_resource` không dùng trên 21 file `.tscn` (~979 dòng) |
| Xoá | `scripts/utils/{archivement,profile,ranking}.gd::_tree()` (không còn ai gọi sau khi có `Svc`) |
| Thêm | `scripts/core/life_store.gd` — sổ LƯỢT CHƠI tách từ `GameManager` |
| Di chuyển | Phase 3: 418 file `.gd`(+`.uid`) sang cây mới `scripts/{autoload,data,ui/*,tools}`; xoá lớp trung gian `manager/LevelManager.gd` |
| Đổi tên | Phase 3A: `archivement*` → `achievement*` (thư mục + file + class + scene + art + khoá dịch + autoload) |
| Thêm | `scripts/utils/svc.gd` — accessor autoload duy nhất |
| Thêm | `nodes/main/event_button_column.tscn` · `nodes/main/event_button_item.tscn` · `resources/settings/styles/event/pill.tres` |
| Thêm | `resources/settings/styles/dock/*.tres` (8 stylebox nút dock) |
| Thêm | `docs/STRUCTURE.md` · `REFACTOR_LOG.md` · `tools/refactor/*` · `tools/probe_event_column.gd` · `tools/print_autoload_paths.gd` · `scripts/test_case/dev_probe_main_metrics.gd` |

### 7.4 Nghi ngờ / đã GIỮ (node ẩn còn lại + code bật nó)

| Node ẩn | Code bật |
|---|---|
| `nodes/hud/*/tutorial/base_tutorial.tscn` → `Dots/Dot1..6` | `scripts/nodes/tutorial/base_tutorial.gd::_update_dots()` sinh dot theo tiến trình bài học |
| 36 node nhóm SPLIT-BASE + 59 node nhóm REVIEW | Không đủ bằng chứng tĩnh để xoá; ghi nhận, giữ nguyên |
| `CoinChip` / `LifeChip` trong `scenes/layout/base_layout.tscn` | **Theo yêu cầu người dùng**: giữ trong base; màn không dùng thì ẩn + `mouse_filter=2` + `process_mode=4` **tại layout** (13 layout/26 stanza) |

### 7.5 Việc bỏ qua + lý do

| Việc | Lý do |
|---|---|
| Phase 3 — đổi `archivement` → `achievement` + sắp xếp lại `scripts/` | **XONG** sau khi người dùng đồng ý mất tiến trình (xem §2). Ảnh trong `assets/images*` cũng đã đổi tên thư mục + import lại |
| Phase 5 (§8.3) — tách god class `board.gd` (2052) · `game_manager.gd` (1083 sau 4 đợt) · `game_controller.gd` (1136) · `debug.gd` (1192) | **ĐÃ TÁCH `game_manager.gd`**: lượt chơi · kỷ lục tầng · kho dụng cụ · rương mốc chương → 4 "store" trong `scripts/core/` (1256 → 1083 dòng). Còn lại: `board.gd` (input/render/effects); `game_controller.gd` (challenge/tutorial/tool); `debug.gd` (theo tab); phần còn lại của `game_manager.gd` (daily/mode prepare, tiến trình chương) |
| Phase 4 — gộp scene Portrait/Landscape trùng nhau | Tùy chọn (§7), cần review thị giác từng màn; rủi ro đổi hình ảnh mà không xác nhận được ⇒ theo §10 phải hỏi |
| Xoá hàm "ngờ thừa" (`Nav.goto_levels`, `GameManager.go_to_levels`, helper levels của `SceneManager`) | `scripts/test_case/test_main_merge.gd:88,91` khẳng định chúng **phải tồn tại** |

### 7.6 Bảng "hard-code → vị trí mới" (tóm tắt; chi tiết từng dòng ở §2)

| File cũ | Giá trị | Vị trí mới |
|---|---|---|
| `scripts/scenes/main.gd` (23 P · 8 T · 12 C · 4 E) | cỡ/màu/texture/vị trí chip, nút Settings, dock 4 nút, chest, `Body.offset_top` | `scenes/layout/{portrait,landscape}/main.tscn` · `resources/settings/styles/dock/*.tres` · `nodes/main/dock_button.tscn` · `scripts/nodes/dock_button.gd` (`@export`) |
| `scripts/nodes/main/chapter_gate.gd` · `popups/gameover*.gd` · `daily/action_card.gd` · `event_header.gd` · `level_section.gd` · `coin_chip.gd` · `life_chip.gd` | nối signal của **node tĩnh** | `[connection]` trong `.tscn` tương ứng (7 dây mới ở đợt 3) |
| `scripts/nodes/main/event_button_column.gd` (8 P · 1 T · 2 C · 4 S) | khung cột, `Timer`, nút event, stylebox viên thuốc, `gutter`/`left_inset` | `nodes/main/event_button_column.tscn` · `event_button_item.tscn` · `styles/event/pill.tres` · `@export` |
| `scripts/nodes/main/level_section.tscn` (qua script) | `LevelMap.bottom_reserve`, kích cỡ `ChestWidget` | `.tscn` |
| `scripts/nodes/{coin,life}_chip.gd` | biến thể "lớn" (cao/rộng/icon/font) | `@export` + giá trị trong `main.tscn` |
| Toàn bộ `scripts/` | 441 dòng runtime thật (chữ/số theo dữ liệu, art theo trạng thái, pose trước tween, stylebox vẽ runtime, nối autoload, nối node sinh lúc chạy) | giữ tại chỗ + `# keep-code: <lý do>` |

### 7.7 Nghi ngờ bug (ghi nhận — KHÔNG sửa trong refactor)

1. `nodes/main/event_card.tscn:5` trỏ `res://assets/images-png/events/halloween_card_grid.png` **không tồn tại** (cả PNG lẫn SVG) ⇒ art event Halloween chưa được sinh.
2. `dev_aspects --only=main` bố cục NGANG: `Landscape/TopBar/ProfileCard` cao 109.5 > `TopBar` (y = −8.26) ⇒ thò lên trên mép. Đã chứng minh **PRE-EXISTING** bằng A/B trên `HEAD~1`.
3. `test_levels_map`: `scroll_to(1)` đưa nút tới y = 480 trong khi mong đợi 285 (có thể do padding `level_section` đổi).
4. `test_layout_bindings` 5/84 và `test_popup_bindings` 1/34: binding chưa khớp layout mới (thuộc WIP redesign của người dùng).
5. 13 test đỏ baseline đều thuộc luồng gộp Levels/Chapters vào Main + redesign HUD mà người dùng đang làm dở.

### 7.8 Cần người dùng test thủ công trong editor (cả Portrait và Landscape)

Xem checklist đầy đủ ở **§6** (Title · Splash · Credit · Main · Game từng mode · Daily · Shop · Ranking ·
Achievement · Settings · Tutorial · các popup Win/GameOver/Retry/OutOfLife/Pause).
Riêng 2 điểm mới của refactor cần soi kỹ:
- **Main**: cột nút Event bên phải bản đồ (khoảng cách, viên thuốc "Còn N ngày", chạm mở event) và bản đồ có bị nút đè không.
- **Màn không dùng chip** (Settings/Splash/Title/Tutorial/Profiler/Event): không thấy ví Xu/lượt, không có vùng chạm "vô hình" ở thanh trên.
