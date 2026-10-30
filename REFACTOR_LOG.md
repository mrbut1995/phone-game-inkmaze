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

