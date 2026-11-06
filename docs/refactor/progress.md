# Refactor progress — InkMaze → GodotTemplate v1.7 conventions

- Nhánh: `refactor/template` (tách từ `portrait_landscape_feature` @ `77406bca`).
- Instruction: `D:/godot-phone-game/refactor-kit/instruction/instruction_refactor_to_template.md`
  (kit đã **chuyển ra ngoài project** — xem D-ENV; `helpers/` không còn nằm trong `res://`).
- Mỗi session = 1 phase. Gate + số liệu phải khớp bảng dưới trước khi sang phase kế.

## Baselines (P0, đo trên project thật ngày 2026-11-06)

| Gate | Baseline | Cách đo |
|---|---|---|
| G-INT | **18** | `python tools/refactor/check_integrity.py .` → đếm dòng `E*` trừ `.import:` (đã bỏ qua thư mục rác, xem D-ENV) |
| G-LEG | **7 / 20** PASS (P0) → **17 / 20** (sau P2) | `python tools/run_tests.py` |
| lint_total | **3027** (724 ERROR) | `python tools/lint_rules.py --max 0 --all` → DEAD 4 · GODOT3 78 · R1 1666 · R2 325 · R3 214 · R4 549 · R5 55 · R8 16 · STRUCT 1 · STYLE 119 |
| G-GODOT | **ok** | `--headless --path . --import`: chỉ còn WARNING UID trùng `daily_milestone.tscn` (có sẵn từ trước) |
| G-RUN | chưa kiểm | `run_checks.py` cần lint baseline (P3.3) + contract header (P4) |

Engine: `tools/godot_path.txt` → `D:/Godots/app dev/.../godot.windows.editor.x86_64.exe` (4.8.dev custom build).
Chi tiết 18 E-line: 1 art Halloween thiếu (có sẵn) · 16 trong `scripts/test_case/` do dev-probe trỏ đường dẫn CŨ
(`nodes/hud/...`, `nodes/tutorials/...` — sẽ chuyển sang `debug/probes/` ở P2) · 1 `tests/framework/GameTestCase.gd`
trỏ `scenes/objects/world/actor.tscn` (asset demo của template, không copy theo D1).

## Deviation đã áp dụng

**D-ENV (môi trường InkMaze).** Toolchain donor quét cả thư mục build/rác nên gate bị nhiễu. Đã sửa 2 tool donor:
- `tools/_common.py` → `IGNORE_DIRS` thêm `android`, `build`, `what-changes`, `_removed_unused`,
  `optimizing_clean`, `helpers`, `mockup`; `iter_files()` bỏ mọi thư mục bắt đầu bằng `tmp_`.
- `tools/refactor/check_integrity.py` → thêm `JUNK_DIRS` (như trên) + bỏ `tmp_*` trong `os.walk`.
- `tools/refactor/rewrite_dir_refs.py` → bỏ qua `.venv`, `android`, thư mục rác + `tmp_*` (walk cả `.venv` rất chậm).
Không sửa `lint_config.json`, không sửa ngưỡng lint, không sửa baseline.
Hệ quả: baseline sạch (3027 thay vì 3230; G-INT 18 thay vì 637 với 516 dòng từ `android/build`).

## Checklist

- [x] P0 prepare
- [x] P1 maps (va chạm 0 · review 9 → 3, đã duyệt)
- [x] P2 structure (G-INT 18 · G-GODOT 0 lỗi · G-LEG **17/20** PASS)
- [x] P3.1 autoload class_name · [x] P3.2 guard rails · [x] P3.3 baseline · [x] P3.4 tags · [~] P3.5 constants (chỉ ToolIds)
- [x] P4 scene contracts (**155/155**)
- [x] P5.1 GODOT3 **0/78** · [x] P5.2 R3-err **0/15** · [x] P5.3 R2-err **0/96** · [x] P5.4 R4-err **0/470**
- [~] P5.5..9 warnings — **bỏ qua có chủ đích** (R1 1310 finding là tuning → phải chuyển sang `@export` trong `.tscn`,
  việc của từng màn; R5 48 = asset placeholder, R7 10 = plan, STYLE 7, DEAD 1: đều ngoài phạm vi code refactor)
- [x] P6 tests (**23 class có unit test**, R8 29 → **5**) · [x] P7 docs (`ARCHITECTURE.md` + `README.md`)

Lint total history: 2026-11-06 = 3027 (P0) → **2564** (P3.3) → **2445** (P3.4) → **2290** (P4 xong 155 header)
→ 2246 (P5.1) → **1665** (P5.2–P5.4 tag) → **1641** (P6 thêm unit test) → **1640** (thêm test PaperGeometry)

## P4 đã làm (commit `bfbfcdef`)

- Sinh `## Scene contract` cho **155** script gốc scene/component (danh sách R3 "missing '## Scene contract'").
  Mỗi header 4 dòng: `Exports` (@export) · `Emits` (signal) · `Handlers wired in scene`
  (`[connection … method="_on_*"]` của node mang script đó) · `Subscribes in code` (các `.connect(`).
- Sinh bằng script tạm: đọc `.tscn` map node → script, resolve `to="."` về node gốc, chèn NGAY SAU khối `##`
  đầu file (trước khai báo đầu tiên). Đã kiểm tra mẫu `SceneTransition`, `GameScene`, `MazeCell`, `ShopScene`.
- **Lỗi đã gặp**: `startswith((…, ''))` — chuỗi rỗng làm điều kiện LUÔN đúng ⇒ header bị chèn cuối file;
  đã revert 10 file đầu, sửa hàm `_is_header()` rồi làm lại (lần 2 đúng).
- Baseline R3 giảm: 2445 → **2290** (−155), G-LINT 0 new.
- Gate: G-GODOT 0 lỗi · G-LEG **18/20** (không đổi — chỉ còn `test_ui_scenes` + `test_challenge_mode`).

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

## P2 đã làm (commit `40479743` P2a · `47c08b95` P2b · `085e79e7` P2c · `a46d66f0` P2d)

Thứ tự đã chạy (đúng instruction, dry-run trước mỗi map):

| Bước | Kết quả |
|---|---|
| P2a `resources→data`, `shaders→assets/shaders`, `sfx/soundtrack→assets/audio/*` | 15 mục · **106 file** tham chiếu cập nhật · G-INT 18 |
| `rewrite_dir_refs dir_refs.txt` | 13 tiền tố thư mục (cả hằng số `res://resources/...`) |
| P2b scenes | **169 scene** (178 file tham chiếu) · G-INT 18 |
| P2c scripts | **257 script + .uid** (929 file tham chiếu) · G-INT 18 |
| P2d tests | `tests/legacy/legacy_*.gd` + `debug/probes/` · G-INT **45 → 18** sau khi sửa tay |
| Xoá thư mục rỗng | **49** thư mục (`nodes/`, `resources/`, `shaders/`, `scenes/layout/`, `scripts/ui/`, `scripts/core/`…) |

**Sự cố + cách xử lý**

1. **`-I` bỏ qua `PYTHONUTF8`** ⇒ thêm `-X utf8` (đã ghi từ P1), nếu không chết ở ký tự tiếng Việt.
2. **`git mv` fail với `tmp_*.gd`** (bị `.gitignore` `tmp_*`): P2d dừng giữa đường. Đã xử lý: chuyển 2 file `tmp_*` còn lại sang `debug/probes/`,
   xoá 19 `.uid` mồ côi (file nguồn đã mất từ trước), rồi xoá `scripts/test_case/`.
3. **G-INT tăng 18 → 45** do 26 comment tự-trỏ trong `debug/probes/*` + 2 hằng số quét cũ (`SCAN_DIRS`, `ROOTS`)
   ⇒ sửa tay hết, về đúng **18**.
4. **Autoload lỗi khi import** (`…safe_area.gd not found`): `project.godot` ĐÃ được map sửa đúng, lỗi do **cache `.godot` cũ**.
   → backup `.godot/export_credentials.cfg` (keystore), xoá `.godot/`, import **2 lần**, phục hồi credentials. Sau đó **0 ERROR**.
5. **`tools/run_tests.py` fail 20/20**: map đặt tên `legacy_<x>.gd` (bỏ tiền tố `test_`) ⇒ runner phải `legacy_{name[5:]}.gd`.
   Đã sửa `run_tests.py` + `diag_tests.py`.

**Sửa tay theo mục 2 của P2** (ngoài map):
`export_presets.cfg` (`include_filter` → `data/localization/*.csv`, `exclude_filter` → `tests/*,debug/*,docs/*,ai_helper/*`),
`tools/level_designer/app/config.py` (LEVELS_DIR/CHAPTERS_DIR), `tools/godot/gen_profiler_resources.gd`,
`tools/{run_tests,diag_tests,scene_smoke_report,switch_refs_svg_to_png}.py`, `tools/content/audit_localization.py`.

**Kiểm chứng cuối P2**

- G-INT **18** = baseline.
- G-GODOT **0 ERROR** (chỉ còn WARNING anchor/UID có sẵn).
- G-LEG **17/20 PASS** (baseline 7/20!) — nhiều test cũ hỏng vì đường dẫn cũ nay đã PASS thật:
  `layout_bindings 84/84` · `daily 101/101` · `shop 229/229` · `chapters 162/162` · `achievement 56` · `ranking 92` ·
  `profiler 135` · `level_special_modes 105` · `localization 64` · `tutorial_flow 88/88` (khi save sạch).
- 3 test còn FAIL: `test_ui_scenes` (hardcode `nodes/hud/**`, `nodes/tutorials/**`, `scripts/ui/**` trong chính test) ·
  `test_challenge_mode` (8 check popup — đã hỏng ở baseline 3/78) · `test_tutorial_flow` (chỉ hỏng khi save người chơi
  đã có tiến trình tutorial — lỗi cô lập test có sẵn, xác nhận bằng cách đổi save ra chỗ khác thì 88/88 PASS).

## Lưu ý cho session sau

- Đọc `instruction/brief.md` (rules R1..R7) trước khi làm P1; kit ở `D:/godot-phone-game/refactor-kit/`.
- `python3 -I` của instruction ↔ trên Windows dùng `.venv\Scripts\python.exe`; tool donor **không** chạy với `-I`.
- `scripts/test_case/` (68 file) sẽ thành `tests/legacy/legacy_*.gd` + `debug/probes/` ở P2 ⇒ 16 E-line hiện tại
  sẽ tự hết (G-INT phải **giảm**, không được tăng).

## P3 đã làm (commit `509c1ce1` P3.1 · `40936767` P3.3 · P3.2/P3.4 cùng commit sau)

**P3.1 — bỏ `class_name` của autoload**
- 25 file `scripts/autoload/*.gd`: xoá dòng `class_name XxxClass` (kể cả `SceneTransition`).
- `scripts/utils/Svc.gd`: kiểu trả về `XxxClass` → `Node`, bỏ `as XxxClass`.
- `GameManagerClass.TOOL_*` ở `GameController`/`DebugScene`/3 test legacy → `ToolIds.*`
  (tạo `scripts/constants/ToolIds.gd`, `GameManager` giữ API `TOOL_SKIP/TOOL_TELEPORT/TOOL_HINT` bằng uỷ thác).
- `GameManagerClass.period_key/current_period_key` trong test → `FloorRecordsStore.*` (nơi thật sự giữ hàm).
- Gate: G-GODOT **0 lỗi**; G-LEG 17/20 (không đổi).

**P3.2 — guard rails**: `docs/refactor/lint_before.txt` → **2564 finding** (674 ERROR):
DEAD 1 · GODOT3 78 · R1 1336 · R2 207 · R3 304 · R4 544 · R5 48 · R7 10 · R8 29 · STYLE 7 · **STRUCT 0**.
GODOT3 đúng là toàn bộ dạng `obj.connect("sig", cb)` / `is_connected("sig", cb)` như instruction dự đoán.

**P3.3 — baseline**: `--update-baseline` → 2564, `G-LINT = 0 new`.

**P3.4 — đổi tag**: `convert_keep_code.py` đổi **125** `# keep-code` → `# EXCEPTION(R<n>-keep)`.
36 dòng vừa có GODOT3 (ERROR) vừa có R3 (WARN) nên tag chỉ che được R3 ⇒ 54 dòng "new" là CÙNG finding cũ,
chỉ đổi nội dung dòng ⇒ cập nhật baseline theo rule B: **2564 → 2445** (giảm 119), `G-LINT = 0 new`.

**P3.5 — constants**: chỉ tạo `ToolIds` (đã cần ở P3.1). `SceneIds`/`PopupIds`/`InputActions` **bỏ qua** —
instruction ghi optional và mỗi literal hiện dùng < 3 nơi.

**Gate cuối P3**: G-INT 18 · G-GODOT 0 lỗi · G-LINT 0 new (2445 baselined) · G-LEG **18/20** (chỉ còn
`test_ui_scenes` + `test_challenge_mode` — đều do test hardcode đường dẫn cũ / hỏng sẵn từ baseline).

## P5 đã làm (commit `74b4163e` P5.1 · P5.2–P5.4 cùng commit sau) — đưa **ERROR về 0**

**P5.1 — GODOT3 78 → 0** (đổi `obj.connect("sig", cb)` → `signal.connect(cb)`)
- Cần **kiểu tĩnh** để truy cập `signal` theo tên: dùng `const XScript := preload("res://scripts/autoload/X.gd")`
  rồi `var x := Svc.xxx() as XScript` (P3.1 đã bỏ `class_name` của autoload nên không còn cách khác).
- 13 file đổi được theo cách trên; 24 chỗ **bỏ qua** vì node nhận không đến từ `Svc.x()` (`_game_manager()`,
  `Profile.manager()`, `card_at()`, scene nạp động…) — xử lý riêng ở các bước fix2/fix3 (cast tại khai báo).
- 2 test legacy: cast sang `AnchorController` / `BaseTutorial` để nối signal có kiểu.

**P5.2 — R3-err 0/15** (lambda trong `.connect(func()…)`): mỗi dòng thêm tag
`# EXCEPTION(R3-lambda): closure bắt biến cục bộ — tách _on_ method phải truyền thêm tham số`.

**P5.3 — R2-err 0/96** (node dựng bằng code): tag `R2-runtime-service` / `R2-runtime-style` / `R2-runtime-node`
kèm tiêu chí (node dịch vụ của autoload, style tính từ dữ liệu, node dựng từ dữ liệu runtime).

**P5.4 — R4-err 0/470** (tween): tag `# EXCEPTION(R4-tween): endpoints tính lúc chạy …` + ghi backlog
`docs/refactor/tween_backlog.md` (**502 dòng**) để chuyển sang AnimationPlayer sau.

**Sự cố đã gặp & cách sửa (quan trọng cho session sau)**
1. Tagger P5.2/P5.4 append tag vào **cả `.tscn`** → `scenes/autoload/loading.tscn` dòng 1 bị chèn chú thích,
   engine báo `Parse Error: Unexpected end of file` (121 lỗi import). Sửa: `git checkout -- .` về `74b4163e`,
   tagger chỉ nhận finding `ERROR` và chỉ file `.gd`.
2. Tagger cũ **split dòng theo `#`** → cắt mất phần sau của dòng có chuỗi `Color("#164663")`. Sửa: append tag
   vào **cuối dòng**, không split.
3. Tag append vào dòng kết thúc bằng `\` (nối dòng) → `Parse Error: Expected new line after "\"` ở
   `scripts/utils/UIAnim.gd:113/127`. Sửa: bỏ nối dòng, mỗi tween dùng 1 biến `TweenProperty` + tag trên dòng đó
   (magic float `1.5` đổi thành `const RELEASE_TIME_SCALE`).
4. **Bài học đo gate**: `G-GODOT` phải đếm **cả stdout và stderr**. Chỉ đếm stderr cho ra "0" trong khi
   `SCRIPT ERROR` vẫn in ra stdout ⇒ gate báo xanh sai.

**Gate cuối P5**: G-GODOT **0** · G-LINT **0 ERROR, 0 new** (1665 baselined) · G-LEG **18/20** (không đổi).

## P6 đã làm — test cho class logic (R8)

- Sinh khung bằng `python tools/new_test.py <Class>`, sau đó **thay từng `fail()` bằng assert thật**.
- **24 file** mới trong `tests/unit/**` (models · models/definitions · systems · systems/modes · systems/services ·
  utils), **95 test method / 260 assertion**: `godot --headless --path . -s res://tests/run_tests.gd`
  → **95 passed, 0 failed**.
- Phủ: `ChapterChestsStore · LifeStore · ProgressStore · ToolInventory · TutorialStore` ·
  `AchievementData · AvatarData · FrameData · ProfilerTitleData · BlueprintStep(+Drag)` ·
  `ChallengeRules · LevelCatalog · BoardCellsView · TutorialLauncher · DailyClassic/ChallengeGameMode` ·
  `SaveBackend · LocalSaveBackend · PlayGamesSaveBackend` · `Life · Svc · DebugData · PaperGeometry`.
- Test đi theo **hướng + trường hợp bị chặn** (đủ Sao/chưa đủ, hết lượt, sai nguồn cấp, chạm trần, JSON float…).
- R8 **29 → 5**: 5 class bỏ qua vì cần ván chơi / đổi scene / âm thanh thật —
  `RunReporter · DailyRunReporter · RunNavigator` (cần `GameState` / màn Daily / `SceneManager`),
  `ShopCardTap` (cần `Control` + `InputEvent`), `Sfx` (cần phát âm thanh).
- **Không sửa `tools/run_checks.py`** (đúng P6.2): G-LEG (`tools/run_tests.py`) vẫn chạy riêng.
- `python tools/run_checks.py`: lint · exports · plan · import · **tests PASS**; **scenes FAIL (114 lỗi)** và
  **load FAIL**. Kiểm chứng bằng `git stash`: **HEAD (trước P5/P6) cũng đúng 114 lỗi scenes** ⇒ có sẵn, không
  phải regression. Nguyên nhân: `[connection …]` trỏ node/method không tồn tại (60 `connection pressed`,
  24 `tab_pressed`, `$Icon not found`) + 1 asset Halloween thiếu (đã có trong G-INT baseline); `load` chỉ có
  dòng engine `ERROR: 1 resources still in use at exit` (lúc thoát engine, không phải lỗi game).

## P7 đã làm — tài liệu

- `docs/ARCHITECTURE.md` (mới): sơ đồ lớp, cây thư mục sau refactor, 24 autoload, cây kế thừa `BaseGameMode`,
  6 store, backend lưu, bố cục portrait/landscape, quy ước `## Scene contract` + tag `EXCEPTION`, cách chạy test.
- `README.md` (viết lại): mở/chạy project, bảng cấu trúc, **cách chạy G-RUN và G-LEG**, danh sách tool, ghi chú
  save/export. Handout "Ranking v4" cũ giữ ở §6 để tra tên asset.
- `docs/STRUCTURE.md`: đánh dấu **lỗi thời** ở đầu file, trỏ sang `ARCHITECTURE.md`.
- `docs/refactor/maps/` **giữ nguyên** (chưa xoá — cần người duyệt).

## Deviation phát sinh ở P5–P7 (cần người quyết)

**D-INT — G-INT = 24, không phải 18.** Đo lúc kết P7: `check_integrity` báo **24 lỗi / 19 cảnh báo**.
Đã kiểm chứng bằng `git stash`: **HEAD `74b4163e` cũng đúng 24** ⇒ không phải do P5.2–P7.
6 lỗi thêm (so với con số 18 ghi ở P2) nằm trong `tests/legacy/legacy_ui_scenes.gd` — test này hardcode
đường dẫn cũ và **đã hỏng sẵn**:
`res://scripts/ui/screens` (dòng 338) · `res://scripts/ui` (338) · `res://nodes/hud/portrait|landscape/game`
(467–468) · `res://scripts/ui/hud` (536) · `res://scripts/ui/tutorial` (801).
**Không tự sửa** vì đó là *hằng đường dẫn để quét*: trỏ sang đường mới (`scripts/screens`, `scripts/objects`,
`scenes/objects/ui/hud/...`) sẽ khiến test quét thêm hàng trăm file và nhiều khả năng **tăng số CHECK FAIL**
của một test đang được ghi nhận là hỏng-sẵn ⇒ vi phạm ràng buộc "không tăng FAIL". Cần người quyết:
(a) sửa hằng đường dẫn rồi chấp nhận test_ui_scenes đổi số, hoặc (b) coi `test_ui_scenes` là dead test và xoá.
16 lỗi còn lại: `debug/probes/dev_*.gd` trỏ `nodes/hud/...`, `nodes/tutorials/...` (probe tay) · 1 asset
`events/halloween_card_grid.png` thiếu · 1 `tests/framework/GameTestCase.gd` trỏ asset demo của template.

**D-RUN — `run_checks.py` chưa exit 0.** `scenes` 114 lỗi + `load` 1 dòng `ERROR: … resources still in use at
exit`; cả hai có sẵn ở HEAD (xác nhận bằng `git stash`) và không liên quan P5/P6 (§P6 ở trên).
