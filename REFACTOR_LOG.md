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

---

## 4. Việc còn lại (chưa làm — cần user quyết)

| Nhóm | Nội dung | Vì sao dừng |
|---|---|---|
| Phase 1b | Tách `CoinChip`/`LifeChip` khỏi `scenes/layout/base_layout.tscn` (13/31 layout đang ẩn) | Đổi cấu trúc kế thừa của 31 scene, cần render so sánh từng màn |
| Phase 1c | `Content/ModeInformation/Time` ẩn ở 4/11 HUD mỗi hướng | Cần xác nhận Time chỉ dùng cho mode giới hạn thời gian |
| Phase 1d | `Dim` (memory_countdown), `Panel/Art` (profiler_popup) | Nên tách bằng base trung gian, cần review thị giác |
| Phase 2B | Hardcode trong `scripts/scenes/main.gd` (47 findings) | Chuyển sang `.tscn`/theme phải render so sánh pixel-perfect |
| Phase 3 | Đổi `archivement` -> `achievement` | Đụng key lưu `user://inkmaze_data.json` — §10 yêu cầu DỪNG và hỏi user |
| Phase 5/6 | `docs/STRUCTURE.md` + báo cáo cuối | Làm sau khi các phase trên xong |

### Nghi ngờ bug (ghi nhận, KHÔNG sửa trong refactor)

- 13 test đỏ baseline thuộc luồng gộp Levels/Chapters + redesign HUD mà user đang làm dở.
- `test_levels_map`: `scroll_to(1)` lệch y (480 vs 285) — có thể do `level_section.tscn` đổi padding.
- `test_layout_bindings` 5/84 và `test_popup_bindings` 1/34: node binding chưa khớp layout mới.
