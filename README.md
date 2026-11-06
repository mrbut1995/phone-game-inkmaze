# InkMaze — Phone Game (Godot 4.8.dev)

Game mê cung giấy–mực cho điện thoại: vẽ đường bằng ngòi bút qua mê cung **tường vô hình**, dò tường bằng
cách "chạm" thử, dùng công cụ (skip · teleport · hint) và leo tháp Dungeon.

* Engine: **Godot 4.8.dev** (bản custom, đã bỏ splash) — đường dẫn ghi trong `tools/godot_path.txt`:
  `D:/Godots/app dev/Godot Source Code/godot/bin/godot.windows.editor.x86_64.exe`
* Nền tảng: Android (portrait + landscape). `project.godot` đặt `window/handheld/orientation=6` (sensor),
  UI tự đổi bố cục theo hướng màn hình.
* Ngôn ngữ: GDScript; dữ liệu tĩnh trong `.tscn`/`.tres`, hành vi trong `scripts/`.

## 1. Mở project

```
godot --path . --editor           # mở editor
godot --path .                    # chạy game (scene chính: scenes/screens/splash.tscn)
```

Sau khi **thêm/bớt script có `class_name`** hoặc **di chuyển file**, chạy 1 lần để cập nhật cache:

```
godot --headless --path . --import
```

Nếu cache hỏng: xoá `.godot/` (nhớ giữ `.godot/export_credentials.cfg` nếu dùng để export Android) rồi
`--import` hai lần.

## 2. Cấu trúc (tóm tắt — chi tiết: `docs/ARCHITECTURE.md`)

| Thư mục | Nội dung |
|---|---|
| `scenes/screens/` | 14 màn (`main · splash · title · shop · daily · ranking · achievement · settings · credit · tutorial · tutorial_list · event · game · debug`) |
| `scenes/objects/` | layout dọc/ngang (`objects/layouts/<màn>/portrait|landscape.tscn`), popup, HUD, chip/card, bàn cờ |
| `scenes/components/` | mảnh nhỏ của bàn cờ & tutorial (ô, tường, con trỏ, callout) |
| `scripts/autoload/` | 24 singleton (`GameManager · SaveManager · DailyManager · LevelManager …`) |
| `scripts/screens/` | controller của từng màn (`XxxScene.gd`) |
| `scripts/components/shared/` | `GameController` + các controller (`Grid · Floor · Mission · Timer · Tool · Hint · Undo · Anchor · Tutorial · UI · GameMode`) |
| `scripts/systems/` | luật & dịch vụ: `modes/` (chế độ chơi), `ChallengeRules`, `LevelCatalog`, `ScoreCalculator`, `RunReporter`, `services/` (backend lưu) |
| `scripts/models/` | dữ liệu thuần: `MazeData`, `GameState`, các **store** (`Progress · Life · ToolInventory · Tutorial · ChapterChests · FloorRecords`) |
| `scripts/utils/` | facade tĩnh (`Svc · Loc · Nav · Popups · Save · Shop · Profile · Achievement · Ranking · Life · Sfx`) + helper |
| `resources/` | `levels/ · chapters/ · achievements/ · profiler/ · settings/` (dữ liệu `.tres`) |
| `tests/` | `unit/` (test mới) · `legacy/` (82 test scene cũ) · `framework/` (`TestCase`) |
| `tools/` | tool Python (lint, test runner, sinh scene/SVG, refactor) — **không** chạy lúc runtime |

Quy ước: script của `scenes/objects/ui/popups/won.tscn` là `scripts/objects/ui/popups/WonPopup.gd`; mỗi `.gd`
đi kèm `.gd.uid` (không sửa tay uid).

## 3. Chạy kiểm tra

Tất cả bằng Python của venv (`.venv\Scripts\python.exe`), chạy từ gốc project.

```powershell
# G-RUN: lint + validate scene + export check + import + load + unit test
python tools\run_checks.py

# G-LINT riêng: 0 finding mới so với baseline, 0 ERROR
python tools\lint_rules.py --max 0
python tools\lint_rules.py --update-baseline     # chỉ khi --max 0 đã in "0 new"

# G-LEG: 20 test tích hợp scene (tests/legacy/legacy_*.gd) — chạy RIÊNG, không nằm trong run_checks
python tools\run_tests.py                        # thêm --timeout 180 nếu máy chậm
python tools\run_tests.py test_shop test_daily   # chạy lẻ vài test

# Unit test mới (tests/unit/**) chạy trực tiếp bằng runner của project
godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/run_tests.gd -- --filter=test_life_store
```

Hiện trạng: **G-LINT 0 new / 0 ERROR** · **G-LEG 18/20** (`test_ui_scenes`, `test_challenge_mode` hỏng sẵn từ
baseline) · **unit 87/87 PASS**.

## 4. Tool hay dùng

| Tool | Việc |
|---|---|
| `tools/run_checks.py` | gate tổng (lint · scenes · exports · plan · import · load · tests) |
| `tools/lint_rules.py` | lint theo bộ luật R1–R8 + baseline `tools/lint_baseline.json` |
| `tools/run_tests.py` | chạy test legacy với timeout từng test |
| `tools/new_test.py` | sinh khung `tests/unit/**/test_*.gd` cho một `class_name` |
| `tools/validate_scenes.py` | soi `.tscn`: `$Node` không tồn tại, connection trỏ method/node sai |
| `tools/export_check.py` | kiểm tra export preset / template / keystore trước khi build Android |
| `tools/new_scene.py`, `tools/new_svg.py` | tạo scene / SVG mới đúng quy ước |
| `tools/svg_to_png.py`, `tools/spritesheet.py` | build asset PNG từ SVG nguồn |
| `tools/refactor/` | kit refactor (map move, rewrite path, integrity check) |
| `tools/diag_tests.py` | chẩn đoán test scene hỏng |

## 5. Ghi chú

* Save người chơi: key `player_progress` qua `DataManager`, fallback `user://inkmaze_save.json`.
  Đổi `LocalSaveBackend.DATA_MANAGER_KEY` = mất tiến trình ⇒ đã có unit test canh.
* Xuất Android: SDK/JDK/keystore + `export_presets.cfg`; xem `tools/export_check.py` và `docs/refactor/progress.md`.
* Trước khi commit: `python tools\lint_rules.py --max 0` phải in `0 new (0 errors)`.

## 6. Tài liệu cũ (giữ để tra asset)

### 6.1 Ranking v4 — assets SVG → PNG
Xuất PNG bằng tool của bạn, GIỮ TÊN FILE, đặt vào `assets/images-png/...` (cùng thư mục con với svg):
- Ghi đè file cũ (giữ uid): `ranking/rank_sheet`, `ranking/rank_row`, `ranking/rank_row_you`, `ranking/my_rank_bar`, `ranking/tab_normal`, `ranking/tab_active`, `btn_header_back_normal`, `btn_header_back_pressed`
- File MỚI: `ranking/hero_card`, `ranking/duo_card_silver`, `ranking/duo_card_bronze`, `ranking/medal_circle`, `ranking/banner_title`, `ranking/hole`
- Không còn dùng (xoá được): `podium_gold/silver/bronze`, `chip_scope`, `medal_gold`, `divider_dashed` (phần ranking), `washi_tape` (ranking)
Mỗi SVG ghi sẵn kích thước ở comment đầu file; viewBox gấp đôi nên xuất 1x hoặc 2x đều khớp.

## 2. Scene / script
scenes/ranking.tscn (đã dọn ext_resource thừa) · scenes/layout/portrait|landscape/ranking.tscn ·
nodes/ranking/tab_button.tscn + rank_row.tscn · scripts/scenes/ranking.gd + layout/ranking_layout.gd · scripts/nodes/ranking/tab_button.gd

## 3. Lưu ý
- Cần Godot 4.5+ (`pivot_offset_ratio`).
- Bỏ Chip "STR_RANK_SCOPE", Footer và FooterNote (mockup không có). Muốn giữ thì báo mình thêm lại.
- Màu chữ các nhãn mới đặt trực tiếp trong scene (theme_override), nên không phải sửa theme_default.tres.
