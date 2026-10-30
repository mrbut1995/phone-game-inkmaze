# Cấu trúc dự án — InkMaze (Godot 4.8.dev)

> Tài liệu NGẮN (1 trang). Nguồn sự thật: **scene/`.tres` cho bố cục & giá trị tĩnh, script cho hành vi**.

## 1. Cây thư mục

```
scenes/                     # MÀN HÌNH: x.tscn = vỏ (base.tscn + Portrait/Landscape) + scripts/scenes/x.gd
  layout/
    base_layout.tscn        # layout gốc: TopBar (CoinChip · LifeChip) — DÙNG CHUNG mọi màn
    portrait/<màn>.tscn     # layout DỌC (kế thừa base_layout)
    landscape/<màn>.tscn    # layout NGANG (kế thừa base_layout)
  <màn>.tscn                # main · settings · shop · daily · ranking · archivement · title · splash · credit · tutorial · debug
nodes/                      # COMPONENT (.tscn + script cùng tên ở scripts/nodes/)
  game/  hud/  popups/  main/  daily/  shop/  ranking/  chapters/  level_selection/  profiler/  archivements/  tutorials/  common/
scripts/
  scenes/<màn>.gd           # điều khiển màn hình (extends BaseScene / BaseUI)
  scenes/layout/<màn>_layout.gd  # `@export` node UI của layout (MainLayout, ShopLayout…)
  nodes/<...>.gd            # hành vi component
  core/                     # logic không phụ thuộc UI: game_state · maze_data · level_manager · controllers/ · modes ở scripts/modes/
  manager/                  # AUTOLOAD (singleton) — xem §4
  resources/                # script Resource (`class_name`): LevelData · ChapterData · ArchivementData · Avatar/Frame/Title
  services/                 # save backend (local · play games)
  utils/                    # facade tĩnh: Nav · Popups · Sfx · Shop · Profile · Archivement · Loc · UIAnim · PenSkin
  test_case/                # test/harness chạy `--script` (dev_* = probe thủ công)
assets/ images/ frames/ icons/ sfx/ soundtrack/ fonts/   (SVG nguồn + assets/images-png là bản build — gitignored)
resources/ settings/ (theme_default.tres · theme_hslider.tres · text/*.tres · styles/) · levels/ · chapters/ · archivements/ · profiler/
tools/                      # tool Python/GDScript ngoài runtime (refactor/, level_designer/, svg_to_png.py, run_tests.py…)
```

## 2. Quy ước đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File script/scene | `snake_case` | `main.gd`, `level_section.tscn` |
| `class_name` | `PascalCase` (thì/danh từ nghĩa) | `MainScene`, `CoinChip`, `LevelSection` |
| Node trong scene | `PascalCase`, đúng vai trò (danh sách thật thì `Slot1..N`) | `TopBar`, `Dock`, `DockDaily` |
| Handler signal | `_on_<Node>_<signal>` | `_on_profile_card_pressed` |
| Hằng nội bộ | `SCREAMING_SNAKE_CASE` (chỉ thuật toán; giá trị UI → `.tscn`/Theme) | `MAZE_MIN_SIZE` |
| Khoá dịch | `STR_<NHÓM>_<TÊN>` trong `resources/localization/*.csv` | `STR_BTN_SHOP` |
| Style dùng chung | Theme Type Variation trong `theme_default.tres`; style của 1 chỗ dùng | `.tres` ở `resources/settings/styles/*` + `theme_override_styles/*` trong `.tscn` |

## 3. Mô hình layout Portrait / Landscape

1. `scenes/<màn>.tscn` **chỉ** chứa: instance `base.tscn` (root, gắn script màn) + `Portrait` + `Landscape`.
2. `BaseUI` (`scripts/scenes/base_ui.gd`) bật/tắt layout theo tỉ lệ khung và phát `orientation_changed`.
3. Script màn **không** dò đường dẫn node: mỗi layout có class `<X>Layout extends BaseLayout` khai `@export` node;
   `.tscn` bind bằng `node_paths=PackedStringArray(...)` + `<tên> = NodePath("...")` (NodePath tương đối với node mang script).
4. Khác biệt hướng (vị trí, cỡ, ẩn/hiện) nằm **trong 2 file layout**, không `if is_landscape` trong script.
5. Node **dùng chung** (CoinChip · LifeChip · TopBar) khai 1 lần ở `base_layout.tscn`; màn không dùng thì
   override `visible = false` + `mouse_filter = 2` + `process_mode = 4` (DISABLED) trong layout của màn đó — **không** tách/xoá khỏi base.
6. Dây signal: nút nằm trong component → nối trong `.tscn` của component; nút của layout → nối trong `.tscn` của layout rồi
   layout phát signal ngữ nghĩa (`profile_pressed`…), màn nối `[connection signal="…" from="Portrait" to="." method="…"]`.

## 4. Autoload & trách nhiệm

| Autoload | File | Trách nhiệm |
|---|---|---|
| `SafeArea` | `utils/safe_area.gd` | vùng an toàn tai thỏ / thanh điều hướng |
| `LoadingManager` | `manager/LoadingManager.gd` | màn loading/chuyển cảnh phụ |
| `LevelManager` | `core/level_manager.gd` | đọc/ghi `resources/levels|chapters/*.tres` (cache id, sort) |
| `GameManager` | `core/game_manager.gd` | phiên chơi, tiến trình màn/chương, tiền tệ, chế độ đang chạy |
| `AppManager` | `manager/AppManager.gd` | version, vòng đời app, orientation |
| `SettingManager` | `manager/SettingManager.gd` | cài đặt âm thanh/rung, lưu local |
| `SceneManager` · `ScreenManager` | `manager/*` | đổi scene (hiệu ứng) · lịch sử điều hướng |
| `PopupManager` | `manager/PopupManager.gd` | mở/đóng popup theo id hoặc path |
| `SfxManager` · `MusicManager` | `manager/*` | hiệu ứng âm thanh · nhạc nền theo ngữ cảnh |
| `DataManager` | `manager/DataManager.gd` | đọc/ghi `user://inkmaze_data.json` |
| `DailyManager` | `manager/DailyManager.gd` | lịch daily, chuỗi ngày, nhiệm vụ ngày |
| `DebugManager` | `manager/DebugManager.gd` | cờ log debug + phím mở Debug Console |
| `AdsManager` | `manager/AdsManager.gd` | stub quảng cáo (rewarded) |
| `LocalizationManager` | `manager/LocalizationManager.gd` | nạp CSV đa ngôn ngữ (19 locale) |
| `SaveManager` | `manager/SaveManager.gd` | gom `export/import_progress` của provider → backend (local/cloud) |
| `ShopManager` · `ArchivementManager` | `manager/*` | cửa hàng & ví Xu · sổ tay thành tựu (AP, mốc) |
| `PlayerProfileManager` | `manager/PlayerProfileManager.gd` | hồ sơ: avatar/viền/tên, thống kê sâu |
| `RankingManager` | `manager/RankingManager.gd` | 3 bảng xếp hạng (mô phỏng đối thủ, seed 10 phút) |
| `ThemeManager` | `manager/ThemeManager.gd` | skin giấy/mực + ngòi bút (áp lên bàn cờ & nền) |
| `TutorialManager` | `manager/TutorialManager.gd` | luồng học lần đầu (bài học ⇄ màn thực hành) |
| `EventManager` | `manager/EventManager.gd` | sự kiện theo thời gian + thẻ Daily ảo |

## 5. Ghi chú

- `.gd` dùng **TAB**, kết thúc bằng newline; bật warnings-as-errors ⇒ `var x := <Variant>` là lỗi parse.
- `class_name` mới ⇒ chạy `godot --headless --path . --editor --quit` để cập nhật class cache.
- Asset: `assets/images*/**.svg` là nguồn; `assets/images*-png/**` là bản build (gitignored) — chạy `tools/svg_to_png.py` khi clone.
