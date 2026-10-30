# Cấu trúc dự án — InkMaze (Godot 4.8.dev)

> Tài liệu NGẮN (1 trang). Nguồn sự thật: **scene/`.tres` cho bố cục & giá trị tĩnh, script cho hành vi**.

## 1. Cây thư mục

```
scenes/                     # MÀN HÌNH: x.tscn = vỏ (base.tscn + Portrait/Landscape) + scripts/ui/screens/x.gd
  layout/
    base_layout.tscn        # layout gốc: TopBar (CoinChip · LifeChip) — DÙNG CHUNG mọi màn
    portrait/<màn>.tscn     # layout DỌC (kế thừa base_layout)
    landscape/<màn>.tscn    # layout NGANG (kế thừa base_layout)
  <màn>.tscn                # main · settings · shop · daily · ranking · achievement · title · splash · credit · tutorial · debug
nodes/                      # COMPONENT (.tscn; script tương ứng ở scripts/ui/)
  game/  hud/  popups/  main/  daily/  shop/  ranking/  level_selection/  profiler/  achievements/  tutorials/  common/
scripts/
  autoload/                 # 24 SINGLETON (tên file = snake_case của tên autoload) — xem §4
  core/                     # logic không phụ thuộc UI: game_state · maze_data · score_calculator · controllers/
                            # + "store" tách từ GameManager: life_store (lượt chơi) · floor_records_store (kỷ lục tầng) · tool_inventory (kho dụng cụ)
  modes/                    # *_game_mode.gd (Standard · Countdown · Dungeon · Fog …)
  data/                     # script Resource (class_name): LevelData · ChapterData · AchievementData · Avatar/Frame/Title
  services/                 # save backend (local · play games)
  utils/                    # facade tĩnh: Svc · Nav · Popups · Sfx · Shop · Profile · Achievement · Loc · Life · UIAnim · PenSkin
  ui/
    screens/                # điều khiển MÀN (extends BaseScene / BaseUI): main · shop · daily · game …
    layouts/                # `<màn>_layout.gd` — @export node UI của layout; game_scene_layout + game_layout_portrait|landscape
    hud/                    # base_hud + hud/game/<mode>_hud
    game/                   # board · cell · cursor · ink · wall (bàn cờ & hiệu ứng)
    popups/                 # base popup + từng popup (win · gameover · retry · pause …)
    tutorial/               # base_tutorial + các bài how_to_play_*
    widgets/                # chip/card/button + widget theo màn: common · main · daily · shop · ranking · level_selection · profiler · achievements
  tools/                    # script chạy trong EDITOR/CLI (gen_*, nine_patch) — không chạy lúc runtime
  test_case/                # test/harness chạy `--script` (dev_* = probe thủ công)
assets/ images/ frames/ icons/ sfx/ soundtrack/ fonts/   (SVG nguồn + assets/images-png là bản build — gitignored)
resources/ settings/ (theme_default.tres · theme_hslider.tres · text/*.tres · styles/) · levels/ · chapters/ · achievements/ · profiler/
tools/                      # tool Python/GDScript ngoài runtime (refactor/, level_designer/, svg_to_png.py, run_tests.py…)
```

**Quan hệ scene ⇔ script:** script của scene `nodes/<nhóm>/x.tscn` nằm ở `scripts/ui/<nhóm>/x.gd`
(`<nhóm>` = `hud` · `game` · `popups` · `tutorial`; các widget còn lại ở `scripts/ui/widgets/<nhóm>/`).
Thư mục **scene** giữ nguyên tên cũ (`nodes/main`, `nodes/chapters`…) để không đổi đường dẫn ảnh/hình —
chỉ nhánh `scripts/` được sắp lại theo tầng.

## 2. Quy ước đặt tên

| Loại | Quy ước | Ví dụ |
|---|---|---|
| File script/scene | `snake_case` (enforced từ Phase 3) | `main.gd`, `shop_manager.gd`, `level_section.tscn` |
| `class_name` | `PascalCase` (thì/danh từ nghĩa) | `MainScene`, `CoinChip`, `LevelSection` |
| Node trong scene | `PascalCase`, đúng vai trò (danh sách thật thì `Slot1..N`) | `TopBar`, `Dock`, `DockDaily` |
| Handler signal | `_on_<Node>_<signal>` | `_on_profile_card_pressed` |
| Hằng nội bộ | `SCREAMING_SNAKE_CASE` (chỉ thuật toán; giá trị UI → `.tscn`/Theme) | `MAZE_MIN_SIZE` |
| Khoá dịch | `STR_<NHÓM>_<TÊN>` trong `resources/localization/*.csv` | `STR_BTN_SHOP` |
| Style dùng chung | Theme Type Variation trong `theme_default.tres`; style của 1 chỗ dùng | `.tres` ở `resources/settings/styles/*` + `theme_override_styles/*` trong `.tscn` |

## 3. Mô hình layout Portrait / Landscape

1. `scenes/<màn>.tscn` **chỉ** chứa: instance `base.tscn` (root, gắn script màn) + `Portrait` + `Landscape`.
2. `BaseUI` (`scripts/ui/screens/base_ui.gd`) bật/tắt layout theo tỉ lệ khung và phát `orientation_changed`.
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
| `SafeArea` | `autoload/safe_area.gd` | vùng an toàn tai thỏ / thanh điều hướng |
| `LoadingManager` | `autoload/loading_manager.gd` | màn loading/chuyển cảnh phụ |
| `LevelManager` | `autoload/level_manager.gd` | đọc/ghi `resources/levels|chapters/*.tres` (cache id, sort) |
| `GameManager` | `autoload/game_manager.gd` | phiên chơi, tiến trình màn/chương, tiền tệ, chế độ đang chạy |
| `AppManager` | `autoload/app_manager.gd` | version, vòng đời app, orientation |
| `SettingManager` | `autoload/setting_manager.gd` | cài đặt âm thanh/rung, lưu local |
| `SceneManager` · `ScreenManager` | `autoload/*` | đổi scene (hiệu ứng) · lịch sử điều hướng |
| `PopupManager` | `autoload/popup_manager.gd` | mở/đóng popup theo id hoặc path |
| `SfxManager` · `MusicManager` | `autoload/*` | hiệu ứng âm thanh · nhạc nền theo ngữ cảnh |
| `DataManager` | `autoload/data_manager.gd` | đọc/ghi `user://inkmaze_data.json` |
| `DailyManager` | `autoload/daily_manager.gd` | lịch daily, chuỗi ngày, nhiệm vụ ngày |
| `DebugManager` | `autoload/debug_manager.gd` | cờ log debug + phím mở Debug Console |
| `AdsManager` | `autoload/ads_manager.gd` | stub quảng cáo (rewarded) |
| `LocalizationManager` | `autoload/localization_manager.gd` | nạp CSV đa ngôn ngữ (19 locale) |
| `SaveManager` | `autoload/save_manager.gd` | gom `export/import_progress` của provider → backend (local/cloud) |
| `ShopManager` · `AchievementManager` | `autoload/*` | cửa hàng & ví Xu · sổ tay thành tựu (AP, mốc) |
| `PlayerProfileManager` | `autoload/player_profile_manager.gd` | hồ sơ: avatar/viền/tên, thống kê sâu |
| `RankingManager` | `autoload/ranking_manager.gd` | 3 bảng xếp hạng (mô phỏng đối thủ, seed 10 phút) |
| `ThemeManager` | `autoload/theme_manager.gd` | skin giấy/mực + ngòi bút (áp lên bàn cờ & nền) |
| `TutorialManager` | `autoload/tutorial_manager.gd` | luồng học lần đầu (bài học ⇄ màn thực hành) |
| `EventManager` | `autoload/event_manager.gd` | sự kiện theo thời gian + thẻ Daily ảo |

## 5. Ghi chú

- `.gd` dùng **TAB**, kết thúc bằng newline; bật warnings-as-errors ⇒ `var x := <Variant>` là lỗi parse.
- `class_name` mới ⇒ chạy `godot --headless --path . --editor --quit` để cập nhật class cache.
- Asset: `assets/images*/**.svg` là nguồn; `assets/images*-png/**` là bản build (gitignored) — chạy `tools/svg_to_png.py` khi clone.

Mọi script khác **không** truy cập autoload bằng `get_node("/root/X")`; dùng `Svc.x()` (`scripts/utils/svc.gd`) — accessor tĩnh có kiểu, trả `null` an toàn khi chạy `--script` (harness không có autoload).
