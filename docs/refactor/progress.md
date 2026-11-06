# Refactor progress — InkMaze → GodotTemplate v1.7 conventions

- Nhánh: `refactor/template` (tách từ `portrait_landscape_feature` @ `77406bca`).
- Instruction: `D:/godot-phone-game/refactor-kit/instruction/instruction_refactor_to_template.md`
  (kit đã **chuyển ra ngoài project** — xem D-ENV; `helpers/` không còn nằm trong `res://`).
- Mỗi session = 1 phase. Gate + số liệu phải khớp bảng dưới trước khi sang phase kế.

## Baselines (P0, đo trên project thật ngày 2026-11-06)

| Gate | Baseline | Cách đo |
|---|---|---|
| G-INT | **18** | `python tools/refactor/check_integrity.py .` → đếm dòng `E*` trừ `.import:` (đã bỏ qua thư mục rác, xem D-ENV) |
| G-LEG | **7 / 20** PASS | `python tools/run_tests.py` (7 PASS / 13 FAIL — toàn test cũ hỏng sẵn) |
| lint_total | **3027** (724 ERROR) | `python tools/lint_rules.py --max 0 --all` → DEAD 4 · GODOT3 78 · R1 1666 · R2 325 · R3 214 · R4 549 · R5 55 · R8 16 · STRUCT 1 · STYLE 119 |
| G-GODOT | **ok** | `--headless --path . --import`: chỉ còn WARNING UID trùng `daily_milestone.tscn` (có sẵn từ trước) |
| G-RUN | chưa đạt được | `run_checks.py` cần `scenes/base/base_scene.tscn` → chỉ có sau **P2** |

Engine: `tools/godot_path.txt` → `D:/Godots/app dev/.../godot.windows.editor.x86_64.exe` (4.8.dev custom build).
Chi tiết 18 E-line: 1 art Halloween thiếu (có sẵn) · 16 trong `scripts/test_case/` do dev-probe trỏ đường dẫn CŨ
(`nodes/hud/...`, `nodes/tutorials/...` — sẽ chuyển sang `debug/probes/` ở P2) · 1 `tests/framework/GameTestCase.gd`
trỏ `scenes/objects/world/actor.tscn` (asset demo của template, không copy theo D1).

## Deviation đã áp dụng

**D-ENV (môi trường InkMaze).** Toolchain donor quét cả thư mục build/rác nên gate bị nhiễu. Đã sửa 2 tool donor:
- `tools/_common.py` → `IGNORE_DIRS` thêm `android`, `build`, `what-changes`, `_removed_unused`,
  `optimizing_clean`, `helpers`, `mockup`; `iter_files()` bỏ mọi thư mục bắt đầu bằng `tmp_`.
- `tools/refactor/check_integrity.py` → thêm `JUNK_DIRS` (như trên) + bỏ `tmp_*` trong `os.walk`.
Không sửa `lint_config.json`, không sửa ngưỡng lint, không sửa baseline.
Hệ quả: baseline sạch (3027 thay vì 3230; G-INT 18 thay vì 637 với 516 dòng từ `android/build`).

## Checklist

- [x] P0 prepare
- [x] P1 maps (va chạm 0 · review 9 → 3, đã duyệt)
- [ ] P2 structure
- [ ] P3.1 autoload class_name · [ ] P3.2 guard rails · [ ] P3.3 baseline · [ ] P3.4 tags · [ ] P3.5 constants
- [ ] P4 scene contracts (0/…)
- [ ] P5.1 GODOT3 0/78 · [ ] P5.2 R3-err 0/… · [ ] P5.3 R2-err 0/… · [ ] P5.4 R4-err 0/549
- [ ] P5.5..9 warnings (tuỳ chọn) · [ ] P6 tests · [ ] P7 docs

Lint total history: 2026-11-06 = 3027 (baseline P0, chưa tạo lint_baseline — việc của P3.3)

## P1 đã làm (maps — commit `P1`)

- `python -X utf8 -I tools/refactor/gen_move_map.py . --out docs/refactor/maps`. **Phải thêm `-X utf8`** vì `-I`
  bỏ qua biến môi trường `PYTHONUTF8` ⇒ trên Windows rơi về cp1252 và chết ở ký tự tiếng Việt.
- Lần 1: va chạm 0 · **review 9** → người dùng duyệt toàn bộ đề xuất ⇒ `docs/refactor/overrides.txt` (8 override).
- Xoá `nodes/daily/daily_milestone.tscn` (scene **trùng UID**, không ai tham chiếu — `PopupManager` chỉ nạp
  `nodes/popups/daily_milestone.tscn`) rồi sinh lại map.
- Lần 2: **va chạm 0 · review 3** — cả 3 là mục đã duyệt giữ nguyên (`PaperGeometry`→`utils/`, `DebugData`→`utils/`,
  `ShopCardTap`→`systems/`), không còn mục nào chưa quyết.
- Kết quả map: P2a **15** dòng · P2b **169 scene** (screens 14 · base 5 · objects 136 · autoload 1 · components 13) ·
  P2c **257 script** · P2d **68 test/probe** · dir_refs **13** tiền tố.
- Override quan trọng: `BoardCellsView`→`systems/`, `MissionCard`→`components/hud/`, `AutoFitLabel`→`components/shared/`,
  `DockStyleJ`→`utils/`, `DailyMilestonePopup`→`objects/ui/popups/`, layout màn Game →
  `objects/layouts/game/{GameSceneLayout,GameLayoutLandscape,GameLayoutPortrait}.gd`.

## P0 đã làm (commit `47e6f0ac`, `6284b77f`, + commit D-ENV)

1. `git checkout -b refactor/template` (trước đó commit 2 file `.import` localization vừa đổi).
2. Donor D1: `tools/*.py` (29) + `tools/*.json` (3) · `instruction/` · `ai_helper/` · `tests/run_tests.gd` +
   `tests/framework/{TestCase,GameTestCase}.gd` · `.editorconfig`; kit `tools/refactor/{gen_move_map,
   rewrite_dir_refs,convert_keep_code}.py`.
3. `tools/godot_path.txt`; `.gitignore` merge (`tools/.logs/`, `ai_helper/session_*/…`).
4. Chuyển kit ra `D:/godot-phone-game/refactor-kit/` (quyết định của người dùng) + D-ENV.
5. Gate P0: `python tools/start.py` → `PROJECT InkMaze (4.8, Mobile) | scenes 194 | scripts 325`.
   `--import` sạch.

## Lưu ý cho session sau

- Đọc `instruction/brief.md` (rules R1..R7) trước khi làm P1; kit ở `D:/godot-phone-game/refactor-kit/`.
- `python3 -I` của instruction ↔ trên Windows dùng `.venv\Scripts\python.exe`; tool donor **không** chạy với `-I`.
- `scripts/test_case/` (68 file) sẽ thành `tests/legacy/legacy_*.gd` + `debug/probes/` ở P2 ⇒ 16 E-line hiện tại
  sẽ tự hết (G-INT phải **giảm**, không được tăng).
