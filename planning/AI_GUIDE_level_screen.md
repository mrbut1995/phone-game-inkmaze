# HƯỚNG DẪN CHO AI AGENT — Viết lại hệ thống màn LEVEL (bản dọc)

> Người giao việc: chủ dự án InkMaze (Godot 4.8, GDScript). Giao diện/art do Claude (chat) thiết kế, **agent chỉ làm hệ thống: script, scene, dây tín hiệu, test**.
> Mọi comment/chuỗi hiển thị viết **tiếng Việt**. Tài liệu tham chiếu hình: `mockup/level_final.svg|png`, `level_final_chuong_khoa.*`, `level_final_chuong_du_sao.*` (khung 540×960 đơn vị thiết kế).

---

## 0. Đọc trước khi làm
1. Đọc `PROJECT_NOTES.md` (nếu có) và quy ước ở mục 2.
2. Đối chiếu **ảnh mockup** với mục 5 (đặc tả). Nếu ảnh và chữ lệch nhau, **ảnh đúng**, hỏi lại chủ dự án khi còn mơ hồ.
3. Làm **theo giai đoạn** ở mục 4, mỗi giai đoạn chạy test + chụp ảnh màn hình trước khi sang giai đoạn sau.

## 1. Mục tiêu
Thay giao diện màn **Chọn màn (Level)** dọc bằng bố cục chốt:

| Khu vực | Hiện tại | Mới |
|---|---|---|
| Chọn chương | Banner "ĐỔI CHƯƠNG ›" → mở màn `chapters` riêng | **Hàng TAB chương** ngay trên màn Level (4 chương hiện có, tối đa 99). Bấm tab đã mở = đổi chương tại chỗ. Bấm tab khoá = mở **khung "chương đang khoá"** (overlay) |
| Thưởng chương | `ChapterProgress` — thanh ngang + 3 rương dưới banner | **Thanh dọc ở lề trái** (`ChapterRail`), 3 rương ở 33% · 67% · 100% |
| Bản đồ | Zigzag 2 cột, nối bằng đường cong | **Đường rắn 3 cột** (snake): hàng 1 trái→phải, hàng 2 phải→trái… nối hàng bằng nét cong ở mép |
| Chân màn | Nút "TIẾP TỤC MÀN n" | **Thẻ "MÀN TIẾP THEO"** (số màn + sao + nút CHƠI) |
| Màn Chapters | `scenes/chapters.tscn` | **Bỏ dần** (xem 4.6 — chỉ xoá sau khi bản ngang cũng xong) |

**Ngoài phạm vi:** bản **ngang** (landscape) của màn Level; art mới (Claude giao riêng); popup thắng/thua; logic chơi.

## 2. Quy ước dự án (BẮT BUỘC)
- Hiệu ứng/animation khai trong **AnimationPlayer ngay trong scene** (`EnterAnim`, `PulseAnim`, … xem `UIAnim.play_layout_anim`); script chỉ chọn animation hoặc gán dữ liệu. Tween chỉ làm **fallback**.
- Node UI bind bằng **`@export`** trong `.tscn`; **không** `get_node("đường/dẫn")` / `find_child` trong code chạy thật (trừ test).
- Dây signal khai bằng **`[connection]` trong `.tscn`**; `ensure_signal()` của `BaseUI` chỉ là lưới an toàn.
- Màn dọc/ngang là 2 layout (`scenes/layout/portrait|landscape/levels.tscn`) dùng chung script `LevelsLayout`. Mọi export mới phải **cho phép `null`** (layout ngang chưa có) và code kiểm `if x == null`.
- SVG đặt ở `assets/images/**`; pipeline `tools/svg_to_png.py` sinh PNG ở `assets/images-png/**`; **scene chỉ tham chiếu PNG**.
- Chuỗi: thêm vào `string_extra.csv` (cột `id,en,vi`), dùng `tr()`/`TranslationServer.translate()`. Ưu tiên **tái dùng key có sẵn** (mục 3.4).
- Kiểu chữ qua **theme type variation** trong `resources/settings/theme_default.tres`, không set font/màu rời trong scene.
- Test: đặt ở `scripts/test_case/…`, chạy bằng `godot --headless --script …`. Test **không** được làm bẩn tiến trình người chơi (xem `GameManager._is_automated_test`).
- Autoload dùng thẳng: `Nav`, `Sfx`, `Popups`, `GameManager`, `LevelManager`, `Save`, `ScreenManager`.

## 3. Hiện trạng cần biết (đã đọc từ file thật)

### 3.1 Màn Level hiện tại
- `scripts/scenes/levels.gd` (`class_name LevelScenes extends BaseScene`): `_build_map()`, `_refresh_header()`, `_refresh_progress()`, `_on_continue_pressed()`, `_on_banner_input()` → `Nav.goto_chapters()`, `chapter_continue_level()`, `chapter_cleared()`, `_filter_by_chapter()` (lọc màn theo `GameManager.current_chapter`), rương: `_wire_progress()` / `_on_chest_claim_requested()` / `_show_chest_reward()` (mở `Popups.DAILY_MILESTONE`).
- `scripts/scenes/layout/levels_layout.gd` (`LevelsLayout`): export `btn_back, btn_continue, lbl_continue, lbl_stars, lbl_stars_total, lbl_chapter, lbl_change_chapter, banner, banner_normal, banner_focus, level_map, progress`.
- `LevelMap` (Node2D trong `MapArea` Control có clip): `build(level_ids, stars_dict, unlocked_level, current_level)`, signal `level_selected(id)`, `scrolled(delta_y)` → `background.set_scroll_delta()`. Cuộn bằng node `Tracks` (kéo/quán tính/lăn chuột). `LevelMapNode` trạng thái LOCKED/NORMAL/CURRENT/DONE/SKIPPED; `LevelMapPath` LOCKED/UPCOMING/SKIPPED/COMPLETE. Nút dùng `TextureButton2D` (nhận input bằng `_unhandled_input` ⇒ **root `BaseScene` phải `mouse_filter = IGNORE`**, đừng đổi).
- `ChapterProgress` (`nodes/chapters/chapter_progress.tscn`): `setup(stars_own, stars_total)`, signal `claim_requested(index)`, meta `chapter_id`; chip rương `ChapterChestChip`; tự đặt chip theo tỉ lệ. Được dùng ở `levels.gd` **và** `chapters.gd` (xem test `scripts/test_case/test_chapter_rewards.gd`).

### 3.2 API dữ liệu có sẵn (KHÔNG viết lại, chỉ gọi)
`GameManager` (`scripts/core/game_manager.gd`):
- Chương: `unlocked_chapters`, `current_chapter`, `set_chapter(id)`, `is_chapter_unlocked(id)`, `chapter_star_cost(id)`, `can_unlock_chapter(id)`, `unlock_chapter(id) -> bool` (emit `chapter_unlocked(id)`), `has_unlockable_chapter()`, `total_stars()`, `chapter_of_level(id)`, `next_level_in_chapter(id)`, `can_play_level(id)`.
- Rương: `chapter_chest_defs(stars_total)`, `claimed_chapter_chests(id)`, `is_chapter_chest_claimed(id, i)`, `can_claim_chapter_chest(id, i, own, total)`, `claim_chapter_chest(id, i, own, total) -> Dictionary` (rỗng = không nhận được), `chapter_chest_reward_text(def)`, signal `chapter_chest_claimed(chapter_id, index)`. Ngưỡng 33%/67%/100% (`chest_threshold`).
- Chơi: `start_level(id)`, `level_stars: Dictionary`, `unlocked_levels`.
- ⚠️ **`star_cost` KHÔNG bị trừ**: mở khoá chương chỉ cần `total_stars() >= star_cost`. UI phải ghi "CẦN 25 SAO", **không** ghi "−25★".
- Điều hướng: `go_to_chapters()` (còn tồn tại), `go_to_levels()`.

`LevelManager`: `get_chapters() -> Array[ChapterData]`, `get_chapter(id)`, `levels_in_chapter(id)`, `chapter_stars(id)`, `chapter_star_total(id)` (= số màn × 3), `chapter_cleared_count(id)`, `current_chapter_id()`.

`ChapterData` (`scripts/resources/chapter_data.gd`): `chapter_id, title, subtitle, title_key, subtitle_key, size_label, star_cost, icon` + `display_title()`, `display_subtitle()`, `display_size()`, `display_icon()`. Ví dụ: chương 2 = SUY LUẬN, `star_cost 25`, `size_label "4×4 – 11×11"`, icon `logic`; chương 3 = BẪY ẨN, `45`, `"8×8"`, icon `trap`. Chương 1 `star_cost 0`.

`Nav`/`SceneManager`: `goto_levels()`, `goto_chapters()` (SCENE_CHAPTERS), `ScreenManager.go_back()`. **Cảnh báo vòng lặp Back:** `chapters.gd` cố ý quay về bằng `ScreenManager.go_back()`; không ghi lịch sử khi quay lại (xem comment trong `chapters._on_back_pressed`). Màn Level mới **không** được `push_history` khi đổi tab chương (đổi tab không phải đổi scene).

### 3.3 Số chương
File `chapter_*.tres` thấy: 2 và 3. Có key dịch cho **4 chương** (`STR_CHAPTER_1..4_NAME/SUB`). `LevelManager` hỗ trợ tới **99**. Tab phải xử lý: ít chương (vừa 540px) **và** nhiều chương (cuộn ngang). Chương **không có màn** (`levels_in_chapter` rỗng) = trạng thái **SẮP RA MẮT**.

### 3.4 Chuỗi có sẵn trong `string_extra.csv` (tái dùng)
`STR_CHAPTER_FORMAT` "CHƯƠNG {0}" · `STR_CHAPTER_TITLE_FORMAT` · `STR_CHAPTER_RIBBON_{PLAYING,OPEN,READY,LOCKED,COMING}` · `STR_CHAPTER_REQUIRE_FORMAT` "CẦN {0} SAO" · `STR_CHAPTER_NEED_FORMAT` "CÒN THIẾU {0} SAO" · `STR_CHAPTER_HAVE_FORMAT` "✓ ĐÃ ĐỦ: {0} / {1} SAO" · `STR_CHAPTER_STARS_FORMAT` "{0} / {1} SAO" · `STR_CHAPTER_LEVELS_FORMAT` "({0}/{1} màn)" · `STR_CHAPTER_UNLOCK` "MỞ KHÓA" · `STR_CHAPTER_NOT_ENOUGH` "Chưa đủ sao" · `STR_CHAPTER_PROGRESS_TITLE` "THƯỞNG CHƯƠNG" · `STR_CHAPTER_UNLOCKABLE` · `STR_CHAPTER_{1..4}_NAME/SUB` · `STR_LEVEL_TITLE_FORMAT` "MÀN {0}" · `STR_LEVEL_NEXT` "MÀN TIẾP".
**Key MỚI cần thêm:** `STR_LEVEL_NEXT_CARD_TITLE` "MÀN TIẾP THEO" · `STR_LEVEL_PLAY` "CHƠI" · `STR_LEVEL_START_LABEL` "BẮT ĐẦU" · `STR_CHAPTER_LOCK_TITLE` "CHƯƠNG ĐANG KHOÁ" (nếu cần) · `STR_CHAPTER_DONE_TITLE` "HOÀN THÀNH CHƯƠNG" · `STR_CHAPTER_GO_NEXT` "CHƯƠNG TIẾP ›". Đừng tạo key trùng — kiểm `grep` trước.

## 4. Các giai đoạn
Làm lần lượt; mỗi giai đoạn: code → test → chụp ảnh → báo cáo ngắn.

### 4.1 `ChapterTabs` (component mới)
- Scene `nodes/level_selection/chapter_tabs.tscn` + `scripts/nodes/level_selection/chapter_tabs.gd` (`class_name ChapterTabs extends Control`), tab con `ChapterTab` (`chapter_tab.tscn/.gd`).
- `setup(chapters: Array[ChapterData], selected_id: int)`; đọc trạng thái từ `GameManager` / `LevelManager`.
- Trạng thái tab: `SELECTED` (đang xem, rộng, chữ "CHƯƠNG n") · `OPEN` (đã mở, không chọn) · `READY` (đủ sao nhưng chưa mở: huy hiệu đỏ "!") · `LOCKED` (khoá) · `COMING` (không có màn, xám, **không bấm được**).
- Signal: `chapter_selected(chapter_id)` (tab OPEN/SELECTED) và `locked_chapter_requested(chapter_id)` (tab LOCKED/READY).
- Chứa trong `ScrollContainer` ngang; tab đang chọn luôn cuộn vào giữa tầm nhìn (khi > 4 tab).
- Hoạt ảnh (AnimationPlayer của scene): tab được chọn "nảy" lên; tab READY nhịp thở nhẹ.
- Thay thế vai trò `banner` + `lbl_change_chapter` + `has_unlockable_chapter()` pulse (huy hiệu READY thay cho banner focus).

### 4.2 `ChapterLockSheet` (khung chương đang khoá)
- Overlay trong scene Level (Control full-rect có nút Dim + thẻ giấy), mở/đóng bằng AnimationPlayer (`open`/`close`), giống `MonthSheet` của Daily (`nodes/daily/`) — **tái dùng mẫu đó**.
- Nội dung (xem `level_final_chuong_khoa.png` và `…_du_sao.png`): vòng tròn icon (khoá, hoặc sao khi đủ sao) · "CHƯƠNG n" · tên · mô tả · chip `size_label` · "CẦN {star_cost} SAO" · thanh sao `total_stars()/star_cost` · dòng trạng thái (`STR_CHAPTER_NEED_FORMAT` hoặc `STR_CHAPTER_HAVE_FORMAT`) · nút.
- Nút: chưa đủ ⇒ xám, vô hiệu, nhãn `STR_CHAPTER_NOT_ENOUGH`; đủ ⇒ xanh lá, nhãn `STR_CHAPTER_UNLOCK`.
- Bấm MỞ KHÓA: `GameManager.unlock_chapter(id)` → nếu `true`: `Sfx.play(Sfx.ACHIEVEMENT)`, đóng sheet, `GameManager.set_chapter(id)`, dựng lại cả màn (tab + bản đồ + rương). Nếu `false`: `Sfx.play(Sfx.BTN_CLICK)`.
- Back cứng/Esc khi sheet mở ⇒ **đóng sheet trước** (xem cách Daily xử lý `is_month_sheet_open()` trong `daily.gd`). Lưu ý `ScreenManager._handle_back` chỉ biết `PopupManager`; nếu sheet không phải popup thì màn Level cần tự chặn Back (tham khảo Daily).
- Lắng nghe `GameManager.chapter_unlocked` để làm tươi tab.

### 4.3 `ChapterRail` (thanh thưởng dọc)
- **Không** viết mới hoàn toàn: thêm chế độ dọc cho `ChapterProgress` (`@export var vertical := false`) **hoặc** tạo `ChapterRail` kế thừa, miễn **giữ nguyên API**: `setup(own, total)`, signal `claim_requested(index)`, meta `chapter_id`. `levels.gd` (`_wire_progress`, `_refresh_progress`, `_on_chest_claim_requested`) và test hiện có **không được hỏng**.
- Thanh dọc cao cố định (không cuộn theo bản đồ): 0★ ở đáy, chip rương đặt ở 33%/67%/100% chiều cao, phần lấp đầy tính theo `own/total`. Nhãn ngưỡng "9★ · 18★ · 27★" lấy từ `GameManager.chapter_chest_defs(total)[i].stars` (**không hard-code 9/18/27**).
- Trạng thái chip: đã nhận (mở nắp + tick xanh) · sẵn sàng (huy hiệu đỏ "!", nhịp thở) · khoá (mờ). Tái dùng `ChapterChestChip` + art Daily.
- Bấm chip: giữ nguyên luồng `_on_chest_claim_requested` (popup rương Daily).

### 4.4 `LevelMap` — chế độ rắn (snake)
- Thêm `@export var columns := 3` và hàm xếp vị trí kiểu rắn: hàng i đi trái→phải nếu i chẵn, phải→trái nếu lẻ; **hàng 0 ở dưới cùng**, màn lớn dần đi lên (như mockup: 1-2-3 dưới, 4-5-6 giữa, 7-8-9 trên).
- Nối hàng bằng cung cong ở mép (`LevelMapPath` thêm kiểu `U_TURN` hoặc cho phép truyền điểm điều khiển). Nối cùng hàng: đoạn gần thẳng, nét đứt.
- Trạng thái nút/đường giữ nguyên enum hiện có; **không đổi** signal `level_selected`, `scrolled`, và cách `Tracks` cuộn.
- Số hàng > chiều cao vùng nhìn ⇒ cuộn dọc như hiện nay (chương 2 có bàn tới 11×11 → nhiều màn hơn 9). Cuộn tự đưa **màn hiện tại** vào giữa tầm nhìn khi mở.
- Cờ đích gắn trên màn **cuối chương**; bút chì chỉ gắn trên màn **hiện tại** (`chapter_continue_level()`).
- Dưới mỗi nút (không phải CURRENT/LOCKED): thẻ 3 sao nhỏ. LOCKED: icon khoá + số mờ. Nhãn "BẮT ĐẦU" dưới màn đầu chương.
- Sinh tự động: `columns` 3 là mặc định; nếu `MapArea` quá hẹp (tablet/màn nhỏ) vẫn giữ 3 cột, chỉ co khoảng cách.

### 4.5 `NextLevelCard` (thẻ chân màn)
- Scene `nodes/level_selection/next_level_card.tscn` + script; thay `ContinueButton`/`lbl_continue`.
- Hiển thị: ô số màn (vàng) · "MÀN TIẾP THEO" · "Màn n" · 3 sao đã đạt của màn đó · nút **CHƠI** (xanh, 3D).
- Nguồn: `chapter_continue_level()` (màn đầu tiên chưa có sao trong chương). Bấm CHƠI giữ logic cũ `_on_continue_pressed()` (kiểm `level_id <= _unlocked_level()` → `start_level`).
- **Chương đã xong** (`chapter_cleared()`): thẻ đổi sang "HOÀN THÀNH CHƯƠNG" + nút "CHƯƠNG TIẾP ›": chọn tab chương kế tiếp nếu đã mở, nếu chưa mở thì mở `ChapterLockSheet` của chương đó, nếu không còn chương nào thì ẩn nút. **Không** gọi `Nav.goto_chapters()` nữa (ở bản dọc).
- Hoạt ảnh `PulseAnim` cho nút CHƠI (giữ tên player/animation cũ để `UIAnim.play_layout_anim` chạy).

### 4.6 Bỏ màn Chapters (làm CUỐI, có điều kiện)
Hiện **bản ngang vẫn dùng banner + `Nav.goto_chapters()`**. Vì vậy:
1. Giai đoạn này **chỉ** chuyển hướng ở bản dọc. Giữ `scenes/chapters.tscn`, `chapters.gd`, `chapter_card.*` cho tới khi bản ngang cũng đổi.
2. Khi bản ngang xong, xoá: `scenes/chapters.tscn`, `scenes/layout/*/chapters.tscn`, `chapters.gd`, `chapters_layout.gd`, `chapter_card.tscn/.gd`, `SCENE_CHAPTERS`/`goto_chapters()` trong `SceneManager`, `GameManager.go_to_chapters()`, `Nav.goto_chapters()`, `STR_WL_CHAPTERS` nếu không dùng, mockup `chapter_selection.svg`. Chạy `grep -rn "goto_chapters\|go_to_chapters\|SCENE_CHAPTERS\|chapters.tscn\|ChapterCard\|ChaptersScene\|ChaptersLayout\|back_to_levels" --include=*.gd --include=*.tscn --include=*.tres --include=*.cfg` để tìm hết tham chiếu (kể cả `export_presets`, danh sách scene trong `project.godot`).
3. Test `test_chapter_rewards.gd` đang dựng **màn chapters** để tìm `ChapterProgress`: viết lại dùng màn Level (`levels_scene.call("progress_widget")` đã có). Test nào khác nhắc tới `chapters` cũng phải cập nhật.

## 5. Đặc tả giao diện (đơn vị thiết kế 540×960 — quy đổi theo hệ toạ độ thật của layout dọc)
> Kiểm tra root của `scenes/layout/portrait/levels.tscn` đang thiết kế theo 540 hay 1080 rồi **nhân tỉ lệ**. Không dùng số tuyệt đối nếu layout dùng container/anchor; mockup chỉ để định tỉ lệ & thứ tự.

| Khối | Vị trí/kích thước (x, y, w, h) | Ghi chú |
|---|---|---|
| TopBar (back + chip xu + chip bút chì) | y≈28, cao 36 | Dùng `TopBar` dùng chung + `header_anchor` như hiện nay |
| Hàng tab | y 84→130, tab chọn rộng 150×46; tab thường 70×38 cách nhau 8 | Tab chọn cao hơn 8px, nối liền xuống thẻ |
| Thẻ chương | (26, 130, 488×78) | Tên chương 22px đậm, mô tả 11.5px, pill sao "x/y" ở phải, dòng nhỏ "7 / 9 màn · {size_label}" |
| Thanh thưởng dọc | tâm x=76, từ y=340 (100%) đến y=766 (0★) | Chip rương r=19 ở 33/67/100%; nhãn ngưỡng bên phải chip |
| Bản đồ rắn | cột x = 200 / 320 / 440; hàng y = 680 / 510 / 340 (hàng 0 dưới) | Nút 62×62 bo 17; khoảng cách hàng 170 |
| Nối hàng | cung ra mép phải x≈492 (hàng 0→1), mép trái x≈146 (1→2) | Nét đứt navy |
| Thẻ màn tiếp theo | (26, 812, 488×100) | Ô số 60×60, nút CHƠI 150×52 |
| Khung chương khoá | (50, 250, 440×380) nền tối 50% | Nút đóng ✕ ở góc phải trên |

Màu/phong cách: giấy ô ly, nền kem `#FFFDF7`, viền navy `#164663`, hổ phách `#FBBF24`/`#C98A0B`, cam `#E4622B`, nút 3D xanh `#5BA3D6`. **Không dùng filter** trong SVG; không chữ trong SVG.

### Hành vi
- Mở màn: chọn tab = `GameManager.current_chapter`; cuộn bản đồ tới màn hiện tại; chạy `EnterAnim`.
- Bấm tab khác (đã mở): `GameManager.set_chapter(id)` → dựng lại bản đồ, rương, thẻ chương, thẻ màn tiếp theo; **không đổi scene, không ghi lịch sử**.
- Bấm tab khoá/READY: mở `ChapterLockSheet`, **không** đổi `current_chapter`.
- Màn khoá (LOCKED) trên bản đồ: rung nhẹ + `Sfx` như hiện tại; không vào chơi (`can_play_level`).
- Quay lại từ màn chơi: `_on_active()` làm tươi sao, rương, thẻ tiếp theo (như hiện tại).

## 6. Art
Claude sẽ giao riêng bộ SVG mới (nút màn 4 trạng thái, halo, tab chương, thẻ chương, thanh dọc, thẻ màn tiếp theo, khung khoá, cờ, bút chì chỉ) vào `assets/images/level_selector/**`. Trong lúc chờ: **dùng art hiện có hoặc ô giữ chỗ**, đặt đường dẫn PNG qua `@export` để thay sau mà không sửa code. Đừng tự vẽ lại art.

## 7. Tiêu chí hoàn thành
1. Màn Level dọc khớp ảnh `level_final.png`; mở khung khoá khớp `level_final_chuong_khoa.png` / `…_du_sao.png`.
2. Đổi tab chương không đổi scene, không thêm lịch sử; nút Back vẫn về đúng màn trước; Back khi sheet mở chỉ đóng sheet.
3. Rương: nhận đúng 1 lần/mốc, popup rương hiện đúng, thanh dọc cập nhật; `chapter_chest_claimed` vẫn phát.
4. Mở khoá chương: đủ sao ⇒ mở được, `unlocked_chapters` lưu qua `Save`, sao **không bị trừ**; thiếu sao ⇒ nút vô hiệu.
5. Chương không có màn ⇒ tab COMING không bấm được; chương nhiều màn ⇒ bản đồ cuộn, mở là thấy màn hiện tại.
6. Bản **ngang** vẫn chạy như cũ (không lỗi, banner → màn chapters còn hoạt động).
7. Không còn cảnh báo `push_warning` mới; `grep` ở 4.6 (bước 1) không phát hiện tham chiếu hỏng.
8. Test: viết/ cập nhật tối thiểu — (a) dựng tab từ `get_chapters()` đúng trạng thái; (b) mở khoá chương đủ/thiếu sao; (c) rắn xếp đúng vị trí cho 9 và 14 màn; (d) nhận rương qua màn Level; (e) chương cleared ⇒ thẻ đổi trạng thái; (f) đổi hướng màn hình giữ nguyên dữ liệu.

## 8. Câu hỏi mở (hỏi chủ dự án nếu gặp)
- `chapter_4.tres` đã có file chưa (có key dịch nhưng chưa thấy file)? Tên icon từng chương (`intro/logic/trap/master`) có dùng trên tab không (mockup hiện chỉ dùng số + khoá)?
- Chương 2+ có bao nhiêu màn? (ảnh hưởng số hàng cuộn.)
- Bản ngang làm khi nào (quyết định lúc nào xoá màn Chapters)?
