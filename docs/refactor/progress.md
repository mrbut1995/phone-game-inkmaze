# Refactor progress — InkMaze → GodotTemplate v1.7 conventions

Nhánh: `refactor/template` (tách từ `portrait_landscape_feature` @ `77406bca`)
Kit nguồn (ignored, không commit): `helpers/refactors/` — instruction + `GodotTemplate_v1.7` + `tools/refactor/*`
Ghi chú: các phase P0..P7 theo `instruction_refactor_to_template.md`; mỗi session 1 phase.

## Baselines (P0, đo trên project thật)

| Gate | Baseline | Ghi chú |
|---|---|---|
| G-INT | **637** | `E*` trừ `.import:`; bóc `android/**` 516 + `helpers/**` 91 + `what-changes/**` 12 ⇒ **trong phạm vi game = 18** (`scripts/test_case` 16 · `nodes/main` 1 · `tests/framework` 1) |
| G-LEG | **7 / 20** PASS | `python tools/run_tests.py` (7 PASS / 13 FAIL — đều là test cũ đang hỏng sẵn) |
| lint_total | **3230** (739 ERROR) | `python tools/lint_rules.py --max 0 --all` · DEAD 7 · GODOT3 80 · R1 1742 · R2 343 · R3 235 · R4 549 · R5 57 · R8 16 · STRUCT 1 · STYLE 200. Trong đó **115 dòng thuộc `helpers/`** (kit template, gitignored) — xem "Cần quyết định" |
| G-GODOT | ok | `--headless --import` chỉ còn WARNING UID trùng `daily_milestone.tscn` (có sẵn từ trước) |

Engine: `tools/godot_path.txt` → `D:/Godots/app dev/.../godot.windows.editor.x86_64.exe` (4.8.dev custom build).

## Checklist

- [x] P0 prepare
- [ ] P1 maps
- [ ] P2 structure
- [ ] P3.1 autoload class_name · [ ] P3.2 guard rails · [ ] P3.3 baseline · [ ] P3.4 tags · [ ] P3.5 constants
- [ ] P4 scene contracts (0/156)
- [ ] P5.1 GODOT3 0/80 · [ ] P5.2 R3-err 0/… · [ ] P5.3 R2-err 0/… · [ ] P5.4 R4-err 0/…
- [ ] P5.5..9 warnings (tuỳ chọn) · [ ] P6 tests · [ ] P7 docs

Lint total history: 2026-11-06 = 3230

## P0 đã làm

- `git checkout -b refactor/template` từ `portrait_landscape_feature` (đã commit 2 file `.import` của localization trước khi tách nhánh).
- Copy donor theo D1: `tools/*.py` + `tools/*.json` (29 py + 3 json), `instruction/`, `ai_helper/`, `tests/run_tests.gd` + `tests/framework/`, `.editorconfig`; `tools/refactor/{gen_move_map,rewrite_dir_refs,convert_keep_code}.py`.
- `tools/godot_path.txt` (đường dẫn engine) — `run_checks.py` đọc file này.
- `python tools/start.py` chạy được: `PROJECT InkMaze (4.8, Mobile) — scenes 194, scripts 325`.
- `godot --headless --path . --import`: **không lỗi** (kit nằm trong `helpers/` bị bỏ qua vì là project lồng nhau, không có `class_name` collision).
- `python tools/run_checks.py --fast`: **FAIL (đúng như dự kiến ở P0)**, 2 nguyên nhân:
  1. bước `scenes` quét cả `android/build/**` và `helpers/**` (`tools/_common.py` `IGNORE_DIRS` không có 2 thư mục này) ⇒
     báo thiếu resource của file build/kit;
  2. bước `exports` đòi `scenes/base/base_popup.tscn`, `scenes/base/base_scene.tscn`… — chỉ tồn tại **sau P2**.
  ⇒ G-RUN chỉ có thể đạt từ P2 trở đi; gate P0 là `tools/start.py` (đạt).

## Cần quyết định (dừng lại hỏi người)

1. **`helpers/` nằm trong `res://`**: Godot bỏ qua (không lỗi), nhưng `lint_rules.py` vẫn quét ⇒ 115/3230 finding thuộc kit
   template (`helpers/refactors/GodotTemplate_v1.7/...`). Đề xuất: **chuyển `helpers/refactors/` ra ngoài project**
   (`D:/godot-phone-game/refactor-kit/`) trước P3.3, hoặc chấp nhận 115 dòng đó nằm trong baseline vĩnh viễn.
2. Instruction giả định archive ~50 E-line; project thật có 637 vì còn `android/build` — tôi ghi baseline tổng **và**
   baseline trong phạm vi (18) để gate còn ý nghĩa.
