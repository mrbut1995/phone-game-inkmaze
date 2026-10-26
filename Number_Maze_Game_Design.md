# Number Maze — Game Design Document

## 0. Tiêu chuẩn tài liệu (Design Template)

| | |
|---|---|
| **Tài liệu** | Number Maze — Game Design Document| **Phiên bản** | v2.52 — 2026-10-25 (**HẾT LỖI "BACK VỀ ĐÚNG VÁN VỪA CHƠI"**: thắng màn cuối chương → nút "CHỌN CHƯƠNG" gọi `GameManager.go_to_levels()` = điều hướng **đi TIẾN** ⇒ `SceneManager` đẩy `game.tscn` vào lịch sử ⇒ Back ở màn Chọn màn pop đúng `game.tscn` và quay lại màn 9; thêm `ScreenManager.drop_history(path)`/`peek_history()` + `GameManager.return_to_levels()`/`return_to_daily()` (`_return_to()` = gỡ mục màn nguồn đã đẩy lúc vào ván rồi `Nav.back_to()` KHÔNG ghi lịch sử) và dùng ở 5 chỗ kết thúc ván trong `game_controller` (Continue hết chương · Skip hết chương · "VỀ DAILY" · nhánh dự phòng của "TRỞ VỀ"); `test_scene_transition` +3 check lịch sử, `test_chapters` 123 → **124** — §13.25b) · v2.51 — 2026-10-24 (**HẾT “GIẬT CỤC” Ở MÀN SPLASH**: 2 layout `scenes/layout/{portrait,landscape}/splash.tscn` khai `AnimationPlayer` bằng `libraries/ = SubResource(...)` — cú pháp `.tscn` SAI ⇒ **thư viện hoạt ảnh RỖNG**, `play_entrance`/`play_exit` chưa bao giờ chạy, `splash.gd` rơi vào nhánh tween dự phòng `TRANS_BACK` (logo phóng vọt 1,058 rồi co lại) ⇒ sửa thành `libraries = { "": SubResource(...) }`; `LoadingManager` **không chặn main thread ngay frame đầu** nữa: nhường `VISUAL_GRACE_SEC` 0,82 s cho hoạt ảnh mở màn chạy trọn 60 fps + 3 scene `PRELOAD_SCENES` chuyển sang **nạp ở luồng nền** (`load_threaded_request()` ngay trong `_ready()` → poll `load_threaded_get_status()`), hết hẳn các frame 126–230 ms; **quét sửa cùng lúc 25 scene khác** bị y hệt lỗi `libraries/ =` (49 dòng: `title` · `daily` · `levels` · `ranking` · `shop` · `archivement` · `loading` · `popups/*` · `daily/*` · `base_tutorial` · `action_bar` · `level_node` · `level_map`) ⇒ hoạt ảnh khai trong scene lần đầu thật sự chạy (`test_daily` 3 → 1 lỗi); tiêu đề Splash được đặt `pivot_offset` giữa (Label chỉ có `size` sau lượt layout đầu ⇒ đặt deferred); đo lại: khung hình **16–17 ms** suốt 0 → 0,8 s, logo 0,300 → 0,477 → 0,675 → 0,825 → 0,929 → 0,987 → 1,000 (không còn overshoot), tổng thời gian Splash **vẫn ≈1,5 s** vì đã bị chặn dưới bởi `MIN_DISPLAY_SEC` 1,2 s — §13.25a) · v2.50 — 2026-10-23 (**XOÁ MÀN “CHỌN CHƯƠNG”**: tab chương + khung khoá trong màn Chọn màn đã thay thế hoàn toàn màn riêng ở cả 2 hướng ⇒ xoá `scenes/chapters.tscn` + 2 layout + `chapters.gd` + `chapters_layout.gd` + `chapter_card.tscn/.gd` và toàn bộ route `Nav.SCENE_CHAPTERS`/`goto_chapters()` · `SceneManager` · `GameManager.go_to_chapters()` (2 chỗ gọi trong `GameController` → `go_to_levels()`) · mục “Select Chapter” của Debug Console; dọn thêm 5 export chết của `LevelsLayout` (`btn_continue` · `lbl_continue` · `lbl_stars` · `lbl_stars_total` · `lbl_change_chapter`), thẻ chương không còn dây `gui_input`, `test_chapters` 238 → **123 check** (bỏ mục thẻ/màn Chọn chương, thêm 6 check gác “đã xoá sạch”) — §12 · §12.8) · v2.49 — 2026-10-23 (**TÁCH TUTORIAL THÀNH 2 MÀN**: `scenes/tutorial_list.tscn` = DANH SÁCH 12 bài (`TutorialListScene` + `TutorialListLayout`), `scenes/tutorial.tscn` = CHI TIẾT bài đang xem (`TutorialScene` + `TutorialLayout` chỉ còn `Paper`/`TopBar`/`TutorialContainer`); 4 bố cục `.tscn` tách đôi (portrait|landscape × list|detail), màn danh sách **không** còn `TutorialController`; nút LUẬT CHƠI ở Main → `Nav.goto_tutorial_list()`, bấm 1 bài → `GameManager.request_tutorial(id, true)` + `Nav.goto_tutorial()`, luồng onboarding/nút "?"/Debug bài lẻ vẫn vào thẳng màn CHI TIẾT; cờ mới `pending_return_to_list` + `take_return_to_list_flag()` để Back/học xong quay về DANH SÁCH; `TutorialContainer.z_index = 30` ⇒ hết 2 tiêu đề chồng nhau + Back lơ lửng trên bài học; `TutorialController` bỏ qua id không tồn tại (trước đây để màn trống vĩnh viễn); tiêu đề màn gán `tr()` + nghe `locale_changed` — §10.2i) · v2.48 — 2026-10-23 (**NỐI ART MỚI “VÒNG 1” CHO MÀN CHỌN MÀN**: 28 asset trong `art_level_round1/` đã vào `assets/images/level_selector/` (SVG) + `assets/images-png/level_selector/` (PNG 2×) và được **nối vào scene** — tab chương dùng `tab_selected`/`tab_normal`/`tab_locked` + huy hiệu `badge_ready` (đổi từ Label “!” sang TextureRect) + `icon_lock_small`, thêm 3 theme variation `ChapterTabTitle(Selected/Locked)`; rail dùng `rail_track_v`/`rail_fill_v`; thẻ màn kế dùng `card_next_level` + `level_badge_gold` + `btn_play_blue_*` (thêm style `disabled`) + `star_pill_full/empty`; sheet khoá dùng `card_lock_sheet` + `btn_green_*`/`btn_grey_disabled`; thẻ chương bản DỌC đổi `chapter_banner` → `card_chapter` (bản NGANG giữ art cũ); ô màn dùng `level_node_{normal,hover,pressed,disabled}` + **`level_node_current`** (thêm export `art_normal`/`art_current`) + `icon_lock_small` + `star_pill_*`; mũi chỉ đổi `map_marker_arrow` → `map_marker_pencil`, cờ đích art mới — **quy tắc 9-slice: PNG là 2× nên `patch_margin`/`texture_margin`/`stretch_margin` = NỬA giá trị “px PNG” trong README**, riêng tab dùng patch = 0 vì tỉ lệ art khớp đúng nút — §12.4d) · v2.47 — 2026-10-22 (**MÀN CHỌN MÀN BẢN DỌC VIẾT LẠI THEO `planning/AI_GUIDE_level_screen.md`**: bỏ banner “ĐỔI CHƯƠNG” + nút chân trang, thay bằng **dải TAB chương** (`ChapterTabs`/`ChapterTab` — 5 trạng thái: ĐANG CHỌN · ĐÃ MỞ · ĐỦ ĐIỀU KIỆN (badge “!” nhấp nháy) · KHOÁ · SẮP RA MẮT), **thẻ chương** (tiêu đề + mô tả + `x / y STARS` + `n/n levels`), **RAIL thưởng DỌC** ở lề trái (`nodes/chapters/chapter_rail.tscn` = `ChapterProgress` với `vertical = true`: 0★ ở ĐÁY → 100% ở ĐỈNH, rương mốc 9/18/27★ xếp từ đáy lên), **bản đồ RẮN 3 cột** (`LevelMap.columns · column_spacing · row_spacing · turn_bulge · snake_center_shift`: hàng 0 ở đáy đi trái→phải, hàng lẻ chạy NGƯỢC, đường nối vòng ra MÉP ở mỗi lần chuyển hàng) và **thẻ “MÀN TIẾP THEO”** ở chân màn (`NextLevelCard`: CHƠI / CHUYỂN CHƯƠNG + số sao đã đạt); bấm tab chương KHOÁ ⇒ mở **`ChapterLockSheet`** (tiến độ sao · `CẦN n SAO` / `ĐÃ ĐỦ` · nút mở khoá **không tiêu Sao**); bản DỌC bỏ `Progress` ngang + `ContinueButton`; bản NGANG **giữ nguyên** zigzag + thanh ngang + nút “CHỌN CHƯƠNG”; **màn Chọn chương vẫn giữ** (bản ngang còn dùng); 7 khoá dịch mới (`STR_LEVEL_NEXT_CARD_TITLE` · `STR_LEVEL_PLAY` · `STR_LEVEL_START_LABEL` · `STR_CHAPTER_LOCK_TITLE` · `STR_CHAPTER_READY_TITLE` · `STR_CHAPTER_DONE_TITLE` · `STR_CHAPTER_GO_NEXT`); test mới `test_level_screen` (59 check) + cập nhật `test_levels_map` (bố cục rắn) · `test_chapter_rewards` (rail dọc) · `test_layout_bindings` — §12.4 · §12.4c) · v2.46 — 2026-10-22 (**CHUYỂN THANH TIẾN ĐỘ CHƯƠNG SANG MÀN CHỌN MÀN**: thanh “THƯỞNG CHƯƠNG” + 3 rương mốc **rời màn Chọn chương** (nơi chỉ còn danh sách chương) và **vào màn CHỌN MÀN** — `Content/InformationArea/Progress` (export `LevelsLayout.progress`) nằm ngay **dưới banner chương, trên bản đồ**, cắm ở cả 2 bố cục; `MapArea` hạ `anchor_top` 0.20 → 0.31 để không đè thanh; `levels.gd` tự vẽ lại thanh khi vào màn / màn được kích hoạt lại (thắng–thua xong số Sao đã đổi) / xoay màn hình, bấm rương ⇒ nhận thưởng + popup rương; widget nhãn tự dịch lại theo `LocalizationManager.locale_changed` (nếu bảng dịch nạp sau `_ready` cũng đúng); bổ sung lại 5 khoá dịch `STR_CHAPTER_PROGRESS_TITLE` · `STR_CHAPTER_CHEST_{TOOLTIP,LIFE,POPUP_TITLE,POPUP_SUB}` bị thiếu trong `string_extra.csv`; `test_chapter_rewards` (74 check) đổi sang kiểm tra màn Chọn màn + gác “màn Chọn chương KHÔNG còn thanh này” — §12.4 · §12.4b) · v2.45 — 2026-10-22 (**THANH TIẾN ĐỘ + RƯƠNG MỐC THƯỞNG Ở MÀN CHỌN CHƯƠNG** (tầng B của planning "Chiến lược thưởng chế độ Play"): thêm widget **`nodes/chapters/chapter_progress.tscn`** (`ChapterProgress`) nằm ngay dưới băng hướng dẫn ở **cả 2 hướng** — thanh Sao kiểu màn Daily (`bar_track`/`bar_fill_gold`) + nhãn "x / y SAO" + **3 rương mốc** ở ngưỡng **33% · 67% · 100%** tổng Sao chương (chương 27★ ⇒ 9/18/27★); rương dùng art Daily qua **`nodes/chapters/chest_chip.tscn`** (`ChapterChestChip`: vòng hổ phách khi đủ Sao · rương mở + ✓ khi đã nhận); `GameManager` thêm `chapter_chests` + `chapter_chest_defs()`/`chest_threshold()`/`claim_chapter_chest()` (nhận **MỘT lần/chương**, `+50 Xu` · `Gợi ý ×2 + Hoàn tác ×1` · `+150 Xu + 1 lượt chơi`), nguồn cấp mới `"chapter_chest"` cho `grant_tool_uses`/`grant_lives`, lưu trong blob tiến trình; bấm rương ⇒ mở **popup rương dùng chung của Daily** với `title_text`/`sub_text`/`reward_text` riêng cho chương; test mới `test_chapter_rewards` (73 check) — §12.4 · §12.4b · §12.5 · §12.6) · v2.44 — 2026-10-22 (**HỒ SƠ: BỎ NHÓM “SỐ LẦN CHƠI CHẾ ĐỘ”**: xoá hẳn nhóm `GAME MODE STATS` khỏi popup Hồ sơ — `ProfilerScene` không còn `MODE_ROWS`, không còn nhóm washi thứ 4 (`tape_mode`/`squiggle_mode`) và 11 icon riêng của chế độ; danh sách số liệu còn **4 nhóm / 17 thẻ** (Play 6 · Dungeon 2 · Time 3 · InGame 6), lưới dọc 3/2/3/3 cột; dữ liệu `mode_plays` trong `Profile.deep_stats()` vẫn được ghi (chỉ KHÔNG hiển thị); `test_profiler` cập nhật 4 nhóm/17 thẻ + kiểm tra cuộn theo mức cuộn tối đa thay vì hằng số 40 — §4 · §8) · v2.43 — 2026-10-21 (**KỶ LỤC TẦNG CAO NHẤT THEO NGÀY / TUẦN / THÁNG**: `GameManager` giữ `floor_records` (khoá ngày `YYYY-MM-DD` · tuần = ngày **thứ Hai** của tuần · tháng `YYYY-MM`), ghi bằng `record_floor_reached()` mỗi khi vào tầng mới của ván **Dungeon (vô tận)** — chỉ NÂNG chứ không hạ, bỏ qua ván Debug/test, sang kỳ mới thì tự về 0; lưu cùng blob tiến trình + tự lưu ngay khi lập kỷ lục (`floor_record_changed`); **popup Game Over Dungeon** (`gameover.tscn`) thêm hàng `Records` dưới 3 chỉ số hiện **“Kỷ lục tuần: N”** và **“Kỷ lục tháng: N”** (`--` khi chưa có); test mới `test_floor_records` (64 check) — §5.10c) · v2.42 — 2026-10-21 (**POPUP RETRY: THỬ LẠI = HỒI SINH — SỬA LỖI "ĐỨNG IM KHÔNG DI CHUYỂN ĐƯỢC"**: `UIController.show_game_over()` trước đây nối tín hiệu `retry_requested` trong khi `RetryPopup` chỉ phát `revive_requested` ⇒ bấm **XEM QUẢNG CÁO** / **TRẢ XU** chỉ đóng popup, `_game_over()` đã khoá bàn cờ (`_interaction_enabled = false`) nên người chơi không đi được nữa. Nay popup Retry phát `revive_requested` → `UIController` phát tín hiệu mới **`revive_confirmed`** → `GameController.revive_run()` (đúng đoạn của nút **HỒI SINH** ở popup Game Over): mở khoá bàn cờ, chạy lại đồng hồ, tiếp tục ĐÚNG ván đang chơi thay vì mở ván mới; bỏ hàm chết `_on_retry_popup_retry()`; test: `test_retry_popup` 32 check (thêm "thua màn → xem quảng cáo ⇒ bàn cờ mở khoá + đi được bước tiếp theo"), `test_retry_floor` sửa lại luồng "popup Retry mở trước ⇒ BỎ QUA mới vào popup thua" (hết FAIL cũ) — §5.10a) · v2.41 — 2026-10-22 (**BỎ `_apply_chip_visibility()` — HIỆN/ẨN CHIP KHAI TRONG `.tscn`**: `BaseLayout` không còn `toggle_visible` · `shared_coin_chip` · `shared_life_chip` hay `_apply_chip_visibility()`; 11 file layout (Settings · Tutorial · Splash · Title · Profiler popup · Event ngang, cả 2 hướng) tự khai block override `[node name="CoinChip" parent="TopBar"] visible = false` (+`LifeChip`) — hiển thị/vị trí/thứ tự 100% do `.tscn` quyết định; `_content_min_height()` lọc chip theo `class` thay vì biến tham chiếu; giữ `_sync_shared_header()` để `TopBar` vẫn khớp khung co giãn (`Scaler`/`Stage`) — §4.2 · §4.3) · v2.40 — 2026-10-21 (**THANH TRÊN: BỎ `move_child`, CONTENT NẰM PHẲNG TRONG `TopBar`**: xoá hẳn `BaseLayout._setup_shared_chips()` — không còn di chuyển chip lúc chạy, thứ tự do `index` trong `.tscn`; bỏ node bao `HeaderRow` ở 8 layout (Chapters/Levels/Shop/Tutorial ngang · Event/Game/Levels/Tutorial dọc) và trả thứ tự icon về như thiết kế gốc: Main = Hồ sơ → Xu → Lượt → Sao → Cài đặt; 5 màn cần khung định vị/dọc (Daily 2 hướng · Shop dọc · Game ngang · Event ngang · Profiler) vẫn giữ `HeaderRow`; `landscape/event` có thanh trên là CỘT DỌC nên ẩn chip dùng chung và tự khai 2 chip trong hàng tiêu đề; `can_animate_bar()` chặn tween vị trí `TopBar` khi có `header_anchor` — §4.2 · §4.3) · v2.39 — 2026-10-20 (**CHIP DÙNG CHUNG QUAY VỀ `base_layout` + CỜ `toggle_visible`**: `TopBar/CoinChip` + `TopBar/LifeChip` khai MỘT lần trong `scenes/layout/base_layout.tscn`; `BaseLayout._setup_shared_chips()` đưa 2 chip về CUỐI thanh trên và ẩn/hiện theo `@export toggle_visible` (`false` ở **Settings · Tutorial · Splash · Title · Profiler popup**, cả 2 hướng); layout chỉ ghi đè thuộc tính chip khi cần (Shop: `navigate_on_plus = false`, size riêng) — 24 layout đã bỏ node chip cục bộ, binding ví Xu/Lượt chơi trỏ `TopBar/CoinChip` · `TopBar/LifeChip` — §4.2) · v2.38 — 2026-10-20 (**LƯỢT CHƠI (LIFE) DÙNG CHUNG TOÀN GAME**: tối đa **5 lượt**, mỗi **30 phút** hồi 1 lượt (đếm bằng đồng hồ thực, tắt app vẫn hồi); **thua mà KHÔNG thử lại ⇒ −1 lượt** (`GameManager.register_run_loss()` chỉ chạy 1 lần/ván, `begin_run_guard()` mở lại khi bấm Thử lại); **hết lượt ⇒ không vào được ván nào** — mọi lối vào ván đi qua `_enter_game_scene()` và mở **popup HẾT LƯỢT CHƠI** (`out_of_life.tscn`): THOÁT RA hoặc CỬA HÀNG (Back của Shop quay về **đúng màn trước đó** nhờ `shop_return_path`); **`LifeChip`** (`nodes/main/life_chip.tscn`) nằm cạnh `CoinChip` trên **mọi layout có ví Xu**, nhãn `x/5`, nút `+` chỉ hiện khi thiếu lượt; Cửa hàng bán gói `life_x1` (300 Xu); Debug Console có mục **LIVES**; **FIX**: `UIAnim.play_slide_in()` trượt bằng OFFSET thay vì `position` — ví Xu không còn bị đóng băng offsets rồi văng khỏi màn hình ở Cửa hàng — §5.10b · §4.2 · §9) · v2.37 — 2026-10-20 (**VÍ XU KHAI TRỰC TIẾP TRONG TỪNG LAYOUT — HẾT COIN TRÙNG**: bỏ `CoinChip`/`CoinChipSpacer` khỏi `base_layout.tscn` và bỏ hẳn `hide_coin_chip` + `_setup_coin_chip` + `_push_chip_right` trong code; mỗi layout khai **đúng MỘT** `CoinChip` trong `TopBar`/`HeaderRow` của mình (Settings · Tutorial · Splash · Profiler không có), vị trí/góc phải do `index` trong `.tscn` quyết định — editor không còn 2 coin, runtime không còn xoá node) · v2.36 — 2026-10-20 (**MỌI THANH TRÊN NẰM TRONG `TopBar` CỦA BASE_LAYOUT**: các `TopBar`/`Header` cục bộ (Main · Daily · Levels · Game · Event · Chapters ngang · Shop · Tutorial · Profiler) được **đưa nguyên vào `TopBar/HeaderRow`** của `base_layout.tscn`; `TopBarAnchor` vô hình giữ rect cũ và `BaseLayout.header_anchor` đồng bộ `global_position`/`size`/`scale` mỗi frame (đúng cả với `Stage`/`Scaler`/cột), min-size của neo = min-size của HeaderRow; `TopBar` có `z_index = 10` (trên nội dung, dưới `Popups` z=20); toàn bộ NodePath/`[connection]`/track animation/export được cập nhật — §4.3) · v2.35 — 2026-10-20 (**VÍ XU DÙNG CHUNG TOÀN MÀN HÌNH**: `CoinChip` tự cập nhật số Xu qua `ArchivementManager.progress_changed`, nút `+` mặc định mở Cửa hàng (`navigate_on_plus = false` ở Shop để chuyển tab NẠP XU); **Shop bỏ hẳn `Wallet` riêng** (`wallet_chip` + `icon_coin` + `btn_plus`) và dùng `CoinChip` cho cả 2 hướng, `WalletAnim` trỏ vào `CoinChip/Content/Value`; `coin_tile.tscn` vẫn giữ vì là **thẻ gói nạp** — §4.2 · §13.4) · v2.34 — 2026-10-20 (**POPUP RETRY TRƯỚC KHI VÀO GAME OVER**: khi người chơi Game Over, game hiển thị popup Retry (`nodes/popups/retry.tscn` / `Popups.RETRY`) trước tiên thay vì vào thẳng popup thua; cung cấp 3 lựa chọn: Xem quảng cáo (Advert), Trả Xu (Gold, 100 Xu qua `Archivement.spend_coins()`) hoặc Bỏ qua để chuyển tiếp vào popup Game Over thông thường — **§5.10a**) · v2.33 — 2026-10-19 (**VÍ XU Ở MÀN DAILY + HIỆU ỨNG SAO KHI HOÀN THÀNH VÁN**: màn Daily (cả 2 hướng) có **`CoinChip` 111×32 ở góc phải thanh trên** — dùng đúng `nodes/main/coin_chip.tscn` như Main, đọc `Shop.coins()`, bấm `+` mở Cửa hàng; thu hẹp Tiêu đề/Phụ đề để không đè ví; ván Daily vừa xong ghi cờ **`GameManager.daily_celebrate`** (đọc-rồi-xoá 1 lần) ⇒ `daily.gd._celebrate_daily_win()` chọn đúng **ngày** + đúng **thẻ** (CHƠI/THỬ THÁCH) rồi chạy **`celebrate_1..3`** khai trong `action_card.tscn` (Sao nảy lần lượt + khung icon nhún, `pivot_offset` đặt trong scene); `test_daily` thêm §5d (10 check: ví Xu 2 hướng · đổi ví · đúng thẻ · đọc cờ 1 lần · tự chọn ngày) — **§6.8**) · v2.32 — 2026-10-19 (**RƯƠNG QUÀ CÓ ANIMATION MỞ/ĐÓNG**: sinh `SpriteFrames` `chest_frames.tres` từ `chest_spritesheet.png` (3 anim `closed`/`open`/`idle`, cùng một vùng cắt nên rương không nhảy frame); popup mốc dùng `AnimatedSprite2D` + **AnimationPlayer `reveal`** khai trong SCENE (đung đưa → bung nắp → rương mở lấp lánh, kèm squash&stretch + nhảy nhẹ + băng dính rung), script chỉ gọi lại animation; chip mốc dùng `chest_closed` khi chưa nhận và `chest` khi đã nhận; sửa cú pháp thư viện animation `libraries = { &"": … }` cho popup + 2 layout Daily) · v2.31 — 2026-10-18 (**TÁCH `event_card` THÀNH `EventCard` + `DailyCard`**: phần chung (tỉ lệ, bấm/kéo phát `card_pressed`, `setup` + `Timer` làm mới, 5 helper tô màu theo theme) gom vào lớp cơ sở **`EventCardBase`**; `EventCard` chỉ còn sự kiện THẬT (theme art · 2 phần thưởng · đếm ngược hạn · `claimed/completed`), `DailyCard` là thẻ riêng cho event ảo của `DailyManager` (lá lịch tháng/ngày/thứ · panel `★ x/6` Sao hôm nay · đếm ngược tới 00:00 · CTA đỏ); `EventCarousel` có thêm `daily_card_scene` và chọn scene theo `EventData.Type`) · v2.30 — 2026-10-18 (**CHỌN NGÀY CÓ VÒNG SÁNG · MỞ KHOÁ BẰNG QUẢNG CÁO · POPUP NHẬN THƯỞNG MỐC**: ô lịch đang chọn có vòng sáng xanh trùm ngoài ô; ngày bỏ lỡ **không còn trả 50 Xu** mà chạy `AdsManager.show_rewarded("daily_unlock")` (placeholder) rồi mới vào màn, nút ghi như game đã mở; bấm rương mốc đã đủ Sao ⇒ nhận Xu/lượt công cụ + **popup nhỏ `daily_milestone`** báo phần thưởng; **Debug Console §9.3** thêm đọc Sao tháng/mốc kế tiếp/trạng thái AdsManager + lệnh **+30 Sao**, **Nhận mốc kế tiếp**, **Test rewarded ad**, **Mở khoá ngày bỏ lỡ (miễn phí)**) · v2.29 — 2026-10-17 (**DỰNG LẠI MÀN DAILY Y HỆT `mockup/daily_challenge.svg`**: thanh Sao dày có **ngôi sao lớn chứa số Sao** + **4 huy hiệu mốc 15★/30★/45★/60★** (vòng hổ phách + rương + ✓ khi đã nhận); lịch tháng có **ô HÔM NAY** (nhãn hổ phách + số lớn + viên "x/6 ★"), chú giải **nằm trong bảng lịch**; **2 thẻ hành động lớn** (băng dính chéo · khung icon · tiêu đề + dòng phụ · 3 Sao · nút CTA xanh/hổ phách); mỗi layout có `Panel/Stage` **phóng/thu đều theo canvas** nên giữ đúng tỉ lệ mockup ở mọi cỡ màn hình; `DailyManager.MILESTONES` đổi về đúng số trên mockup) · v2.28 — 2026-10-17 (**TINH GIẢN DAILY CHALLENGE: 1 MÀN + 1 CHALLENGE, 2 NÚT NGANG & TIẾN ĐỘ SAO THÁNG**: thay bảng 3 nhiệm vụ thường + 1 special cồng kềnh bằng 2 nút ngang nhỏ gọn [CHƠI] và [CHALLENGE] có subtitle chế độ chơi; mỗi ngày tối đa **6 Sao** (3 Sao CHƠI theo nhiệm vụ + 3 Sao THỬ THÁCH khi thắng) và thanh Sao tháng có **4 mốc thưởng 15★/30★/45★/60★** (thưởng Xu + lượt công cụ); mockup cập nhật `daily_challenge.svg` và `daily_challenge_landscape.svg`) · v2.27 — 2026-10-15 (**THẺ DAILY TRÊN MAIN MỞ THẲNG MÀN DAILY**: `MainScene._on_event_card_pressed()` trước đây đẩy MỌI thẻ qua `Nav.goto_event()` nên bấm thẻ Daily lại mở `scenes/event.tscn` (phải bấm thêm CTA mới tới Daily); nay tra loại qua `EventManager.get_event()` — `type == DAILY` → `Nav.goto_daily()`, các loại khác vẫn mở màn chi tiết Event; `test_main_layout` thêm phép gác "bấm thẻ Daily phải ra `res://scenes/daily.tscn`" (đã thử phá thì test FAIL đúng như thiết kế)) · v2.26 — 2026-10-14 (**BẢN ĐỒ CHỌN MÀN, BẢN NGANG: hết tự cắt**: điểm uốn vuông góc ở bản ngang (nút lệch 640×200) làm tiếp tuyến Catmull-Rom quá lớn ⇒ đường nối tự cắt thành hình chữ X (probe đếm **3 chỗ**); thêm `sway_flat_ratio` (bản ngang uốn nhẹ 0,30 thay vì 0,60 — quét thử: ≤0,30 sạch, ≥0,45 tự cắt 3 chỗ), `test_levels_map` thêm `road_crossings()` chặn đường TỰ CẮT ở cả 3 phép thử) · v2.25 — 2026-10-14 (**BẢN ĐỒ CHỌN MÀN: hướng màn hình lấy theo CANVAS + nét nối dày hơn**: `LevelMap.is_wide()` trước đây so khung `MapArea` (chỉ cao 62 % canvas, nằm trong cột nội dung) nên màn DỌC rộng (3:4, cửa sổ lớn khi test) bị coi là NGANG ⇒ zigzag 320 làm nút lòi ra ngoài khung + đổi trục uốn khiến đường nối vẽ sai dáng chữ S; nay lấy theo canvas, thêm `_zigzag()` kẹp theo bề rộng khung (`node_half_width`), nét nối dày hơn (5→8 · 4,5→7 · 4→6,5 · 3,5→5,5 px; gạch đứt 10/7 → 15/11), `test_levels_map` thêm mục gác `_check_portrait_wide_column()`) · v2.24 — 2026-10-14 (**`LoadingManager` + THANH TIẾN TRÌNH Ở SPLASH**: gom việc **nạp/khởi động** vào autoload `LoadingManager` — autoload nặng đăng ký `add_step(initialize)` và manager còn **nạp sẵn scene** (`PRELOAD_SCENES`: title · main · levels) rồi giữ tham chiếu; màn Splash có `Panel/LoadingBox` (`ProgressBar` + nhãn `STR_LOADING_PROGRESS`, theme variation `SplashLoadingLabel`) hiện tiến trình 0→100 % và **chờ nạp xong + 1,2 s tối thiểu** mới sang Title) · v2.23 — 2026-10-14 (**KHỞI ĐỘNG "SPLASH TRƯỚC, NẠP SAU" + NÚT BACK CỨNG ANDROID**: thêm autoload **`BootManager`** (nay là `LoadingManager`) hoãn 4 việc nạp nặng (`LocalizationManager` · `PlayerProfileManager` · `EventManager` · `ArchivementManager`) tới SAU frame Splash đầu tiên ⇒ hết màn hình đen sau icon app (frame đầu **1216 → 397 ms**); `project.godot` thêm ảnh **boot splash** (`assets/images-png/boot_splash.png` sinh bằng `tools/make_boot_splash.py`, nền giấy `#FAF5EB` + logo) + `quit_on_go_back=false`; `export_presets.cfg` đổi nền system splash & nền cửa sổ từ đen sang `#FAF5EB`; nút **Back cứng Android** nay điều hướng qua `ScreenManager` (bắt `NOTIFICATION_WM_GO_BACK_REQUEST`) thay vì thoát app, lịch sử điều hướng không còn bị "bẩn") · v2.22 — 2026-10-13 (**8 EVENTDATA MÙA VỤ + MÀU TIÊU ĐỀ RIÊNG THEO THEME**: thêm 8 `EventData` (Anniversary · Autumn · Easter · New Year · Spring · Summer · Thanksgiving · Valentine — mỗi event 3 màn + 2 quà Xu + lịch UTC) ⇒ **16 event** gồm Daily ảo; `title_color`/`title_outline` riêng cho **cả 16 theme** (chọn theo tông thật của vùng chữ trên art, viền 5 px, test chặn trùng màu + bắt tương phản ≥ 4,5:1); `EventManager` bỏ trần 8 thẻ, `EventDots` tạo chấm theo số trang, Main có cờ tạm `show_all_events_for_preview` để xem thử mọi event) · v2.21 — 2026-10-11 (**EVENT SYSTEM + GIAO DIỆN MAIN MỚI**: thêm **hệ thống Sự kiện** data-driven (`EventData`/`EventTheme`/`EventReward` `.tres`, autoload **`EventManager`**, thẻ `EventCard` 340×504 + carousel `EventCarousel`/`EventDots`, màn chi tiết `scenes/event.tscn`, 8 theme + 8 event + màn event riêng, test `test_event_manager` 33 check) → **§15**; **Main Screen bố cục lại cả 2 hướng**: thanh trên (Hồ sơ · Xu · Sao · Cài đặt) + khối Sự kiện (Daily **ghim đầu**, bỏ thẻ Daily riêng) + 2 thẻ giấy `ModeCard` 9-slice (Play · Dungeon) + dock 4 nút (Cửa hàng · Xếp hạng · Danh hiệu · Luật chơi); bỏ tờ giấy lớn/hero/hàng nút `btn_menu_utility_*`; harness `dev_aspects -- --only=main,event` **20/20 OK**) · v2.20 — 2026-09-28 (**ĐA NGÔN NGỮ — QUÉT CHUỖI CỨNG → KHOÁ DỊCH · DỌN KHOÁ CHẾT · SỬA MOJIBAKE CSV**: thêm bộ công cụ `tools/content/` (`audit_localization.py` quét & chặn hồi quy · `migrate_hardcoded_text.py` đổi chuỗi cứng → khoá · `fix_mojibake.py` sửa CSV từng ô); 16 chuỗi trong `.tscn` + chữ HUD/ô/nút công cụ/đếm bước tutorial trong script đổi sang `tr()` · **28 thành tựu** (`title_key`/`desc_key`) + **4 chương** (`title_key`/`subtitle_key`) lấy chữ qua `ChapterData.display_title()`; `string_extra.csv` **+73 khoá mới** (en/vi) và **xoá 76 khoá chết**; `string.csv` (91 dòng) **sửa xong mojibake nội dung ở cả 19 ngôn ngữ**; test mới `test_localization` (50 check) chặn mojibake/khoá thiếu/tên node bị đổi thành khoá → §14) · v2.19 — 2026-09-27 (**TUTORIAL KHAI TRONG SCENE + HIỆU ỨNG + TEST TRONG DEBUG**: toàn bộ UI/khung/bàn mini của 7 bài học đưa từ script vào `.tscn` — `base_tutorial.tscn` khai 13 node + 5 StyleBox + 6 chấm tiến độ, mỗi bài khai `BoardPanel` · ô `Cell1…CellN` (component **`TutorialCell`**) · `PathLine` · HUD · nút tường (**`TutorialWallToggle`**) · `BtnSubmit`; 3 nút điều hướng + 2 nút tường + nút GỬI nối bằng `[connection]` trong scene; art chuyển sang SVG (`tutorial_pointer/spotlight/wall/board_paper.svg`); script chỉ còn `@export` bind + luật chơi ⇒ **sửa 3 lỗi thật** (bàn mini bị đẩy ra ngoài màn hình do neo CENTER · kéo đường không ăn vì BoardHost nuốt chuột · so toạ độ lệch không gian) → §10.2h; **HIỆU ỨNG**: mở bài nở so le · chấm bước nảy · vòng sáng trượt + thở · ô nháy đỏ khi sai / nở khi đi qua · toast nở ra · chữ nổi `✓`/`+N` · HUD cuộn số · tường nở ra (dùng `UIAnim`/`Sfx`, không node mới); **DEBUG**: thêm mục **TUTORIAL (TEST)** vào Debug Console — vào thẳng từng bài qua `request_tutorial()`/`take_tutorial_request()`, “Test mode” không ghi tiến trình, xong bài ở lại màn Tutorial → §9.2) · v2.18 — 2026-09-27 (**HUD “CHỈ HIỆN THỨ CẦN THIẾT”**: mỗi HUD chỉ còn đúng thẻ cần (Dungeon Step+Floor · Countdown Budget · Fog Lượt thử lại · Sum Path Tổng+Mục tiêu · mode khác chỉ Time), node thừa **xoá hẳn** khỏi cả 2 hướng (bản DỌC dùng node kế thừa thì chỉ ẩn được) → §10.1 · §10.2g) · v2.17 — 2026-09-27 (**TỐI ƯU: UI KHAI TRONG SCENE — TAB TỰ LO**: 3 màn có tab (Cửa hàng · Xếp hạng · Sổ tay thành tựu) **không còn dựng tab bằng code** — tab là node **KHAI SẴN trong scene bố cục** (`Tabs/*`, mỗi hướng 1 bản), mỗi tab tự khai `category`/`board_id` + `label_key`, **tự nối `pressed` → `tab_pressed`** và tự chỉnh cỡ; script màn chỉ `_collect_tabs()` gom lại (hết `_build_tabs()`); lưới ô của Cửa hàng cũng thành node **khai sẵn dùng lại** (không instantiate lại mỗi lần đổi tab/trang); Xếp hạng **dùng lại hàng** khi đổi bảng; dọn code thừa (`TAB_*_SCENE` · `_fit_tab_widths` · `apply_row_layout` · `_capture_tab_layout`) → §10.2g; **BÀN CỜ**: 4 **node MẪU** (ô · tường · neo · vệt mực cũ) khai trong `nodes/game/board_layers.tscn` — board `_spawn_template()` = `duplicate()` thay `instantiate()`, cỡ THIẾT KẾ của tường/vệt mực đọc từ node mẫu (bỏ `_read_scene_line_width()` + 4 `preload()`); **Cửa hàng**: bàn nháp thử bút (`Content/List/Pad` · `PadSlot/Pad`) + hàng VIP *Xoá quảng cáo* (`Content/List/NoAds`) cũng khai sẵn trong 2 scene bố cục; `test_ui_scenes` thêm **mục 8** = hàng rào: script nào còn `preload()/instantiate()` scene ĐÃ khai sẵn thì FAIL) · v2.16 — 2026-09-27 (**TÔ GIÁ TRỊ THEO ĐƯỜNG ĐI + MỰC TÔ TAY**: công cụ 8 giờ biết **TÔ GIÁ TRỊ** thay vì chỉ sinh tường — `countdown_cost` có ô **Tổng chi phí đường đi** (chia 1..4 cho các ô sao cho TỔNG khớp, tự nâng `max_steps`), `sum_path` có ô **Tổng điểm đường đi** (chia 1..9), `fading_ink` thêm công cụ 7 **tô MỰC từng ô** + ô **Mực dư mỗi bước** (mực tăng dần theo bước); GAME: Sum Path **không tính S/F** nữa (tổng khớp đúng số thiết kế), Countdown Cost **tôn trọng `max_steps` của màn**, Fading Ink đọc **mực tô tay** → §10.2f) · v2.15 — 2026-09-27 (**VẼ ĐƯỜNG ĐI TRONG TOOL + MÀN MẪU CHO MỌI CHẾ ĐỘ**: công cụ **8** = kéo chuột vẽ đường S→F rồi `Ctrl+Enter` để sinh tường quanh nó (nét vẽ thành **ĐƯỜNG DUY NHẤT**, tự đặt S/F + `max_steps`); thêm **6 màn mẫu 15–20** phủ nốt mọi chế độ Special (mỗi chế độ 1 màn); **sửa LỖI THẬT của One Stroke** (thuật toán phủ kín luôn từ chối nước cuối bước vào F ⇒ màn thiết kế trước đây luôn âm thầm bị thay bằng bàn tự sinh); Debug Console (F9) nhảy được **mọi** màn + đánh dấu màn ◆ chế độ → §10.2f) · v2.14 — 2026-09-27 (**KIỂU EDIT THEO CHẾ ĐỘ + BỎ `dungeon` KHỎI MÀN**: mỗi chế độ có **1 kiểu edit** riêng trong tool (`custom_cell_values`, công cụ **7**): Minesweeper **GHIM MÌN** · Sum Path **ĐIỂM Ô** 1..9 · Countdown Cost **CHI PHÍ Ô** 1..4 (ô không tô = game tự sinh, cố định theo màn); `dungeon` bị **loại khỏi danh sách chế độ của màn** (validator báo LỖI, game coi như `play`) → §10.2f) · v2.13 — 2026-09-27 (**MÀN CHƠI CHẾ ĐỘ SPECIAL + SKIP LEVEL**: màn khai `mode_id` trong LevelData ⇒ game chạy chế độ Special **TRÊN ĐÚNG BÀN NHÀ THIẾT KẾ VẼ** (tường + cell_mask), "gia vị" của chế độ (mìn · điểm ô · chi phí · mực) **CỐ ĐỊNH theo `level_id`**; thêm **nút SKIP LEVEL** trên thanh hành động (chỉ hiện khi chơi MÀN, bấm ⇒ mở khoá màn kế trong chương mà KHÔNG ghi Sao); tool level_designer báo luật riêng theo chế độ → §10.2f) · v2.12 — 2026-09-26 (**THANH HÀNH ĐỘNG MỚI + GIỚI HẠN LƯỢT**: bỏ hẳn 2 nút công cụ VẼ ĐƯỜNG/GHI NHỚ (bàn cờ tự nhận thao tác), **nút CHƠI LẠI dời từ thanh trạng thái xuống thanh hành động** (cả 2 hướng), thêm nút **GỬI BÀI (`Submit`)** cho Wall Builder, **GIỚI HẠN lượt UNDO/HINT mỗi màn** (mặc định 3) + badge **`PanelLimit`** hiện số lượt còn lại và **khoá nút khi hết lượt** → §10.2e) · v2.11 — 2026-09-26 (**HAI KIỂU HIỂN THỊ ĐIỂM**: bản NHÚNG (HUD ngang) = ảnh SẠCH chữ + badge số + DANH SÁCH điểm đầy đủ bên phải; bản POPUP = ảnh giữ NGUYÊN chữ như mockup, KHÔNG badge + KHÔNG khối ĐIỂM (ảnh nở hết bề ngang) — MỌI chữ mô tả trên ảnh đều thành ĐIỂM có hàng trong danh sách → §10.2d) · v2.10 — 2026-09-26 (**SỬA LỖI LẬT TRANG + ẢNH SẠCH**: cụm điều hướng nhúng về **BĂNG ĐÁY khung**, ẩn mọi chữ mô tả trên ảnh) · v2.9 — 2026-09-26 (**BỐ CỤC CỐ ĐỊNH cho hệ hướng dẫn**) · v2.8 — 2026-09-26 (**HƯỚNG DẪN theo mockup landscape**) · v2.7 — 2026-02 (**TÁCH hệ hướng dẫn**) · v2.6 — 2026-02 (**Nền tảng đa tỉ lệ mới**) · v2.5 — 2026-09-19 (**BỎ hẳn Time Attack Maze**) · v2.4 — 2026-09-19 (2 mode mới vào vòng xoay Daily 9 ngày) · v2.3 — 2026-09-19 (**Wall Builder đã lập trình xong** → §5.13 · §13.19) · v2.2 — 2026-09-19 (**One Stroke đã lập trình xong** → §5.12 · §13.18) · v2.1 — 2026-09-18 (đặc tả 2 bộ luật mới → §13.17) · v2.0 — 2026-11 (chuẩn hoá template đặc tả mode + bộ mockup matchup 9 chế độ) | độ (mìn · điểm ô · chi phí · mực) **CỐ ĐỊNH theo `level_id`**; thêm **nút SKIP LEVEL** trên thanh hành động (chỉ hiện khi chơi MÀN, bấm ⇒ mở khoá màn kế trong chương mà KHÔNG ghi Sao); tool level_designer báo luật riêng theo chế độ → §10.2f) · v2.12 — 2026-09-26 (**THANH HÀNH ĐỘNG MỚI + GIỚI HẠN LƯỢT**: bỏ hẳn 2 nút công cụ VẼ ĐƯỜNG/GHI NHỚ (bàn cờ tự nhận thao tác), **nút CHƠI LẠI dời từ thanh trạng thái xuống thanh hành động** (cả 2 hướng), thêm nút **GỬI BÀI (`Submit`)** cho Wall Builder, **GIỚI HẠN lượt UNDO/HINT mỗi màn** (mặc định 3) + badge **`PanelLimit`** hiện số lượt còn lại và **khoá nút khi hết lượt** → §10.2e) · v2.11 — 2026-09-26 (**HAI KIỂU HIỂN THỊ ĐIỂM**: bản NHÚNG (HUD ngang) = ảnh SẠCH chữ + badge số + DANH SÁCH điểm đầy đủ bên phải; bản POPUP = ảnh giữ NGUYÊN chữ như mockup, KHÔNG badge + KHÔNG khối ĐIỂM (ảnh nở hết bề ngang) — MỌI chữ mô tả trên ảnh đều thành ĐIỂM có hàng trong danh sách → §10.2d) · v2.10 — 2026-09-26 (**SỬA LỖI LẬT TRANG + ẢNH SẠCH**: cụm điều hướng nhúng về **BĂNG ĐÁY khung**, ẩn mọi chữ mô tả trên ảnh) · v2.9 — 2026-09-26 (**BỐ CỤC CỐ ĐỊNH cho hệ hướng dẫn**) · v2.8 — 2026-09-26 (**HƯỚNG DẪN theo mockup landscape**) · v2.7 — 2026-02 (**TÁCH hệ hướng dẫn**) · v2.6 — 2026-02 (**Nền tảng đa tỉ lệ mới**) · v2.5 — 2026-09-19 (**BỎ hẳn Time Attack Maze**) · v2.4 — 2026-09-19 (2 mode mới vào vòng xoay Daily 9 ngày) · v2.3 — 2026-09-19 (**Wall Builder đã lập trình xong** → §5.13 · §13.19) · v2.2 — 2026-09-19 (**One Stroke đã lập trình xong** → §5.12 · §13.18) · v2.1 — 2026-09-18 (đặc tả 2 bộ luật mới → §13.17) · v2.0 — 2026-11 (chuẩn hoá template đặc tả mode + bộ mockup matchup 9 chế độ) |
| **Trạng thái** | Đang phát triển · build Godot 4.7 · màn hình dọc 1080×1920 |
| **Cập nhật tính năng** | 2026-10-10: số lượt Skip/Eraser/Hint được lưu dùng chung toàn game, badge `PanelLimit` hiện số dư, và Debug Console cho phép chỉnh số lượng. |
| **Nguồn sự thật** | **Code là nguồn sự thật cuối cùng**: `scripts/modes/*.gd` · `nodes/hud/*.tscn` · `scenes/game.tscn` · `resources/levels/*.tres`. Tài liệu này mô tả đúng theo code tại thời điểm cập nhật. |
| **Quy ước mode** | 1 bộ luật = 1 `class_name` kế thừa `BaseGameMode`; mỗi mode có `mode_id` (khoá xoay vòng Daily + tra chuỗi `STR_MODE_<ID>`), luật riêng, và **1 mockup matchup** ở mục 10 |

**Template đặc tả mỗi bộ luật (mục 5.1–5.13)** — mọi mode dùng CÙNG bộ 9 trường sau, để đọc/đối chiếu nhanh giữa các mode:

| Trường | Ý nghĩa |
|---|---|
| **Cổng vào** | Màn hình/mục mở được mode · `mode_id` · file mode |
| **Bàn cờ** | Cách sinh bàn: kích thước, tường, ràng buộc bảo đảm màn **luôn thắng được** |
| **Số trên ô** | Con số trên ô nghĩa là gì (tường · mìn · điểm · chi phí · mực · không có số) |
| **Di chuyển** | Số hướng đi · chi phí bước · giới hạn bước/thời gian · công cụ (UNDO/GỢI Ý) |
| **Thắng** | Điều kiện qua màn + thưởng/xếp hạng |
| **Thua** | Điều kiện thua + hành vi khi đâm tường/đạp mìn |
| **Hồi sinh** | Hồi sinh thay đổi những gì (undo bước · +bước · giữ nguyên màn) |
| **HUD** | Scene HUD thật + các thẻ hiển thị + file mockup matchup |
| **Chi tiết** | Diễn giải đầy đủ luật + ghi chú thiết kế/edge case |

**Quy ước màu & chất liệu UI (áp dụng mọi màn hình):** nền giấy kem `#FAF5EB` + lưới vở ô ly 40px `#8FB9D2` + lề đỏ `#D84444`; thẻ HUD là **mẩu giấy trắng** `#FEFDFA` viền xanh `#6EA0C8` / xanh đậm `#3D83AE` / đỏ `#D84444` + **lề sổ tay** cùng màu + **dòng kẻ ngang** `#9FC0D6`; mực chữ `#224C6D`, nhãn phụ `#718B9E`. **Không dùng emoji trong UI thật** — icon là SVG vẽ tay trong `assets/images/icons/`.

## 1. Tổng quan

**Tên game:** Number Maze
**Thể loại:** Puzzle / Logic, chơi trên di động
**Ý tưởng cốt lõi:** Kết hợp lối suy luận kiểu Minesweeper (dùng số để đoán vị trí "tường vô hình") với việc vẽ đường đi trong mê cung, dưới áp lực số bước di chuyển hoặc thời gian có hạn.

Game có **10 bộ luật chơi** (9 bộ luật cũ + **One Stroke** & **Wall Builder** — bổ sung 2026-09-18, đặc tả ở §5.12–5.13; **Time Attack Maze đã BỎ 2026-09-19**) dùng chung 1 bộ khung Grid / S-F / vẽ đường (mục 2–3), nhưng được tổ chức lại thành **3 cổng vào chính** trên Main Screen thay vì liệt kê cả 10 luật ngang hàng — xem mục 4.

Phần thưởng **Sao (Star)** của **mọi match-up** nay do **3 Thử thách (Challenge)** quyết định: hoàn thành 1 Thử thách = 1 Sao (tối đa 3 Sao), **KHÔNG còn tính theo thời gian còn lại** — xem mục 3.1.

---

## 2. Cấu trúc bàn chơi (Grid)

- Grid kích thước linh hoạt từ **2x2, 3x3, 4x4, 5x5** hoặc lớn hơn tùy chế độ / độ khó.
- **Board có thể KHÔNG phải hình chữ nhật**: mỗi màn có thêm `cell_mask` đánh dấu **ô nào thuộc board**,
  nên board có thể là **hình bất kỳ (polyomino)** — ví dụ chữ H, thập tự, vòng có lỗ, chữ U…
  Ô không thuộc board coi như “ngoài board”: không có ô để bước vào, không hiện số, và **viền bao quanh
  board luôn là tường nhìn thấy được**.
- Mỗi ô (cell) có:
  - 4 điểm neo (dot / anchor) ở 4 góc, dùng để kéo nối đánh dấu tường giữa các khe (Tường Nghi Ngờ).
    Góc nào không dính ô nào thuộc board thì không có neo.
  - Con số ở giữa ô (ý nghĩa con số **thay đổi tùy theo chế độ chơi** — xem mục 5).
- Ở các chế độ dùng số làm "tường vô hình" (Dungeon Mode, Play Mode, Fog of War, **Wall Builder**), con số biểu thị **số lượng cạnh GIỮA 2 Ô THUỘC BOARD của ô đó là tường vô hình (0 đến 4)** — cạnh bao quanh board (viền ngoài hoặc giáp ô trống) không tính vào ô; số này không hiển thị mặc định — người chơi phải suy luận để biết cạnh nào là tường thật.
  > Ngoại lệ **Wall Builder (§5.13)**: số hiện **rõ trên MỌI ô** (kể cả số 0) và bàn **KHÔNG có tường sẵn** — người chơi dùng số để **tự vẽ ra tường** rồi bấm GỬI.
- **One Stroke (§5.12)** là chế độ **DUY NHẤT không hiện số** nhưng **tường nhìn thấy rõ** (mọi vách giữa 2 ô + viền ngoài) — thử thách nằm ở **thứ tự đi**, không phải suy luận tường.
- Riêng **Countdown Cost** con số **không liên quan tới tường**: nó là **chi phí bước** của ô (xem mục 5).

---

## 3. Mục tiêu & Luật chơi cơ bản (áp dụng mọi chế độ)

- Có 1 điểm bắt đầu **S** và 1 điểm kết thúc **F** trên grid.
- Người chơi vẽ đường đi bằng cách kéo nối tâm các ô liền kề (lên/xuống/trái/phải), tạo thành một đường liên tục từ S đến F.
- Người chơi có thể kéo nối (drag) giữa các điểm neo (anchor) kề nhau để tự vẽ ra "tường nghi ngờ" nhằm hỗ trợ hình dung — thao tác này **không bắt buộc đúng/sai**, chỉ là công cụ hỗ trợ suy luận cá nhân.

### 3.1. Hệ thống Thử thách & Sao (áp dụng MỌI chế độ)

- Mỗi match-up — mỗi **Màn** (Play Mode), mỗi **Tầng** (Dungeon Mode), mỗi **ngày** (Daily Challenge) — gắn **TỐI ĐA 3 Challenge (thử thách)**.
- **Hoàn thành 1 Challenge ⇒ được thưởng 1 Sao.** Tối đa **3 Sao / match-up** (màn chỉ chọn 2 challenge thì tối đa 2 Sao).
- ❗ **Thay đổi so với bản thiết kế cũ:** Sao **KHÔNG** còn được tính theo **thời gian còn lại**; nay **Sao = số Challenge đã hoàn thành**.
- Trạng thái các Challenge hiển thị **ngay trên HUD khi đang chơi** (panel "THỬ THÁCH" — xem mockup `matchup_level.svg`) và được **tổng kết ở popup kết quả / popup thua** (xem 5.10).
- **Màn cũ / màn không chọn gì** → game tự dùng 3 thử thách mặc định:
  1. `no_wall` — Không đâm vào tường vô hình
  2. `steps_max` — Đi không quá N bước (N = `max_steps` thiết kế của màn)
  3. `time_max` — Về đích dưới T giây (T = N × 3, kẹp trong 30..240 giây)

**Danh sách 17 loại thử thách** (Level Designer cho chọn tối đa 3; lưu vào `LevelData.challenge_types` + `challenge_params`):

| id | Ý nghĩa | Tham số |
|---|---|---|
| `no_wall` | Không đâm vào tường vô hình | – |
| `steps_max` | Đi không quá N bước | N (bước) |
| `time_max` | Về đích dưới T giây | T (giây) |
| `only_numbered` | Chỉ đi vào ô CÓ số (trừ S/F) | – |
| `avoid_numbered` | Không đi vào ô CÓ số | – |
| `no_revisit` | Không đi lại ô đã đi (không lặp lại đường) | – |
| `visit_all` | Đi qua hết mọi ô của board | – |
| `visit_all_numbered` | Đi qua hết mọi ô CÓ số | – |
| `len_min_percent` | Đi tối thiểu n% số ô của board | n (%) |
| `len_max_percent` | Đi tối đa n% số ô của board | n (%) |
| `sum_lt` · `sum_le` · `sum_gt` · `sum_ge` | Tổng số hiện trên các ô đã đi **<** / **≤** / **>** / **≥** N | N |
| `no_hint` | Không dùng nút Gợi ý lần nào | – |
| `no_undo` | Không dùng nút Hoàn tác lần nào | – |
| `no_wrong_submit` | **Gửi bàn tường đúng ngay lần GỬI đầu tiên** (chỉ dùng cho Wall Builder) — ĐÃ LẬP TRÌNH 2026-09-19 | – |

> Ô **"có số"** = ô mà chế độ chơi đang hiện số (Play/Dungeon/Fog: số tường quanh ô > 0 · **Wall Builder: số tường quanh ô ≥ 0** · Minesweeper: số mìn · Sum Path / Countdown Cost: giá trị riêng). S và F **không** tính là ô có số — riêng **Wall Builder không có S/F**.
> **Level Designer kiểm tra trước khi lưu:** mâu thuẫn `only_numbered` + `avoid_numbered`, `steps_max` nhỏ hơn đường đi ngắn nhất, `len_max_percent` nhỏ hơn độ dài đường ngắn nhất, `visit_all` khi có ô không tới được, `sum_gt/ge` lớn hơn tổng số tối đa của board… và cảnh báo khi màn không có ô nào hiện số.

---

## 4. Hai cổng chính + Danh sách Sự kiện (Main Screen)

Theo mockup `mainscreen.svg` / `mainscreen_landscape.svg` mới nhất (v2.21), Main Screen **không còn 3 thẻ chế độ lớn** và không liệt kê 9 luật chơi ngang hàng. Bố cục mới gồm **thanh trên** + **khối Sự kiện** (carousel thẻ dọc) + **2 thẻ chế độ thường trực** + **dock 4 nút**.

| Khối | Nội dung |
|---|---|
| **Thanh trên** | Thẻ **Hồ sơ** (avatar · khung · cấp · tên · thanh XP) · **ví Xu** (`+` mở Cửa hàng) · **tổng Sao** · nút **Cài đặt** (bánh răng) |
| **Khối Sự kiện** | Tiêu đề (badge cam = số event đang mở) + **carousel thẻ dọc 340×504** + chấm phân trang. **Daily Challenge là event ghim ĐẦU danh sách** |
| **2 thẻ chế độ** (`ModeCard`) | **PLAY · CHỌN MÀN** (Play Mode — chọn màn theo chương) · **DUNGEON MODE** (vô tận) |
| **Dock 4 nút** | **Cửa hàng** · **Xếp hạng** · **Danh hiệu** (Sổ tay thành tựu) · **Luật chơi** (Tutorial) |

**Nguyên tắc quan trọng:** Chỉ có **Play Mode** và **Dungeon Mode** là 2 chế độ "thường trực" người chơi vào bất cứ lúc nào (2 thẻ giấy `ModeCard`). **8 bộ luật còn lại** (Minesweeper Maze, **Fading Ink**, Sum Path, Countdown Cost, Blind Memory Maze, Fog of War Maze, **One Stroke**, **Wall Builder**) **không tồn tại như mục chọn riêng** — chúng chỉ xuất hiện qua **Daily Challenge** (luân phiên mỗi ngày — mục 6) và qua **Event** (event dùng lại chính các luật này — xem **§15**).

> **BỎ so với bản v2.20:** tờ giấy lớn (`NinePatchRect` `main_menu_paper.svg`) + lỗ bấm sổ còng + kẹp giấy + băng washi; thẻ **DAILY CHALLENGE** riêng (Daily chuyển vào danh sách Sự kiện); khối **Hero** (logo + tag + con dấu + nút **DANH HIỆU 224×224**) và **hàng 3 nút nhỏ** `btn_menu_utility_*`.
>
> **GIỮ:** nền `Background` (giấy kem + lưới ô ly + lề đỏ + 2 dải `SideL`/`SideR`), logic điều hướng, hiệu ứng bấm nút.

### 4.1. Thanh trên & dock

| Thành phần | Nội dung / hành vi |
|---|---|
| `ProfileCard` | avatar tròn + khung + chip `LV.xx` + tên + thanh XP mini + `x / y XP`. Bấm → **popup Hồ sơ** |
| `CoinChip` | icon Xu Mực vàng + số Xu + nút `+` → mở **Cửa hàng**. Dùng CHUNG toàn game (xem §4.2) |
| `StarChip` | icon Sao + **tổng Sao** (nguồn `GameManager.total_stars()` — cùng số dùng mở khoá chương §12.3) |
| `Settings` | bánh răng → màn **Settings** |
| `DockShop` | → Cửa hàng (art `btn_menu_utility_*` 9-slice, nhãn `STR_BTN_SHOP`) |
| `DockRanking` | → Bảng xếp hạng (§11) |
| `DockBadges` | → Sổ tay thành tựu (§8); có badge đỏ khi có danh hiệu chưa nhận |
| `DockRules` | → màn **Tutorial** (7 bài §9.2) |

- Mọi nút dock dùng chung khuôn giấy `btn_menu_utility_*` (StyleBoxTexture 9-slice, margin 20) — **không kéo méo art**.

### 4.2. Hai chip dùng chung khai trong `base_layout`, ẩn/hiện khai trong `.tscn` (v2.41)

**1. Một chỗ khai duy nhất.** `scenes/layout/base_layout.tscn` khai **`TopBar/CoinChip`** (Xu Mực) và
**`TopBar/LifeChip`** (lượt chơi) — mọi layout đều kế thừa nên **không layout nào khai lại chip**.

| Cơ chế | Chi tiết |
|---|---|
| Hiện/ẩn chip | Khai **trong `.tscn` của từng màn** bằng block override thuộc tính của node kế thừa (không `type=`): `[node name="CoinChip" parent="TopBar"]` + `visible = false` (và `LifeChip`). `BaseLayout` **không** còn `toggle_visible`/`_apply_chip_visibility()` |
| THỨ TỰ chip | Do **chính file `.tscn`** quyết định bằng `index` của từng node — **KHÔNG di chuyển node lúc chạy** (đã bỏ `move_child` của `_setup_shared_chips`) |
| Override theo màn | Layout ghi đè thuộc tính của node kế thừa (không khai `type=`): VD Shop đặt `navigate_on_plus = false`, size riêng, `index` riêng |
| `can_animate_bar(node)` | `TopBar` dùng chung bị `header_anchor` đồng bộ vị trí mỗi frame ⇒ KHÔNG chạy hiệu ứng trượt cho chính nó (tránh giật); thanh riêng của màn vẫn trượt bình thường |

**2. Thứ tự icon trên thanh trên** (giữ đúng như thiết kế gốc):

| Màn | Thứ tự trong `TopBar` |
|---|---|
| Main (dọc & ngang) | ProfileCard → (SpacerL · LogoBlock · SpacerR) → **CoinChip → LifeChip** → StarChip → Settings |
| Chapters · Levels · Ranking · Archivement · Credit · Debug | Back → Title(giãn) → [Wallet/StarsCounter/Chip] → **CoinChip → LifeChip** |
| Daily · Shop · Game · Event dọc · Tutorial | khối thanh trên riêng của màn → **CoinChip → LifeChip** |
| Title | `TopBarSpacer` → chip (chip bị ẩn bằng `visible = false` trong `.tscn`) |

**3. Màn ẩn chip (`visible = false` trong `.tscn`)** — cả 2 hướng: **Settings · Tutorial · Splash · Title ·
Profiler popup**. Ngoài ra **`landscape/event`** cũng ẩn chip dùng chung vì thanh trên của màn này là
**CỘT DỌC 36 px** bên trái (tiêu đề nằm trong hàng tiêu đề của nội dung) — màn tự khai 2 chip cục bộ
đặt trong `Content/Body/BodyContent/TitleRow` (`LAYOUT_LOCAL_CHIPS` trong `test_life_points`).

**4. `CoinChip`** (`scripts/nodes/coin_chip.gd`): `_ready()` đọc `Shop.coins()`, nghe
`ArchivementManager.progress_changed` để tự cập nhật; nút `+` = `Sfx.BTN_CLICK` + `Nav.goto_shop()`.
Shop đặt `navigate_on_plus = false` để `+` chỉ chuyển tab NẠP XU.

**5. `LifeChip`** (`scripts/nodes/life_chip.gd`): nhãn `3/5`, tự nghe `GameManager.life_changed`,
nút `+` **chỉ hiện khi chưa đầy lượt** (`hide_plus_when_full`) → mở Cửa hàng (Shop: mở tab DỤNG CỤ).

**6. Shop dùng đúng 2 chip này** (đã xoá `Wallet` riêng từ v2.35):

- `ShopLayout.wallet_count` → `TopBar/CoinChip/Content/Value` · `wallet_plus` → `…/Content/Plus` ·
  `wallet_bar` → `TopBar/CoinChip` · `life_chip` → `TopBar/LifeChip`.
- Animation `wallet_pop` trỏ `TopBar/CoinChip/Content/Value:scale` (khai
  `libraries = { "": SubResource(...) }` — cú pháp `libraries/ = …` cho **thư viện rỗng**).
- Dọc: chip override 128×35 (sau khối `HeaderRow` dùng định vị tuyệt đối); ngang: Xu 110×38 · Lượt 72×38
  + `show_max = false` (cột trái hẹp 370 px).

> **Phân biệt:** `nodes/shop/coin_tile.tscn` **KHÔNG phải ví** — đây là **thẻ gói nạp Xu** (475×240)
> dùng ở tab NẠP XU, nên vẫn giữ nguyên.

**7. Bẫy đã sửa (2026-10-20):** `UIAnim.play_slide_in()` trước đây tween `position` — với node **neo
phải** (chip trong thanh trên) Godot biến `position` thành offsets tuyệt đối NGAY LÚC thanh chưa dàn
xong bề rộng ⇒ chip bị "đóng băng" ở toạ độ cũ và **văng ra ngoài màn hình** (bug: mất ví Xu ở Cửa
hàng). Nay hiệu ứng trượt tween **`offset_left/top/right/bottom`** nên neo luôn giữ nguyên.

**8. Kiểm thử:** `test_life_points` gác "base_layout có đúng 1 `CoinChip` + 1 `LifeChip` · layout không
khai lại chip (trừ ngoại lệ `landscape/event`) · 2 chip dùng chung được ẩn đúng cách bằng `visible = false`
khai trong `.tscn` của từng màn"; `test_shop` gác
"2 chip nằm trong màn hình · bám mép phải ≤ 40 px · Xu ở bên trái Lượt chơi"; `test_main_layout` gác
"thanh trên KHÔNG còn `HeaderRow` · thứ tự Hồ sơ → Xu → Lượt → Sao → Cài đặt".


### 4.3. Mọi thanh trên nằm trong `TopBar` của `base_layout` (v2.36)

Trước đây nhiều layout tự khai `TopBar`/`Header` ở giữa cây (trong `Body`, `Panel/Stage`,
`Content/InformationArea`, cột trái…) nên mỗi màn một kiểu. Nay **toàn bộ nội dung thanh trên**
(Back · Title · chips · nút Pause/Help · hồ sơ…) nằm dưới **`TopBar` dùng chung** của
`scenes/layout/base_layout.tscn`.

**1. Cấu trúc chuẩn**

```
BaseLayout
└─ TopBar (HBoxContainer, z_index = 10, mouse_filter = IGNORE)
   ├─ Back · Title · StarChip · Settings · …   (content của từng màn — khai TRỰC TIẾP, có `index`)
   ├─ CoinChip                                (base_layout — vị trí do `index` trong .tscn)
   └─ LifeChip                                (base_layout — màn không cần ví ẩn bằng `visible = false` trong .tscn)
```

- Nội dung thanh trên của mọi màn khai **TRỰC TIẾP trong `TopBar`** kèm `index` (đã là node kế thừa của `base_layout`;
  KHÔNG khai lại `type`). Thứ tự icon giữ như thiết kế gốc — xem bảng ở §4.2.
- Màn cần ĐỊNH VỊ TUYỆT ĐỐI hoặc xếp DỌC cho thanh trên vẫn giữ một node bao (`HeaderRow` — Control/VBox)
  làm khung: Daily (dọc/ngang) · Shop dọc · Game ngang (có nền `Bg`) · Event ngang (cột dọc) · Profiler popup.
  Các màn còn lại (Main · Chapters · Levels · Ranking · Archivement · Credit · Debug · Game dọc · Event dọc ·
  Tutorial · Shop ngang) đã bỏ node bao — content nằm phẳng trong `TopBar`.
- `z_index = 10`: thanh trên luôn nổi trên nội dung màn nhưng vẫn **dưới `Popups` (z = 20)** của
  `scenes/base.tscn`, nên popup Tạm dừng/Thắng/Thua không bị thanh trên che.

**2. Giữ đúng vị trí/kích thước/tỉ lệ: `TopBarAnchor` + `header_anchor`**

- Tại vị trí cũ trong layout, transformer để lại **`TopBarAnchor`** (Control vô hình, không chặn input).
  Node này giữ anchors/offsets/min-size cũ ⇒ các container (VBox/HBox) vẫn chừa đúng chỗ, nội dung
  bên dưới không bị đẩy lên.
- Root layout khai `@export var header_anchor: Control` trỏ tới neo đó. `BaseLayout._process()` chép
  `global_position` · `size` · `global scale` của neo sang `TopBar` ⇒ đúng cả khi thanh cũ nằm trong
  `Panel/Stage` (Daily) hay `Scaler/Body` (Main ngang) hoặc khi xoay màn hình.
- `TopBarAnchor.custom_minimum_size.y` được cập nhật bằng **chiều cao tối thiểu của nội dung thanh**
  (`BaseLayout._content_min_height()` — bỏ qua 2 chip) để container không co neo về 0; bề rộng của neo
  giữ nguyên theo thiết kế nên không bị 2 chip đẩy rộng.

**3. Dọn đường dẫn & kiểm thử**

- Toàn bộ `NodePath` export, `[connection]` trong `scenes/*.tscn` (Daily · Levels · Game · Shop ·
  Chapters · Tutorial · Profiler), track AnimationPlayer (`…/TopBar:modulate`) và test dùng đường dẫn
  cũ đã đổi sang `TopBar/HeaderRow/…`.
- `test_layout_bindings` coi `header_anchor` là export **TUỲ CHỌN** (màn không có thanh cục bộ thì null).
- Đã xác nhận: mọi layout instantiate không còn cảnh báo “parent path … has vanished”; mỗi màn hình có
  đúng **1 `TopBar`**, rect của `TopBar` trùng `TopBarAnchor` ở cả 2 hướng; `test_shop` 260/260 ·
  `test_splash_title_shop_chapters` PASS · `test_level_special_modes` 141/141 ·
  `test_game_scene_integration` PASS · `test_tutorial_flow` 83/83 · `test_profiler` 134/134.
- 2 thẻ chế độ dùng art **`card_mode_normal/pressed/focus/disabled`** qua `StyleBoxTexture` 9-slice (margin trái 40 · trên 30 · phải 60 · dưới 24 đọc từ art 402×155) ⇒ **đóng mục "CÒN LẠI" số 5 của §13.23** (art thẻ không còn bị kéo ngang ở layout ngang).

---

## 5. Chi tiết từng bộ luật chơi

| Bộ luật | Thuộc cổng | Ý nghĩa con số trên ô | Xử lý khi đâm tường | Điều kiện Thắng / Mục tiêu |
|---|---|---|---|---|
| **Play Mode** | Play · Chọn màn | Số tường quanh ô (0..4) | **Game Over ngay** (hồi sinh: quay lại bước trước đó) | Đến F an toàn, xếp hạng theo thời gian nhanh nhất |
| **Dungeon Mode** | Dungeon | Số tường quanh ô (0..4) | Về lại S, trừ 1 bước | Vượt qua càng nhiều Floor càng tốt (chế độ DUY NHẤT có bộ đếm bước còn lại) |
| Minesweeper Maze | Daily Challenge | Số mìn quanh ô (0..8) | Đạp mìn: **THUA NGAY** (nổ, đứng nguyên tại ô, hiện biểu tượng Bomb, giữ nguyên số) | Tránh các ô mìn ẩn, đến đích F an toàn |
| Fading Ink | Daily Challenge | **MỰC của ô** (giá trị riêng, KHÔNG liên quan tường) — giảm 1 mỗi bước đi | Không có tường; ô hết mực = không đi vào được (không mất bước) | Đến F trước khi mực phai hết; hết lối đi = THUA |
| Sum Path | Daily Challenge | Điểm số của ô (1..9) | Không có tường | Đến F với tổng điểm thỏa `SUM < / > / = Target` |
| Countdown Cost | Daily Challenge | **Chi phí bước** của ô (số riêng, KHÔNG liên quan tường) | Về lại S, trừ theo ô đích | Đến F với ngân sách bước hạn chế, tối ưu chi phí |
| Blind Memory Maze | Daily Challenge | Không có số (ẩn hoàn toàn) | Tùy chọn (về S hoặc thua ngay) | Ghi nhớ tường khi Countdown (3..2..1) rồi đi khi tường ẩn |
| Fog of War Maze | Daily Challenge | Số tường (chỉ hiện ô gần) | Về S + **trừ 1 LƯỢT THỬ** (3 lượt — §13.16) | Dò đường trong sương mù quanh vị trí nhân vật |
| **One Stroke** | Daily Challenge | **KHÔNG có số** — tường **hiện rõ** | Không có tường vô hình (đi vào tường chỉ là nước đi bị từ chối) | Đi qua **TẤT CẢ các ô, mỗi ô đúng 1 lần**, rồi kết thúc ở **F** |
| **Wall Builder** | Daily Challenge | Số tường quanh ô (0..4) — hiện trên **MỌI** ô | Không có di chuyển / đâm tường | **Vẽ đủ tường** khớp mọi con số rồi bấm **GỬI** (3 lượt gửi) |
> **Quy ước "Số tường quanh ô":** chỉ tính **4 cạnh bên trong board** (kể cả tường vô hình). **Tường viền bao quanh board KHÔNG tính vào ô** — nếu tính thì mọi ô sát biên đều bị cộng thêm (ô góc +2) và con số mất ý nghĩa. Viền ngoài vẫn **chặn đường đi như cũ**, chỉ không được đếm.
> ⇒ Ô sát biên tối đa 3, ô giữa board tối đa 4, ô trống hoàn toàn = 0 (không hiện số).

> **Quy ước "Số bước":** **CHỈ Dungeon Mode có bộ đếm số bước còn lại** (thẻ **SỐ BƯỚC** + thẻ **TẦNG** trên HUD — xem `matchup_dungeon.svg`). **Mọi chế độ khác KHÔNG giới hạn và KHÔNG hiển thị số bước còn lại** — Play Mode chỉ hiện thẻ **THỬ THÁCH** + **THỜI GIAN** (`matchup_level.svg`), các bộ luật Daily hiện tài nguyên riêng của chúng (đồng hồ, điểm, số mìn...). *Ngoại lệ duy nhất:* **Countdown Cost** vẫn dùng **ngân sách bước**, vì đó chính là cơ chế cốt lõi của bộ luật này (xem 5.3–5.9).

> **Bố cục HUD màn chơi (bộ mockup matchup — xem mục 10):** khung thẻ rộng **980px** (x = 50 → 1030) nằm tại `y = 175..424`; mỗi chế độ có 1 mockup `mockup/matchup_<mode>.svg` vẽ đúng hàng thẻ của mình:
> - **Play Mode** (`matchup_level.svg`): thẻ **THỜI GIAN** 250×138 bên trái + thẻ **THỬ THÁCH** 720×156 bên phải.
>   Thẻ THỬ THÁCH gồm cột tổng kết (**số Thử thách đã đạt** `x/3 ✓` + dòng `n ĐÃ HOÀN THÀNH`) và **3 dải thử thách** 490×42: **ô tích đỏ** = đã đạt (kèm nhãn đỏ `✓ ĐẠT`), **ô chờ tích** (nét đứt) = chưa đạt (kèm tiến độ ở góc phải).
> - **Dungeon Mode** (`matchup_dungeon.svg`): thẻ **THỜI GIAN** 250×138 + thẻ **SỐ BƯỚC** 440×158 (viền đỏ, con số lớn 72px — KHÔNG còn dạng `14/20`) + thẻ **TẦNG** 250×138.
> - **Minesweeper Maze**: thẻ **THỜI GIAN** 250×138 + thẻ **BOM CÒN LẠI** 440×158 — art `card_bomb.svg` (mẩu giấy viền ĐỎ + lề đỏ + dòng kẻ ngang kiểu vở) + **sticker icon_bomb** bên phải, con số `còn/tổng` mực đỏ 72px. Panel MISSION cũ được thay bằng thẻ Bomb.
> - **Sum Path**: thẻ **THỜI GIAN** 250×138 + thẻ **TỔNG HIỆN TẠI** 440×158 (`card_sum.svg` — viền xanh đậm, mực xanh, dòng kẻ ngang) + **thẻ TOÁN TỬ 112×112** (`card_op.svg`, nằm CHÍNH GIỮA thẻ Tổng và thẻ Mục tiêu, đè lên mép 2 thẻ — dạng `12 = 23`, ký hiệu mực ĐỎ) + thẻ **MỤC TIÊU** 250×138 (chỉ hiện con số). Panel MISSION cũ được thay bằng 3 thẻ này.
> - **Blind Memory**: thẻ **THỜI GIAN** 250×138 + thẻ **GHI NHỚ VỊ TRÍ TƯỜNG** 440×158 (`card_sum.svg`) — **KHÔNG có thẻ THỬ THÁCH** (`mockup/matchup_blind_memory.svg`).
> - **HUD mặc định `LevelHUD`** (THỜI GIAN + THỬ THÁCH) dùng cho **Play Mode**. Countdown Cost / Fading Ink / Sum Path / Blind Memory / One Stroke / Wall Builder / Fog of War có HUD riêng (mục 10.2b).
> - **Chất liệu HUD (từ 2026-11):** mọi thẻ là **mẩu giấy trắng trên nền vở kẻ ngang** — viền màu (xanh `#6EA0C8` / xanh đậm `#3D83AE` / đỏ `#D84444`) + lề sổ tay cùng màu + **dòng kẻ ngang** `#9FC0D6` (opacity 0.5) như trang vở. Art dùng cho các HUD mới: `card_time_slip.svg` (250×138), `card_bomb.svg` (440×158), `card_sum.svg` (440×158), `card_op.svg` (112×112).
> - Tiêu đề game: Dungeon = `DUNGEON MODE` (một dòng, số tầng đã chuyển xuống thẻ TẦNG); Play Mode = dòng phụ đỏ `PLAY MODE · CHƯƠNG n` + dòng lớn `MÀN xx`.

> **Kiến trúc HUD (tách thành scene theo chế độ):** khung **Information** trong `scenes/game.tscn` không còn chứa sẵn mọi thẻ — mỗi chế độ có 1 scene HUD riêng, tất cả đều kế thừa `nodes/hud/base.tscn` (khung 980×249 tại `(50,175)`, script `scripts/nodes/hud/base.gd`):
> - `nodes/hud/level_mode.tscn` → `LevelHUD` — thẻ **THỬ THÁCH** + **THỜI GIAN** (Play Mode và các bộ luật không có thẻ riêng).
> - **One Stroke / Wall Builder / Fog of War** có HUD riêng (mục 10.2b).
> - `nodes/hud/dungeon_mode.tscn` → `DungeonHUD` — **SỐ BƯỚC** + **THỜI GIAN** + **TẦNG**.
> - `nodes/hud/minesweep_hud.tscn` → `MinesweepHUD` — **BOM CÒN LẠI** + **THỜI GIAN**.
> - `nodes/hud/sum_path_hud.tscn` → `SumPathHUD` — **TỔNG HIỆN TẠI** + **TOÁN TỬ** (giữa) + **MỤC TIÊU** + **THỜI GIAN**.
> - `nodes/hud/blind_memory_hud.tscn` → `BlindMemoryHUD` — **THỜI GIAN** + thẻ **GHI NHỚ VỊ TRÍ TƯỜNG** (không có thẻ Thử thách).
>
> `GameScene._apply_hud_for_mode()` thay node HUD đúng lúc đổi chế độ rồi gắn lại cho `UIController.set_hud()` (vẽ số liệu) và `ChallengeController.card` (chỉ LevelHUD có thẻ Thử thách). Mỗi HUD nhận dữ liệu qua `update_hud(ctx)` với các khoá `title / subtitle / steps_remaining / elapsed_time / floor_number / extra / mode`.
### 5.1. 🎯 Play Mode (Level Selection) *(đổi tên từ "Classic Maze" / "Level Maze")*

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Nút **PLAY** trên Main Screen · `mode_id = play` (`standard_game_mode.gd`) |
| **Bàn cờ** | Theo dữ liệu Màn trong `resources/levels/level_*.tres` (kích thước, tường, `cell_mask` polyomino, 3 thử thách riêng) |
| **Số trên ô** | **Số tường quanh ô** (0..4, chỉ tính 4 cạnh bên trong board — xem quy ước ở đầu mục 5) — hiện cả tường vô hình |
| **Di chuyển** | 4 hướng (không đi chéo) · **không giới hạn số bước** · kéo từ tâm ô / bấm ô kề · có **UNDO** + **GỢI Ý** |
| **Thắng** | Tới F · 3 thử thách chốt khi kết thúc → tối đa 3 Sao · xếp hạng theo **thời gian nhanh nhất** |
| **Thua** | **Đâm tường vô hình = THUA NGAY** (giữ nguyên vị trí + xử lý ở popup) |
| **Hồi sinh** | **Quay lại ô ngay trước đó** (undo bước vừa đi, không cộng bước) — xem 5.10 |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`): **THỜI GIAN** + **THỬ THÁCH** · mockup `mockup/matchup_level.svg` |
| **Chi tiết** | Xem bên dưới |

> Đây là **chế độ chính, cửa vào đầu tiên của game** — thay cho khái niệm "chọn độ khó Dễ/Vừa/Khó" ở bản thiết kế cũ.

- Theo mockup `level_selection.svg`: màn chơi được tổ chức thành **Chương (Chapter)**, mỗi Chương có kích thước lưới cố định (ví dụ *"CHƯƠNG 1: BÀN CỜ NHẬP MÔN (7×7)"*), gồm nhiều **Màn (Level)** đánh số tuần tự (Màn 01, 02, 03...).
- Người chơi chọn đúng 1 Màn cụ thể để chơi, không còn chọn độ khó tổng quát — độ khó tăng dần tự nhiên theo số thứ tự Màn và theo Chương.
- Có thanh tiến trình phần trăm hoàn thành theo Chương (ví dụ "65%"), nút "TIẾP TỤC MÀN 07" để chơi tiếp Màn dở dang gần nhất, và nút "ĐỔI CHƯƠNG" để chuyển giữa các Chương đã mở khóa.
- Mỗi Màn: **Đâm vào tường vô hình = Game Over ngay lập tức** — không có cơ hội quay về S thử lại (giữ nguyên tinh thần "một-lần-ăn-cả" của Classic Maze cũ). Người chơi có thể **hồi sinh bằng cách quay lại bước trước đó** (xem 5.10).
- **Không có giới hạn số bước:** Play Mode **không** dùng bộ đếm bước. HUD của màn chơi chỉ gồm thẻ **THỬ THÁCH** (3 thử thách + ô tích đỏ đã đạt) và thẻ **THỜI GIAN** — theo mockup `matchup_level.svg`; đã bỏ hẳn thẻ số bước và thẻ điểm của bản Dungeon cũ.
- Mỗi Màn có **3 Thử thách**; hoàn thành 1 Thử thách = **1 Sao** (tối đa 3 Sao) — xem 3.1. Tổng kết ở popup thắng màn `popup_win_level.svg`, còn popup thua là `popup_game_over_level.svg`.
- Bảng xếp hạng theo **Thời gian hoàn thành nhanh nhất (Fastest Clear Time)** cho từng Màn.

### 5.2. 🏰 Dungeon Mode

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Nút **DUNGEON** trên Main Screen · `mode_id = dungeon` (`dungeon_game_mode.gd`) |
| **Bàn cờ** | Sinh theo Tầng: kích thước + mật độ tường tăng dần (`FloorController.setup_floor`) |
| **Số trên ô** | **Số tường quanh ô** (0..4) · tỉ lệ tường **hiện sẵn** giảm dần theo Tầng (về 0% ở tầng sâu) |
| **Di chuyển** | 4 hướng · có **bộ đếm bước còn lại** (duy nhất trong game) · UNDO + GỢI Ý |
| **Thắng** | Tới F → cộng điểm + thưởng bước → sang **Tầng kế tiếp** (endless, không có màn cuối) |
| **Thua** | **Hết bước** (đâm tường không thua ngay — chỉ về S và mất 1 bước) |
| **Hồi sinh** | **+N bước** (`revive_bonus_steps`, mặc định 3) và **giữ nguyên 100%** mê cung · vị trí · đường vẽ · tường đã lộ |
| **HUD** | `nodes/hud/dungeon_mode.tscn` (`DungeonHUD`): **SỐ BƯỚC** + **THỜI GIAN** + **TẦNG** · mockup `mockup/matchup_dungeon.svg` |
| **Chi tiết** | Xem bên dưới |

- Chế độ endless, chơi qua nhiều Floor liên tiếp — càng đi sâu càng khó.
- Áp dụng cơ chế **Endless Visible Wall**: tỉ lệ tường hiển thị (visible) giảm dần liên tục theo mỗi Floor càng lên cao, tiến tới 0% ở các floor sâu.
- Đâm tường vô hình: trừ 1 bước, lộ tường thật, rung bàn cờ và đưa nhân vật về điểm S.
- Đến đích F: cộng điểm (Base Score, Move Bonus, Time Bonus, Perfect Floor) và thưởng thêm số bước cho Floor tiếp theo.
- ⚠️ **Dungeon Mode là chế độ DUY NHẤT có bộ đếm số bước còn lại** (thẻ **SỐ BƯỚC** + thẻ **TẦNG** trên HUD, theo mockup `matchup_dungeon.svg`; thẻ chỉ hiện con số bước còn lại, không có `/max`). Hết bước = thua Tầng; **hồi sinh = nhận thêm +3 bước** để đi tiếp ở đúng Tầng hiện tại, **giữ nguyên mê cung — vị trí nhân vật — đường đã vẽ — tường đã lộ** (không sinh lại màn, popup `popup_game_over_dungeon.svg`, xem 5.10).
- Mỗi Tầng có **3 Thử thách**; hoàn thành 1 Thử thách = 1 Sao (tối đa 3 Sao) — xem 3.1.
- Theo mockup `matchup_dungeon.svg`: màn chơi có thêm nút **UNDO** (hoàn tác bước vừa đi) và **GỢI Ý** (Hint) bên cạnh thao tác "VẼ ĐƯỜNG" (kéo từ tâm ô) và "GHI NHỚ" (nối 2 Anchor để đánh dấu tường nghi ngờ) — bổ sung so với bản thiết kế UX trước đó (mục 9).

### 5.3–5.9 · 5.12–5.13. Chín bộ luật chỉ chơi được qua Daily Challenge

Nội dung luật của từng bộ **giữ nguyên như bản thiết kế trước**, chỉ khác về **cách truy cập**: không còn là mục chọn độc lập trên Main Screen, mà là **nội dung xoay vòng theo ngày** trong Daily Challenge (`GameManager.DAILY_MODES`, xem mục 6).

> **2 bộ luật mới (2026-09-18):** **One Stroke** (`one_stroke`) và **Wall Builder** (`wall_builder`) được đặc tả ở **§5.12–5.13** — đặt sau §5.10–5.11 để **không phải đánh số lại** các mục đang được tham chiếu ở nhiều nơi trong tài liệu.

Mỗi bộ luật dưới đây được đặc tả theo **cùng một template**: Cổng vào · Bàn cờ · Số trên ô · Di chuyển · Thắng · Thua · Hồi sinh · HUD & mockup · Chi tiết.

### 5.3. ⏱ Time Attack Maze — ❌ ĐÃ BỎ (2026-09-19)

> Chế độ này **đã được xoá khỏi game** theo yêu cầu (2026-09-19): xoá mode + HUD + popup hướng dẫn + asset + vòng xoay Daily.
> Phần đặc tả cũ được giữ trong lịch sử ở §13.20 và các mục §13.x trước đó. Danh mục mode hiện tại xem bảng đầu mục 5.
> *(Khoá dịch `STR_MODE_TIME_ATTACK` / `STR_HINT_TIME_ATTACK` vẫn giữ trong `string_extra.csv` để save cũ không hiện khoá thô.)*

<details><summary><b>Đặc tả CŨ (giữ để tham khảo lịch sử — KHÔNG còn hiệu lực)</b></summary>

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · `mode_id = time_attack` |
| **Bàn cờ** | Sinh theo Tầng/độ khó, tường vô hình |
| **Số trên ô** | Số tường quanh ô (0..4) |
| **Di chuyển** | 4 hướng · **không giới hạn bước** · đâm tường về S và mất thời gian |
| **Thắng** | Tới F trước khi đồng hồ đếm ngược về 0 |
| **Thua** | **Hết giờ** |
| **Hồi sinh** | Quay lại bước trước đó (undo) |
| **HUD** | `nodes/hud/time_attack_hud.tscn` (`TimeAttackHUD`) — **CHỈ thẻ THỜI GIAN phóng to GIỮA khung** (anchors tỉ lệ, ≈291×206 — đếm ngược + dòng phụ "ĐẾM NGƯỢC", số tự co), **KHÔNG có thẻ THỬ THÁCH** (2026-09-19) · mockup `mockup/matchup_time_attack.svg` (đã sinh lại theo HUD này) |
| **Chi tiết** | ✨ **⏱ Time Attack Maze** — Giới hạn thời gian tổng (60s/90s/120s) đếm ngược, không giới hạn số bước. Đâm tường về S mất thời gian. Hết giờ = Game Over. HUD chỉ để **đồng hồ đếm ngược ở giữa** cho tập trung; 3 Thử thách vẫn được chấm và hiện đầy đủ ở popup kết quả. |

</details>

### 5.4. 💣 Minesweeper Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (màn khai `mode_id = minesweeper` trong LevelData → chơi TRÊN BÀN NHÀ THIẾT KẾ VẼ — §10.2f) |
| **Bàn cờ** | Vuông **`2 + tầng`, kẹp 3..5** (tầng 1 = 3×3) · **không tường trong** · luôn có đường BFS **không mìn** từ S tới F · mật độ mìn `min(0.18 + tầng×0.03, 0.32)` |
| **Số trên ô** | Số mìn trong **8 ô lân cận** (0..8) · S/F luôn an toàn |
| **Di chuyển** | 4 hướng · mỗi bước 1 điểm · hồi sinh = quay lại ô trước đó |
| **Thắng** | Tới F mà không đạp mìn |
| **Thua** | **Đạp mìn = THUA NGAY** — đứng nguyên tại ô, hiện **icon Bomb** (giữ nguyên con số), HUD **BOM CÒN LẠI** giảm 1 rồi mở popup thua |
| **Hồi sinh** | Quay lại ô ngay trước đó |
| **HUD** | `nodes/hud/minesweep_hud.tscn` (`MinesweepHUD`): **BOM CÒN LẠI** + **THỜI GIAN** · mockup `mockup/matchup_minesweeper.svg` |
| **Chi tiết** | ✨ **💣 Minesweeper Maze** — Số trên ô = số mìn trong 8 ô lân cận. S/F luôn an toàn, luôn tồn tại ít nhất 1 đường BFS không mìn. **Đạp mìn = THUA NGAY** (giống Play Mode đâm tường): nhân vật **đứng nguyên tại ô vừa nổ** (không bị đưa về S), trừ 1 bước rồi mở **popup thua**; ô đó hiện **biểu tượng Bomb to ở giữa ô** (icon `game/icon_bomb.svg`) nhưng **giữ nguyên con số** — số nằm ĐÈ LÊN icon (có viền màu giấy cho dễ đọc). HUD hiện thẻ **BOM CÒN LẠI** dạng `còn/tổng` (giảm 1 mỗi quả đã nổ). Hồi sinh = quay lại ô ngay trước đó. |

### 5.5. 🧠 Blind Memory Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (`mode_id = blind_memory` — §10.2f) |
| **Bàn cờ** | Thường: 4×4 · Hardcore: 5×5 · tường vô hình, **không hiện số** |
| **Số trên ô** | **Không có số** (chỉ S/F) — người chơi phải **ghi nhớ** vị trí tường |
| **Di chuyển** | 4 hướng · bị **khoá tương tác** trong lúc đếm ngược · có UNDO + GỢI Ý |
| **Thắng** | Tới F sau khi tường đã ẩn, đi bằng trí nhớ |
| **Thua** | Hết giờ · Hardcore: đâm tường = thua ngay (Thường: về S) |
| **Hωi sinh** | Quay lại bước trước đó |
| **HUD** | `nodes/hud/blind_memory_hud.tscn` (`BlindMemoryHUD`): **THỜI GIAN** + thẻ **GHI NHỚ VỊ TRÍ TƯỜNG** (**KHÔNG có thẻ Thử thách**) · mockup `mockup/matchup_blind_memory.svg` |
| **Popup riêng** | `nodes/popups/memory_countdown.tscn` — mẩu giấy đếm ngược **3 → 2 → 1 → GO!**, **không nền mờ** (vẫn thấy mê cung) |
| **Chi tiết** | * **🧠 Blind Memory Maze** — Không số. **Pha GHI NHỚ khi vào màn:** hiện **toàn bộ tường thật** + mở **popup giấy đếm ngược `3 → 2 → 1 → GO!`** (`nodes/popups/memory_countdown.tscn`, **không có nền mờ** nên vẫn nhìn rõ mê cung), **khoá tương tác** và **đồng hồ ĐỨNG YÊN** (thời gian ghi nhớ không tính vào giờ chơi). Hết đếm ngược: tường ẩn hoàn toàn, mở tương tác, đồng hồ bắt đầu chạy — người chơi đi bằng trí nhớ. **HUD riêng không có thẻ THỬ THÁCH** (`BlindMemoryHUD`): THỜI GIAN + thẻ nhắc GHI NHỚ. Tùy chọn Thường (về S) / Hardcore (thua ngay). |

### 5.6. 🌫 Fog of War Maze

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (`mode_id = fog_of_war` — §10.2f) |
| **Bàn cờ** | Sinh theo tầng/độ khó, tường vô hình như Play Mode |
| **Số trên ô** | Số tường quanh ô — **chỉ hiện ở các ô trong bán kính 1** quanh nhân vật; ô xa bị phủ mờ (modulate `0.6` / alpha `0.4`) |
| **Di chuyển** | 4 hướng · sương mù cập nhật theo từng bước đi |
| **Thắng** | Tới F |
| **Thua** | Hết giờ · Hardcore: đâm tường = thua ngay (Thường: về S) |
| **Hồi sinh** | Quay lại bước trước đó |
| **HUD** | `nodes/hud/level_mode.tscn` (`LevelHUD`) · mockup `mockup/matchup_fog_of_war.svg` |
| **Chi tiết** | * **🌫️ Fog of War Maze** — Có tường vô hình như Play Mode, nhưng chỉ hiện số ở các ô trong bán kính 1 quanh vị trí hiện tại; ô xa ẩn số. Tùy chọn Thường (về S) / Hardcore (thua ngay). |

### 5.7. ➕ Sum Path

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (`mode_id = sum_path` — §10.2f) |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 · **không có tường** |
| **Số trên ô** | **Điểm số của ô (1..9)** — không liên quan tường |
| **Di chuyển** | 4 hướng · mỗi ô **chỉ tính điểm 1 lần** (quay lại ô cũ không cộng thêm) |
| **Thắng** | Tới F với tổng điểm thỏa điều kiện `SUM < / > / = Target` (luôn tồn tại ít nhất 1 nghiệm đúng) |
| **Thua** | Hết đường hợp lệ / hết thời gian (không có hazard) |
| **HUD** | `nodes/hud/sum_path_hud.tscn` (`SumPathHUD`) — **thiết kế mới 2026-02**: **THỜI GIAN** (250×156) + thẻ **CÂN BẰNG TỔNG ĐIỂM ĐƯỜNG ĐI** (715×156) gồm **TỔNG HIỆN TẠI — con dấu TOÁN TỬ — MỤC TIÊU PHẢI ĐẠT** + thanh tiến độ + chip trạng thái (**KHÔNG có thẻ THỬ THÁCH** — thử thách chốt ở popup kết quả) · mockup `mockup/matchup_sum_path.svg` |
| **Chi tiết** | ✨ **➕ Sum Path** — Không có tường. Số trên ô là điểm (1..9). Thắng khi tới F với tổng điểm thỏa `SUM < / > / = Target`. Mỗi ô chỉ tính điểm 1 lần. Luôn đảm bảo tồn tại ít nhất 1 nghiệm đúng. **HUD hiện 3 thẻ theo đúng thứ tự `TỔNG HIỆN TẠI — TOÁN TỬ — MỤC TIÊU`** (thẻ TOÁN TỬ nhỏ 112×112 nằm chính giữa, đè lên mép 2 thẻ kia; MỤC TIÊU chỉ hiện con số) thay cho panel MISSION cũ. **Không còn thắng được nữa** (tổng đã VƯỢT mục tiêu trong khi điều kiện là `<` hoặc `=` — đi thêm chỉ tăng điểm) → nút **CHƠI LẠI** tự hiện **DƯỚI hai nút Vẽ Đường / Ghi Nhớ** (2026-09-19); người chơi vẫn có thể **Undo** để lùi bước — tổng tính lại theo đường đã đi nên nút tự ẩn khi tổng về dưới mức chết. |

### 5.8. ⏳ Countdown Cost

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (`mode_id = countdown_cost` — §10.2f) |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 (xem bảng chi phí/ngân sách bên dưới) |
| **Số trên ô** | **CHI PHÍ BƯỚC** khi bước vào ô đó (mọi ô trừ S/F đều có số ≥ 1) |
| **Di chuyển** | 4 hướng · bước vào ô nào trừ đúng chi phí ô đó · đâm tường về S và trừ chi phí ô đích |
| **Thắng** | Tới F trong ngân sách (ngân sách = đường rẻ nhất + dự phòng ⇒ luôn thắng được nếu chọn đường rẻ) |
| **Thua** | **Hết bước** |
| **HUD** | `nodes/hud/countdown_hud.tscn` (`CountdownHUD`) — **thiết kế mới 2026-02**: **THỜI GIAN** (250×156) + **SỔ THEO DÕI NGÂN SÁCH BƯỚC CHÂN** (715×156) gồm **NGÂN SÁCH CÒN** (`còn/tổng`) · **ĐÃ TIÊU TỐN** (`-N BƯỚC` + số ô đã đi) · **GIÁ CƯỚC MỖI Ô** (chip RẺ/ĐẮT theo độ khó + dự phòng) + **dải phân đoạn** (mỗi đoạn = 1 bước) — **KHÔNG có thẻ THỬ THÁCH** · mockup `mockup/matchup_countdown_cost.svg` |
| **Chi tiết** | ✨ **⏳ Countdown Cost** — **Số trên ô = CHI PHÍ BƯỚC khi bước vào ô đó**, hoàn toàn **không liên quan tới số tường quanh ô** (khác Play / Dungeon / Fog of War). Mọi ô trừ S/F đều có số ≥ 1 và luôn hiện số. Bước vào ô nào thì trừ đúng chi phí của ô đó; đâm tường: về S và trừ chi phí của ô đích vừa đâm vào. Ngân sách bước được tính đủ cho **đường đi rẻ nhất + khoảng dự phòng**, nên màn luôn thắng được nếu chọn đúng đường ít tốn kém; đi lệch qua các ô đắt sẽ hết bước. **Hết ngân sách (0 bước còn lại) thì KHOÁ DI CHUYỂN** — người chơi phải bấm **UNDO** (nút được NHẤN MẠNH: ám vàng + nhịp phồng) để hoàn lại **đúng chi phí bước vừa đi** rồi mới đi tiếp (2026-09-19). |

  | Độ khó | Lưới | Chi phí mỗi ô | Dự phòng | Ngân sách tối thiểu |
  |---|---|---|---|---|
  | Easy | 3×3 | 1..2 bước | +6 | 12 bước |
  | Medium | 4×4 | 1..3 bước | +4 | 14 bước |
  | Hard | 5×5 | 1..4 bước | +3 | 15 bước |

  > Ngân sách thực tế = `max(ngân sách tối thiểu, chi phí đường đi rẻ nhất + dự phòng)`, tính bằng Dijkstra trên trọng số là chi phí ô đích — xem `scripts/modes/countdown_cost_game_mode.gd` (`cheapest_path_cost()` / `_ensure_budget()`).

### 5.9. 💧 Fading Ink (Mực Phai)

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge (thay chỗ **Area Maze** — đã BỎ từ 2026-11) · **MÀN campaign** (`mode_id = fading_ink` — §10.2f) |
| **Bàn cờ** | Theo độ khó: easy 3×3 · medium 4×4 · hard 5×5 · **không có tường trong** |
| **Số trên ô** | **MỰC của riêng ô đó** (ban đầu 2..9) — **giảm 1 mỗi bước đi** (mọi ô cùng phai một nhịp) |
| **Di chuyển** | 4 hướng · **chỉ đi vào ô còn mực**; ô hết mực bị chặn (không mất bước), mất số và hiện **lớp gạch + huy hiệu CẠN**; ô còn đúng **1 mực** hiện **lớp SẮP PHAI** (nền hổ phách + chữ cảnh báo) |
| **Thắng** | Tới F trước khi mực phai hết — phải đi **đường ngắn nhất** |
| **Thua** | **Hết lối đi mà chưa tới F** → popup thua tiêu đề riêng `HẾT ĐƯỜNG ĐI!` (`STR_GAME_OVER_NO_PATH`) |
| **Hồi sinh** | Quay lại bước trước đó — **mực hồi lại** đúng 1 điểm cho mọi ô |
| **HUD** | `nodes/hud/fading_ink_hud.tscn` (`FadingInkHUD`) — **thiết kế mới 2026-02**: **THỜI GIAN** (250×156) + **TRẠM ĐO ĐỘ PHAI MỰC** (715×156) gồm **BƯỚC ĐÃ ĐI** (`N` + `-N MỰC`) · **QUANG PHỔ ĐẬM NHẠT CỦA MỰC** (4 mức) · cảnh báo **N Ô ĐÃ CẠN MỰC** (ẩn khi chưa có ô nào cạn) — **KHÔNG có thẻ THỬ THÁCH** · mockup `mockup/matchup_fading_ink.svg` |
| **Chi tiết** | * **💧 Fading Ink (Mực Phai)** — *(thay cho Area Maze — đã BỎ từ 2026-11)* **Không có tường trong bàn.** Con số trên ô **KHÔNG phải số tường** mà là **MỰC của riêng ô đó** (mực ban đầu 2..9). **Người chơi chỉ được đi vào ô còn mực**; ô đã phai hết mực coi như ô trống — không đi vào được (bị chặn, KHÔNG mất bước, ô đó mất số và hiện **lớp gạch ngang + huy hiệu CẠN**). **MỖI BƯỚC ĐI làm MỌI ô trên bàn nhạt đi đúng 1 điểm mực** (không riêng ô vừa đi), nên phải tìm **đường ngắn nhất** tới F trước khi lối đi biến mất; đi vòng sẽ tự bịt đường của chính mình. Bàn luôn được sinh sao cho **đường ngắn nhất có đủ mực để tới F** (các ô trên đường đi được cấp mực theo số bước cần tới chúng, ô ngoài đường nhận mực thấp làm lối tắt dự phòng). **Đồng hồ đếm thời gian như thường**, không giới hạn số bước. **Hết lối đi mà chưa tới F = THUA** (popup thua hiện tiêu đề riêng `HẾT ĐƯỜNG ĐI!`). Nút **UNDO** lùi 1 bước thì **mực hồi lại** đúng 1 điểm cho mọi ô (trạng thái mực được tính lại từ số bước đã đi, không cần lưu lịch sử). HUD dùng bản **thiết kế mới**: thẻ **THỜI GIAN** + **TRẠM ĐO ĐỘ PHAI MỰC** (số bước đã đi · số mực đã phai · quang phổ đậm nhạt · cảnh báo ô cạn mực) — xem 10.2b. |
### 5.10. Popup kết quả & Hồi sinh khi thua (Revive)

| Cổng chơi | Mockup popup thua | Nội dung chính | Con dấu (stamp) | Nút HỒI SINH |
|---|---|---|---|---|
| **Play Mode** (Chọn màn) | `popup_game_over_level.svg` | Danh sách **3 Thử thách** kèm trạng thái ĐẠT / CHƯA ĐẠT | **Số Thử thách đã hoàn thành** (ví dụ `1 / 3 ★`) | **Quay lại bước trước đó** |
| **Dungeon Mode** | `popup_game_over_dungeon.svg` | Quãng đường đã đi · số lần va chạm tường vô hình · điểm an ủi tích lũy | **Bước còn lại** khi thua (ví dụ `HẾT BƯỚC — 00 / 20 BƯỚC`) | **Nhận thêm +3 bước để đi tiếp** |

- **Play Mode — hồi sinh = Quay lại bước trước đó:** Play Mode thua vì **đâm vào tường vô hình**; hồi sinh đưa nhân vật **về đúng ô ngay trước bước vừa rồi** (giữ nguyên đường đã vẽ, đồng hồ vẫn chạy). Play Mode **không cộng thêm bước** vì vốn không có giới hạn bước.
- **Dungeon Mode — hồi sinh = Thêm bước (giữ nguyên màn đang chơi):** Dungeon thua vì **hết bước**; hồi sinh **cộng thêm +N bước** (`GameController.revive_bonus_steps`, mặc định **3** — dòng mô tả ở popup tự hiện đúng số này) và **chơi tiếp ngay tại chỗ**: mê cung, vị trí nhân vật, đường đã vẽ và các đoạn tường đã lộ **giữ nguyên 100%** (không sinh lại màn — sinh lại mê cung coi như chơi ván khác). Đồng hồ chạy tiếp.

> **Quy ước nút "Chơi lại" (Retry) — phân biệt theo chế độ:**
> | Chế độ | "Chơi lại" (popup thua · popup thắng · nút Restart trên HUD) | "Hồi sinh" |
> |---|---|---|
> | **Dungeon** (endless) | Mở **ván mới — bắt đầu từ TẦNG 1** | Ở lại **đúng Tầng hiện tại** + cộng thêm **+N bước** |
> | **Play Mode / Level** và các mode khác (trừ endless) | Chơi lại **ĐÚNG màn đang chơi** | **Quay lại bước trước đó** (undo bước vừa đi, không cộng bước) |
> | **Chế độ có LƯỢT THỬ** — **Fog of War** (§13.16) · **Wall Builder** (§5.13) | Chơi lại **ĐÚNG màn đang chơi** (nạp lại đủ 3 lượt) | **+1 LƯỢT**: Fog = +1 *lượt thử lại* · Wall Builder = +1 *lượt gửi* |
- **Popup thắng màn ở Play Mode** (`popup_win_level.svg`) hiển thị: thời gian hoàn thành, số bước đã đi, **3 sticker sao = 3 Thử thách** (sao vàng = đã đạt · sao rỗng = chưa đạt) cùng bảng trạng thái từng Thử thách và con dấu `2 / 3 THỬ THÁCH`.

### 5.10a. Popup Retry trước khi vào Game Over (v2.34 — 2026-10-20 · sửa 2026-10-21: thử lại = HỒI SINH)

Thay vì chuyển ngay vào popup tổng kết thua cuộc (`gameover_level.tscn` / `gameover_challenge.tscn`), khi người chơi bị Game Over, hệ thống sẽ mở **Popup Retry (`nodes/popups/retry.tscn` / `Popups.RETRY`) trước tiên** để mang lại cơ hội tiếp tục chơi nhanh cho người chơi qua 3 lựa chọn:

| Lựa chọn | Thao tác | Hành vi & Hệ thống xử lý |
|---|---|---|
| **Xem Quảng Cáo (Advert)** | Bấm nút **XEM ⏵** (`BtnAd`) | Gọi `AdsManager.show_rewarded("retry")`. Xem xong thành công ⇒ phát `revive_requested("ad")` → `UIController` phát tiếp **`revive_confirmed`** → `GameController.revive_run()`: **HỒI SINH và chơi tiếp ĐÚNG ván đang chơi** (mở khoá bàn cờ, chạy lại đồng hồ) — giống hệt nút **HỒI SINH** của popup Game Over. |
| **Trả Gold (Xu)** | Bấm nút **TRẢ XU** (`BtnGold`) | Mặc định **100 Xu** (`DEFAULT_GOLD_COST`). Kiểm tra số dư qua `Archivement.coins()`; nếu đủ, trừ xu bằng `Archivement.spend_coins(100)` rồi phát `revive_requested("gold")` ⇒ cũng đi đường **`revive_confirmed` → `revive_run()`** (hồi sinh, chơi tiếp); nếu thiếu Xu, hiển thị nhãn cảnh báo đỏ và phát SFX va chạm. |
| **Bỏ qua (Skip)** | Bấm nút **BỎ QUA** (`SkipBtn`) hoặc phím Back Android | Đóng Popup Retry và chuyển tiếp vào **Popup Game Over chính** (`gameover_level.tscn` hoặc `gameover_challenge.tscn`) để người chơi xem chi tiết danh sách nhiệm vụ, số Sao đạt được, cũng như các tùy chọn Về Menu / Thử lại / Hồi sinh. **Bỏ qua = THUA CHỐT VÁN ⇒ mất 1 LƯỢT CHƠI** (§5.10b). |

- **Hai đường hồi sinh, MỘT đoạn xử lý:** nút **HỒI SINH** của popup Game Over phát `revive_requested` (còn phải chạy quảng cáo) → `GameController._on_revive_requested()`; popup Retry đã tự trả giá nên phát `revive_confirmed` → gọi thẳng `GameController.revive_run()`. Cả hai kết thúc ở cùng một chỗ nên bàn cờ luôn được mở khoá như nhau.
- **Bug đã sửa (2026-10-21):** trước đây `UIController` nối nhầm tín hiệu `retry_requested` (popup Retry không có tín hiệu này) nên bấm **XEM QUẢNG CÁO** / **TRẢ XU** chỉ đóng popup mà **không mở khoá bàn cờ** (`_interaction_enabled = false` từ `_game_over()`) ⇒ người chơi đứng im, không di chuyển được. Nay popup Retry phát `revive_requested` → `revive_confirmed` → `revive_run()`.
- **Bỏ qua luồng Retry (bước đệm):** Luồng học việc lần đầu (`guided = true`) hoặc các cuộc gọi chỉ định (`direct_game_over = true`) sẽ tự động bỏ qua Popup Retry để đến thẳng popup Game Over.
- **Ràng buộc tương tác:** `close_on_outside = false` để tránh việc người chơi vô tình bấm nhầm ra ngoài vùng nền mờ làm mất cơ hội lựa chọn.
- **Kiểm thử:** `test_retry_popup` gác "popup Retry phát `revive_requested('ad'/'gold')` · `UIController` phát `revive_confirmed` (KHÔNG phát `retry_requested`) · **thua màn → XEM QUẢNG CÁO ⇒ bàn cờ MỞ KHOÁ, đồng hồ chạy lại và đi được bước tiếp theo**"; `test_retry_floor` gác "popup Retry mở trước ⇒ BỎ QUA mới vào popup thua".

### 5.10b. LƯỢT CHƠI (life) — vào ván · thua · hồi lượt · mua thêm (v2.38 — 2026-10-20)

Lượt chơi là **tài nguyên dùng chung toàn bộ trò chơi** (giống ví Xu), không phải "mỗi màn một ít":

| Luật | Giá trị / hành vi |
|---|---|
| Tối đa | **5 lượt** (`GameManager.MAX_LIVES`) |
| Cách MẤT lượt | Mỗi ván **THUA mà KHÔNG thử lại** = **−1 lượt** (bấm **BỎ QUA** ở popup Retry, hoặc vào thẳng popup Game Over khi không có popup Retry) |
| Không mất lượt | Ván **thắng** · ván **thử lại bằng quảng cáo/Xu** · luồng **học việc** (`guided`) · ván **Debug Console** / test tự động |
| Cách HỒI lượt | Tự động **+1 lượt mỗi 30 phút** (`LIFE_RECHARGE_SECONDS`) — đếm bằng **đồng hồ thực** nên tắt app vẫn hồi; đầy 5 lượt thì **dừng đếm** |
| Cách CỘNG lượt | Mua **gói lượt** ở Cửa hàng (`purchase`) · thưởng nhiệm vụ (`mission`) · mốc Sao Daily (`daily_milestone`) — `GameManager.grant_lives()` chỉ nhận 3 nguồn này (đầy lượt thì không cộng) |
| Hết lượt | **KHÔNG vào được ván nào** (Play · Dungeon · Daily · Event · Special) |

**1. Chặn vào ván + popup "HẾT LƯỢT CHƠI".** Mọi lối vào ván của `GameManager`
(`start_level` · `start_dungeon` · `start_mode` · `start_daily*` · `start_level_from_event`) đi qua
`_enter_game_scene()`; hàm này hỏi `can_start_run()` — **hết lượt thì KHÔNG đổi scene** mà mở
`nodes/popups/out_of_life.tscn` (`Popups.OUT_OF_LIFE`):

| Nút | Hành vi |
|---|---|
| **THOÁT RA** | Đóng popup, ở lại **đúng màn đang đứng** |
| **CỬA HÀNG** | `GameManager.request_shop_from_life_gate()`: ghi `shop_return_path` = scene hiện tại rồi `Nav.goto_shop()`. Nút **Back của Shop** đọc `take_shop_return_path()` ⇒ quay về **ĐÚNG màn trước đó** (không phải Main) |

- Popup hiện thêm **đồng hồ đếm ngược lượt kế tiếp** (`Lượt kế tiếp sau mm:ss`, cập nhật mỗi giây).
- `close_on_outside = false` (phải chọn 1 trong 2 nút) · `close_on_back = true`.

**2. Trừ lượt đúng MỘT lần cho mỗi ván.**
`UIController.show_direct_game_over()` (điểm duy nhất khi ván thua đã chốt) gọi
`GameManager.register_run_loss()`; `GameController.start_new_run()` gọi `begin_run_guard()` để mở lại
"van" cho lần thua kế tiếp ⇒ **thử lại bao nhiêu lần cũng không trừ thêm**, chỉ khi thua chốt mới trừ 1.

**3. Dữ liệu & lưu trữ.** `GameManager` giữ `lives` + `next_life_at` (mốc unix giây của lượt kế tiếp);
cả hai nằm trong blob tiến trình (`export_progress` / `import_progress`) nên `SaveManager` tự lưu.
`_process()` quét mỗi 0,5 s để hồi lượt và phát `life_changed(lives, max)` cho các `LifeChip`.

**4. Mua thêm lượt ở Cửa hàng.** Tab **DỤNG CỤ** có món `life_x1` (giá **300 Xu**, `"life": true`):
`ShopManager._buy_life_pack()` gọi `GameManager.grant_lives(1, "purchase")` rồi mới trừ Xu;
**đầy lượt thì không mua được** (nút hiện `ĐÃ ĐẦY LƯỢT`). Dòng phụ của thẻ hiện `Lượt chơi: x/5`.

**5. Debug Console (§9.3).** Mục **LIVES**: xem `lives`/`max` + đếm ngược, `SpinBox` đặt số lượt,
nút **Empty lives (0)** (thử popup hết lượt), **Fill lives (5)**, **Advance 30 min recharge**.

**6. Kiểm thử:** `scripts/test_case/test_life_points.gd` (112 check) — trừ lượt 1 lần/ván · hồi lượt kể cả
offline · nguồn cộng hợp lệ · lưu/đọc · chặn vào ván + mở popup · binding popup · `LifeChip` (ẩn `+` khi đầy)
· mua gói lượt · **mỗi layout đúng 1 `CoinChip` + 1 `LifeChip`**.
> Test runner tự động **không trừ lượt** (`_is_automated_test()` + cờ `life_cost_in_tests`) và bỏ qua cổng
> chặn (`can_start_run()`), để bộ test không làm cạn lượt thật; test muốn kiểm tra luật thật thì bật cờ
> `life_cost_in_tests = true` / ép `life_gate_override = -1`.


### 5.10c. KỶ LỤC TẦNG CAO NHẤT — ngày / tuần / tháng (v2.43 — 2026-10-21)

Lưu **tầng sâu nhất người chơi từng đạt** theo từng kỳ, để so sánh nỗ lực hôm nay với cả tuần/tháng:

| Kỳ | Khoá (`key`) | Ý nghĩa |
|---|---|---|
| `day` | `2026-10-21` (`Time.get_date_string_from_system()`) | Kỷ lục của RIÊNG ngày hôm đó |
| `week` | Ngày **THỨ HAI** của tuần chứa hôm nay (VD `2026-10-19`) | Tuần ISO bắt đầu từ **thứ Hai**; khoá là ngày đầu tuần nên không cần tính số tuần |
| `month` | `2026-10` | Kỷ lục của tháng dương lịch |

**1. Dữ liệu (`GameManager`).** `floor_records = { "day": {key, floor}, "week": {…}, "month": {…} }`
nằm trong blob tiến trình (`export_progress` / `import_progress`) nên `SaveManager` tự lưu — đăng ký thêm
tín hiệu `floor_record_changed` để **lưu ngay khi vừa lập kỷ lục**.
`reset_progress()` xoá sạch cả 3 kỳ.

**2. Ghi nhận.** `GameManager.record_floor_reached(floor)` — gọi từ `GameController._start_floor()` khi
**vào một tầng mới của ván VÔ TẬN (Dungeon)**; ván theo **MÀN (Play)** và Daily **không** ghi vì số "tầng"
ở đó chỉ là ID màn, không phải độ sâu. Hàm chỉ **nâng** kỷ lục (không hạ), bỏ qua `floor <= 0`, ván
**Debug Console** và test runner tự động (trừ khi bật cờ `floor_record_in_tests = true`).

**3. Kỳ mới ⇒ kỷ lục bắt đầu lại.** Mọi lần đọc đều so `key` với khoá hiện tại: khoá khác ⇒ trả **0**
(không mang kỷ lục hôm qua/tuần trước/tháng trước sang kỳ mới). `_sync_floor_records()` đặt lại khoá + 0
mỗi khi ghi.

**4. Hiển thị — popup Game Over Dungeon (`nodes/popups/gameover.tscn`).** Thêm hàng **Records** ngay dưới
3 chỉ số (Đường đã đi · Va chạm tường · Điểm an ủi):

| Node | Nhãn | Khoá dịch |
|---|---|---|
| `Information/Records/WeekBest` | **Kỷ lục tuần: 14** | `STR_GAMEOVER_BEST_WEEK` (`Week best: {0}`) |
| `Information/Records/MonthBest` | **Kỷ lục tháng: 23** | `STR_GAMEOVER_BEST_MONTH` (`Month best: {0}`) |

- Chưa có kỷ lục trong kỳ ⇒ hiện `--` (`STR_GAMEOVER_BEST_NONE`).
- Popup đọc qua `GameManager.best_floor("week"/"month")`, nhưng **ưu tiên** `data.best_floor_week` /
  `data.best_floor_month` nếu `GameController` truyền sẵn.
- `GameManager.best_floor("day" | "week" | "month")` là API đọc dùng chung (Profiler/Event có thể dùng lại).

**5. Kiểm thử:** `scripts/test_case/test_floor_records.gd` (64 check) — khoá ngày/tuần/tháng (kể cả Chủ
nhật lùi về thứ Hai của CÙNG tuần và lùi qua tháng trước) · chỉ nâng không hạ · bỏ qua tầng ≤ 0 / ván Debug ·
kỳ cũ ⇒ 0 · lưu/đọc + `reset_progress()` · popup hiện đúng số và `--` · bố cục không tràn · **ván Dungeon
ghi kỷ lục theo tầng, ván Play thì không**.


### 5.11. Con dấu · icon nút · vuốt cuộn trong popup (2026-09)

**Quy tắc vàng về art SVG:** ThorVG (bộ nhập SVG của Godot) **KHÔNG render `<text>`** → mọi chữ trong game phải là **Label node**, art chỉ vẽ hình (vòng, khung, nét). Các file `stamp_*.svg` vì vậy chỉ có vòng nét đứt, **chữ nằm ở 2 Label con của node `Stamp`**:

| Popup | StampTitle | StampSub | Khung con dấu |
|---|---|---|---|
| Thắng màn (`winning.tscn`) | `STR_WIN_STAMP_TITLE` — "{0} / {1} THỬ THÁCH" | `STR_WIN_STAMP_SUB` — "★ ĐẠT {0} SAO ★" | (622, 88) 156×90 · đỏ, chữ `PopupStampTextDanger`/`PopupStampSubDanger` |
| Thông qua tầng (`next_floor.tscn`) | `STR_RESULT_STAMP_PASSED` — "ĐÃ QUA" | `STR_RESULT_STAMP_FLOOR` — "TẦNG {0} ✔" (`"%02d"`) | (592, 47) 116×116 · xanh lục, chữ `PopupStampText`/`PopupStampSub` |

- **Icon nút CHƠI LẠI** (`winning.tscn` → `Panel/Content/ReplayBtn/TextureRect`) = `assets/images/popups/icon_replay.svg`, **cùng hình mũi tên vòng với nút Restart trên HUD** (`assets/images/game/btn_restart_*.svg`): cung `M 50 25 A 15 15 0 1 0 52 42` + mũi tên `42,20 52,24 50,34` (theo `mockup/matchup_level.svg`). Trước đây icon Restart bị vẽ **mũi tên gãy nằm lệch ngoài cung** nên trông như lỗi.
- **Popup ngôn ngữ** (`language.tscn`): nút HỦY BỎ = **180×96** và ÁP DỤNG = **390×96** (đúng mockup `popup_language.svg`) + khung nội dung rộng **600px** (`Content` offsets 110 / -70) → hàng nút 180 + 30 + 390 = 600 **vừa khít**, không tràn.
- **QUY ƯỚC ART NÚT (quan trọng):** `TextureButton` mặc định **`stretch_mode = STRETCH_KEEP (2)`** — art được vẽ **ĐÚNG kích thước gốc**, KHÔNG tự co theo node (khác `TextureRect`). Vì vậy **art nút phải khớp 1:1 với kích thước node**; nếu art to hơn thì hình **thò ra ngoài** (đã từng bị: nút 390×96 nhưng gán `btn_popup_wide_*` art **630×96** → vệt xanh thò tới mép màn hình).

| Nút popup ngôn ngữ | Art | Cỡ | Kiểu |
|---|---|---|---|
| HỦY BỎ | `popups/btn_lang_cancel_{normal,pressed,focus,disabled}.svg` | **180×96** | giấy `#FEFDFA` + viền xám `#BAC7CF` 2.5, rx 16 |
| ÁP DỤNG | `popups/btn_lang_apply_{normal,pressed,focus,disabled}.svg` | **390×96** | mực `#3D83AE` + viền `#256286` 3.5, rx 18 |

> Các popup khác đã khớp 1:1: `winning` (CHƠI LẠI 192×108 = `btn_paper_secondary_*`; MÀN KẾ TIẾP 437×108 = `btn_paper_primary_*`), `next_floor` (art 425×96 nằm trong node 437×108 — nhỏ hơn nên canh giữa, không tràn), `pause` (checkbox art 50×50 trong node 44×44 nhưng `stretch_mode = 0` nên tự co).
- **Vuốt cuộn danh sách ngôn ngữ:** hàng là `TextureButton` nên "ăn" hết sự kiện kéo → `language_popup.gd` tự xử lý kéo ở `_input` (giống màn Cửa hàng): ngưỡng 14px mới tính là vuốt, `set_input_as_handled()` khi cuộn, và **khoá bấm hàng 0.35s** sau khi vuốt để không chọn nhầm ngôn ngữ.
- **Bảng 19 ngôn ngữ** (`LocalizationManager.LOCALE_INFO`): mỗi mã trong `string.csv` phải có **tên bản địa + phụ đề tiếng Anh + cờ riêng**. Thiếu khoá ở đây thì popup sẽ hiện **mã thô** (vd "MS", "PT_BR") và cờ dự phòng `flag_generic.svg` — đúng lỗi đã gặp.

| Mã | Tên hiển thị | Phụ đề | Cờ |
|---|---|---|---|
| `en` | English | United States | `flag_en.svg` |
| `vi` | Tiếng Việt | Mặc định hệ thống | `flag_vi.svg` |
| `zh_TW` | 繁體中文 | Traditional Chinese | `flag_zh_tw.svg` |
| `zh_CN` | 简体中文 | Simplified Chinese | `flag_zh_cn.svg` |
| `es` | Español | Spanish | `flag_es.svg` |
| `ar` | العربية | Arabic | `flag_ar.svg` |
| `de` | Deutsch | German | `flag_de.svg` |
| `fr` | Français | French | `flag_fr.svg` |
| `hi` | हिन्दी | Hindi | `flag_hi.svg` |
| `id` | Bahasa Indonesia | Indonesian | `flag_id.svg` |
| `it` | Italiano | Italian | `flag_it.svg` |
| `ja` | 日本語 | Japanese | `flag_ja.svg` |
| `ko` | 한국어 | Korean | `flag_ko.svg` |
| `ms` | Bahasa Melayu | Malay | `flag_ms.svg` |
| `pt` | Português | Portuguese | `flag_pt.svg` |
| `pt_BR` | Português (Brasil) | Brazilian Portuguese | `flag_pt_br.svg` |
| `ru` | Русский | Russian | `flag_ru.svg` |
| `th` | ไทย | Thai | `flag_th.svg` |
| `tr` | Türkçe | Turkish | `flag_tr.svg` |

- Cờ dùng chung khuôn: viewBox **38×28**, nền bo góc `rx=3` + viền `#224C6D` 1.8; các dải màu vẽ bằng path bo góc theo viền (không dùng `<clipPath>`). Còn `flag_generic.svg` (quả cầu nét đứt) chỉ là dự phòng.
- **Logo `main/logo_doodle_maze.svg`**: chữ **S** (điểm bắt đầu, xanh) và **F** (đích, hổ phách) đã đổi từ `<text>` sang **path vẽ tay** — trước đây biến mất trong game vì ThorVG bỏ qua `<text>`.
- Kiểm thử: `scripts/test_case/test_popup_ui.gd` (**54 check**) — icon Restart 4 trạng thái · con dấu 2 popup (kích thước + chữ đúng dữ liệu) · icon nút CHƠI LẠI căn giữa · popup ngôn ngữ (đủ hàng, hàng nút không tràn, **art nút khớp 1:1**, vuốt cuộn được, không chọn nhầm khi vừa vuốt) · quét art còn `<text>` · bảng 19 ngôn ngữ (tên + cờ riêng, không dùng cờ generic).

---

### 5.12. ✍️ One Stroke (Một Nét)

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (`mode_id = one_stroke` — §10.2f) · tên gọi: EN **ONE STROKE** · VI **MỘT NÉT** *(phương án khác: Full Page / KÍN TRANG · Cover All / PHỦ KÍN)* |
| **Bàn cờ** | Theo độ khó — **luôn là bàn VUÔNG LẺ ô** để bảo đảm tồn tại đường Hamilton S→F: easy **3×3** · medium **5×5** · hard **7×7** · **tường NHÌN THẤY RÕ 100%** (mọi vách giữa 2 ô + viền ngoài board đều vẽ ra) |
| **Số trên ô** | **KHÔNG hiện số** — bàn chỉ có tường + S/F. Không phải suy luận tường: toàn bộ độ khó nằm ở **thứ tự đi** |
| **Di chuyển** | 4 hướng · kéo từ tâm ô · **ô đã đi qua bị KHOÁ VĨNH VIỄN** (hiện lớp tô xanh + gạch chéo + nhãn `ĐÃ ĐI`); kéo nét đè lên ô cũ ⇒ **THUA NGAY** (chất hazard `revisit`, xem mục *Thua*) |
| **Mục tiêu** | Đi qua **TẤT CẢ các ô thuộc board, mỗi ô ĐÚNG 1 LẦN**, và **ô cuối cùng phải là F** ⇒ đường đi chính là một **đường Hamilton** từ S tới F (*"vẽ một nét kín trang rồi mới chạm đích"*) |
| **Thắng** | Chạm F **sau khi đã phủ kín mọi ô** (còn ô chưa đi mà chạm F ⇒ nước đi bị chặn, màn chưa kết thúc) |
| **Thua** | **(a) Đi đè lên ô đã đi ⇒ THUA NGAY** → popup thua tiêu đề riêng `ĐI LẠI Ô CŨ!` (`STR_GAME_OVER_REVISIT`) · **(b) Hết lối đi khi vẫn còn ô chưa đi** → `HẾT ĐƯỜNG ĐI!` (`STR_GAME_OVER_NO_PATH`, dùng chung với Fading Ink) · **(c) hết giờ** |
| **Hồi sinh** | **Quay lại bước trước đó** (undo 1 bước — ô vừa rời được **mở lại**) |
| **HUD** | `nodes/hud/one_stroke_hud.tscn` (`OneStrokeHUD`) — theo mockup `mockup/matchup_one_stroke.svg`: **THỜI GIAN** (270×156, chip `ĐANG TÍNH GIỜ`) + **BẢNG TIẾN ĐỘ PHỦ KÍN** (690×156, viền xanh `#2575A7`): cột trái `📐 ĐÃ PHỦ KÍN` · `13/25 Ô` · `CÒN LẠI 12 Ô` (đỏ); cột phải hàng `✍️ MỘT NÉT KHÔNG LẶP` + chip `52% KÍN` + **thanh tiến độ** (tô theo số ô đã đi) + 2 dòng nhắc luật (`Phải đi hết mọi ô mới được chạm đích F` · `✓ Không lùi ô`) — **KHÔNG có thẻ THỬ THÁCH** |
| **Thanh công cụ** | **BỎ nút VẼ ĐƯỜNG/GHI NHỚ (2026-09-26)** — bàn cờ tự nhận thao tác; thanh hành động còn **CHƠI LẠI · UNDO · GỢI Ý** (mỗi nút UNDO/GỢI Ý có **badge `PanelLimit`** hiện số lượt còn lại) — xem §10.2e |
| **Nội dung hướng dẫn** | `nodes/popups/instruction/one_stroke.tscn` (3 trang, kế thừa `content_instruction.tscn` — nạp bởi popup chung — xem §10.2d) · chip `ONE STROKE • MỘT NÉT` |
| **Chi tiết** | Xem bên dưới |

- **Sinh bàn (bắt buộc có nghiệm — ĐÃ LẬP TRÌNH):** `OneStrokeGameMode.setup_floor()` dựng **đường rắn bò (snake)** phủ kín board từ S=(0,0) tới F=(n-1,n-1) **trước**, rồi mới đặt tường ngẫu nhiên (mật độ 18% / 34% / 50% theo độ khó) **CHỈ trên các cạnh KHÔNG thuộc đường mẫu** ⇒ đường mẫu luôn còn nguyên ⇒ bàn luôn có ít nhất 1 lời giải phủ kín. Mọi vách đặt thêm đều được `maze.reveal_wall()` cho **hiện rõ 100%**.
- **Ràng buộc chẵn/lẻ khi đặt S/F (bắt buộc):** tô lưới 2 màu như bàn cờ — đường Hamilton chỉ tồn tại khi **S và F KHÁC màu**. Vì S=(0,0) và F=(n-1,n-1) trên bàn **n lẻ** có **cùng màu đa số** nên chế độ **chỉ dùng bàn n lẻ** (3×3 · 5×5 · 7×7); board chẵn (4×4) bị loại vì cặp góc chéo đó cùng màu ⇒ vô nghiệm.
- **GỢI Ý:** soi **1 ô đúng kế tiếp** — nếu người chơi còn đi đúng **đường mẫu** thì trả về ô kế tiếp của đường đó (tức thời); nếu đã đi lệch thì **tự giải lại** bài toán phủ kín bằng DFS cắt tỉa (bỏ F khỏi vùng đi xuyên, ưu tiên ô ít lối thoát kiểu Warnsdorff, ngân sách 60.000 nút) và trả về nước đi đầu của lời giải. Khi bế tắc hoàn toàn, hàm trả về ô hiện tại *(chưa có dòng chữ cảnh báo riêng)*.
- **is_dead_end (HẾT ĐƯỜNG ĐI!):** coi **F như tường** khi xét vùng ô trống (vì F chỉ được là ô cuối) — nếu phần ô trống còn lại bị **cắt rời** (hoặc không còn chạm tới được, kể cả trường hợp chỉ còn F mà không kề) thì thua ngay với lý do `dead_end`.
- **Thử thách mặc định** khi màn không khai báo gì: `time_max` · `no_hint` · `no_undo` — **không** dùng `visit_all`/`no_revisit` làm thử thách vì đó là **luật cứng của chế độ**.
- **Không có hazard:** bàn không có tường vô hình ⇒ **không có "đâm tường"** và **không có LƯỢT THỬ**; mọi va chạm chỉ là nước đi bị từ chối (không mất bước).

### 5.13. 🧱 Wall Builder (Xây Tường)

| Trường | Nội dung |
|---|---|
| **Cổng vào** | Daily Challenge · **MÀN campaign** (`mode_id = wall_builder` — §10.2f) · tên gọi: EN **WALL BUILDER** · VI **XÂY TƯỜNG** *(phương án khác: Bricklayer / THỢ XÂY · Draw the Walls / ĐẮP TƯỜNG)* |
| **Bàn cờ** | Theo độ khó: easy **3×3** · medium **4×4** · hard **5×5** · mê cung sinh sẵn nhưng **tường bị ẩn HOÀN TOÀN**; **KHÔNG có S/F**, **không có nhân vật**, **không di chuyển** |
| **Số trên ô** | **Số tường quanh ô (0..4)** — hiện **rõ trên MỌI ô** (kể cả số 0); đếm đúng quy ước ở đầu mục 2 (chỉ 4 cạnh giữa 2 ô thuộc board) |
| **Thao tác chính** | **VẼ TƯỜNG** = kéo nối 2 **Anchor** kề nhau để **bật/tắt 1 đoạn tường** tại khe giữa 2 ô (đúng thao tác "Tường Nghi Ngờ" trước đây — nay là **hành động CHÍNH**, không còn là giấy nháp). **Viền ngoài board là tường cố định**, không vẽ được và không tính vào số |
| **Số tường cần tạo** | Game nói trước cần bao nhiêu đoạn: **`y = Σ(số trên mọi ô thuộc board) / 2`** (mỗi đoạn tường bên trong được **đúng 2 ô** kề nó đếm chung) — HUD hiện `đã vẽ x / y đoạn` |
| **GỬI (Submit)** | Nút **GỬI** đối chiếu cấu hình tường đã vẽ với các con số: **khớp TOÀN BỘ số ⇒ THẮNG**. **Sai ⇒ mất 1 LƯỢT GỬI** + hiện **số đoạn sai** (chỉ số lượng, **KHÔNG** chỉ vị trí) + rung bàn cờ. Mỗi màn chỉ có **3 LƯỢT GỬI**; hết lượt ⇒ THUA |
| **Thắng** | Cấu hình tường thoả **mọi con số trên bàn** (không bắt buộc trùng đúng mê cung gốc — xem "Vì sao" bên dưới) |
| **Thua** | **Hết 3 lượt gửi** · **hết giờ** |
| **Hồi sinh** | **+1 LƯỢT GỬI** (đồng bộ cơ chế LƯỢT THỬ của Fog of War §13.16) — popup thua hiện dòng mô tả riêng `STR_REVIVE_DESC_SUBMIT` (*"Nhận thêm +1 LƯỢT GỬI để nộp lại"*) |
| **HUD** | `nodes/hud/wall_builder_hud.tscn` (`WallBuilderHUD`) — theo mockup `mockup/matchup_wall_builder.svg`: **THỜI GIAN** (270×156, chip `ĐANG SUY LUẬN`) + **BẢNG TƯỜNG ĐÃ VẼ** (690×156, viền XANH LÁ `#2E7D32`): cột trái `🧱 ĐÃ DỰNG` · `14/18 ĐOẠN` · `CÒN THIẾU 4 ĐOẠN` (đỏ); cột phải hàng `❤️ LƯỢT GỬI: 3 / 3 LẦN` + chip trạng thái (`ĐANG NỐI TƯỜNG` · `ĐỦ TƯỜNG` · `SẴN SÀNG GỬI`) + **thanh tiến độ dựng tường** + 2 dòng nhắc luật (`Khớp mọi con số rồi bấm GỬI` · `✓ Sai -1 lượt`) — **KHÔNG có thẻ THỬ THÁCH** |
| **Thanh công cụ** | **BỎ 2 nút công cụ cũ (2026-09-26)** — **VẼ TƯỜNG** = kéo nối 2 **Anchor** trực tiếp trên bàn (không cần nút chọn công cụ); **GỬI BÀI** = nút **`Submit`** trên thanh hành động (chỉ hiện ở chế độ này) + **CHƠI LẠI** + **UNDO** (xoá đoạn vừa nối) + **GỢI Ý** (mở + khoá 1 đoạn tường thật) — xem §10.2e |
| **Nội dung hướng dẫn** | `nodes/popups/instruction/wall_builder.tscn` (3 trang, kế thừa `content_instruction.tscn` — nạp bởi popup chung — xem §10.2d) · chip `WALL BUILDER • XÂY TƯỜNG` |
| **Chi tiết** | Xem bên dưới |

- **Vì sao thắng = "khớp mọi con số" mà không phải "trùng mê cung gốc":** một bộ con số có thể có **nhiều cấu hình tường** thoả mãn; nếu bắt khớp mê cung gốc thì người chơi vẽ ra cấu hình **đúng logic** vẫn bị báo sai (bất công). Vì vậy **nghiệm = MỌI cấu hình thoả số**. Điểm hay: **tổng số đoạn tường của mọi nghiệm là như nhau** (`Σ số / 2`) nên câu *"cần tạo bao nhiêu tường"* luôn xác định ngay từ đầu.
- **Luôn có nghiệm:** cấu hình tường của **chính mê cung sinh ra** luôn thoả các con số của nó ⇒ màn không bao giờ bất khả.
- **Sinh bàn & độ khó:** lưới theo độ khó; **mật độ tường ~45..60%**; loại bỏ bàn quá dễ (quá nhiều ô 0 hoặc 4) và ưu tiên bàn có **≥ 2 nghiệm** để phải suy luận thật (đếm nghiệm bằng solver nhỏ — lưới ≤ 5×5 chạy được).
- **GỢI Ý:** hiện + **khoá** 1 đoạn tường **thuộc mê cung gốc** (luôn là một nghiệm hợp lệ); đoạn đã gợi ý **không xoá được** và tính vào thử thách `no_hint` như mọi chế độ.
- **Thử thách mặc định:** `no_wrong_submit` (gửi đúng ngay lần đầu) · `time_max` · `no_hint`.
- **Không có S/F — ĐÃ LẬP TRÌNH:** `get_cell_text()` trả SỐ TƯỜNG cho **mọi** ô (kể cả S/F ẩn danh), nên bàn chỉ hiện số; `shows_player() = false` → board ẩn hẳn nhân vật và `evaluate_move()` luôn từ chối (không di chuyển, không mất bước).
- **Chi tiết đã lập trình:** `WallBuilderGameMode` — `required_segments = Σ(số mọi ô)/2` (đếm bằng `count_true_segments()`); khe chỉ vẽ được khi có **2 ô thuộc board** kề nó (`can_draw_wall()`), đoạn vẽ ra hiện kiểu **`built`** (xanh lá, `wall_segment.gd`); `evaluate_submit()` trả `số đoạn CÒN LỆCH = Σ|chênh lệch từng ô| / 2` (khớp mọi con số ⇒ 0) — **nghiệm không bắt buộc trùng mê cung gốc**; GỬI sai ⇒ `register_failed_submit()` trừ 1 LƯỢT GỬI + `board.shake_board()` + chữ nổi `CÒN LỆCH n ĐOẠN!`; hết lượt ⇒ `GameController._game_over("out_of_submits")` → tiêu đề `HẾT LƯỢT GỬI!` (`STR_GAME_OVER_OUT_OF_SUBMITS`) + popup thua nói `STR_REVIVE_DESC_SUBMIT`; GỢI Ý ⇒ `hint_wall()` mở + **khoá** 1 đoạn tường thật (xoá không được, `is_wall_locked()`), UNDO ⇒ `undo_drawn_wall()` bỏ qua đoạn đã khoá; độ khó 3×3 / 4×4 / 5×5 và **loại bàn quá dễ** (quá nhiều ô 0/4 — sinh lại tối đa 12 lần).
- **Khoá dịch đề xuất:** `STR_MODE_ONE_STROKE` · `STR_MODE_WALL_BUILDER` · `STR_HINT_ONE_STROKE` · `STR_HINT_WALL_BUILDER` · `STR_REVIVE_DESC_SUBMIT` · `STR_HUD_ONE_STROKE_*` · `STR_HUD_WALL_*` · `STR_GAME_OVER_NO_PATH` (dùng lại) · `STR_CHALLENGE_NO_WRONG_SUBMIT`.

---

## 6. Hệ thống Daily Challenge (v2.29 — DỰNG LẠI Y HỆT MOCKUP)

> **v2.21:** Daily Challenge là **event ẢO ghim ĐẦU** danh sách Sự kiện (thẻ lá lịch đỏ) do `EventManager` tạo từ `DailyManager`; bấm thẻ mở **thẳng** `scenes/daily.tscn` (§15).
> **v2.29:** toàn bộ màn Daily được **dựng lại theo đúng `mockup/daily_challenge.svg`** (khung 1080×1920 ⇒ scene dùng **K = 0.5**): thanh Sao dày có **ngôi sao lớn chứa số Sao + 4 huy hiệu mốc**, lịch tháng có **hào quang ô HÔM NAY + nhãn + viên "x/6 ★"**, chú giải nằm TRONG bảng lịch, và **2 thẻ hành động lớn** (khung icon + tiêu đề + dòng phụ + 3 Sao + nút CTA).

### 6.1. Cấu trúc nội dung mỗi ngày (1 CHƠI + 1 THỬ THÁCH)
Mỗi ngày có **2 hoạt động**, mỗi hoạt động tối đa **3 Sao** ⇒ **tối đa 6 Sao/ngày**.

| Hoạt động | Nội dung | Sao | Điều kiện nhận |
|---|---|---|---|
| **CHƠI** (`daily_classic`) | 1 màn maze thường của ngày | 0–3 | **Mỗi NHIỆM VỤ hoàn thành = 1 Sao** (`MissionController.stars()`) |
| **THỬ THÁCH** (`daily_challenge`) | 1 maze chạy **luật Special** xoay vòng của ngày | 0 hoặc 3 | Luật Special **không có nhiệm vụ** ⇒ **thắng ván = +3 Sao** |

- **Giữ mức cao nhất:** chơi lại chỉ ghi khi tốt hơn (`record_daily_win()` lấy `max`).
- **Ngày bỏ lỡ** mở khoá bằng **50 Xu** (`unlock_day()`).
- Lưu **theo THÁNG**: `months["YYYY_MM"] = { days: { ngày: {play, challenge} }, claimed: [mốc] }` ⇒ sang tháng tự về 0; dữ liệu qua `SaveManager`, có **di trú** từ `user://daily.cfg` (bitmask 4 nhiệm vụ cũ).

### 6.2. Bố cục (đo trực tiếp từ mockup, chia 2)
Khung thiết kế: **540×920** (dọc) · **960×540** (ngang). Mỗi layout có `Panel/Stage` khai `custom_minimum_size` = khung thiết kế; `daily.gd._layout_stage()` đặt Stage vào **giữa canvas** và **phóng/thu đều** theo `min(canvas.w/design.w, canvas.h/design.h)` ⇒ giữ đúng tỉ lệ mockup ở mọi cỡ màn hình (không kéo méo art).

| Khối | Vị trí · kích thước (thiết kế dọc) | Chi tiết |
|---|---|---|
| **TopBar** | Back (26,45) 36×36 · tiêu đề font 21 · phụ đề font 10 | Back = ô giấy trắng viền xanh `#6EA0C8` bo 16 |
| **Thanh Sao tháng** | (60,102) 448×42 | Nền navy `#164663` bo tròn + phần đã đạt màu hổ phách; **ngôi sao lớn** 75×65 ở đầu thanh chứa **số Sao tháng**; **4 huy hiệu mốc** (vòng 43 px + rương + nhãn "N★") |
| **Lịch tháng** | (54,206) 462×417 | Bảng giấy trắng viền xanh + gấp mép; hàng tháng `< Tháng 10 • 2026 >`; hàng T2…CN (**CN đỏ**); lưới 7×5 ô 57×58; **chú giải** ✓ Đã xong · ✗ Bỏ lỡ · □ Hôm nay · ⌐ Sắp tới |
| **Ô ngày** | 57×58 | Ô trắng + **✓ đỏ** (đã chơi) · ô hồng `#F1E2DE` + **✗ đỏ** (bỏ lỡ) · ô **nét đứt** (sắp tới) · số trơn (1–2 ngày tới, tháng trước) · **HÔM NAY**: ô kem viền hổ phách `#C4843A` + nhãn "HÔM NAY" + số lớn + viên **"x/6 ★"** · **ĐANG CHỌN**: vòng sáng xanh `#256C96` vẽ TRÙM ra ngoài ô 3 px (`Selected`) |
| **Chip làm mới** | (177,636) 186×24 | "⏱ Làm mới sau HH:MM:SS" (đếm ngược thật, `ResetTimer` 1 s) |
| **2 thẻ hành động** | (54,690) + (292,690), mỗi thẻ 224×195 | Băng dính chéo (xanh/hổ phách) · khung icon 41×41 · tiêu đề font 20 · dòng phụ font 11 · **3 Sao** (vàng/xám) · nét đứt · nút CTA 194×38 (xanh `#256C96` / hổ phách `#F59E0B`, bo 22, có bóng) |

**Bản ngang:** lịch ở cột trái (20,62) 462×417; cột phải 444 rộng gồm thanh Sao → chip làm mới → thẻ CHƠI (156 cao) → thẻ THỬ THÁCH (156 cao).

**Trạng thái nút CTA:** chưa chơi → "CHƠI NGAY"/"THỬ SỨC"; đã có Sao → "CHƠI LẠI"/"THỬ LẠI". Ngày bỏ lỡ **KHÔNG còn hiện giá Xu** — nút ghi như game đã mở (xem §6.6).
Dòng phụ thẻ THỬ THÁCH in **tên luật của ngày** bằng màu hổ phách.

### 6.3. Mốc thưởng THÁNG (`DailyManager.MILESTONES`) — đúng số trên mockup
| Mốc | Phần thưởng | Ghi chú |
|---|---|---|
| **15 ★** | +100 Xu | Huy hiệu 1 |
| **30 ★** | Gợi ý ×2 | Huy hiệu 2 |
| **45 ★** | +250 Xu **+ Hoàn tác ×2** | Huy hiệu 3 |
| **60 ★** | **+500 Xu + Gợi ý ×3** | Huy hiệu 4 (đích của thanh) |

- Huy hiệu: **vòng hổ phách đậm** = đã đạt · **vòng xanh nhạt** = chưa đạt · **✓ xanh** ở góc = **đã nhận thưởng**.
- Bấm huy hiệu khi đủ Sao để **nhận thưởng** (mỗi mốc 1 lần, `claimed` lưu cùng tháng); Xu vào ví chung, lượt công cụ qua `GameManager.grant_tool_uses(..., "daily_milestone")`.
- `MILESTONES` là **nguồn sự thật duy nhất** (UI + test đọc từ đây).

### 6.4. Cơ chế xoay vòng Special Mode
`challenge_mode_for_day(day)` = `ChallengeGameMode.CHALLENGE_IDS[(day - 1) % 8]` — cùng ngày luôn ra cùng luật:
`minesweeper · sum_path · countdown_cost · blind_memory · fog_of_war · fading_ink · one_stroke · wall_builder`.

### 6.5. File & kiểm thử
| Việc | File |
|---|---|
| Dữ liệu Sao/mốc thưởng | `scripts/manager/DailyManager.gd` |
| Màn hình | `scripts/scenes/daily.gd` · `scripts/scenes/layout/daily_layout.gd` · `scenes/daily.tscn` · `scenes/layout/{portrait,landscape}/daily.tscn` |
| Component | `nodes/daily/{calendar,day,action_card,milestone_chip}.tscn` (+ script trong `scripts/nodes/daily/`) |
| Art mới (SVG) | `assets/images/daily/`: `board` · `bar_track` · `bar_fill` · `star_big` · `ring_on/off` · `check_badge` · `chest` · `cell_done/missed/future/today` · `today_ribbon` · `pill_stars` · `card_paper` · `icon_box_blue/amber` · `tape_blue/amber` · `btn_square_*` · `btn_nav_*` · `btn_cta_blue/amber_*` · `chip_white` · `divider_dashed` · `tri_blue/white/dark` · `bolt_amber` · `check_red` · `cross_red` · `legend_box` · `legend_dashed` |
| Vào màn chơi | `GameManager.start_daily_play(day)` / `start_daily_challenge(day)`; chốt Sao ở `GameController._complete_daily_missions()` |
| Popup thắng | `nodes/popups/winning_daily.tscn` — **+N ★ ván này** + **Sao tháng `x/60 ★`** + con dấu `x/6 SAO` |
| Kiểm thử | `scripts/test_case/test_daily.gd` (**104 check**): mô hình Sao · giữ max · mốc thưởng · mở khoá · vào màn · 2 thẻ + 4 huy hiệu + ô lịch "x/6 ★" · popup · chơi thật 1 ván THỬ THÁCH + 1 ván CHƠI · **ví Xu 2 hướng + hiệu ứng Sao khi xong ván (§5d)** |

---


### 6.6. Chọn ngày · mở khoá bằng QUẢNG CÁO · popup nhận thưởng (v2.30)

**a) Ô lịch ĐANG CHỌN.** Bấm một ngày ⇒ `DailyCalendar.set_selected_day(day)` bật vòng sáng
(`assets/images/daily/cell_selected_ring.svg` → PNG) quanh **đúng ô đó** — vẽ trùm ra ngoài ô 3 px nên
không đè viền hổ phách của ô HÔM NAY. Chỉ **một** ô sáng tại một thời điểm; ô trống/tháng khác thì không sáng.
`daily.gd._refresh()` đồng bộ lại vòng sáng sau mỗi lần dựng lịch.

**b) Ngày bỏ lỡ: xem QUẢNG CÁO thay vì trả Xu.** (v2.30 bỏ hẳn "MỞ KHOÁ: 50 XU")
- Nút CTA của ngày bỏ lỡ ghi **như game đã mở** ("CHƠI NGAY"/"THỬ SỨC"), không còn giá Xu.
- Bấm CTA trên ngày bỏ lỡ ⇒ `daily.gd._request_ad_then_play()` gọi
  **`AdsManager.show_rewarded("daily_unlock")`**; nhận `rewarded_completed("daily_unlock")` xong mới
  **mở khoá MIỄN PHÍ** (`set_day_unlocked`) rồi **vào đúng hoạt động vừa bấm** (CHƠI hoặc THỬ THÁCH) —
  nhớ `_ad_challenge_pending` để biết vào thẻ nào.
- `AdsManager` hiện là **PLACEHOLDER** (`scripts/manager/AdsManager.gd`, `enabled = true` giả lập "xem xong"):
  khi gắn SDK thật chỉ cần thay thân `show_rewarded()`, phần còn lại của luồng giữ nguyên.
  Nếu `show_rewarded()` trả `false` (chưa có quảng cáo) thì ngày **vẫn khoá**, chỉ kêu tiếng "cụt".
- **Không trừ Xu**: `DailyManager.unlock_day()` (trả 50 Xu) chỉ còn là API dự phòng, UI không gọi.

**c) Bấm rương mốc đã đủ Sao ⇒ nhận thưởng + POPUP NHỎ.**
- `_on_milestone_claim()` → `DailyManager.claim_milestone(threshold)` (cộng Xu + lượt công cụ) → mở
  **`Popups.open(Popups.DAILY_MILESTONE, {stars, reward})`** = `nodes/popups/daily_milestone.tscn`
  (`DailyMilestonePopup`): thẻ giấy nhỏ giữa màn, **rương + "MỐC N★" + "Đã nhận thưởng tháng" + chuỗi phần thưởng**
  (dựng từ `DailyManager.reward_text()`) + nút **TUYỆT VỜI**. Dim nền tối, bấm ra ngoài/Back đều đóng.
- Huy hiệu mốc đổi sang **vòng hổ phách + ✓ xanh** sau khi nhận; mốc chưa đủ Sao thì nút bị khoá.

| Việc | File |
|---|---|
| Vòng sáng ô đang chọn | `assets/images/daily/cell_selected_ring.svg` (+PNG) · `nodes/daily/day.tscn` (`Selected`) · `scripts/nodes/daily/{day,calendar}.gd` · `scripts/scenes/daily.gd` |
| Quảng cáo mở khoá | `scripts/manager/AdsManager.gd` (placeholder) · `scripts/scenes/daily.gd` (`_enter_day` · `_request_ad_then_play` · `_on_ad_rewarded` · `_grant_day_unlock` · `_start_day`) |
| Popup thưởng mốc | `nodes/popups/daily_milestone.tscn` · `scripts/nodes/popups/daily_milestone.gd` · `PopupManager.POPUPS["daily_milestone"]` · `Popups.DAILY_MILESTONE` |
| Khoá dịch mới | `STR_DAILY_MILESTONE_POPUP_{TITLE,SUB,OK}` |
| Kiểm thử | `test_daily` thêm **§5b** (chỉ 1 ô sáng + đúng ô · CTA ngày bỏ lỡ không còn "XU" · mở khoá bằng quảng cáo **không trừ Xu**) và **§5c** (nhận mốc → `Popups.is_open("daily_milestone")` + tiêu đề/phần thưởng đúng) ⇒ **94 check**; `test_popup_bindings` phủ luôn popup mới (32 check) |

---

### 6.7. Rương quà: animation MỞ/ĐÓNG (v2.32)

**a) Asset animation sinh từ spritesheet.** `assets/images/spritesheets/chest_spritesheet.png`
(3072×2048 · 6 cột × 4 hàng · khung 512×512 · 24 frame · 12 fps) + `chest_spritesheet.json`
(có `tags`: `open` 0–15, `idle` 16–23) ⇒ sinh `resources/animations/chest_frames.tres`
(**`SpriteFrames`**) với 3 animation:

| Animation | Frame | Lặp | Dùng khi |
|---|---|---|---|
| `closed` | 0–5 | ✔ | Rương **đóng** — nhịp rung nhẹ trong lúc *đung đưa* |
| `open` | 0–15 | ✘ | Rung → **bung nắp** → lộ châu báu (1,33 s) |
| `idle` | 16–23 | ✔ | Rương **mở** + lấp lánh (giữ mãi sau khi mở) |

- Mọi frame dùng **cùng một vùng cắt** `Rect2(68, 96, 376, 332)` (union bbox của cả sheet,
  đo bằng PIL) ⇒ rương **không nhảy** vị trí/kích thước giữa các frame; rương nằm đúng giữa
  vùng cắt nên tâm xoay/scale trùng tâm rương.

**b) Hiệu ứng trong popup — viết bằng `AnimationPlayer` NGAY TRONG SCENE.**
`nodes/popups/daily_milestone.tscn` đổi `Chest` (TextureRect) → **`Chest` (Control neo điểm) +
`Sprite` (`AnimatedSprite2D`)**; `AnimationPlayer` `FxAnim` có animation **`reveal`** (2,9 s):

| Track | Nội dung |
|---|---|
| `Sprite:animation` | `closed` (0 s) → `open` (1,05 s) → `idle` (2,55 s) — khoá rời rạc (`update = 1`) |
| `Sprite:rotation` | **đung đưa** trước khi mở: 0 → −5,5° → +5,5° → −3° → 0 |
| `Sprite:scale` | **squash & stretch**: (0,61) → (0,64 · 0,58) lúc bắt đầu bung → (0,60 · 0,64) → về (0,61) |
| `Sprite:position` | **nhảy nhẹ** lên 16 px rồi hạ xuống khi nắp bung |
| `Panel/Art/WashiTape:rotation` | băng dính rung theo nhịp mở |

`autoplay = "reveal"` + `daily_milestone.gd._replay_reveal()` chỉ **gọi lại** animation khi popup
được mở lại (không có tween/hiệu ứng nào trong script).

**c) Chip mốc trên thanh Sao tháng** (`nodes/daily/milestone_chip.tscn`):
- **Chưa nhận thưởng** → `assets/images-png/daily/chest_closed.png` (rương đóng).
- **Đã nhận thưởng** → `chest.png` (rương mở, có châu báu) + huy hiệu ✓ xanh.
- Chip chưa đủ Sao vẫn dùng rương đóng nhưng giảm độ đậm (`modulate` 0,85).

**d) Lưu ý kỹ thuật (đã sửa):** Godot 4 **không** nạp thư viện animation qua cú pháp
`libraries/ = SubResource(...)` (im lặng để `libraries = {}`, `has_animation()` trả `false` — mọi popup
trong dự án đang rơi vào nhánh tween dự phòng). Cú pháp ĐÚNG là **`libraries = { &"": SubResource(...) }`**;
đã áp cho `daily_milestone.tscn` và 2 layout `scenes/layout/{portrait,landscape}/daily.tscn`
(nên `PulseAnim`/`EnterAnim` của màn Daily nay chạy thật).

| Việc | File |
|---|---|
| Nguồn frame | `assets/images/spritesheets/chest_spritesheet.png` + `.json` |
| SpriteFrames | `resources/animations/chest_frames.tres` |
| Popup + hiệu ứng | `nodes/popups/daily_milestone.tscn` (`Chest/Sprite`, `FxAnim: reveal`) · `scripts/nodes/popups/daily_milestone.gd` |
| Chip mốc | `nodes/daily/milestone_chip.tscn` · `scripts/nodes/daily/milestone_chip.gd` |
| Rương tĩnh (SVG → PNG) | `assets/images/daily/chest.svg` · `chest_closed.svg` → `assets/images-png/daily/{chest,chest_closed}.png` |

---

### 6.8. Ví Xu trên thanh trên + hiệu ứng Sao khi hoàn thành ván (v2.33)

**a) Ví Xu (`CoinChip`) ở CẢ 2 bố cục.** Màn Daily nay có ví Xu ở góc phải thanh trên — dùng
**đúng** `nodes/main/coin_chip.tscn` như Main Screen (icon giọt mực vàng + số Xu + nút `+` mở Cửa hàng),
nên người chơi thấy số Xu và vào Cửa hàng ngay trong màn Daily mà không phải quay về Main.

| Bố cục | Kích thước | Vị trí (trong `Panel/Stage`) | Node |
|---|---|---|---|
| Dọc (`scenes/layout/portrait/daily.tscn`) | 111×32 | `x` 324…440 · `y` 4…39 | `TopBar/CoinChip` |
| Ngang (`scenes/layout/landscape/daily.tscn`) | 111×32 | bám mép phải `TopBar` | `TopBar/CoinChip` |

- Thanh trên thu hẹp Tiêu đề/Phụ đề để **không đè** ví Xu (dọc: `offset_right` 292, cỡ chữ tiêu đề 17;
  ngang: Tiêu đề thêm `offset_left = 70`, `offset_right = -290`) — từ v2.38 thanh trên còn có thêm
  **`LifeChip`** (`TopBar/LifeChip`, 96×32 — khai trong `base_layout`) nằm ngay phải ví Xu (xem §4.2 · §5.10b).
- Script layout khai thêm `@export var coin_chip: CoinChip`; `daily.gd` chỉ **đọc/ghi dữ liệu**:
  `_refresh_wallet()` → `coin_chip.set_value(Shop.coins())` (gọi trong `_refresh()`). Từ v2.35 chip
  **tự** nghe `ArchivementManager.progress_changed` và nút `+` **tự** mở Cửa hàng (không còn nối
  `plus_pressed` thủ công trong `daily.gd`). Layout Daily khai trực tiếp **một** `CoinChip` trong
  `TopBar/HeaderRow` (không còn chip mặc định trong `base_layout.tscn`).

**b) Hiệu ứng Sao khi vừa hoàn thành ván.** `GameController._complete_daily_missions()` (sau khi
`record_daily_win`) đặt cờ **một lần** vào `GameManager.daily_celebrate`:

```gdscript
{ "day": <ngày>, "challenge": <true nếu ván THỬ THÁCH>, "stars": <Sao của ván>, "gained": <Sao tăng thêm> }
```

`GameManager.take_daily_celebrate()` **đọc rồi xoá** (chỉ ăn mừng 1 lần, không lặp lại khi mở lại
màn). `daily.gd._ready()` gọi `_celebrate_daily_win()` (deferred) → nếu có cờ thì chọn đúng **ngày**
vừa chơi, chờ **0,55 s** (cho `EnterAnim` của layout chạy xong) rồi gọi `play_celebrate()` trên
**đúng thẻ** (`challenge` → thẻ THỬ THÁCH, ngược lại → thẻ CHƠI).

**c) Animation khai trong SCENE, script chỉ chọn animation.** `nodes/daily/action_card.tscn` có
`FxAnim` (`AnimationPlayer`) với 3 animation **`celebrate_1` / `celebrate_2` / `celebrate_3`**
(chọn theo số Sao đã đạt): từng ngôi sao đã đạt **nảy lần lượt** (scale 1 → 1,45 → 0,92 → 1) +
khung icon nhún nhẹ; `pivot_offset` của Sao (14,5; 14,5) và IconBox (20,5; 20,5) đặt sẵn trong
scene nên hiệu ứng nảy quanh **tâm** từng node. `DailyActionCard` chỉ có: `play_celebrate()`
(chọn `celebrate_N` + `play`), `is_celebrating()`, `stop_celebrate()`.

| Việc | File |
|---|---|
| Ví Xu (scene dùng chung) | `nodes/main/coin_chip.tscn` · `scripts/nodes/coin_chip.gd` |
| Gắn ví + thu hẹp tiêu đề | `scenes/layout/{portrait,landscape}/daily.tscn` |
| Cờ "vừa xong ván" | `scripts/core/game_manager.gd` · `scripts/core/controllers/game_controller.gd` |
| Tiêu thụ cờ + chọn thẻ | `scripts/scenes/daily.gd` (`_celebrate_daily_win`) |
| Animation Sao | `nodes/daily/action_card.tscn` (`FxAnim`) · `scripts/nodes/daily/action_card.gd` |
| Kiểm thử | `scripts/test_case/test_daily.gd` §5d (ví Xu 2 hướng · đúng thẻ CHƠI/THỬ THÁCH · đọc cờ 1 lần · tự chọn ngày) |

---

## 7. Hệ thống Điểm số & Xếp hạng (Scoring & Leaderboards)

- **Sao (Star) — áp dụng MỌI chế độ:** 1 match-up có **3 Challenge**, hoàn thành 1 Challenge = **1 Sao** (xem 3.1). Sao **KHÔNG** còn phụ thuộc thời gian còn lại.
- **Play Mode:** Xếp hạng theo **Thời gian hoàn thành nhanh nhất** cho từng Màn (không xếp theo số bước — Play Mode không giới hạn bước).
- **Dungeon Mode:** Xếp hạng theo **Floor cao nhất đạt được** và tổng điểm tích lũy (chế độ duy nhất có bộ đếm bước còn lại).
- **Blind Memory Maze / Fog of War Maze:** Xếp hạng theo **Thời gian hoàn thành nhanh nhất** cho ngày Daily Challenge tương ứng.
- **Countdown Cost:** Xếp hạng theo **tổng chi phí bước đã dùng** (càng ít càng tốt, đúng tinh thần "tối ưu chi phí"), sau đó mới tới thời gian — hoặc theo cách server tổ chức ngày hôm đó.
- **Sum Path / Fading Ink:** Xếp hạng theo **Điểm độ chính xác và thời gian**.
- Ngoài xếp hạng riêng từng bộ luật, Daily Challenge còn có **bảng xếp hạng theo tổng số sao tích lũy trong tháng** và **độ dài Streak**.

**Đã hiện thực (bản offline, 2026-02):** màn **BẢNG XẾP HẠNG** với 3 tab DUNGEON · CHẾ ĐỘ PLAY · CHUỖI NGÀY — xem **mục 11** để biết công thức điểm, dữ liệu thật/mô phỏng và các file liên quan. Khi nối Google Play Games sẽ thay nguồn dữ liệu đối thủ, không phải sửa UI.

---

## 8. Sổ tay thành tựu (Badge Book / Achievement)

Màn hình `scenes/archivement.tscn` — vào từ **Main Screen → nút "SỔ TAY THÀNH TỰU"** (hàng nút Other, nút thứ 4) hoặc từ Debug Console (`Badge Book`).

### 8.1. Dữ liệu: mỗi danh hiệu = 1 file `.tres` (data-driven)

- Danh sách danh hiệu **không nằm trong code**: `ArchivementManager` quét toàn bộ `resources/archivements/*.tres` (`ArchivementData`) lúc khởi động → **thêm/bớt danh hiệu chỉ cần thêm/bớt file**, không sửa code.
- Trường của 1 danh hiệu: `id` (duy nhất) · `category` · `title` / `description` (tiếng Việt hiển thị trong game) · `title_key` / `desc_key` (tuỳ chọn, dùng chuỗi localization) · `icon` · `stat` (khoá số liệu) + `target` + `unit` (đơn vị hiển thị, ví dụ "Tầng") · `reward_coins` (xu) · `points` (AP) · `secret` (danh hiệu ẩn).
- Danh sách đầy đủ 28 danh hiệu hiện có (id · điều kiện · thưởng) được xuất ra **`archivements_list.txt`** ở gốc project.

### 8.2. Phân nhóm (5 tab)

| Tab | `category` | Số danh hiệu | Nội dung |
|---|---|---|---|
| **TẤT CẢ (n)** | `` (rỗng) | 28 | Toàn bộ catalog |
| **MÀN CHƠI** | `levels` | 7 | Số màn đã qua · tổng sao · số màn 3 sao · tốc độ phá màn |
| **DUNGEON** | `dungeon` | 7 | Tầng sâu nhất · tổng tầng đã vượt · điểm cao nhất 1 ván |
| **DAILY** | `daily` | 7 | Số ngày Daily · chuỗi ngày liên tiếp · tổng sao Daily |
| **ĐẶC BIỆT** | `special` | 7 (2 ẩn) | Thắng không gợi ý / không hoàn tác · Hardcore · số danh hiệu đã nhận + **2 danh hiệu ẨN** |

### 8.3. Bốn trạng thái của thẻ danh hiệu

| Trạng thái | Điều kiện | Hiển thị |
|---|---|---|
| **ĐÃ ĐẠT** (xanh lá `#2E7D32`) | đủ điều kiện **và** đã bấm NHẬN | dấu mộc đỏ "ĐÃ ĐẠT · +N xu", thanh tiến độ 100%, dòng tiến độ thêm "(Hoàn thành)" |
| **NHẬN THƯỞNG** (cam `#D97706`) | đủ điều kiện, **chưa** nhận | nút **NHẬN +N** kèm icon xu |
| **ĐANG LÀM** (xanh dương `#3D83AE`) | chưa đủ điều kiện | chip "Thưởng: +N" + tiến độ `x / y đơn vị` |
| **ẨN / KHÓA** (xám `#7A8F9B`) | danh hiệu `secret` chưa đạt | ổ khoá + "Thành Tựu Ẩn • Chưa Khám Phá" + tiến độ `??? / ???` |

### 8.4. Phân trang & thao tác

- **5 thẻ / trang** (`ArchivementScene.CARDS_PER_PAGE = 5`, nhịp thẻ 190px) — catalog nhiều lên thì số trang tự tăng, giống màn **Chọn màn**; hiện tại 28 danh hiệu = 6 trang ở tab TẤT CẢ.
- Chuyển trang: **vuốt ngang** (Touch / Drag / lăn chuột), bấm **dots**, hoặc `go_to_page(i)`. Mở Sổ tay sẽ tự nhảy tới **trang chứa danh hiệu đầu tiên đang chờ nhận thưởng**.
- Bấm tab → dựng lại danh sách + dots theo nhóm đó (kèm SFX lật trang).
- Bấm **NHẬN** → `ArchivementManager.claim(id)`: cộng `reward_coins` vào ví, đánh dấu đã nhận, phát SFX con dấu, vẽ lại toàn bộ màn + cập nhật thẻ tổng kết. **Nhận lần 2 bị chặn** (không cộng xu).
- Thẻ tổng kết (đầu trang): thanh tiến độ **% đã mở khoá**, dòng `Đã mở: x / y Danh hiệu • Điểm: n AP`, dấu mộc góc phải `x/y BADGES`.

### 8.5. Số liệu (stats) — 2 loại

| Loại | Cách có dữ liệu | Khoá |
|---|---|---|
| **Dẫn xuất** (đọc lại khi mở Sổ tay) | đọc từ `GameManager` (sao + best time từng màn) và `DailyManager` (số ngày · chuỗi ngày · tổng sao) | `levels_cleared`, `level_stars_total`, `level_perfect`, `fastest_clear`, `daily_days`, `daily_streak`, `daily_stars_total`, `claimed_count` |
| **Tích luỹ** (game báo về mỗi ván) | `GameController` gọi `Archivement.notify_run_result({mode_id, won, endless, floor, score, elapsed, wall_hits, hints_used, undos_used, hardcore})` ở popup thắng/thua | `dungeon_best_floor`, `dungeon_floors_total`, `dungeon_best_score`, `wins_total`, `wins_no_hint`, `wins_no_undo`, `hints_total`, `undos_total`, `hardcore_wins`, `play_seconds` |

- `dungeon_best_floor` = tầng **sâu nhất đã tới** (thắng tầng N ⇒ đã tới tầng N+1) nên danh hiệu "Tầng 5/15/30" luôn khớp với dòng "Tầng tiếp theo" ở popup thắng.
- Danh hiệu ẩn vẫn **đếm tiến độ ngầm**; khi đủ điều kiện thì tự hiện tên thật + mô tả điều kiện (người chơi mới biết mình vừa đạt gì).

### 8.6. Lưu trữ

- `ArchivementManager` là **provider của SaveManager**: `export_progress()` → `{coins, claimed[], stats{}}`, `import_progress(data)`, `reset_progress()`; mọi thay đổi số liệu phát `progress_changed` → SaveManager **autosave** (giống `level_completed` của GameManager, `daily_changed` của DailyManager).
- Số liệu **dẫn xuất KHÔNG lưu** (luôn tính lại từ GameManager/DailyManager) → tránh lệch dữ liệu khi save cũ được nạp.
- **Điểm danh hiệu (AP)** = tổng `points` của các danh hiệu **đã đạt** (không cần nhận thưởng); **xu** chỉ cộng vào ví khi bấm NHẬN (tổng thưởng tối đa của catalog hiện tại: 5.260 xu · 810 AP).

### 8.7. File liên quan

| File | Vai trò |
|---|---|
| `resources/archivements/*.tres` | **Catalog** 28 danh hiệu (data-driven) |
| `scripts/resources/archivement_data.gd` | Resource `ArchivementData` — schema 1 danh hiệu |
| `scripts/manager/ArchivementManager.gd` | Autoload: nạp catalog · tính số liệu · kiểm tra mở khoá · nhận thưởng · lưu trữ |
| `scripts/utils/archivement.gd` | Facade tĩnh `Archivement.*` cho UI/test (không tham chiếu autoload trực tiếp) |
| `scenes/archivement.tscn` + `scripts/scenes/archivement.gd` | Màn "Sổ tay thành tựu" (tab + phân trang + tổng kết + nút Nhận) |
| `nodes/archivements/card.tscn` + `scripts/nodes/archivements/card.gd` | Thẻ 1 danh hiệu (4 trạng thái) |
| `assets/images/archivements/*.svg` | Giấy sổ tay · 4 nền thẻ · tab · thanh tiến độ · dấu mộc · chip · nút NHẬN · huy hiệu |
| `scripts/test_case/test_archivement.gd` | Test catalog · tiến độ · nhận thưởng · lưu trữ · phân trang scene (54 check) |
| `archivements_list.txt` | Danh sách danh hiệu dạng văn bản (xuất từ catalog) |

---

## 9. Debug Console (chỉ có ở bản dev)

Mở bằng **F9** (hoặc bấm 5 lần vào con dấu phiên bản ở màn Settings, hoặc `Nav.goto_debug()`); bấm F9 lần nữa để quay lại.

| Nhóm | Nội dung |
|---|---|
| STATE | FPS/MEM/Obj · locale · mode · **ván test** (cờ + tầng ép) · số popup đang mở |
| **LIVES** | Xem `lượt/max` + **đếm ngược lượt kế tiếp** · `SpinBox` đặt số lượt (0–5) · **Empty lives (0)** (thử popup HẾT LƯỢT CHƠI) · **Fill lives (5)** · **Advance 30 min recharge** — xem §5.10b |
| NAVIGATE | Main · Chọn màn · Daily · Settings · **Tutorial** · Sổ tay thành tựu · Dungeon run |
| PROGRESS | Nhảy tới màn 1–9 · mở khoá tất cả · ghi 3 sao · xoá tiến trình (**xoá cả RƯƠNG THƯỞNG của từng chương** — `chapter_chests`, xem §12.4b) |
| DAILY | **Đọc:** hôm nay · chuỗi ngày · Sao CHƠI hôm nay (x/3) · Sao hôm nay (x/6) · **Sao tháng (x/60)** · **mốc kế tiếp** · **số mốc đã nhận** · **trạng thái ngày hôm qua** · **trạng thái AdsManager** — **Lệnh:** chơi CHƠI/THỬ THÁCH hôm nay · đánh dấu hôm nay xong **6 Sao** · **+30 Sao tháng** · **Nhận mốc kế tiếp (mở popup thưởng)** · **Test rewarded ad** · **Mở khoá hôm qua (AD · miễn phí)** · **Mở khoá mọi ngày bỏ lỡ (AD · miễn phí)** · xoá dữ liệu Daily — xem §9.3 |
| **EVENTS** | Danh sách event đang mở + tiến độ · **Bắt đầu ngay / Kết thúc ngay** (ép cửa sổ thời gian) · **±1 ngày** (dịch `now_utc` giả) · **Hoàn thành màn kế** · **đặt tiến độ = đủ** · **Nhận quà** · **Reset tiến độ + cờ đã nhận** — xem §15.5 |
| **SPECIAL MODES (TEST)** | Vào thẳng **9 chế độ Special** (vốn chỉ chơi được qua Daily) — xem 9.1 |
| **TUTORIAL (TEST)** | Vào thẳng **7 bài hướng dẫn** + chạy lại chuỗi onboarding — xem 9.2 |
| SAVE | Backend · save now · reload · đổi backend · xoá toàn bộ + dump blob JSON |
| POPUPS | Mở thử win / next floor / game over / pause / language |
| DEBUG FLAGS | Bật/tắt log theo nhóm (general · sfx · flow · save) |

### 9.1. Test 9 chế độ Special (SPECIAL MODES)

Daily Challenge chỉ cho chơi **1 luật/ngày** (`(ngày-1) % 9`), nên Debug Console cho vào thẳng từng luật để test:

- **Test mode (mặc định BẬT):** ván mở từ đây **không ghi tiến trình** — không đánh dấu ngày Daily (`_mark_daily_completed_if_needed` bỏ qua) và không tính vào Sổ tay thành tựu (`_report_to_archivements` bỏ qua). Tắt toggle nếu muốn ghi như chơi thật.
- **Độ khó:** easy · medium · hard (áp dụng cho các luật có tham số độ khó: `sum_path`, `countdown_cost`, `blind_memory`, `fog_of_war`, **`one_stroke`**, **`wall_builder`**).
- **Tầng bắt đầu:** 1 · 2 · 3 · 5 — một số luật sinh bàn theo tầng (`minesweeper`: `2 + tầng`, tối đa 5×5) nên chọn tầng cao để test bàn to.
- **Mỗi chế độ 1 hàng lệnh:** tiêu đề ghi `Tên mode [id] · Daily ngày N, N+7, N+14…`; dòng mô tả lấy trực tiếp từ `BaseGameMode.mode_description` của chính mode đó (không chép lại chữ).
- Thêm **“Chế độ kế tiếp”** (xoay vòng 9 luật) và **“Chế độ ngẫu nhiên”** để test nhanh nhiều luật liên tiếp.

Cơ chế: `GameManager.prepare_mode_run(mode_id, difficulty, test_run, floor_override)` (đặt cờ, **không** đổi scene — test gọi được) và `GameManager.start_mode(...)` (= prepare + vào `scenes/game.tscn`); `game.gd::_start_floor_for()` đọc `start_floor_override` để chọn tầng xuất phát cho ván test.

### 9.2. Test Tutorial (TUTORIAL (TEST)) — 7 bài hướng dẫn

Muốn **xem lại 1 bài hướng dẫn** (hoặc ôn cả chuỗi onboarding) mà không phải chơi từ đầu: mục
**TUTORIAL (TEST)** trong Debug Console.

- **Mỗi bài 1 hàng lệnh** (dấu `●` = đã học xong · `○` = chưa): bấm là **vào thẳng bài đó** — Debug gọi
  `GameManager.request_tutorial(id)` rồi `Nav.goto_tutorial()`; màn **CHI TIẾT** (`scenes/tutorial.tscn`) đọc
  yêu cầu bằng `take_tutorial_request()` (**đọc 1 lần rồi xoá**) và gọi
  `TutorialController.play_single_tutorial(id)`.
  Danh sách bài lấy từ `TutorialController.TUTORIAL_SCENES` ⇒ thêm bài mới là console tự có hàng,
  và nút **“Tutorial (menu)”** (mở màn **DANH SÁCH** `scenes/tutorial_list.tscn`) nằm luôn ở nhóm NAVIGATE.
- **“Chạy chuỗi CORE (3 bài onboarding)”**: `request_tutorial(TutorialController.REQUEST_CORE)` ⇒ màn CHI TIẾT
  chạy `start_sequence()` (first_time → move → checking wall).
- **Test mode**: DÙNG CHUNG cờ `GameManager.debug_run` với SPECIAL MODES — bật thì học xong **không ghi**
  `tutorial_progress` (`TutorialController._save_progress()` bỏ qua) và **không tự nhảy** vào Màn 1.
- **Học xong về DANH SÁCH**: mở bài LẺ từ Debug (hoặc Test mode bật) ⇒ `TutorialScene._stay_after_finish` ⇒
  `Nav.back_to_tutorial_list()` (màn danh sách để chọn bài khác); luồng onboarding thật vẫn giữ hành vi cũ
  (xong → bước kế của luồng / Màn 1). Xem §10.2i.
- **“Đánh dấu xong hết”** = `mark_core_tutorials_completed()` + ghi cờ cả 7 bài · **“Xoá tiến trình tutorial”**
  = `GameManager.reset_tutorial_progress()` (KHÔNG đụng tiến trình màn chơi).
- Kiểm thử: `test_debug_modes` **mục 6** (console có đủ hàng · API yêu cầu · màn Tutorial mở đúng bài ·
  Test mode không ghi · Test mode tắt thì ghi · reset xoá sạch) — **59/59 PASS**.

---

## 10. Mockup matchup & đặc tả HUD theo chế độ

**Mockup matchup** = bản vẽ 1080×1920 mô tả **đúng hàng HUD của một chế độ** (khung `Information` 980×249 tại `(50,175)`), kèm màn chơi, thanh nút dưới, và **bảng chú thích đánh số** cho từng thẻ.

### 9.3. Test DAILY (v2.30) — chọn ngày · mốc thưởng · mở khoá bằng quảng cáo

Nhóm **DAILY** trong Debug Console bám đúng luồng mới của màn Daily (§6.6):

| Mục | Ý nghĩa |
|---|---|
| `Play stars today` / `Stars today` | Sao phần CHƠI (0..3) và tổng Sao hôm nay (0..6) |
| `Stars this month` | Sao tích luỹ tháng / đích của thanh (`month_star_goal`, mặc định 60) |
| `Next milestone` | Mốc kế tiếp chưa đạt + còn thiếu bao nhiêu Sao (hoặc “đã đạt hết”) |
| `Milestones claimed` | Số huy hiệu đã nhận / tổng số mốc |
| `Yesterday` | Ngày hôm qua **đã chơi/mở khoá** hay còn **BỎ LỠ (cần quảng cáo)** |
| `AdsManager` | `placeholder BẬT` (chưa gắn SDK, `show_rewarded()` giả lập xem xong) hoặc `TẮT` |
| **Add +30 stars this month** | Cộng dồn 30 Sao vào đầu tháng (mỗi ngày tối đa 6) để thấy thanh tiến độ + huy hiệu đổi màu |
| **Claim next milestone** | Nhận mốc kế tiếp đã đủ Sao ⇒ mở luôn **popup thưởng** `daily_milestone` (test cả luồng nhận) |
| **Test rewarded ad** | Gọi `AdsManager.show_rewarded("daily_unlock")` đúng 1 lần — **không ghi dữ liệu**, footer báo “xem xong ✔ / KHÔNG phát được ✘” |
| **Unlock yesterday (AD · free)** | Mở khoá ngày hôm qua **miễn phí** (mô phỏng kết quả sau khi xem quảng cáo) — dùng để test trạng thái ô lịch “ĐÃ MỞ” |
| **Unlock all missed days (AD · free)** | Mở khoá **mọi** ngày đã qua còn bỏ lỡ để xem nhanh lịch ở trạng thái “đã mở hết” |

> Từ v2.30 **không còn lệnh “trả Xu mở khoá”** trong Debug (game cũng không trả Xu nữa —
> xem §6.6b). Muốn xem lại vòng sáng “đang chọn”: mở màn Daily rồi bấm một ngày bất kỳ trên lịch.

### 10.1. Danh sách mockup

| Chế độ | `mode_id` | HUD scene | Mockup matchup | Thẻ trên HUD |
|---|---|---|---|---|
| Play Mode | `play` | `nodes/hud/level_mode.tscn` (LevelHUD) | `mockup/matchup_level.svg` | **CHỈ THỜI GIAN** (thẻ THỬ THÁCH gỡ 2026-09-27 — kết quả + Sao ở popup kết ván) |
| Dungeon Mode | `dungeon` | `nodes/hud/dungeon_mode.tscn` (DungeonHUD) | `mockup/matchup_dungeon.svg` | **SỐ BƯỚC + TẦNG** (bỏ đồng hồ — 2026-09-27) |
| Time Attack Maze | `time_attack` | `nodes/hud/time_attack_hud.tscn` (TimeAttackHUD) | `mockup/matchup_time_attack.svg` | **CHỈ THỜI GIAN** (đếm ngược, đặt giữa khung — 2026-09-19) |
| Minesweeper Maze | `minesweeper` | `nodes/hud/minesweep_hud.tscn` (MinesweepHUD) | `mockup/matchup_minesweeper.svg` | **CHỈ THỜI GIAN** (bỏ thẻ BOM CÒN LẠI — 2026-09-27) |
| Blind Memory Maze | `blind_memory` | `nodes/hud/blind_memory_hud.tscn` (BlindMemoryHUD) | `mockup/matchup_blind_memory.svg` | **CHỈ THỜI GIAN** (bỏ thẻ GHI NHỚ; popup đếm ngược giữ nguyên — 2026-09-27) |
| Fog of War Maze | `fog_of_war` | `nodes/hud/fog_of_war_hud.tscn` (FogOfWarHUD) | `mockup/matchup_fog_of_war.svg` | **CHỈ LƯỢT THỬ LẠI** (bỏ đồng hồ · tầm nhìn · cảnh báo — 2026-09-27) |
| One Stroke | `one_stroke` | `nodes/hud/one_stroke_hud.tscn` (OneStrokeHUD) | `mockup/matchup_one_stroke.svg` | **CHỈ THỜI GIAN** (bỏ BẢNG TIẾN ĐỘ PHỦ KÍN — 2026-09-27) |
| Wall Builder | `wall_builder` | `nodes/hud/wall_builder_hud.tscn` (WallBuilderHUD) | `mockup/matchup_wall_builder.svg` | **CHỈ THỜI GIAN** (bỏ BẢNG TƯỜNG ĐÃ VẼ — 2026-09-27) |
| Sum Path | `sum_path` | `nodes/hud/sum_path_hud.tscn` (SumPathHUD) | `mockup/matchup_sum_path.svg` | **TỔNG — TOÁN TỬ — MỤC TIÊU** (bỏ đồng hồ + thanh tiến độ + dòng tiêu đề — 2026-09-27) |
| Countdown Cost | `countdown_cost` | `nodes/hud/countdown_hud.tscn` (CountdownHUD) | `mockup/matchup_countdown_cost.svg` | **CHỈ NGÂN SÁCH CÒN** (bỏ đồng hồ · tiêu tốn · giá cước · dải phân đoạn — 2026-09-27) |
| Fading Ink | `fading_ink` | `nodes/hud/fading_ink_hud.tscn` (FadingInkHUD) | `mockup/matchup_fading_ink.svg` | **CHỈ THỜI GIAN** (bỏ TRẠM ĐO ĐỘ PHAI MỰC — 2026-09-27) |

> **v2.18 (2026-09-27) — HUD “chỉ hiện thứ cần thiết” (theo yêu cầu user)**: mỗi HUD CHỈ còn đúng thẻ
> cần cho luật chơi; các node thừa đã **XOÁ HẲN khỏi scene** bằng tool `tools/ui/hud_trim.py`
> (bảng `CONFIG` trong tool là nguồn sự thật: xoá node + chỉnh cỡ/neo panel + dọn `@export` cho khớp).
> ⚠️ Node `Time` của bản DỌC là node **KẾ THỪA** (`game_hud.tscn`) ⇒ KHÔNG xoá được, chỉ ẩn được
> (`visible = false`); bản NGANG khai `Time` trong từng HUD chế độ nên xoá được thật.
> **Hàng rào**: `test_ui_scenes` mục **10** chốt tập node CON CÒN LẠI của `Content/ModeInformation`
> (node bị ẩn coi như không hiện) + ruột thẻ `Sheet` (Countdown = `Budget` · Fog = `Retry` ·
> Sum Path = `BlockCurrent`+`Emblem`+`BlockTarget`) cho **cả 2 hướng**; mục **9** vẫn kiểm mọi `@export`
> node phải được bind (bảng `HUD_EXPORT_OPTIONAL` ghi rõ export cố ý trống vì node đã xoá).
> **Hệ quả kèm theo**: `ChallengeController` không còn nhận thẻ (`card` = null ⇒ bỏ qua vẽ), popup
> thắng/thua vẫn hiện đủ 3 thử thách + Sao; `MinesweepHUD`/`BlindMemoryHUD`/`FadingInkHUD`/
> `OneStrokeHUD`/`WallBuilderHUD`/`LevelHUD` nay là lớp RỖNG (chỉ để `GameScene` chọn đúng scene HUD +
> cho test nhận diện lớp). Kiểm chứng: `test_ui_scenes` **71/71** · `test_challenge_controller`
> **PASS** (trước 24 check lệch) · full suite **14/14**.

> Hiện **mọi chế độ Special đều có HUD scene riêng** (không dùng chung `LevelHUD` nữa); `matchup_level.svg` (Play) vẫn là mockup gốc cho layout `LevelHUD`. Các chế độ dùng **khung HUD mới (mục 10.2b)** và **KHÔNG hiện thẻ THỬ THÁCH trên HUD**: `sum_path` · `countdown_cost` · `fading_ink` (2026-02) · `fog_of_war` (2026-09-18) · `one_stroke` · `wall_builder` (2 chế độ mới — §5.12–5.13, chưa lập trình). Thử thách/Sao vẫn được tính đủ và hiện ở popup thắng/thua.

### 10.2. Vị trí & kích thước thẻ (đo trực tiếp từ scene)

Khung HUD: `Information` = Control tại `(50, 175)` kích thước `980 × 249` (mọi toạ độ dưới đây tính trong khung này).

| Thẻ | Kích thước | Vị trí (x, y) | Art (res://assets/images/game/) | Label / Value |
|---|---|---|---|---|
| **THỜI GIAN** | 250 × 138 | (0, 31) | `card_time_slip.svg` (HUD mới) · `card_time.svg` (Play/Dungeon) | `text_game_card_label` 18px · `text_game_information_subvalue` 42px |
| **THỬ THÁCH** | 720 × 246 | (271, −29) | `card_challenge.svg` | 3 dải 490×58 tại y = 28/94/160 · cột tổng kết x = 36..186 |
| **SỐ BƯỚC** | 440 × 158 | (270, 18) | `card_steps.svg` | `text_game_challenge_count_sub` 36px · `text_game_card_value_steps` 72px |
| **TẦNG** | 250 × 138 | (730, 28) | `card_floor.svg` | label 18px · `text_game_information_value` 58px |
| **BOM CÒN LẠI** | 440 × 158 | (270, 18) | `card_bomb.svg` + sticker `icon_bomb.svg` 80×80 tại (336, 39) | label 36px đỏ · value 72px đỏ dạng `còn/tổng` |
| **TỔNG HIỆN TẠI** | 440 × 158 | (270, 18) | `card_sum.svg` | label 36px `#718B9E` · value 72px `#224C6D` |
| **TOÁN TỬ** | 112 × 112 | (664, 68) | `card_op.svg` (lề đỏ) | `text_game_information_value` 58px mực đỏ, căn giữa |
| **MỤC TIÊU** | 250 × 138 | (730, 28) | `card_time_slip.svg` | label 18px · value 58px (chỉ con số) |
| **GHI NHỚ** | 440 × 158 | (270, 18) | `card_sum.svg` | title 36px · hint 18px (auto-wrap) · dòng chế độ 18px đỏ |

> Toạ độ trên **khớp với scene thật** (kiểm tra bằng `tools/mockup/gen_matchup.py --dump`), thẻ TOÁN TỬ vẽ SAU cùng nên đè lên mép thẻ TỔNG và thẻ MỤC TIÊU (dạng `12 = 23`).

### 10.2b. HUD thiết kế mới — Sum Path · Countdown Cost · Fading Ink (2026-02)

3 chế độ này dùng **cùng một khung HUD mới**: 2 thẻ cao **156px** đặt tại `y = 178` trong khung `Information` `(50,175)-(1030,424)` (thẻ thời gian ở trái, thẻ chế độ rộng 715 ở phải).

| Thẻ | Kích thước | Vị trí (trong khung) | Art | Nội dung động |
|---|---|---|---|---|
| **THỜI GIAN** | 250 × 156 | (0, 3) | `card_time_tall.svg` | `Time/Value` + dòng phụ theo chế độ (`STR_HUD_TIME_SUPPORT` “Phụ trợ xếp hạng” · `STR_HUD_TIME_FREE` “Không giới hạn”) |
| **SỔ NGÂN SÁCH BƯỚC CHÂN** | 715 × 156 | (265, 3) | `card_budget_sheet.svg` + `chip_price_cheap/pricey.svg` + `budget_segment_on/off.svg` | NGÂN SÁCH CÒN `còn/tổng` · ĐÃ TIÊU TỐN `-N` (+ số ô đã đi) · GIÁ CƯỚC MỖI Ô (chip RẺ/ĐẮT theo độ khó + dự phòng) · **dải phân đoạn** (`CountdownHUD`) |
| **TRẠM ĐO ĐỘ PHAI MỰC** | 715 × 156 | (265, 3) | `card_ink_meter.svg` + `bar_ink_warning.svg` | BƯỚC ĐÃ ĐI (`NN` + `(-N MỰC)`) · quang phổ 4 mức · cảnh báo `N Ô ĐÃ CẠN MỰC` (tự ẩn khi chưa có ô nào cạn) (`FadingInkHUD`) |
| **CÂN BẰNG TỔNG ĐIỂM ĐƯỜNG ĐI** | 715 × 156 | (265, 3) | `card_sum_balance.svg` + `bar_sum_fill.svg` + `bar_sum_ticks.svg` | TỔNG HIỆN TẠI (+ số ô) · con dấu TOÁN TỬ `< > =` · MỤC TIÊU · chip `CẦN THÊM / CÒN ĐƯỢC / ĐANG VƯỢT / ĐÃ ĐỦ` · thanh tiến độ (`SumPathHUD`) |

- Cả 3 thẻ đều theo ngôn ngữ **sổ tay**: viền màu theo chế độ (cam `#C2410C` · mực `#1D4E72` · xanh `#3D83AE`), lề dọc, dòng kẻ ô ly mờ; số liệu dùng theme variation `Hud*` trong `theme_default.tres`.
- **Dải phân đoạn ngân sách**: mỗi bước = 1 phân đoạn (đã dùng = xám `#E2E8F0`, còn lại = cam `#EA580C`); bề rộng phân đoạn **tự co** để cả dải luôn vừa 654px khi ngân sách > 16 bước.
- **Trích KHỐI ra texture node (2026-09-17)**: 3 sheet trên nay **CHỈ vẽ phần tĩnh** (khung · lề · dòng kẻ · vạch chia);
  các khối bên trong đã tách thành art riêng và đặt bằng NODE trong scene HUD (chèn ngay sau `Sheet` → nằm trên
  sheet, dưới các Label):
  · `card_budget_sheet.svg` → `card_budget_block_budget.svg` 217×84 · `card_budget_block_spent.svg` 202×84 ·
    `card_budget_block_price.svg` 197×84 (node `BlockBudget/BlockSpent/BlockPrice` trong `countdown_hud.tscn`).
  · `card_ink_meter.svg` → `card_ink_block_bottle.svg` 50×68 (lọ mực + giọt mực) · `card_ink_swatch_1..4.svg`
    90/90/90/100×28 (4 ô quang phổ) — node `BlockBottle/Swatch1..4` trong `fading_ink_hud.tscn`.
  · `card_sum_balance.svg` → `card_sum_block_current.svg` 252×76 · `card_sum_emblem.svg` 60×60 ·
    `card_sum_block_target.svg` 307×76 · `card_sum_chip_need.svg` 155×26 · `card_sum_bar_track.svg` 654×18
    (node `BlockCurrent/Emblem/BlockTarget/ChipNeed/BarTrack` trong `sum_path_hud.tscn`).
  MẸO ĐỊNH VỊ: mỗi art viết với `viewBox` = **vùng đã cắt** (giữ NGUYÊN toạ độ gốc trong sheet) nên node chỉ cần
  đặt tại `sheet-local + (265, 3)` là khớp 1:1; lề 1px quanh hình để nửa ngoài của `stroke` không bị viewBox cắt.
  Hình render **y hệt bản bake cũ** (soi crop 1:1 khung HUD bằng `dev_fix_shots.gd --hud`).
- 3 chế độ này **không hiện thẻ THỬ THÁCH** trên HUD (thử thách/Sao vẫn tính đủ, hiện ở popup kết quả) — thay hẳn bố cục cũ `THỜI GIAN 250×138 + THỬ THÁCH 720×246`; các chế độ còn lại vẫn dùng bảng 10.2.
- **One Stroke / Wall Builder (2026-09-19)** — biến thể của khung này: `nodes/hud/one_stroke_hud.tscn` (`OneStrokeHUD`) và `nodes/hud/wall_builder_hud.tscn` (`WallBuilderHUD`) — xem §5.12–5.13.

### 10.2c. Panel HƯỚNG DẪN LUẬT CHƠI (Hint Guide)

| Thành phần | Vị trí | Ghi chú |
|---|---|---|
| `HintGuide` (`Control`) trong `scenes/game.tscn` | (50, 1424) 980×90 | nằm **dưới mép giấy bàn cờ** (~1414) và **trên thanh nút** (1528); khai báo `index="6"` để vẫn nằm dưới `Popups` |
| `Bg` | full thẻ | `assets/images/game/panel_hint_guide.svg` (giấy + viền `#6EA0C8` + lề đỏ) |
| `Icon` | (46, 23) 44×44 | `assets/images/icons/icon_bulb.svg` — bóng đèn nét cam (**không dùng emoji 💡**) |
| `Text` | (106, 0) 844×90 | 1 dòng · variation `HintGuideText` (22px Be Vietnam Pro ExtraBold `#244E6E`) |

- Nội dung đổi theo chế độ: `scripts/nodes/game/hint_guide.gd` → `HintGuide.show_mode()` tra khoá `STR_HINT_<MODE_ID>` (9 chế độ đã lập trình, `string_extra.csv`; **2 bộ luật mới §5.12–5.13 sẽ thêm khoá khi triển khai**); chế độ chưa có khoá thì fallback `BaseGameMode.mode_description`. `GameScene.switch_mode()` gọi `_refresh_hint_guide()` mỗi lần đổi chế độ.
- Chuỗi gợi ý phải **vừa đúng 1 dòng** trong 844px — test `scripts/test_case/test_hud_modes.gd` đo bằng **font thật của theme** (không đếm ký tự).

### 10.2d. Hệ HƯỚNG DẪN 2 tầng: NỘI DUNG theo chế độ + POPUP dùng chung (tách lại 2026-02)

Nút **"?"** (bố cục dọc) mở popup hướng dẫn **của chế độ đang chơi**; ở bố cục NGANG nội dung còn được **nhúng thẳng vào khung HUD** (`Panel/GuideHost`). Kiến trúc mới TÁCH ĐÔI "nội dung" ⇄ "vỏ popup": 3 scene nền dùng chung + **10 scene NỘI DUNG** (9 gốc − Time Attack đã bỏ + One Stroke + Wall Builder 2026-09-19) theo bộ mockup `mockup/instruction/*.svg`; mỗi nội dung 3 trang (P1 quy tắc cơ bản · P2 cơ chế phụ · P3 bí quyết).

| Scene nền | Vai trò |
|---|---|
| `nodes/popups/instruction/page.tscn` | **1 TRANG** — CẤU TRÚC CỐ ĐỊNH (`Title` · `Body (VBox)` → `Top (HBox) [Image | Points]` · `Section` · `Instruction (VBox)` · `Cta`/`Link` generator thêm). `Image` (TextureRect; **label chữ-trên-ảnh (PT#) + BADGE SỐ (`Point#`) là CON của `Image`**, neo theo TỈ LỆ ảnh nên co giãn không lệch; **label chữ hiện MẶC ĐỊNH**, badge + `Points`/`HEAD` **ẨN MẶC ĐỊNH** — đúng bản POPUP) · `Points` (khối “chi tiết điểm”: `Head` “CHI TIẾT CHỈ DẪN TRÊN ẢNH” + `List` các hàng `PointRow#`) · `Instruction` (VBoxContainer chứa các hàng luật `Row1..3`). Script `page.gd` (class `InstructionPage`) **KHÔNG chia nhánh theo tỉ lệ khung nữa** — HBox/VBox tự xếp `[ẢNH | ĐIỂM]` cạnh nhau rồi `Section` + luật ở dưới; script chỉ tính cỡ ẢNH theo tỉ lệ, đổi KIỂU HIỂN THỊ ĐIỂM theo `embedded`, cấp min bề cao cho khối ĐIỂM, ẩn `Title` khi nhúng, dàn `Cta`/`Link` đáy (chỉ chừa chỗ khi ở POPUP). Chữ-trên-ảnh/badge tự co theo CỠ ẢNH THẬT (`metadata/base_font` / `base_size`) nên không tràn khung. |
| `nodes/popups/instruction/content_instruction.tscn` | **NỘI DUNG** — `Chip` · `Tabs/Tab1..3` · `Pages` (chứa các `Page`) · `Prev`/`Next` ‹ › · `Dots/Dot1..3` · `Index` "TRANG x / 3". Script `content_instruction.gd` (class `InstructionContent`) lo lật trang (vuốt/lăn/phím/tab/dots) + `set_embedded()` + signal `close_requested`. |
| `nodes/popups/popup_instruction.tscn` | **POPUP dùng chung DUY NHẤT** (kế thừa `base.tscn`): `Panel/Paper` + `Washi` + `PaperDetail` + `Close` + `Content`; script `popup_instruction.gd` (class `PopupInstruction`) nạp `<mode>.tscn` vào `Content` theo `mode_id` và tô giấy theo accent của chế độ — API chuyển tiếp xuống content. |

Bảng chế độ → scene nội dung (`nodes/popups/instruction/<mode>.tscn`, TẤT CẢ kế thừa `content_instruction.tscn`):

| Chế độ | Scene nội dung |
|---|---|
| Play · Daily Classic | `normal_maze.tscn` |
| Dungeon | `dungeon.tscn` |
| Minesweeper | `minesweeper.tscn` |
| Sum Path | `sumpath.tscn` |
| Countdown Cost | `countdowncost.tscn` |
| Blind Memory | `blindmemory.tscn` |
| Fog of War | `fog_of_war.tscn` |
| Fading Ink | `fadingink.tscn` |
| One Stroke | `one_stroke.tscn` |
| Wall Builder | `wall_builder.tscn` |

- **Bố cục thật trong scene** (toạ độ đã nhân nửa `S = 0.5` từ mockup; tờ giấy = `Panel` 460×740 trong `popup_instruction.tscn`):
  - **CẤU TRÚC CỐ ĐỊNH — bỏ nhánh RỘNG/CAO (2026-09-26, v2.9)**: trước đây `page.gd` rẽ 2 nhánh theo `w >= h × 1.15` (rộng → `[Ảnh | Điểm]`; cao → ảnh trên · ĐIỂM dưới) → ở tỉ lệ GẦN VUÔNG, khối ĐIỂM tụt xuống dưới ảnh làm tràn khung + lệch phân trang. Nay mỗi trang LUÔN có cây node cố định: `Page → Title · Body (VBoxContainer) { Top (HBoxContainer) { Image · Points } · Section · Instruction }` + `Cta`/`Link` — HBox/VBox tự xếp nên **KHÔNG tỉ lệ khung nào phá được**.
  - `page.gd` chỉ còn việc TÍNH: cỡ ẢNH theo tỉ lệ (`row_h = 48% bề cao Body`, kẹp **120–340**; **nhúng** `img_w = min(row_h × tỉ lệ ảnh, 52% bề ngang khối)`, **popup** `img_w = min(100% bề ngang khối, chỗ-bề-cao-còn-lại × tỉ lệ ảnh)` — popup không còn cột ĐIỂM nên ảnh nở hết ngang); khối ĐIỂM nở lấp phần bề ngang còn lại + được cấp min bề cao `26 + min(List) + 8` (Panel không tự gom min của con); đổi KIỂU HIỂN THỊ ĐIỂM theo cờ `embedded` (`_apply_point_mode`: nhúng = ẩn chữ + hiện badge + hiện khối ĐIỂM; popup = ngược lại); `Title` ẩn khi NHÚNG; `Cta`/`Link` dàn đáy và **chỉ chừa chỗ khi ở POPUP** (theo cờ `embedded`, không dò `visible` — nút có thể chưa kịp bị ẩn ở lần dàn trang đầu).
  - **Điều hướng nhúng** (`‹ · dots · ›  TRANG x / 3`) nằm trong **BĂNG ĐÁY khung** — DƯỚI khối “QUY TẮC …”, sát đáy (v2.10): `page.gd` chừa `NAV_BAND = 26` ở đáy `Body` và `nav_slot_rect()` trả đúng băng đó — vị trí **CHỈ phụ thuộc CỠ TRANG** nên lật trang KHÔNG xê dịch. (Trước đây bám theo vị trí hàng `Section` — trang hiện LẦN ĐẦU chưa được container dàn xong nên cụm điều hướng bị đặt theo số cũ ⇒ nhảy lên trên đầu khung.)
  - **Không có CHỮ MÔ TẢ trên ảnh minh hoạ** — CHỈ ở **bản NHÚNG** (v2.11): mọi Label chữ đều là của một ĐIỂM (generator gắn `metadata/point`) — `page.gd._apply_point_mode()` ẩn HẾT chúng khi NHÚNG (ảnh chỉ còn HÌNH VẼ + SỐ/KÝ HIỆU `is_literal_text`: 1 · 2 · 15 · 04 · 01:24 · S · F · ✓ · ➔ + badge số) và **hiện lại đầy đủ khi ở POPUP** (đúng như mockup).
  - **Bản NHÚNG** (khung `Panel/GuideHost`): `Pages` phủ KÍN khung (`set_embedded`) + Ẩn Chip/Tabs/Title + Cta/Link; lề `PAD = 10`, nút điều hướng `‹ ›` 24px. Khối ĐIỂM có **TRẦN bề cao** (`_points_budget()` = chỗ còn lại của hàng `[Ảnh|Điểm]` = bề cao Body − khối luật − hàng tiêu đề − 2 khe, xem `_row_budget()`) — vì bề cao tối thiểu của danh sách autowrap lúc CHƯA xếp xong có thể cao vọt, nếu không kẹp thì min-size của `Body` vượt khung làm luật TRÀN ĐÁY; khung quá thấp thì khối ĐIỂM co lại (`clip_contents` cắt hàng cuối gọn gàng) thay vì đẩy luật ra ngoài. Ảnh bị kẹp `img_w ≤ 52% bề ngang` để nhường cột cho khối ĐIỂM.
  - **Bản POPUP** (khung cao 460×740): chrome nội dung hiện ĐỦ chip/tabs/nav; **ảnh nở HẾT bề ngang khối** (`img_w = min(usable, bề-cao-còn-lại × tỉ lệ)` — KHÔNG còn khối ĐIỂM cạnh nó, xem `_layout_image`), `Title` (19) trên cùng, luật + `Cta` 420×50 (viền accent) + `Link` 28 ở dưới.
  - **ĐIỂM = MỌI CHỮ MÔ TẢ trên ảnh** (v2.11): generator gom mọi chữ KHÔNG phải số/ký hiệu (`is_literal_text`) thành từng ĐIỂM theo comment mockup **đứng liền trước** (`<!-- CALLOUT … -->` / `<!-- CHÚ THÍCH … -->` / `<!-- DẢI GHI CHÚ… · DẢI CHÂN HÌNH -->`; chữ không comment = mỗi chữ một ĐIỂM; comment trùng nhưng cách xa nhau vẫn tách nhóm). Mỗi ĐIỂM = 1 **badge số** (`Point#`: vòng tròn 40 + số trắng, màu theo màu chữ ĐẦU, tâm = tâm vùng chữ) + 1 **hàng** `PointRow#` trong `Body/Top/Points/List` (`NumCircle` 17 + `Title` = chữ ĐẦU + `Desc` = các chữ SAU nối ` · `, autowrap). Số lượng thực tế: 3–9 điểm/trang (dày nhất: sum_path P2 = 9). Bề ngang tối thiểu khối chữ của hàng = **250** full-scale (125 scene). Các Label chữ đó NẰM TRONG `Body/Top/Image` (neo TỈ LỆ tâm, có `metadata/point`/`point_order` để đổ chữ xuống hàng) — bản nhúng ẩn đi, bản popup hiện ra (xem 2 bullet trên).
- **Số/ký hiệu trên grid ghi TRỰC TIẾP** khỏi khoá dịch: chuỗi không có chữ cái (1 · 2 · 15 · 04 · 01:24 · = · ? · < · >) + `S`/`F` nướng thẳng vào Label (`is_literal_text()` trong `tools/mockup/instruction_mockup.py`) — chỉ chữ có nghĩa mới dùng khoá `STR_GI_*`.
- **Tab & dots dùng chung** đổi trạng thái bằng script qua `@export` (generator nướng 2 bộ StyleBoxFlat + màu chữ vào root scene): tab đang chọn = accent + chữ/vòng trắng, tab thường = `#F0F7FB` viền `#BACEDC` chữ `#718B9E`; dot đang chọn = viên thuốc 38×18 accent, dot thường = chấm tròn 16×16 `#D1E2ED` — hàng dots canh trái từ mép dot đầu (x=185, cách nhau 12px), script dàn lại vị trí theo trang (khớp mockup cả 3 trang, generator tự cảnh báo nếu lệch > 2.5px).
- **Hành vi** — `scripts/nodes/popups/instruction/content_instruction.gd` (class `InstructionContent`, chỉ lo logic, KHÔNG sinh nội dung): vuốt ngang (ngưỡng 14px/quãng 90px) · lăn chuột · phím ←→ · bấm tab/dots để nhảy trang · `Prev` khoá ở trang 1 & `Next` khoá ở trang 3 · dàn lại dots · format `Index` từ `STR_GI_PAGE_INDEX` · CTA trang cuối phát `close_requested` (popup đóng) · link trang cuối = về trang 1, trang trước = bỏ qua · sfx `BTN_WOOD_TAP`/`PAGE_TURN`/`BTN_CLICK` · **đổ chữ cho khối ĐIỂM của MỌI trang** (`_fill_points`: đọc Label ẩn `metadata/point`, ghép Title/Desc) · **`set_embedded(true)`**: ẩn Chip/Tabs (+Title do trang tự ẩn) và Cta/Link, cho `Pages` phủ KÍN khung rồi dời cụm `‹ dots › TRANG` xuống **BĂNG ĐÁY khung** (dưới khối luật — `nav_slot_rect()` của trang; đặt lại mỗi khi trang đổi cỡ; dùng hệ NEO-GÓC để không bị anchor kéo lại).
  - **GOTCHA đã sửa (2026-09-19):** `Close` là **`TextureButton`** — `TextureButton` kế thừa **`BaseButton`** chứ KHÔNG phải `Button`, nên cast cũ `get_node(...) as Button` trả về **null** → nút X không bao giờ được nối signal (bấm không đóng). Đã đổi `close_button() -> BaseButton`.
- **Ảnh minh hoạ ThorVG-safe**: Godot/ThorVG **không vẽ** `<text>`/`<use>` — `tools/mockup/prepare_guideline_images.py` nhúng cầu thang `<use>` và chuyển số/ký hiệu (✓, ➔→•) thành **path glyph thật** (Be Vietnam Pro Black + fallback Noto Sans JP); ảnh gốc sao lưu ở `mockup/instruction/_extracted_source/`. Chữ ①②③ trên tab thay bằng **vòng số vẽ bằng node** (font game không có các glyph này).
- **Chuỗi dịch**: chữ có nghĩa dùng khoá `STR_GI_*` (vi = đúng chữ trong mockup, en = `tools/content/guide_text_en.py`): chrome theo trang `STR_GI_<MODE>_P<n>_TITLE/SECTION/CTA/LINK/TAB#/R#T/R#D`, chip `STR_GI_<MODE>_CHIP`, chữ trên ảnh dedupe `STR_GI_X###`, nhãn trang `STR_GI_PAGE_INDEX`. Sinh khoá + ghi CSV: `tools/content/build_instruction_data.py` (kèm `tools/content/_guide_keys.json` cho generator scene) — bỏ qua token số/ký hiệu.
- **Sinh scene**: `tools/mockup/gen_instruction_popups.py` — đọc mockup qua `tools/mockup/instruction_mockup.py` (toạ độ tuyệt đối + style kế thừa + **COMMENT khung chú thích** — parser giữ comment để gom mọi chữ mô tả thành nhóm ĐIỂM), ghi scene `<mode>.tscn` ở **nửa cỡ (S = 0.5)**; `Page1..3` là **instance `page.tscn`** — thêm node con bằng override của scene kế thừa (Godot cho sửa nội bộ instance con + `[editable path=…]`), nướng Label/Button/StyleBoxFlat + badge/điểm vào từng trang, giữ nguyên uid + `unique_id` của scene cũ. Hằng kích thước điểm ở đầu file: `POINT_BADGE_D/FONT` · `POINT_ROW_BADGE/FONT` · `POINT_TITLE/DESC_SIZE` · `POINT_TEXT_MIN_W`.
- **Nối dây**: `GameController.INSTRUCTION_SCENES` (play/daily_classic → `normal_maze`, fallback `normal_maze`) trả **scene NỘI DUNG** qua `instruction_scene_path(mode_id)`; `GameController.INSTRUCTION_POPUP = res://nodes/popups/popup_instruction.tscn` — `open_instruction()` = `Popups.open_path(INSTRUCTION_POPUP, {"mode_id": mode_id})`; đồng hồ đứng trong lúc xem hướng dẫn, đóng popup thì chạy lại. **HUD ngang nhúng tại chỗ**: `GameHUD.show_instruction_for(mode_id)` nạp nội dung vào `Panel/GuideHost` full-rect, TRÀN kín khung, `set_embedded(true)` (khung ≥ 300×220; nhỏ hơn thì hiện nút "XEM HƯỚNG DẪN" phát `instruction_requested` cho `GameScene` mở popup) — nút **"?" đã GỠ khỏi StatusBar NGANG** (bố cục dọc vẫn giữ). Đã gỡ `"instruction"` khỏi `PopupManager.POPUPS` và xoá `scripts/nodes/popups/instruction_popup.gd` (class cũ `InstructionPopup`).
- **Kiểm thử**: `scripts/test_case/test_instruction.gd` — **478 check**: bảng mode→scene nội dung · cấu trúc 3 scene nền + quan hệ kế thừa (mỗi `<mode>.tscn` chứa instance `page.tscn`; `page.tscn` có `Body (VBox)` chứa `Top (HBox)` với ẢNH + ĐIỂM; label chữ-trên-ảnh + `metadata/point` nằm TRONG `Body/Top/Image`, badge `Point1`, hàng `PointRow` trong `Body/Top/Points/List`, hàng luật trong VBox `Body/Instruction`) · đủ khoá dịch vi+en quét từ file `.tscn` · từng chế độ: 3 trang/3 tab/3 dots · **POPUP (mặc định): chữ trên ảnh HIỆN HẾT + badge ẨN + khối ĐIỂM ẨN** · **NHÚNG: chữ ẩn hết (mọi trang) + badge HIỆN + khối ĐIỂM HIỆN + chữ đổ sẵn vào hàng, số hàng = số điểm** · **trả về POPUP: chữ hiện lại + badge/khối ĐIỂM ẩn** · lật trang + khoá Prev/Next · CTA/link phát `close_requested` · popup: hiện Chip/Tabs/Title + Cta/Link, khối ĐIỂM ẨN · **nút X đóng popup** · tích hợp `open_instruction` (dungeon/play/minesweeper) · HUD ngang: nút "?" đã gỡ · nhúng TRÀN kín `Panel/GuideHost` + ẨN Chip/Tabs/Title/Cta/Link + **điều hướng nằm DƯỚI khối “LUẬT CHƠI”** · **BẤT BIẾN BỐ CỤC qua 5 tỉ lệ khung (994×800 · 560×560 · 620×700 · 700×620 · 500×640): `[ẢNH | ĐIỂM]` LUÔN cạnh nhau + khối ĐIỂM không tràn khung + `Section` ở dưới + điều hướng DƯỚI khối luật và KHÔNG xê dịch khi lật trang** · thu nhỏ khung → nút dự phòng + signal · phóng to → nhúng lại.

### 10.2e. THANH HÀNH ĐỘNG + GIỚI HẠN LƯỢT CÔNG CỤ (cập nhật 2026-10-10)

Thanh hành động (action bar) nằm TRONG HUD của mỗi chế độ, mỗi hướng một scene riêng
(`nodes/hud/portrait/game/action_bar.tscn` · `nodes/hud/landscape/game/action_bar.tscn`) và
`GameScene._bind_hud_nodes()` lấy nút ra để nối tín hiệu (HUD không giữ logic).

| Nút | Hành vi |
|---|---|
| **`Restart`** (CHƠI LẠI) | **DỜI từ THANH TRẠNG THÁI xuống đây** (2026-09-26) — có ở MỌI chế độ, cả 2 hướng (dọc: trong `Row`; ngang: trong `SubRow`). Bấm ⇒ `GameController.restart_run()` → `_on_retry_requested()` (Dungeon về TẦNG 1, các mode khác chơi lại ĐÚNG màn đang chơi). Thanh trạng thái KHÔNG còn nút này (đã xoá `restart_btn` khỏi `scenes/layout/*/game.tscn` + `GameSceneLayout`). |
| **`Submit`** (GỬI BÀI) | CHỈ chế độ **Wall Builder** (GameScene `_apply_mode_buttons()` bật/tắt theo `mode_id`) ⇒ `GameController.submit_build()`. Ở các chế độ khác nút **ẩn**. (Trước đây GỬI BÀI nằm ở nút công cụ thứ 2 — đã bỏ.) |
| **`Skip`** / **`Undo` (Eraser)** / **`Hint`** | Mỗi nút có badge `PanelLimit` ở cả giao diện dọc/ngang, luôn hiện **SỐ LƯỢT CÒN LẠI** và khoá nút khi hết. Badge dùng `NinePatchStateTexture` với `sync_with_parent_button` ⇒ tự đổi art theo trạng thái (normal/hover/pressed/disabled). |
| **`Replay`** | Nút phụ ẩn sẵn — `UIController` hiện khi ván không còn thắng được (Sum Path). |

- **BỎ hẳn 2 nút công cụ VẼ ĐƯỜNG / GHI NHỚ** (2026-09-26): bàn cờ tự nhận cả 2 thao tác (kéo nhân vật đi đường · kéo nối 2 Anchor để đánh dấu tường) — `Board.tool_mode` không chi phối input, nên 2 nút chỉ là nhãn trang trí. Đã xoá khỏi cả 2 scene + `ActionBar`/`GameHUD`/`GameScene` (hết `TOOL_*`, `_apply_tool_labels_for_mode`, `_apply_tool_textures_for_mode`, `configure_tool_path_button`); `ToolController` chỉ còn giữ TRẠNG THÁI + signal `tool_changed` → `Board.set_tool_mode()`.
- **Số lượt dùng công cụ TOÀN GAME**: `GameManager.tool_uses` lưu riêng số lượt `skip` / `undo` / `hint`, mặc định **3 lượt mỗi công cụ cho người chơi mới**. Số dư được lưu trong tiến trình, dùng chung qua mọi màn, tầng Dungeon và các game mode; `_start_floor()` không cấp thêm lượt. Hành động hợp lệ mới trừ lượt; hết lượt thì nút bị khoá và thao tác bị từ chối. Dữ liệu lưu cũ chưa có `tool_uses` tiếp tục dùng mức khởi tạo 3. Chỉ luồng cấp thưởng mua hàng/nhiệm vụ (`grant_tool_uses`) sẽ nạp thêm sau khi các luồng này được định nghĩa.
- **Dòng dữ liệu**: `GameManager` là nguồn sự thật và lưu `tool_uses`; `GameController._update_hud()` → `ui_controller.set_run_info({skip_left, undo_left, hint_left, …})` → `UIController.update_hud()` → `GameHUD.update_hud(ctx)` → `_sync_limits(ctx)` → `ActionBar.update_tool_counts()`.
- **Debug Console**: `TOOL BALANCES` cho phép chỉnh số lượt `Skip`, `Eraser / Undo`, `Hint` (0..999999) trong debug build; thay đổi được lưu ngay qua `GameManager.debug_set_tool_uses()`. Bản phát hành chỉ tăng lượt qua `grant_tool_uses()` với nguồn `purchase` hoặc `mission`.
- **Tài nguyên**: `btn_restart_*.svg` (đã dùng từ trước) · `btn_submit_*.svg` (nút GỬI BÀI, art mới của user) · `btn_item_*.svg` + `panel_sub_infor_item.svg` (khung badge `PanelLimit`).
- **Kiểm thử**: `test_controllers_and_signals.gd` — thanh trạng thái KHÔNG còn `Restart`, nút CHƠI LẠI nằm trong thanh hành động, mỗi chế độ có `Submit` (ẩn trừ Wall Builder), 2 nút UNDO/HINT có `PanelLimit`, **hết lượt ⇒ nút bị KHOÁ + bấm không trừ thêm lượt**. `test_hud_modes` / `test_wall_builder` / `test_one_stroke` / `test_fog_of_war` kiểm nút `Submit`/`Restart` theo chế độ (4 test này còn vài check cũ đã lệch đường dẫn node HUD từ trước, không liên quan thay đổi này).

### 10.2f. MÀN CHƠI CHẾ ĐỘ SPECIAL + NÚT SKIP LEVEL (2026-09-27)

Ngoài Daily Challenge (bàn TỰ SINH), một **MÀN trong campaign** có thể khai chế độ riêng trong
`LevelData.mode_id` (tool `level_designer` → ô `mode_id`). Khi đó chế độ Special chạy **TRÊN ĐÚNG BÀN
NHÀ THIẾT KẾ VẼ** (tường + `cell_mask`) rồi mới "rắc gia vị" của mình lên trên.

**1. Dòng dữ liệu (code là nguồn sự thật)**

| Nơi | Việc |
|---|---|
| `GameManager.prepare_level_run(id)` | Nạp `mode_id` (id lạ/rỗng ⇒ `play`) + `difficulty` từ LevelData, bật cờ **`level_run = true`** (Daily/Dungeon/Debug ⇒ `false`), phát `mode_changed`. `start_level()` gọi hàm này rồi mới chuyển scene. |
| `GameScene._start_floor_for()` | Ván MÀN ⇒ trả về **ID màn** cho MỌI chế độ (ID màn đóng vai "tầng" để chế độ biết mình đang ở đâu). |
| `BaseGameMode.designed_level()` / `designed_maze()` | Lấy LevelData của màn đang chơi → `to_maze_data()`. `null` với Daily/Dungeon/Debug ⇒ chế độ tự sinh bàn như trước. |
| `BaseGameMode.designed_steps(default)` | Ngân sách bước = `max(LevelData.max_steps, mặc định của chế độ)` — màn to không bị "hết bước oan". |
| `GameController._seed_level_run()` | Gieo `seed(level_id * 7919 + 13)` TRƯỚC `setup_floor()` ⇒ phần ngẫu nhiên của chế độ **CỐ ĐỊNH theo màn** (chơi lại y hệt). |
| `MazeData.set_all_walls_visible(bool)` | Ép cờ hiện/ẩn của MỌI tường (bàn thiết kế đã có mảng hiện/ẩn riêng nên `visible_wall_ratio` không còn tác dụng). |

**2. Mỗi chế độ dùng bàn thiết kế thế nào**

| Chế độ | Tường của màn | "Gia vị" chế độ rắc thêm |
|---|---|---|
| `minesweeper` | **ÉP HIỆN** (cần thấy bàn để chọn đường) | Mìn chỉ rải trên ô **ĐI TỚI ĐƯỢC từ S** và **không** thuộc đường S→F ngắn nhất (BFS) ⇒ luôn có đường an toàn; số = mìn trong 8 ô lân cận |
| `sum_path` | Giữ nguyên thiết kế | Điểm ô 1..9 (hoặc `custom_cell_values["x,y"]` nếu tool khai) + mốc tổng tính theo **đường NGẮN NHẤT** của màn |
| `countdown_cost` | Giữ nguyên thiết kế | Chi phí ô 1..4 (giá trị tô tay giữ ĐÚNG, ô còn lại theo độ khó) + ngân sách theo đường RẺ NHẤT (Dijkstra trên chính bàn đó) |
| `blind_memory` | **ÉP ẨN** | Pha GHI NHỚ như cũ (hiện toàn bộ tường → đếm ngược → ẩn lại) |
| `fog_of_war` | **ÉP ẨN** | Sương mù quanh nhân vật + lượt thử lại |
| `fading_ink` | Giữ nguyên thiết kế | Mực theo đường ngắn nhất của màn |
| `one_stroke` | **ÉP HIỆN** | Đường mẫu = lời giải PHỦ KÍN tự dò (DFS cắt tỉa kiểu Warnsdorff). Bàn **không có lời giải** ⇒ `push_warning` + tạm dùng bàn tự sinh để màn vẫn thắng được |
| `wall_builder` | **ÉP ẨN** (đố suy luận) | Số trên ô suy từ chính tường của màn; `solution_count` đếm từ solver (hết ngân sách = coi như nhiều nghiệm) |

- **HUD**: tiêu đề ván màn hiện `MÀN nn` + phụ đề `TÊN CHẾ ĐỘ · CHƯƠNG n` (giống Play Mode) — xem `BaseGameMode.get_hud_floor_title()/_subtitle()`.
- **Thử thách**: màn khai `challenge_types/params` thì được ưu tiên; để trống ⇒ bộ mặc định RIÊNG của chế độ (`default_challenges()`, vd One Stroke `time_max · no_hint · no_undo`) rồi mới tới bộ chung.

**2b. KIỂU EDIT RIÊNG THEO CHẾ ĐỘ (`custom_cell_values`)** — v2.14

Mỗi chế độ có **1 kiểu edit**: tool đổi thanh công cụ theo `mode_id` (công cụ **7** + ô giá trị + nút "Xoá giá trị"),
lưu vào `custom_cell_values` khoá `"x,y"`. **Ô không tô = game tự sinh** (cố định theo màn). Khai báo 1 chỗ:
`tools/level_designer/app/config.py::MODE_EDITS` (khớp `mode_edit_spec()` dùng chung cho tool + validator).

| Chế độ | `kind` | Tô gì (tool) | Game đọc thế nào |
|---|---|---|---|
| `minesweeper` | `cell_value` 1 | **GHIM MÌN** | `_pinned_mines()` giữ đúng ô ghim; đường an toàn S→F được dò TRÁNH mìn ghim; nếu mìn ghim chặn hết đường ⇒ `push_warning` + **bỏ mìn ghim** (màn luôn thắng được) |
| `sum_path` | `cell_value` 1..9 | **ĐIỂM Ô** | `_designed_score()` ưu tiên giá trị tô (kẹp 1..9), còn lại random — **S/F KHÔNG có điểm** (v2.16) |
| `countdown_cost` | `cell_value` 1..4 | **CHI PHÍ Ô** | `_designed_cost()` giữ ĐÚNG 1..4 (`DESIGNED_COST_MIN/MAX`) — **không kẹp theo độ khó** để tôn trọng ý đồ thiết kế |
| `fading_ink` | `cell_value` 1..9 | **MỰC Ô** (v2.16) | `_designed_ink()` đọc MỰC tô tay; ô không tô thì game tự cấp (đủ đi hết đường ngắn nhất + dư 2..3) |
| `play` · `blind_memory` · `fog_of_war` · `one_stroke` · `wall_builder` | `none` | (không có nút) | Game tự sinh hết; validator in ghi chú riêng của chế độ |

**2b-bis. Ô “TỔNG …” + TÔ GIÁ TRỊ THEO ĐƯỜNG ĐI (v2.16)**

Ba chế độ có giá trị ô ở bảng trên thêm 1 ô nhập **ở BẢNG PHẢI, mục “Lưới & luật chơi”** cùng nút
**“Tô theo đường đi”**: `countdown_cost` = **Tổng chi phí đường đi** · `sum_path` = **Tổng điểm đường đi** ·
`fading_ink` = **Mực dư mỗi bước**. Khi có ô này, `Ctrl+Enter` **TÔ GIÁ TRỊ** cho các ô của đường đi
thay vì dựng tường (xem mục 2c):

| Chế độ | `fill` | Ctrl+Enter làm gì |
|---|---|---|
| `countdown_cost` | `sum` | chia chi phí 1..4 cho các ô của đường sao cho **TỔNG = số đã nhập** (mỗi ô random trong khoảng) và tự nâng `max_steps` = tổng + 3 (`budget_from_sum`) |
| `sum_path` | `sum` | chia điểm 1..9 cho các ô của đường sao cho **TỔNG = số đã nhập** |
| `fading_ink` | `step` | cấp **MỰC tăng dần theo bước**: ô ở bước thứ j nhận `clamp(j + Mực dư, 1, 9)` ⇒ đi đúng đường thì luôn tới được F |

- TỔNG chỉ tính các ô **GIỮA S và F** (game cũng không tính điểm/chi phí ở S/F) ⇒ con số khớp ĐÚNG.
- Ô “Tổng …” tự hiện **tổng đang có** trên đường vừa vẽ; nhập số khác rồi `Ctrl+Enter` (hoặc nút *Tô theo
  đường đi*) để chia lại.
- **Thanh công cụ của tool có 2 DÒNG** (tránh tràn ngang ở cửa sổ hẹp): dòng 1 = công cụ vẽ · dòng 2 =
  khối GIÁ TRỊ (công cụ 7) / khối ĐƯỜNG ĐI + tuỳ chọn xem + zoom + Lưu. Hai khối động **không bao giờ hiện
  cùng lúc** (đang vẽ đường thì khối giá trị ẩn đi). Test GUI đo `winfo_reqwidth` của cả 2 dòng ở cửa sổ
  1080 px để chặn tràn trong tương lai.
- **Chưa vẽ gì** ⇒ `Ctrl+Enter` tô theo **đường NGẮN NHẤT** của màn (đúng đường game dùng làm mẫu).
- Số ngoài khoảng hợp lệ (số ô × min..max) ⇒ tool báo khoảng cho phép và **không tô gì**.

**2b-ter. GAME thay đổi theo (v2.16)**

| Chế độ | Trước | Nay |
|---|---|---|
| `sum_path` | tổng tính CẢ S/F (S/F hiện chữ nên coi như số ẩn, mỗi ô 1..9 random) | **S/F = 0 điểm** ⇒ tổng đường đi khớp đúng số nhà thiết kế tô/chia |
| `countdown_cost` | ngân sách = `max(độ khó, đường RẺ NHẤT + dư)` (bỏ qua `max_steps` của màn) | tôn trọng thêm `max_steps` của màn (`_ensure_budget(maze, designed_steps(...))`) ⇒ nhà thiết kế chốt được ngân sách theo TỔNG chi phí |
| `fading_ink` | mực 100% do game cấp theo đường ngắn nhất | đọc `custom_cell_values` trước, ô không tô mới tự cấp |

- **Tool**: `models/level.py` thêm `custom_value()/set_custom_value()/clear_custom_values()/prune_custom_values()` (tự bỏ giá trị ngoài lưới khi đổi kích thước/bỏ ô board) · `services/tres_io.py` ghi `{"x,y": v}` (sắp theo `y,x`) và **giữ nguyên chuỗi gốc** nếu file có phần tool không hiểu (`custom_raw_unknown` → validator cảnh báo) · `editor_controller.apply_value_tool()` (click lại = xoá, kéo rê = tô, S/F + ô trống bị bỏ qua, có undo) · `grid_view` vẽ số giá trị TO ĐẬM giữa ô (đè số tường) + chuột phải ưu tiên xoá giá trị · `main_window` khối công cụ giá trị động (nút/ô giá trị/nút xoá + phím `7` + menu Sửa → "Xoá hết giá trị riêng của chế độ").
- **`dungeon` KHÔNG dùng được cho màn**: bỏ khỏi `MODE_IDS` (còn trong `RETIRED_MODE_IDS` để báo lỗi rõ), validator **LỖI** cho file cũ khai `dungeon`, và `GameManager.mode_id_of_level()` coi màn `dungeon` như `play` (chế độ bất tận chỉ vào từ Main Screen).
- Màn mẫu: **13** có 2 mìn ghim `{"0,2": 1, "2,3": 1}` · **14** có 3 điểm ô `{"4,8": 5, "2,9": 9, "1,10": 1}` (`make_samples.py` khóa `"custom_values"` ghi lại đúng như vậy).

**2c. TOOL VẼ ĐƯỜNG ĐI (công cụ 8 — v2.15; TÔ GIÁ TRỊ theo đường từ v2.16)**

Nét vẽ là dữ liệu **TẠM** của tool (không ghi vào `.tres`): kéo chuột vẽ 1 nét đường — chỉ nối **ô kề**,
không nhảy ô, không đi đè, kéo ngược lại = lùi 1 ô — rồi `Ctrl+Enter`. Có **2 kiểu áp dụng** tuỳ chế độ:

| Kiểu | Chế độ | Kết quả |
|---|---|---|
| **Sinh tường** (`path_action = walls`) | mọi chế độ còn lại | mọi cạnh **BÊN HÔNG** của đường thành tường hiện; cạnh nối 2 ô LIỀN NHAU được MỞ ⇒ nét vẽ là **ĐƯỜNG DUY NHẤT** S→F |
| **Tô giá trị** (`path_action = values`) | countdown_cost · sum_path · fading_ink | tô giá trị ô theo ô “Tổng …” ở BẢNG PHẢI (chia theo tổng hoặc mực theo bước) — xem **2b-bis** |

Chung cho cả hai kiểu:

| Việc | Kết quả |
|---|---|
| S / F | `S` = ô **ĐẦU** nét vẽ · `F` = ô **CUỐI** nét vẽ |
| `max_steps` | sinh tường/tô điểm: số bước của nét vẽ + 2 · riêng countdown_cost: `max(số bước + 2, TỔNG + 3)` |
| Hoàn tác | cả lần áp dụng là **1 bước** `Ctrl+Z` |

- Code: `app/config.py` (`TOOL_PATH`, `TOOL_PATH_KEY = "8"`, `PATH_WALL_EXTRA_STEPS`, `MODE_EDITS[*]["path"]` +
  `mode_edit_spec()` điền sẵn `path_action`/`path_fill`/`sum_*`/`budget_from_sum`) ·
  `EditorController.begin_path/extend_path/clear_path_draft/apply_path_walls/apply_path_values` +
  `path_edge_ref()` (cùng quy ước cạnh với `MazeData.has_wall`) + `app/services/path_values.py`
  (`distribute_sum` chia tổng theo khoảng · `step_values` mực theo bước · `feasible_range`) ·
  `GridVew._draw_path_draft()` (nét tím + 2 đầu tròn) · toolbar khối **“Đường đi”** (nút *Sinh tường quanh đường*
  / *Sinh giá trị trên đường* — đổi theo chế độ — và nút *Xoá nét vẽ*, chỉ hiện khi có nét vẽ) + ô **“Tổng …”**
  trong khối giá trị · menu **Sửa** (2 lệnh) · phím `8`, `Ctrl+Enter`, `Esc` · chuột phải ở công cụ 8 = xoá nét.
- Test: `tests/test_path_tool.py` (**25 test**, nét vẽ là ĐƯỜNG DUY NHẤT + mở lại lối đi + undo) ·
  `tests/test_path_values.py` (**17 test**: khai báo `path` của từng chế độ · chia tổng đúng và trong khoảng ·
  từ chối tổng ngoài khoảng · mực tăng dần theo bước và luôn ≥ số bước · tô theo đường NGẮN NHẤT khi chưa vẽ ·
  chế độ thường từ chối tô giá trị) · `test_gui_smoke` kiểm ô “Tổng …” + tô giá trị qua đường.
- Bấm `P` sau khi áp dụng để xem lại **đường ngắn nhất** — sẽ trùng đúng nét vừa vẽ.

**3. Nút SKIP LEVEL**

| Việc | Chi tiết |
|---|---|
| Node | `Skip` (LimitedButton) có ở **CẢ 2 thanh hành động**: dọc = `ActionBar/Row`, ngang = `ActionBar/SubRow`; kèm badge `PanelLimit` hiển thị số lượt toàn game và art `btn_skip_normal/pressed/disable.svg`. |
| Hiện/ẩn | `GameScene._apply_mode_buttons()` → `_is_level_run()`: **CHỈ hiện khi ván này là ván MÀN** (`GameManager.level_run`); ẩn ở Dungeon/Daily/Debug Console. |
| Hành vi | `GameController.skip_current_level()` cần và trừ 1 lượt `skip`, sau đó `GameManager.skip_level(id)`: **mở khoá màn KẾ TIẾP trong cùng chương mà KHÔNG ghi Sao/thời gian**, rồi vào luôn màn kế (`start_level`). Hết chương (`next_level_in_chapter() = -1`) ⇒ mở màn **CHỌN CHƯƠNG**. Hết lượt Skip thì nút bị khoá và màn không đổi. |
| Dây nối | `GameScene._wire_action_bar()` nối `skip_btn.pressed → _on_skip_pressed()`; nút cũng nằm trong `_all_buttons()` nên được gắn hiệu ứng nhấn. |

**4. Tool `level_designer`**

- `app/config.py`: `MODE_LABELS` (nhãn người đọc cho từng chế độ) · `MODE_EDITS` + `mode_edit_spec()` (**kiểu edit theo chế độ** — §10.2f mục 2b) · `MODE_WALL_VISIBILITY_OVERRIDE` (chế độ nào game ép hiện/ẩn tường) · `MODES_NEEDING_VISIBLE_WALLS` (nhắc nhà thiết kế) · `MODE_IDS` **KHÔNG có `dungeon`** (`RETIRED_MODE_IDS`).
- `app/services/validator.py`: `_validate_mode()` — LỖI khi `mode_id` không tồn tại / là `dungeon` (chế độ bất tận); CẢNH BÁO khi màn còn **tường ẩn** ở chế độ cần thấy tường / Không có tường nào / Wall Builder quá ít tường; NHẮC luật riêng (One Stroke phủ kín, Minesweeper chỉ rải mìn ở ô tới được, Sum Path mốc = đường ngắn nhất) + ngân sách bước thực tế · `_validate_custom_values()` — giá trị NGOÀI khoảng của chế độ, dữ liệu lạ không hiểu được, mìn ghim nằm trên đường ngắn nhất, và nhắc "đã tô N ô" · **v2.16**: IN TỔNG theo đường ngắn nhất (Tổng điểm / Tổng chi phí / số ô tô mực) + CẢNH BÁO khi mực tô **nhỏ hơn số bước phải đi** để tới ô đó (màn sẽ hết mực trước khi qua).
- `app/models/repository.py` + `app/views/level_list_view.py`: `LevelSummary.mode_id` + nhãn **`◆ tên_chế_độ`** cuối dòng trong danh sách màn.
- `app/views/inspector_view.py`: dòng nhắc dưới ô `mode_id` = nghĩa chế độ **+ kiểu edit của chế độ đó** (và hướng dẫn dùng công cụ 7).
- `make_samples.py`: khóa `"mode"` + khóa `"custom_values"` cho màn mẫu (13 = `minesweeper` + 2 mìn ghim, 14 = `sum_path` + 3 điểm ô).
- Hướng dẫn Minesweeper (`resources/localization/string_extra.csv`): mục "Không Có Bất Kỳ Vách Tường Nào" → **"Tường: Daily Không Có · Màn Thiết Kế Có Thể Có"** (`STR_GI_MINESWEEPER_P1_R3T/R3D`) vì màn Special có tường thật.

**5. Kiểm thử & màn mẫu**

- `scripts/test_case/test_level_special_modes.gd` (**125 check PASS** — v2.15 mục 6, v2.16 thêm check tổng): mode/độ khó đọc từ LevelData · cờ `level_run` đúng cho màn/Daily/Debug · Minesweeper & Sum Path dùng ĐÚNG tường của màn (so từng đoạn tường) + **chơi lại cho kết quả y hệt** (cùng seed) · Daily vẫn tự sinh bàn · nút Skip có ở 2 action bar, ẩn với ván thường, hiện với ván màn · `skip_level()` mở khoá màn kế KHÔNG ghi Sao, màn cuối chương trả `-1` · **mục 5 (kiểu edit)**: chi phí Countdown Cost = giá trị tô (kể cả 4 trên màn "medium") · điểm Sum Path = giá trị tô · mìn GHIM giữ đúng + luôn còn đường an toàn · mìn ghim **chặn hết đường thì bị bỏ** (bàn hành lang 3×2) · **màn khai `dungeon` bị coi như `play`** (thư mục levels tạm) · 2 mìn ghim trong file màn mẫu 13 có mặt trên bàn · **mục 6 (v2.15)**: MỌI màn mẫu 13..20 — chế độ chạy ĐÚNG bàn nhà thiết kế vẽ, tường giữ nguyên, `design_moves`/chi phí ô/tường ép ẩn đúng luật, One Stroke **phủ kín đủ 24 ô** của màn 19.
- `tools/level_designer/tests/test_custom_values.py` (**22 test MỚI**): parse/ghi `custom_cell_values` + giữ chuỗi lạ · model (set/get/xoá/prune/snapshot) · controller (tô/xoá/undo/redo, kẹp giá trị theo chế độ, đổi `mode_id` thì đổi công cụ) · config (không còn `dungeon`, mọi chế độ có kiểu edit) · validator (dungeon = LỖI, ngoài khoảng = CẢNH BÁO, mìn ghim trên đường ngắn nhất). Bộ tool: **153 test PASS** (thêm `tests/test_path_tool.py` — 25 test công cụ vẽ đường 8 · `tests/test_path_values.py` — 17 test chia giá trị theo đường).
- `test_levels_paging.gd`: cập nhật đường dẫn nhãn số màn `Panel/Content/Level` (commit `f0579a7` dời vào `Content` — test cũ vẫn tra `Panel/Level`).
- **Bộ 14 test mặc định PASS 14/14**. 4 test mode ngoài bộ mặc định (`test_hud_modes` 22/49 · `test_wall_builder` 6/51 · `test_one_stroke` 5/34 · `test_fog_of_war` 2/27) giữ NGUYÊN số lỗi như trước phase (đã đối chiếu bằng `git stash`) — lỗi cũ do đường dẫn node HUD, không liên quan.
- Màn mẫu trong repo: **13 = Minesweeper** (board chữ U 6×4) · **14 = Sum Path** (11×11). Ảnh chứng cứ: `D:\godot-phone-game\tmp_shot_inkmaze\phaseE_*.png` (màn 13 cả 2 hướng, màn 14, Daily ẩn nút Skip, màn 1 Play hiện nút Skip).

**6. MÀN MẪU CHO MỌI CHẾ ĐỘ (13–20) + SỬA LỖI ONE STROKE (v2.15)**

`make_samples.py` giờ dựng **11 màn mẫu**, phủ **MỌI chế độ** (mỗi chế độ 1 màn, đều ở **chương 2**:
`10`–`12` polyomino Play · `13` minesweeper (2 mìn ghim) · `14` sum_path (19 ô, **tổng điểm 60**) ·
`15` countdown_cost (8 ô, **tổng chi phí 30** ⇒ `max_steps` 33) · `16` blind_memory · `17` fog_of_war ·
`18` fading_ink (9 ô **có mực tô tay**) · `19` one_stroke (bàn trống 6×4) · `20` wall_builder (12 tường ẩn).
Màn 14/15/18 dùng khóa **`"path_values"`** mới của `make_samples.py` = **tô giá trị theo ĐƯỜNG NGẮN NHẤT**
(giống hệt nút Ctrl+Enter của tool — xem 2b-bis); màn 15–20 **để trống thử thách** ⇒ game dùng bộ thử
thách mặc định riêng của từng chế độ.

- **LỖI THẬT ĐÃ SỬA — One Stroke không bao giờ nhận bàn thiết kế**: `_cover_search()` gọi `_region_ok()` cho
  nước đi CUỐI vào F; lúc đó `rest` đã bỏ F nên hàm luôn trả `false` ⇒ mọi màn one_stroke tự vẽ đều âm thầm rơi
  về bàn tự sinh (chỉ kèm `push_warning`). Nay nước vào F được xử riêng (“F chỉ được là ô cuối cùng”),
  và test mục 6 khẳng định One Stroke **phủ kín đủ số ô của màn mẫu** ⇒ không tái phát.
- **Debug Console (F9)**: lưới “Nhảy tới màn” lấy danh sách **động** từ `LevelManager` (trước đây cứng 9 màn)
  + nút có **◆** nếu màn chạy chế độ Special; “Unlock all levels”/“Set 3 stars” cũng quét hết màn thật.
  ⇒ test nhanh 1 chế độ bất kỳ: F9 → *Nhảy tới màn* → bấm số màn (vd **19** = One Stroke).
- `test_chapters.gd` + `test_level_special_modes.gd` bỏ giả định “màn 14 là màn cuối chương 2” — nay tự lấy
  màn cuối của chương từ `LevelManager.levels_in_chapter()`.

---

### 10.2g. UI KHAI TRONG SCENE — TAB TỰ LO (v2.17)

**Nguyên tắc**: node UI nào **cố định** (không phụ thuộc dữ liệu) thì **khai trong scene bố cục**, không
`instantiate()` lúc chạy. Node tự lo hành vi của mình (nối tín hiệu + nhãn + cỡ) rồi **phát 1 tín hiệu
riêng** cho màn; màn chỉ **gom lại** và điều khiển trạng thái. Chỉ những gì **đếm theo dữ liệu**
(số thẻ, số trang, số chấm, số hàng) mới được sinh lúc chạy.

| Màn | Trước v2.17 (dựng bằng code) | Sau v2.17 (khai trong scene) |
|---|---|---|
| Cửa hàng | `_build_tabs()`: xoá sạch khay rồi `TAB_BUTTON_SCENE.instantiate()` × 4, `setup(category, key)` + nối `pressed` + .attach_press_down` + `_apply_tab_metrics()` tự chia bề rộng | `Tabs/Tab_pen · Tab_theme · Tab_tool · Tab_coin` trong `scenes/layout/{portrait,landscape}/shop.tscn`; màn chỉ `_collect_tabs()` |
| Xếp hạng | `_build_tabs()` + `_fit_tab_widths()` (tự tính lại bề rộng theo anchors vì HBox bị min-size của tab đẩy tràn) | `Sheet/Tabs/Tab_dungeon · Tab_play · Tab_daily` (ĐÚNG thứ tự) trong 2 scene ranking; bề rộng do **HBox chia đều** (`size_flags_horizontal = EXPAND_FILL`) ⇒ hết `_fit_tab_widths()` |
| Sổ tay thành tựu | `_build_tabs()` × 5 tab (khay dọc = HBox · khay ngang = GridContainer 2 cột) | `Sheet/Tabs/Tab0…Tab4` (category `""` · levels · dungeon · daily · special) trong 2 scene archivement |
| Cửa hàng (lưới ô) | `_make_grid()` instantiate `item_grid.tscn` mỗi lần dựng danh sách | `Content/List/Grid` khai sẵn trong 2 scene shop; màn **dùng lại** (xoá thẻ cũ + `move_child` xuống cuối) |
| Cửa hàng (bàn nháp thử bút) | `_build_doodle_pad()` instantiate `doodle_pad.tscn` mỗi lần vào tab BÚT & MỰC (rồi xoá khi rời tab) | `Content/List/Pad` (dọc) · `Body/LeftCol/PadSlot/Pad` (ngang) khai sẵn; màn chỉ `_show_doodle_pad()` (BẬT + nạp ngòi đang xem thử) / ẩn khi rời tab |
| Cửa hàng (hàng VIP *Xoá quảng cáo*) | `_rebuild_coin()` instantiate `noads_row.tscn` mỗi lần vào tab NẠP XU | `Content/List/NoAds` khai sẵn; màn chỉ hiện + nạp dữ liệu |
| Xếp hạng (hàng) | `_fill_rows()` xoá hết rồi instantiate lại toàn bộ hàng mỗi lần đổi bảng | `_fill_rows()` **dùng lại** hàng đang có (chỉ tạo thêm/bớt khi số hạng đổi) |
| Bàn cờ (ô · tường · neo · vệt mực cũ) | `CELL_SCENE` · `WALL_SEGMENT_SCENE` · `ANCHOR_SCENE` · `HISTORY_LINE_SCENE`.instantiate() cho **từng** ô/tường/neo/vệt mực **mỗi tầng mới** | 4 **node MẪU** khai trong `nodes/game/board_layers.tscn` (`Cells/CellTemplate` · `Walls/WallTemplate` · `Anchors/AnchorTemplate` · `Lines/HistoryTemplate` — luôn ẩn); board `_spawn_template()` = `duplicate()` + bật hiện |
| Bàn cờ (nét mực · chỉ dẫn · con trỏ) | `layers.moving_line()` … tự `instantiate()` trong `BoardView._init_layers()` | `Lines/MovingLine` · `Lines/DragGuide` · `Markers/Cursor` khai sẵn trong `board_layers.tscn`; mỗi tầng chỉ RESET trạng thái |

**Cách 1 tab hoạt động (component tự lo)**

1. Scene bố cục khai instance `tab_button.tscn` + 2 thuộc tính `@export`:
   `category` (Cửa hàng) / `board_id` (Xếp hạng) / `category` (Sổ tay) và `label_key` (khoá dịch nhãn;
   Sổ tay để trống vì nhãn kèm **số lượng** nên màn tự đặt qua `set_label_text()`).
2. `_ready()` của component: dịch nhãn · `UIAnim.attach_press_down(self)` · nối `pressed` → phát
   `tab_pressed(id)` · chỉnh cỡ (`ShopTabButton.apply_metrics()` theo cỡ màn hình; `RankTabButton` giữ
   chiều cao của scene nhưng **bỏ bề rộng tối thiểu** để HBox chia đều).
3. Màn `_collect_tabs()`: duyệt `layout.tabs_box.get_children()`, nối `tab_pressed` → handler **1 lần**
   (`is_connected` chống nối trùng khi xoay màn hình), lưu vào `_tabs`/`_tab_buttons`. Xoay màn hình ⇒
   gọi lại `_collect_tabs()` cho layout mới (**không** dựng lại node).

- Thêm/bớt/đổi thứ tự tab ⇒ sửa **scene bố cục** (cả 2 hướng) — không phải sửa script màn.

**Node MẪU cho node ĐỘNG (bàn cờ)**
Ô · tường · neo · vệt mực cũ **đếm theo bàn** nên vẫn phải sinh lúc chạy — nhưng KHÔNG instantiate
scene nữa: `board_layers.tscn` khai sẵn **1 node mẫu** cho mỗi loại (đang ẩn), board nhân bản bằng
`BoardView._spawn_template()` (`duplicate()` + bật hiển thị + đưa về gốc toạ độ).

- Cỡ THIẾT KẾ của tường (5.5) + vệt mực cũ (20) đọc **từ node mẫu** ⇒ bỏ hẳn `_read_scene_line_width()`
  và 4 `preload()` scene trong `board.gd`.
- `BoardLayers.fixed_nodes()` trả về danh sách **node KHAI SẴN không được xoá** — `_clear_runtime_layers()`
  chỉ so `_keep_nodes.has(child)` (trước đây so từng node một).
- Đổi art/cỡ của ô/tường/neo/vệt mực ⇒ sửa **scene GỐC** (`cell.tscn` · `wall_segment.tscn` ·
  `anchor.tscn` · `history_line.tscn`); đổi **bố cục** ⇒ sửa `board_layers.tscn`. Script không biết gì.
- **Hàng rào chống tái phát**: `test_ui_scenes` mục **8** quét mã nguồn — script nào còn
  `preload()/instantiate()` scene ĐÃ khai sẵn trong scene cha thì **FAIL** (đối chiếu bảng `FIXED_SCENES`).
- ⚠️ **Bẫy `null` mất đi**: node khai sẵn có mặt NGAY từ `_ready()` nên `node == null` KHÔNG còn nghĩa
  “chưa setup”. Hàm chạy theo SỰ KIỆN KHUNG (`resized` · `size_changed` · `NOTIFICATION_RESIZED`) phải tự
  kiểm dữ liệu đã đủ chưa — vd `BoardView._update_layout_positions()` phải thoát sớm khi `maze == null`
  (trước đây dựa vào `_cursor == null` để thoát, mà con trỏ nay khai sẵn ⇒ `Out of bounds` ở
  `_cell_center` làm bàn cờ không dàn lưới = app như bị treo · sửa ở v2.17, xem TODO VÒNG 21c).

**API qua METHOD của lớp cha — KHÔNG với tay lấy node con (v2.17)**

Luật cho mọi View mới: **bên ngoài chỉ gọi method**; node nào có “phần trình bày” riêng thì **tách script
gắn gắn thẳng vào node đó** (như `ChallengeCard`), lớp cha giữ API mà caller nhìn thấy.

| Trước (với tay vào node con) | Sau (gọi method) |
|---|---|
| `ChallengeController` tự đọc `card.get_node_or_null("Row1/Bg/Check")`… + 9 hằng art/màu trong controller | Thẻ tự lo: `ChallengeCard.refresh(rows, done, total, note)`; controller chỉ tính TRẠNG THÁI (`done` · `on_track`), art/màu nằm trong `challenge_card.gd` |
| `GameScene`: `hud.get_node_or_null("Content")` để nhường input + `ui("HintGuide")` | `hud.allow_board_input()` · `hud.hint_guide()` (HUD tự tra node con của mình) |
| API chung của HUD nằm ở `GameHUD` (gọi qua `BaseHUD` chỉ nhờ dynamic dispatch) | API chung đưa lên **`BaseHUD`**: `update_hud` · `set_time` · `action_bar` + 5 nút · `challenge_card` · `hint_guide` · `allow_board_input` + hook `_on_update()`/`_sync_instruction()` |
| `board.gd` đọc `cell.get_node_or_null("Sprite/Label")` để lấy cỡ chữ gốc | `MazeCell.text_font_size()` |
| `daily.gd` dò `rows_host.get_node_or_null("Slot1")` · `ranking.gd` dò `my_rank_bar.get_node_or_null("Flag")` | `DailyLayout.mission_slot(i)` · `RankingLayout.my_rank_flag()` |
| `ActionBar.update_tool_counts()` cập nhật badge `PanelLimit` cho Skip/Undo/Hint | `LimitedButton.set_remaining(left)` — script gắn thẳng vào 6 nút Skip/Undo/Hint của 2 bản `action_bar.tscn` |
| `base.gd` tự lấy `Background/SideL` · `SideR` rồi tự tính lại offset viền theo khung | `SceneBackground.apply_sides(canvas, frame)` — script gắn thẳng vào `Background` của `scenes/base.tscn` |
| `board.gd` với tay đặt cỡ/pivot/animation cho từng ô và neo (`cell.size`, `pivot_offset`, tween `scale`) | `MazeCell.set_cell_size()` · `play_entrance()` · `MazeAnchor.set_anchor_size()` · `play_entrance()` · `set_selected()` · `pulse()` |
| `board.gd` gọi con trỏ/nét mực kiểu duck-typing: `_cursor.has_method("run_to")` + `call("run_to", …)` | `BoardLayers` trả **đúng lớp** (`cursor() -> PlayerCursor` · `moving_line() -> InkStroke` · `anchor_template() -> MazeAnchor`) ⇒ gọi thẳng `_cursor.run_to(…)` · `_moving_line.set_stroke(…)` |
| `board.gd`/`GridController`/`GameController` hỏi `game_mode.has_method("ink_left")` rồi `call()`/`get()`/`set()` | `BaseGameMode` khai sẵn **năng lực tuỳ chọn** (cờ + hàm mặc định): `shows_ink_left()`+`ink_left()` · `tracks_visited_cells()`+`is_cell_visited()` · `tracks_satisfied_cells()`+`is_cell_satisfied()` · `is_walkable()` · `has_bomb_marker()` · `is_unwinnable()` · `evaluate_submit()`+`register_submit_miss()`+`submit_miss_count()`+`mark_solved()` — mode con chỉ override phần của mình |
| `GridController`/`GameController` hỏi `board_view.has_method("move_cursor_to")` (kiểu đã là `BoardView` ⇒ guard luôn đúng) | Gọi thẳng method của `BoardView` (`setup_maze` · `move_cursor_to` · `set_moving_path` · `show_wall_hit`/`show_mine_hit` · `pulse_cell` · `reset_to_start` · `set_interaction_enabled` · `reveal_all_walls`/`hide_all_walls` · `shake_board` · `spawn_floating_popup`…), chỉ còn guard `!= null` |

- **Chế độ chơi mới (LSP)**: KHÔNG để board/controller “móc túi” mode bằng `has_method()`/`call()`/`get()`.
  Thêm **1 cặp** vào `BaseGameMode`: *cờ năng lực* (mặc định `false`) + *hàm mặc định* (giá trị trung tính),
  rồi mode con override; nơi gọi chỉ còn `if mode.shows_ink_left(): … mode.ink_left(pos)`.
- **Còn lại (chưa làm)**: nhóm **autoload/dịch vụ** vẫn dùng `has_method()` để chịu được “dịch vụ chưa có”
  (`AdsManager` · `ArchivementManager` · các wrapper `utils/*.gd`) — cùng kiểu “dịch vụ tuỳ chọn”, xử lý sau.
- Đã XOÁ hook chết (v2.18): `GridController.handle_cell_pressed()` trỏ tới `BoardView.highlight_real_walls_of_cell()`
  **không tồn tại** (guard `has_method` luôn `false`) + cả dây `signal cell_pressed` (`BoardView` · `MazeCell`)
  vì không nơi nào nghe — chạm ô không có phản hồi nào cả, thêm lại thì phải viết cả View lẫn Controller.

**Node con của scene ⇒ `@export` bind TRONG SCENE, KHÔNG dò đường dẫn (v2.18)**

Trước: script tự `get_node_or_null("Content/ModeInformation/Sheet/Retry/Value")`. Sau: khai **1 `@export`**
trỏ node rồi **bind trong `.tscn`**; đổi node/bố cục ⇒ sửa scene, script không đổi.

| Trước (dò đường dẫn trong script) | Sau (bind trong scene) |
|---|---|
| `FogOfWarHUD._on_update()` gọi `get_node_or_null("Content/ModeInformation/Sheet/Retry/Value")` | `@export var retry_value_node : Label` + `nodes/hud/<hướng>/game/fog_of_war_hud.tscn` ghi `retry_value_node = NodePath("Content/ModeInformation/Sheet/Retry/Value")` |
| 10 HUD chế độ (Level · Dungeon · Minesweeper · Blind Memory · Fading Ink · Fog of War · One Stroke · Wall Builder · Sum Path · Countdown) tự dò `Content/ModeInformation/…` | mỗi HUD 1–11 export (`step_value_node` · `cover_note_label` · `chip_pricey_label` · `fill_clip` · `segments_box` · `challenge_node`…), bind trong **cả 2 hướng** |
| `BaseHUD`: `get_node_or_null("Content")` · `("Content/ActionBar")` · `("Content/ModeInformation/Time")` + `get_time_node()` | `content_root` · `action_bar_node` · `time_value_node` (bind ở `game_hud.tscn` 2 hướng; scene bản NGANG bind thêm `time_value_node` vì `Time` do từng HUD khai) |
| `GameHUD`: `get_node_or_null("Content/InstructionSection")` rồi `Panel/GuideHost` + `Panel/Fallback` (bản DỌC không có khung nên luôn `null` — che mất lỗi) | `instruction_section_node` / `instruction_host` / `instruction_fallback_btn` — chỉ HUD NGANG bind, HUD DỌC để trống là **đúng thiết kế** |

- `.tscn` ghi 2 phần: dòng `[node name="Hud" … node_paths=PackedStringArray("a", "b") instance=…]` +
  các dòng `a = NodePath("Đường/Dẫn")` trong khối node đó (Godot tự sinh khi kéo node vào ô export).
- Hệ quả ĐÃ SỬA kèm: đồng hồ của các HUD chế độ (Fog · One Stroke · Sum Path · Wall Builder…) trước đây
  để `time_value_node = NodePath("")` ⇒ `set_time()` không ghi gì (đồng hồ đứng im); nay bind đủ 2 hướng.
- **Hàng rào** (`test_ui_scenes` mục 9): instantiate **25 scene HUD** (2 hướng) — mọi `@export` kiểu NODE phải
  KHÁC `null` (bỏ qua 3 export `instruction_*` ở HUD DỌC + scene TRỪU TƯỢNG `game_hud.tscn`); và quét mã nguồn
  `scripts/nodes/hud`: không còn `get_node_or_null("Content/…")`.
- ⚠️ Scene TRƯU TƯỢNG (`game_hud.tscn`) không có node riêng của bản ngang (`Time` để từng HUD chế độ khai)
  ⇒ đừng bind ở đó rồi tưởng mode scene thừa hưởng; export bind trong scene CHA chỉ ăn khi node có thật.

- Thêm `class_name` mới ⇒ chạy 1 lần `godot --headless --path . --editor --quit` để Godot quét lại danh sách
  lớp (`.godot/global_script_class_cache.cfg`), nếu không script khác báo “Could not resolve external class member”.
- Giới hạn đã biết: số tab là **cố định theo thiết kế** (Cửa hàng 4 · Xếp hạng 3 · Sổ tay 5). Tab nào
  đếm theo dữ liệu thì mới cần sinh lúc chạy.
- **Kiểm thử**: `test_shop` (252 check) · `test_ranking` (69) · `test_archivement` (57) đều đọc tab qua
  node của scene (`Sheet/Tabs/TabN`, art active/inactive) — thêm `test_ui_scenes` kiểm tab **tự dịch nhãn
  từ `label_key`** khi gắn vào cây, 4 node MẪU của bàn cờ + `fixed_nodes()` (7 node);
  `test_layout_bindings` (78) chốt lại danh sách `@export` buộc đúng node trong 2 bản bố cục
  (nay thêm `item_grid` · `doodle_pad` · `noads_row`).

---

### 10.2h. TUTORIAL KHAI TRONG SCENE — Ô BÀN MINI · DÂY TÍN HIỆU · ART SVG (v2.19)

**Yêu cầu user**: “việc tạo ra/init node/connecting signal/vẽ bên trong script rất khó maintain ⇒ đưa tất cả
vào `.tscn`; chỗ nào VẼ thì tạo SVG rồi load bằng TextureRect/NinePatchRect; gọi node trong code thì `@export`
và bind ngay trong scene”.

| Trước (dựng trong script) | Sau (khai trong scene) |
|---|---|
| `BaseTutorial._build_ui_if_needed()` + `_create_dialog_bubble()` + `_style_primary/secondary_btn()` dựng Backdrop · Spotlight · BoardHost · HandPointer · DialogBubble (StyleBoxFlat + 3 nút) · ToastLabel | `nodes/tutorials/base_tutorial.tscn`: **13 node + 5 StyleBoxFlat**; script chỉ còn `@export` bind (`backdrop` · `spotlight` · `board_host` · `hand_pointer` · `dialog_bubble` · `lbl_title` · `dots_container` · `lbl_message` · `nav_bar` · `btn_skip/_skip_all/_next` · `toast_label`) |
| `_on_spotlight_draw()` (`draw_rect` vẽ vòng sáng) + `_on_pointer_draw()` (`draw_colored_polygon` vẽ tay chỉ) | art `assets/images/tutorial/tutorial_spotlight.svg` (NinePatchRect, patch 48) + `tutorial_pointer.svg` (TextureRect 48×48) + `tutorial_wall.svg` + `tutorial_board_paper.svg` |
| `_update_dots()` tự `Label.new()` cho từng chấm | 6 chấm `Dot1…Dot6` khai sẵn trong `DialogBubble/VBox/Header/Dots`; `_update_dots()` chỉ đổi `visible`/`text`/màu |
| 3 nút điều hướng `.pressed.connect(_on_*_pressed)` trong code | `[connection signal="pressed" from="DialogBubble/VBox/NavBar/BtnNext" to="." method="next_step"]` (× 3) |
| Mỗi bài (`how_to_play_*.gd`) có `_setup_board()` dựng PanelContainer ô + Label + StyleBoxFlat + Line2D + HUD + nút | bàn mini khai trong `nodes/tutorials/<bài>.tscn`: `BoardPanel` (NinePatchRect giấy) · `Cell1…CellN` (instance **`tutorial_cell.tscn`**) · `PathLine` (Line2D) · `HudPanel`/`Label` · nút tường (`TutorialWallToggle`) · `BtnSubmit` |
| `_cells: Dictionary` + `_cell_labels` + tra toạ độ bằng hằng số | `@export var cells: Array[TutorialCell]` (+ `path_line` · `wall_top` · `lbl_hud_sum` · `lbl_hud_counter` · `wall_toggles` · `preview_cells`) — bind trong `.tscn` |
| Nút bật/tắt tường: `Button.new()` + `ColorRect` làm hình + `pressed.connect(lambda)` | **`TutorialWallToggle`** (`scripts/nodes/tutorial/tutorial_wall_toggle.gd`, `signal wall_toggled(wall_id, active)`, `@export wall_id/wall_visual`) + `[connection]` `pressed → _on_pressed` và `wall_toggled → _on_toggled` khai trong `how_to_play_wall_builder.tscn` |

**2 component mới**

- `TutorialCell` (`nodes/tutorials/tutorial_cell.tscn`): PanelContainer + `Label`; `grid_pos` · `style_visited`
  (nền “đã đi qua” của One Stroke) · `cell_text` · `text_color` · `text_size` — **ghi đè ngay trên node gốc của
  instance trong `.tscn`** (không cần “Editable Children”, không đụng Label bên trong); API `set_text` ·
  `set_text_color` · `set_text_size` · `set_visited` · `pulse`.
- `TutorialWallToggle` (xem hàng bảng trên) — hình đoạn tường là `NinePatchRect` dùng `tutorial_wall.svg`,
  `modulate` xanh (Wall Builder) / đỏ (Checking Wall).

**`.tscn` — 2 bài học bắt buộc nhớ**

1. Export NODE **mảng** (`Array[TutorialCell]`) ghi bằng `node_paths` + danh sách NodePath, KHÔNG phải
   `Array[NodePath]`:
   `[node name="HowToPlayMove" … node_paths=PackedStringArray("cells", "path_line")]`
   → `cells = [NodePath("BoardHost/Cell1"), NodePath("BoardHost/Cell2"), NodePath("BoardHost/Cell3")]`.
   ⚠️ Quên `node_paths=PackedStringArray(...)` ở dòng `[node ...]` ⇒ **mọi export im lặng bằng `null`**
   (`show_step()` chết ngay ở `lbl_message.text`).
2. Scene bài học là **kế thừa `base_tutorial.tscn`** (`instance=ExtResource("1_base")` + `script = …`), thêm
   node con bằng `[node name="BoardHost/…" parent="BoardHost" index="N"]` — node của bài nào nằm trong bài đó.

**Lỗi THẬT đã sửa nhân dịp này** (tutorial trước đây gần như không dùng được, chỉ thấy khung thoại):

- `BoardHost` dựng bằng `set_anchors_preset(PRESET_CENTER)` + `position = (40, 200)` ⇒ trong không gian thiết kế
  **540×920** (`project.godot`: `viewport_width=540 · viewport_height=920 · stretch=viewport`) bàn mini bị đẩy ra
  NGOÀI màn hình (ô đầu ở x ≈ 380…696). Nay `BoardHost` neo **trên-trái (40, 200) · 460×420** ⇒ vừa khít
  (đáy 620 < mép thẻ thoại 740).
- **Kéo đường không bao giờ ăn**: `board_host` (Control, mặc định `STOP`) nuốt sự kiện chuột nên `_gui_input`
  của root không nhận được. Nay `BoardHost` + `BoardPanel` + mọi ô `mouse_filter = IGNORE` (ô khai trong
  `tutorial_cell.tscn`, nút tường/GỬI vẫn `STOP`) ⇒ thao tác kéo rơi xuống tutorial root.
- **Sai không gian toạ độ**: code cũ so `event.position` (toạ độ của root) với `cell.position` (toạ độ trong
  `board_host`) ⇒ lệch 40/200px. Nay so **toàn cục**: `cell.get_global_rect().has_point(event.global_position)`.
- Toạ độ ghi trong dữ liệu bước (`spotlight_rect`, `pointer_drag/tap`) vẫn là toạ độ **trong BoardHost**;
  `BaseTutorial._board_to_overlay()` cộng vị trí `board_host` khi đặt Spotlight/HandPointer ⇒ hết lệch.

**Hàng rào mới** (`test_ui_scenes` mục **11**, 8 scene): mọi `@export` NODE phải bind khác `null` · export mảng
đúng số phần tử (ô mini / nút tường) · mỗi ô 1 `grid_pos` không trùng · `BoardHost` phải `IGNORE` · mọi dòng
`[connection]` trong `.tscn` phải trỏ tới node + hàm CÓ THẬT · **CẤM** `draw_rect/draw_polyline/draw_circle/
draw_colored_polygon` trong `scripts/nodes/tutorial` · bảng bài của `TutorialController` phải có scene thật.
Mục 6 (cấm `.new()` cho lớp UI) tự xanh khi bỏ code dựng node; `test_ui_scenes` nay **106/106 PASS**.

**Xem bằng mắt**: `scripts/test_case/dev_tutorial_shots.gd` (dev, không thuộc suite) — mount từng bài qua
`TutorialController.play_single_tutorial()` ở 2 tỉ lệ rồi lưu `tmp_tut/<WxH>/<bài>_stepN.png`
(&lt;godot&gt; `--path . --rendering-driver opengl3 -s res://scripts/test_case/dev_tutorial_shots.gd`).

**HIỆU ỨNG (animation) — dùng lại `UIAnim` + `Sfx` của game, KHÔNG node mới, KHÔNG `draw_*`:**

| Chỗ | Hiệu ứng |
|---|---|
| Mở bài (`play_entrance()`) | nền tối hiện dần 0.24s · thẻ thoại trượt lên 42px · `BoardHost` nở 0.94→1 · **từng ô nở so le 0.045s** · tiếng lật trang |
| Đổi bước | nhãn thoại fade 0.18s · tiêu đề pop nhẹ · **chấm đang ở bước nảy lên** · tiếng gõ thẻ giấy |
| Ô đi qua | `TutorialCell.play_step()`: nhún + nháy sáng + tiếng chấm bút (`Sfx.CELL_STEP`) |
| Thao tác SAI | `TutorialCell.play_fail()`: nháy đỏ + rung ngang 3 nhịp · `flash_fail()` cho tường/HUD · nền loang đỏ 0.45s · tiếng gãy ngòi (`Sfx.WALL_HIT`) |
| Thao tác ĐÚNG | toast nở ra (0.86→1) rồi mờ dần · `play_cells_win()` cả bàn nở so le · chữ nổi `✓` / `+N` bay lên (`UIAnim.spawn_floating_text`) · tiếng chuông gỗ (`Sfx.STAR_POP`) |
| Vòng sáng | TRƯỢT sang mục tiêu mới 0.26s (không nhảy cứng) rồi "thở" scale 1↔1.06 |
| Tay chỉ | rê lặp như cũ; chạm (tap) thêm **lắc ±7°** như gõ ngón tay |
| HUD bài học | Sum Path **cuộn số** Tổng (`UIAnim.animate_counter`) + nảy khi khớp mục tiêu · Wall Builder nảy khung đếm mỗi lần vẽ/xoá tường · đoạn tường **NỞ RA** khi bật / co lại khi tắt (kèm SFX) |
| Nút điều hướng | `UIAnim.attach_press_down()` cho cả 3 nút (giống mọi nút khác trong game) |

Script bài học KHÔNG tự tạo node/tween lạ: chỉ gọi API `BaseTutorial` (`play_entrance()` · `play_cells_win()` ·
`spawn_board_text()` · `flash_fail()`), `TutorialCell`/`TutorialWallToggle` và `UIAnim`/`Sfx` ⇒ giữ nguyên
hàng rào `test_ui_scenes` mục 11 (không `draw_*` · không `.new()` UI · export bind trong .tscn).

**Kèm theo (cùng vòng)**: `scripts/scenes/tutorial.gd` bỏ `get_node_or_null("Controllers/TutorialController")`
— nay bind trong `scenes/tutorial.tscn` qua `node_paths=PackedStringArray("tutorial_controller")`; `test_ui_scenes`
bỏ 2 lời gọi `tab.setup()` đã bị xoá khỏi `AchTabButton`/`RankTabButton` (lỗi cũ làm 6 check của mục 2/4
KHÔNG hề chạy) → mục 4 nay kiểm đúng thiết kế tab hiện tại (giữ chiều cao 26 · bề rộng do HBox chia · tự
dịch `label_key` · tự nối `pressed` → phát `tab_pressed`).

---

### 10.2i. TÁCH TUTORIAL THÀNH 2 MÀN: DANH SÁCH + CHI TIẾT (v2.47 — 2026-10-23)

**Yêu cầu user**: “tách tutorial scene thành `tutorial_list` để chứa list của tutorial, và `tutorial` để chứa
tutorial mà người dùng chọn để xem”.

Trước đây **1 màn** (`scenes/tutorial.tscn`) vừa là danh sách 12 bài vừa mount bài học **đè lên** danh sách
(`TutorialContainer` full-rect nằm trên `Paper`). Hệ quả nhìn thấy được: khi có bài học, màn hiện **2 tiêu đề
chồng nhau** (tiêu đề của màn + tiêu đề trong `BaseTutorial`) và nút Back của màn nằm **lơ lửng trên** nền bài học.

| | Trước | Sau |
|---|---|---|
| Scene gốc | `scenes/tutorial.tscn` (danh sách + chi tiết) | **`scenes/tutorial_list.tscn`** (DANH SÁCH) + **`scenes/tutorial.tscn`** (CHI TIẾT) |
| Layout | `portrait|landscape/tutorial.tscn` (danh sách + `TutorialContainer`) | `…/tutorial_list.tscn` (chỉ danh sách) + `…/tutorial.tscn` (chỉ `Paper` + `TopBar` + `TutorialContainer`) |
| Script layout | `TutorialLayout` (16 export) | `TutorialListLayout` (16 export: Back · tiêu đề · danh sách + 12 nút) và `TutorialLayout` (4 export: Back · tiêu đề · `tutorial_container` · `header_anchor`) |
| Script màn | `TutorialScene` (danh sách + mount bài) | `TutorialListScene` (khoá/mở 12 nút · bấm ⇒ mở màn chi tiết) + `TutorialScene` (chỉ mount bài/chuỗi) |
| Controller | `Controllers/TutorialController` trong màn duy nhất | chỉ có ở màn CHI TIẾT (màn danh sách **không** mount bài nào) |

**Điều hướng (giữ nguyên 4 nguồn mở, chỉ đổi đích):**

| Nguồn | Trước | Sau |
|---|---|---|
| Nút **LUẬT CHƠI** ở Main (`main.gd::_on_rules_pressed`) | `Nav.goto_tutorial()` (màn chung) | **`Nav.goto_tutorial_list()`** → danh sách |
| Bấm 1 bài trong danh sách | tự mount bài trong cùng màn | `GameManager.request_tutorial(id, true)` → **`Nav.goto_tutorial()`** (màn chi tiết) |
| **Luồng học lần đầu** (`TutorialManager`) | `NAV.goto_tutorial()` | **không đổi** — vẫn vào thẳng màn CHI TIẾT |
| Nút **"?"** trong màn chơi (lớp phủ) | `scenes/tutorial.tscn` add_child | **không đổi** — vẫn là màn CHI TIẾT (chỉ mount container) |
| Debug Console | “Tutorial (menu)” mở màn chung · bài lẻ mở màn chung | “Tutorial (menu)” → **danh sách** (`scenes/tutorial_list.tscn`) · bài lẻ/chuỗi CORE → màn CHI TIẾT |

**Cờ điều hướng mới** (`GameManager`): `pending_return_to_list` + `take_return_to_list_flag()`;
`request_tutorial(id, from_list := false)` đặt cả `pending_tutorial` và cờ này.

**Quy tắc Back / học xong (`TutorialScene`):**

| Mở từ | Học xong / Bỏ qua tất cả | Nút Back |
|---|---|---|
| DANH SÁCH (`from_list`) | `Nav.back_to_tutorial_list()` | về danh sách |
| Lớp phủ "?" trên màn chơi | đóng lớp phủ ⇒ chơi tiếp ĐÚNG ván | đóng lớp phủ |
| Bài học của chế độ (`pending_return_to_game`, đổi scene) | `Nav.goto_game()` | `Nav.goto_game()` |
| Luồng onboarding | đi tiếp luồng / Main | Main |
| Bài lẻ Debug (Test mode) | về DANH SÁCH | về danh sách |

**Sửa kèm (lỗi thật gặp khi tách):**

1. `TutorialContainer.z_index = 30` (> `TopBar.z_index = 10` của `base_layout`) ⇒ bài học VẼ ĐÈ thanh trên:
   hết cảnh 2 tiêu đề chồng nhau + nút Back lơ lửng (ảnh trước/sau ở mục này).
2. `TutorialController._play_next_in_queue()`: id **không tồn tại** trước đây làm màn CHI TIẾT **trống vĩnh viễn**
   (`load_tutorial` trả `null` mà không phát `sequence_finished`). Nay bỏ qua bài lỗi ⇒ hết queue thì phát
   `sequence_finished` ⇒ màn tự điều hướng ra.
3. Tiêu đề màn (`STR_TUT_COMMON_TITLE`) trước đây là **khoá thô** trong `.tscn` (`TopBar` là instance của
   `base_layout` nên Label bên trong không tự dịch). Nay `_apply_texts()` gán `tr(...)` khi `_ready` **và**
   nghe `LocalizationManager.locale_changed` (bảng dịch nạp xong sau ~200 ms do `LoadingManager` hoãn).
4. `.tscn` của bản LIST: **bỏ `uid=` của `ExtResource` script** khi đổi script — `uid` được ưu tiên hơn `path`
   nên giữ uid cũ ⇒ layout vẫn chạy `tutorial_layout.gd` và `active_layout() as TutorialListLayout` trả `null`.

**Kiểm thử:** `test_tutorial_flow` **87 check** (mục 2e viết lại: LUẬT CHƠI → `tutorial_list.tscn`, màn danh sách
**không** có `tutorial_controller`, bấm bài đã xem ⇒ `tutorial.tscn` + `_return_to_list = true`, “Bỏ qua tất cả”
⇒ về lại danh sách, **Back ở màn chi tiết ⇒ danh sách**, **Back ở danh sách ⇒ Main**) ·
`test_layout_bindings` thêm 2 màn `tutorial` (4 export) + `tutorial_list` (16 export) ·
`test_life_points` thêm `tutorial_list` vào `LAYOUT_CHIP_EXCLUDED` (màn này cũng ẩn 2 chip dùng chung) ·
`dev_tutorial_shots.gd` vẫn dùng được (nạp `scenes/tutorial.tscn` + `play_single_tutorial`).

---

### 10.3. Sinh lại mockup

```bash
python tools/mockup/gen_matchup.py            # sinh lại 7 mockup matchup_<mode>.svg
python tools/mockup/gen_matchup.py --list     # danh sách mode sẽ sinh
python tools/mockup/gen_matchup.py --dump     # in toạ độ node thật của các scene HUD
```

- Tool đọc **toạ độ thật** từ `nodes/hud/*.tscn` + `scenes/game.tscn` (Board `(41,420)-(1061,1440)`, thanh nút `(73,1528)-(1031,1688)`, Status `(50,85)`).
- Hằng `HAND_DRAWN` trong tool liệt kê **7 mockup art tay của user** (`matchup_level` · `matchup_dungeon` · `matchup_sum_path` · `matchup_countdown_cost` · `matchup_fading_ink` · `matchup_one_stroke` · `matchup_wall_builder`) → chạy tool sẽ **BO QUA** 7 file này, chỉ sinh lại các mockup còn lại (minesweeper · blind_memory · fog_of_war).
- **Đã có mockup cho cả 2 chế độ mới:** `matchup_one_stroke.svg` + `matchup_wall_builder.svg` (user vẽ tay 2026-09-19) → thêm cả 2 vào `HAND_DRAWN` của `tools/mockup/gen_matchup.py` nếu muốn tool bỏ qua khi sinh lại.
- **Pipeline popup hướng dẫn** (dùng cho cả 2 mode mới): thêm 1 dòng vào `MODES` của `tools/mockup/instruction_mockup.py` → `python tools/mockup/prepare_guideline_images.py` (ảnh guideline ThorVG-safe) → thêm bản EN vào `tools/content/guide_text_en.py` → `python tools/content/build_instruction_data.py` (sinh `STR_GI_*` + CSV) → `python tools/mockup/gen_instruction_popups.py` (sinh `nodes/popups/instruction/<mode>.tscn`). **GOTCHA:** file `assets/images/instructions/guideline_image/*.svg` mới tải về có thể còn `.import` cũ **thiếu `path=`** → Godot báo `Failed loading resource` khi chạy popup; cách sửa: **xoá `.import` cũ rồi chạy lại `--editor --quit`** để import sinh `.ctex` mới.
- Mockup mang **bảng chú thích đánh số**: badge số đặt ngay trên thành phần cần giải thích + danh sách chú thích dưới thanh nút.

---

## 11. Bảng xếp hạng (Ranking Screen)

Màn hình mới theo mockup `mockup/ranking.svg` (1080×1920). Lối vào: nút **XẾP HẠNG** ở Main Screen (mục 4.1) hoặc Debug Console → NAVIGATE → *Leaderboard*.

### 11.1. Ba bảng (tab)

| Tab | Kỷ lục chính (dòng trên mỗi hàng) | Công thức điểm xếp hạng |
|---|---|---|
| **DUNGEON** | Tầng cao nhất | `best_floor × 620 + best_score ÷ 8` |
| **CHẾ ĐỘ PLAY** | Số màn đã qua | `levels_cleared × 360 + stars × 40 + max(0, 600 − fastest_clear) × 2` |
| **CHUỖI NGÀY** | Chuỗi ngày Daily | `streak × 280 + days × 30 + total_stars × 5` |

- **Điểm là khoá sắp xếp duy nhất**; bằng điểm thì xếp theo tên (bảng luôn ổn định, không nhảy lung tung).
- Mỗi bảng có **25 hạng = 24 đối thủ + người chơi**: bục vinh quang 3 hạng đầu (Gold giữa 240×200 · Silver trái 200×155 · Bronze phải 200×130, **đáy thẳng hàng**), danh sách cuộn hiển thị hạng 4 → 25 (7 hàng/lần, nhịp 105px).

### 11.2. Dữ liệu: kỷ lục thật + đối thủ mô phỏng

- **Người chơi — dữ liệu THẬT:** đọc từ `ArchivementManager.stat_value()`: `dungeon_best_floor`, `dungeon_best_score`, `levels_cleared`, `level_stars_total`, `fastest_clear`, `daily_streak`, `daily_days`, `daily_stars_total`. Chưa chơi ván nào → hàng hiện `CHƯA CÓ` + `0 ĐIỂM` và thanh đáy nhắc "hãy chơi một ván".
- **Đối thủ — dữ liệu MÔ PHỎNG (offline):** `RankingManager.RIVAL_POOL` gồm 24 mục `{name, flag, power}`; điểm sinh bằng `RandomNumberGenerator` với seed `hash("bảng|tên|khung-10-phút")` → **ổn định giữa các phiên**, chỉ đổi nhẹ mỗi khung 10 phút ⇒ mô phỏng "bảng xếp hạng sống" đúng như ghi chú chân trang mockup.
- Cờ quốc gia dùng asset có sẵn `assets/images/icons/flags/flag_{vi,en,ja,ko,zh_cn,fr,generic}.svg` (KHÔNG dùng emoji); cờ của người chơi suy từ ngôn ngữ đang chọn.
- **Khi nối Google Play Games** (xem `TODO.txt`): chỉ cần thay thân `RankingManager._build_board()` bằng dữ liệu server — scene, hàng, định dạng giữ nguyên.

### 11.3. Giao diện (đo từ scene thật)

Tờ giấy `rank_sheet.svg` **940×1570 tại (70,185)**, viền `#6EA0C8` 3.5px, lề đỏ x=75, lỗ bấm giấy mỗi 120px, dòng kẻ ô ly mỗi 80px; băng keo washi + kẹp giấy ở mép trên (như Sổ tay thành tựu).

| Thành phần | Vị trí trong tờ giấy | Ghi chú |
|---|---|---|
| 3 tab | (95, 52), rộng 240 · 235 · 245, cách 15 | tab đang chọn = nền `#3D83AE` + chữ trắng; tab còn lại = giấy + viền `#8FB9D2` |
| 2 đường kẻ nét đứt | y = 126 và y = 522, rộng 755 | dùng lại `assets/images/settings/divider_dashed.svg` (STRETCH_TILE) |
| Bục vinh quang | (95, 140), cao 370 | Gold (255,170) · Silver (20,215) · Bronze (525,240) — toạ độ trong cụm |
| Danh sách cuộn | (95, 545) 755×770 | `ScrollContainer` ẩn thanh cuộn (`vertical_scroll_mode = 3`), VBox cách 15px — **vuốt dọc để cuộn** (2026-09-19) |
| Thanh "hạng của bạn" | (95, 1330) 755×110 | nền `#3D83AE` viền `#256286`, hạng màu `#FBBF24` |
| Ghi chú chân trang | y = 1480 / 1516 | 1 dòng nghiêng (làm mới 10 phút) + 1 dòng nhỏ (bảng offline demo) |

- Hàng danh sách: `nodes/ranking/rank_row.tscn` + `scripts/nodes/ranking/rank_row.gd` — `setup(entry, board)`; bố cục `#hạng (x=40) · cờ (x=96) · tên (x=152) · kỷ lục (phải, x=600) · điểm (phải, x=600)`; hàng của người chơi tự đổi sang art `rank_row_you.svg` (nền xanh nhạt).
- **Vuốt/cuộn danh sách (2026-09-19):** hàng xếp hạng là `Control` (mouse_filter STOP) nên "ăn" hết sự kiện kéo → `ScrollContainer` không tự cuộn được. `ranking.gd` tự xử lý ở `_input` (chạy TRƯỚC GUI): ngưỡng **14px** mới tính là vuốt (trục dọc → `scroll_vertical = int(_drag_scroll − delta.y)`), `set_input_as_handled()` khi cuộn; kéo bắt đầu **ngoài** vùng cuộn thì bỏ qua; đổi tab reset `scroll_vertical = 0`.
- Theme variations mới: `RankTabLabel` · `RankRowIndex/Name/Record/Points` · `RankPodiumRank{Gold,Silver,Bronze}` · `RankPodiumPoints{Gold,Silver,Bronze}` · `RankPodiumName/Record` · `RankMyRank/Name/Sub/Record/Value` · `RankChip` · `RankFooter` · `RankFooterNote`.
- Chuỗi dịch mới nằm ở `resources/localization/string_extra.csv` (id,en,vi): `STR_RANK_TITLE`, `STR_RANK_SCOPE`, `STR_RANK_TAB_*`, `STR_RANK_RECORD_*`, `STR_RANK_POINTS`, `STR_RANK_YOU`, `STR_RANK_SUBTITLE`, `STR_RANK_NO_RECORD(_SHORT)`, `STR_RANK_FOOTER`, `STR_RANK_DEMO`.

### 11.4. File liên quan

| File | Vai trò |
|---|---|
| `scripts/manager/RankingManager.gd` | Autoload `RankingManager`: dựng 3 bảng · sắp hạng · cửa sổ làm mới 10 phút · `board_ids/entries/podium/rest/my_entry/my_rank/last_refresh_unix/refresh(force)` · signal `ranking_changed(board)` |
| `scripts/utils/ranking.gd` | Facade tĩnh `Ranking` (test-safe) + định dạng dùng chung: `display_name`, `record_text`, `points_text`, `rank_text`, `thousands` |
| `scenes/ranking.tscn` + `scripts/scenes/ranking.gd` | Màn hình (`class_name RankingScene`): 3 tab dựng bằng code · đổ bục · đổ danh sách · thanh hạng của bạn · Back → Main |
| `nodes/ranking/rank_row.tscn` + `scripts/nodes/ranking/rank_row.gd` | Component 1 hàng 755×90 (`class_name RankRow`, có cache texture cờ) |
| `assets/images/ranking/*.svg` | `rank_sheet` · `tab_active`/`tab_normal` · `medal_gold`/`silver`/`bronze` · `podium_gold`/`silver`/`bronze` · `rank_row` · `rank_row_you` · `my_rank_bar` · `chip_scope` |
| `scripts/test_case/test_ranking.gd` | 95 check: API dữ liệu · sắp hạng · người chơi · ổn định seed · cửa sổ làm mới · định dạng · scene (3 tab · bục · danh sách · thanh đáy · đổi tab · **vuốt dọc cuộn được, kéo ngắn/kéo ngoài vùng không cuộn**) |

**Khác biệt so với mockup (có chủ đích):**

1. Chip góc phải ghi **"MÁY NÀY"** (`STR_RANK_SCOPE`) thay vì "TOÀN CẦU" — bảng hiện là offline/demo, khi nối Google Play sẽ đổi nhãn.
2. **Không dùng emoji** (👑🏆) trong UI thật — icon lấy từ `assets/images/` (quy ước chung của dự án); vương miện cạnh tên top 1 trong mockup được thay bằng huy chương vàng + bục vàng.
3. Bỏ dòng **"• • •"** vì danh sách đã **cuộn được** tới hạng 25 (giữ nguyên tinh thần "còn nữa" của mockup).
4. Chân trang thêm 1 dòng nhỏ ghi rõ **bảng ngoại tuyến (demo) — đối thủ là dữ liệu mô phỏng** để không gây hiểu nhầm là bảng online thật.

---

## 12. Hệ thống CHƯƠNG (Chapter) — màn “Chọn chương” đã XOÁ (v2.49 — 2026-10-23)

Thêm 2026-02 (tinh chỉnh 2026-09-15, viết lại bản dọc 2026-10-22 — §12.4c).

> **2026-10-23: XOÁ màn CHỌN CHƯƠNG.** Tab chương (`ChapterTabs`) + khung khoá
> (`ChapterLockSheet`) nằm ngay trong màn **Chọn màn** đã thay thế hoàn toàn màn riêng này ở
> **cả 2 hướng**, nên đã xoá `scenes/chapters.tscn` · `scripts/scenes/chapters.gd` ·
> `scripts/scenes/layout/chapters_layout.gd` · 2 layout `scenes/layout/{portrait,landscape}/chapters.tscn` ·
> `nodes/chapters/chapter_card.tscn` + `scripts/nodes/chapters/chapter_card.gd` ·
> `Nav.goto_chapters()` · `SceneManager.SCENE_CHAPTERS`/`goto_chapters()` ·
> `GameManager.go_to_chapters()` (2 chỗ gọi trong `game_controller` nay là `go_to_levels()`) ·
> mục “Select Chapter” của Debug Console. **KHÔNG xoá** `chest_chip` · `chapter_progress*` ·
> `chapter_rail` (màn Chọn màn đang dùng). Chi tiết: §12.8.

Luồng màn hình hiện tại:

```
Main ──[CHƠI]──▶ Chọn màn ──[bấm TAB chương đã mở]──▶ đổi chương NGAY TẠI CHỖ (không đổi scene)
                    │        └─[bấm TAB chương KHOÁ]──▶ ChapterLockSheet (MỞ KHOÁ / Đóng)
                    └──[Back]──▶ Main
```

- Màn **Chọn màn** là màn duy nhất của hệ chương (bấm CHƠI vào thẳng).
- **Tab chương** ở trên cùng là lối đổi chương duy nhất ở **cả 2 hướng**: tab đã mở ⇒ đổi chương
  không đổi scene; tab khoá ⇒ mở `ChapterLockSheet` (§12.4c).
- **Thẻ chương** chỉ để xem (không còn dây `gui_input` nào) — màn Chọn chương không còn để mở.
- Back ở màn Chọn màn (khi sheet đang mở thì Back đóng sheet trước) → Main.

### 12.1. Dữ liệu: `ChapterData` + quan hệ với `LevelData`

- Mỗi chương = **1 file `resources/chapters/chapter_<id>.tres`** (`script_class="ChapterData"`, schema `scripts/resources/chapter_data.gd`): `chapter_id` · `title` · `subtitle` · `size_label` (rỗng = ẩn chip) · `star_cost` (0 = mở sẵn).
- **Quan hệ là NGƯỢC:** `LevelData.chapter` (int) trỏ tới chương của màn — "thêm màn vào chương" = ghi `chapter = N` cho file màn đó (nhờ vậy màn chỉ thuộc **đúng 1** chương, không sợ danh sách chương lệch dữ liệu).
- `ChapterData.icon` = **tên icon riêng của chương** (`intro` · `logic` · `trap` · `master` — rỗng thì UI tự chọn theo số chương, ngoài phạm vi thì fallback theo cỡ bàn). Icon thật nằm ở `assets/images/chapters/icon_<tên>.svg`, mỗi chương một doodle mê cung khác nhau:

| Chương | Icon | Hình |
|---|---|---|
| 1 · NHẬP MÔN | `icon_intro` | lưới 3×3 + đường chữ L đơn giản |
| 2 · SUY LUẬN | `icon_logic` | lưới 5×5 + đường zigzag nhiều khúc |
| 3 · BẪY ẨN | `icon_trap` | lưới 7×7 + 2 dấu X nét đứt (bẫy) |
| 4 · BẬC THẦY | `icon_master` | lưới 9×9 + đường xoắn dài + ngôi sao |
| ≥ 5 / chưa đặt | `maze_small`/`medium`/`large` | theo cỡ bàn lớn nhất của chương |
- 4 chương hiện có: 1 · **NHẬP MÔN** (3×3–5×5, mở sẵn, 9 màn) · 2 · **SUY LUẬN** (4×4–11×11, 25 sao, 5 màn) · 3 · **BẪY ẨN** (8×8, 45 sao) · 4 · **BẬC THẦY** (9×9, 70 sao).

| API `LevelManager` | Vai trò |
|---|---|
| `get_chapters()` / `get_chapter(id)` / `chapter_count()` / `has_chapter(id)` | Đọc dữ liệu chương |
| `chapter_of_level(id)` / `levels_in_chapter(id)` | Gom màn theo chương |
| `chapter_star_total(id)` · `chapter_cleared_count(id)` · `chapter_stars(id)` | Số liệu tiến độ của chương |
| `current_chapter_id()` | Chương chứa `GameManager.current_level` |

### 12.2. Năm trạng thái TAB chương (thay thẻ chương cũ)

> Thẻ chương 5 trạng thái (`ChapterCard`) đã **XOÁ** cùng màn Chọn chương — trạng thái chương nay
> nằm trên **TAB** của màn Chọn màn (`ChapterTab.State`, §12.4c):

| Trạng thái tab | Điều kiện | Tab hiện |
|---|---|---|
| `SELECTED` | Chương đang xem **và** đã mở | Nhãn dài "CHƯƠNG n" · nền `tab_selected` (cam) · chữ trắng |
| `OPEN` | Đã mở, có màn | Số chương · nền `tab_normal` |
| `READY` | Chưa mở + `total_stars >= star_cost` | Số chương + huy hiệu `badge_ready` "!" nhấp nháy |
| `LOCKED` | Chưa mở + thiếu Sao | Số chương + ổ khoá · nền `tab_locked` (nét đứt xám) |
| `COMING` | Đã mở nhưng chương **chưa có màn nào** | Số chương + ổ khoá mờ, không bấm được |

Bấm tab `OPEN`/`SELECTED` ⇒ đổi chương tại chỗ; bấm `READY`/`LOCKED` ⇒ mở **khung khoá** (KHÔNG
tiêu Sao — chỉ cần `total_stars >= star_cost`, xem §12.3).

### 12.3. Mở khóa bằng Sao (`GameManager`)

- `unlocked_chapters: Array[int] = [1]` (chương 1 luôn mở) + `current_chapter: int = 1`; cả hai được lưu trong save (`export_progress`/`import_progress`) và xoá khi `reset_progress()`.
- `total_stars()` = tổng Sao **toàn bộ** màn · `chapter_star_cost(id)` = `star_cost` của chương · `can_unlock_chapter(id)` · `unlock_chapter(id)` → phát signal `chapter_unlocked` + `Save.queue_save()`.
- Sao dùng để mở khóa là **tổng Sao tích lũy** (không tiêu mất) — mở chương 2 (25) xong vẫn còn nguyên Sao để tiến tới chương 3 (45).

**Khóa theo chương (chống nhảy chương):**

- `record_level_clear()` chỉ mở màn kế tiếp khi màn đó **tồn tại** *và* **chương của nó đã mở** → xong màn cuối chương 1 **không** tự mở màn 10 khi chương 2 còn khóa.
- `next_level_in_chapter(level_id)` = màn kế tiếp **trong cùng chương** (−1 nếu là màn cuối chương) · `can_play_level(level_id)` = tồn tại + chương đã mở + đã mở theo tiến trình.
- `has_unlockable_chapter()` = có chương **đủ Sao để mở** mà chưa mở (tab `READY` nhấp nháy ở màn Chọn màn).

### 12.3b. Tiếp tục sau khi thắng màn (popup kết quả)

- Nút phải của popup thắng: **"MÀN KẾ TIẾP"** khi còn màn trong cùng chương **và** chương đó đã mở; nếu đây là **màn cuối của chương** (hoặc chương kế chưa mở) thì đổi thành **"CHỌN MÀN"** (`STR_CHAPTER_SCREEN_TITLE`) và quay về **màn Chọn màn**.
- Dữ liệu popup có thêm cờ `next_available` (do `GameController._complete_floor()` tính) — `winning.gd` đổi nhãn theo cờ này; cả hai trường hợp đều đi qua `continue_requested` → `GameController._on_continue_requested()` (đi tiếp trong chương nếu được, ngược lại `GameManager.go_to_levels()`).
- Màn **Chọn màn**: thẻ chân màn **"MÀN TIẾP THEO"** theo cùng luật — hiện màn chưa đạt sao đầu tiên của chương, và đổi thành **"HOÀN THÀNH CHƯƠNG"** + nút **"CHƯƠNG TIẾP ›"** khi đã xong hết màn của chương (§12.4c).
- **Ô đếm Sao ở màn Chọn màn** (`card_stars`, pill trên thẻ chương) hiện `chapter_stars(current) / chapter_star_total(current)` (Sao TRONG chương đang xem).

### 12.4. Giao diện — ĐÃ XOÁ (2026-10-23)

`scenes/chapters.tscn` (`ChaptersScene`) và `nodes/chapters/chapter_card.tscn` (`ChapterCard`) đã bị
xoá; bảng đo đạc chi tiết của 2 file này chỉ còn giá trị lịch sử (xem git history). Giao diện chương
hiện tại nằm trong màn Chọn màn — **§12.4c**.

### 12.4b. Thanh tiến độ + 3 RƯƠNG MỐC thưởng — đặt ở màn **CHỌN MÀN** (v2.46 — 2026-10-22)

Tầng **B** của [planning/Number Maze — Chiến lược thưởng chế độ Play.md](../planning/Number%20Maze%20—%20Chiến%20lược%20thưởng%20chế%20độ%20Play.md):
màn **CHỌN MÀN** (`scenes/levels.tscn`) có **thanh tiến độ Sao** giống thanh Sao của màn Daily, kèm
**3 rương mốc** nằm đúng ngưỡng **33% · 67% · 100%** tổng Sao của chương.

> **Vị trí (đổi 2026-10-22):** thanh này **KHÔNG** nằm ở màn Chọn chương nữa — người chơi nhìn thấy nó
> ngay khi chọn màn, nằm **giữa banner chương và bản đồ**. Màn Chọn chương chỉ còn danh sách chương.
> **Bản DỌC từ v2.47** dùng **rail DỌC ở lề trái** thay thanh ngang (xem §12.4c) — cùng widget, chỉ khác
> `vertical = true`; bản NGANG vẫn là thanh ngang như bảng dưới.

**1. Widget `nodes/chapters/chapter_progress.tscn`** (`class_name ChapterProgress`):

```
ChapterProgress (Control, cao 64)
├─ Caption  Label        "THƯỞNG CHƯƠNG"  (STR_CHAPTER_PROGRESS_TITLE)
├─ Count    Label        "x / y SAO"      (STR_CHAPTER_STARS_FORMAT)
├─ Bar      TextureProgressBar  (daily/bar_track.png + daily/bar_fill_gold.png, 9-slice, cao 32)
└─ Chips    Control
   ├─ Chip0 / Chip1 / Chip2   instance nodes/chapters/chest_chip.tscn
```

- `setup(stars_own, stars_total)` đổ dữ liệu: `Bar.max_value = stars_total`, `Bar.value = stars_own`,
  nhãn Sao, rồi hỏi `GameManager.chapter_chest_defs(stars_total)` để biết 3 ngưỡng + phần thưởng.
- **Vị trí rương do code tính lại khi đổi kích thước** (`_layout_chips()`): tâm thanh tại
  `EDGE_MARGIN + (width − 2·EDGE_MARGIN) × ngưỡng/tổng`, nhờ vậy rương ở 0%/100% không bị cắt nửa vòng.
- Chương **chưa có màn nào** (`stars_total = 0`) ⇒ widget tự ẩn.
- Nhãn tự viết lại khi **đổi ngôn ngữ** và khi bảng dịch nạp xong (`LocalizationManager.locale_changed`).

**2. Chèn vào 2 bố cục màn Chọn màn** (`scenes/layout/portrait|landscape/levels.tscn`) — bản NGANG dùng
export `LevelsLayout.progress` nằm trong `Content/InformationArea` ngay dưới `ChapterBanner`; bản DỌC dùng
export `LevelsLayout.rail` (`chapter_rail.tscn`, `vertical = true`) ở lề trái — xem §12.4c:

| Hướng | Node | Anchor | Ghi chú |
|---|---|---|---|
| Dọc (tới v2.46) | `Progress` ngang | `left 0.13 · top 0.232 · right 0.87 · bottom 0.30` | **đã thay** bằng `Rail` dọc ở v2.47 (§12.4c) |
| Dọc (v2.47) | `Rail` = `chapter_rail.tscn` | `left 0.015 · top 0.305 · right 0.265 · bottom 0.815` | rail DỌC ở lề trái, bản đồ dịch phải `snake_center_shift = 50` |
| Ngang | `Progress` ngang | `left 0.18 · top 0.215 · right 0.82 · bottom 0.283` | không kéo hết bề ngang màn rộng |

`MapArea` (node dùng chung trong `scenes/levels.tscn`) hạ `anchor_top` **0.20 → 0.31** để bản đồ
không đè lên thanh.

**3. Chip rương `nodes/chapters/chest_chip.tscn`** (`class_name ChapterChestChip`) — dùng lại art của
màn Daily: vòng hổ phách (đủ Sao) / vòng xanh (chưa đủ) · rương đóng ↔ mở · huy hiệu ✓ khi đã nhận ·
`tooltip` = `STR_CHAPTER_CHEST_TOOLTIP` ("{0}★ reward: {1}"). Bấm khi đủ Sao ⇒ `claim_requested(index)`.

**4. Dữ liệu (`GameManager`, lưu cùng blob tiến trình):**

| Thành phần | Giá trị |
|---|---|
| `CHAPTER_CHEST_RATIOS` | `[0.33, 0.67, 1.0]` |
| `CHAPTER_CHEST_REWARDS` | `{coins: 50}` · `{hint: 2, undo: 1}` · `{coins: 150, life: 1}` |
| `chapter_chests` | `chapter_id -> [index đã nhận]` (JSON: khoá chuỗi + float, đã ép kiểu khi nạp) |
| Nguồn cấp mới | `"chapter_chest"` thêm vào `GRANT_SOURCES` + `LIFE_GRANT_SOURCES` |

API: `chapter_chest_defs(stars_total)` · `chest_threshold(ratio, total)` (làm tròn, kẹp `[1, total]`;
chương 27★ ⇒ 9/18/27) · `claimed_chapter_chests(id)` · `is_chapter_chest_claimed(id, index)` ·
`can_claim_chapter_chest(id, index, stars_own, stars_total)` ·
`claim_chapter_chest(...)` (đánh dấu **trước** khi trao ⇒ bấm liên tiếp không nhận 2 lần) ·
`chapter_chest_reward_text(def)` (ghép "+50 XU" · "Gợi ý ×2 + Hoàn tác ×1" · "… + 1 lượt chơi") ·
**`reset_chapter_chests()`** (xoá trạng thái đã nhận của MỌI chương + `Save.queue_save()` — Debug Console
“Reset progress” gọi hàm này, xem §9 PROGRESS).

**5. Luồng trên màn Chọn màn** (`scripts/scenes/levels.gd`):

- `_refresh_progress()` luôn hiển thị **chương đang chơi** (`current_chapter` → `ChapterData`), gọi lại khi
  vào màn, khi màn được kích hoạt lại (`_on_active` — thắng/thua xong quay về là số Sao đã đổi) và khi
  xoay màn hình (`_rebind_after_orientation`).
- Bấm rương ⇒ `_on_chest_claim_requested(index)`: `claim_chapter_chest()` → `Sfx.ACHIEVEMENT` →
  mở **popup rương dùng chung của Daily** (`nodes/popups/daily_milestone.tscn`) với
  `title_text = STR_CHAPTER_CHEST_POPUP_TITLE` ("CHƯƠNG n — THƯỞNG m★") + `reward_text` →
  vẽ lại header + thanh.
- `DailyMilestonePopup` nhận thêm `title_text` / `sub_text` / `reward_text` (không truyền thì giữ
  nguyên hành vi cũ của mốc Daily).

**6. Kiểm thử:** `scripts/test_case/test_chapter_rewards.gd` (**74 check**) — ngưỡng 33/67/100 · bộ
thưởng · chỉ nhận 1 lần & độc lập từng chương · cộng Xu/lượt công cụ/lượt chơi đúng nguồn ·
lưu/đọc (`reset_progress` xoá, save cũ không lỗi, khoá chuỗi của JSON) · **thanh/rail nằm đúng chỗ ở màn
Chọn màn** (ngang: giữa banner và bản đồ · dọc: rail lề trái giữa thẻ chương và thẻ màn kế) · đầy đúng 10/27 ·
3 rương đúng ngưỡng 9/18/27 và nằm trong phạm vi thanh ·
bấm rương 1 ⇒ +50 Xu + popup + dấu ✓ + rương mở · **màn Chọn chương KHÔNG còn thanh này** ·
popup dùng chung vẫn đúng mặc định cho Daily.

### 12.4c. Màn CHỌN MÀN bản **DỌC** — viết lại theo mockup (v2.47 — 2026-10-22)

Guide gốc: [planning/AI_GUIDE_level_screen.md](../planning/AI_GUIDE_level_screen.md) (pha 4.1–4.6 · §5 hình học · §7 tiêu chí).
**Chỉ bản DỌC đổi** — bản NGANG giữ nguyên bố cục cũ (banner “ĐỔI CHƯƠNG” · thanh thưởng NGANG · bản đồ zigzag ·
nút “CHỌN CHƯƠNG” chân màn), vì vậy **màn Chọn chương vẫn được giữ** cho tới khi bản ngang được dựng lại.

Bố cục từ trên xuống trong `scenes/layout/portrait/levels.tscn`:

| Khối | Node | Anchor (L · T · R · B) | Vai trò |
|---|---|---|---|
| Thanh trên | `TopBar` (dùng chung) | 0.034 · 0.034 · 0.961 · 0.142 | Back · tiêu đề · ví Sao + chip Xu/Lượt |
| **Tab chương** | `Tabs` — `nodes/level_selection/chapter_tabs.tscn` | 0.03 · 0.146 · 0.97 · 0.196 | Đổi chương ngay tại chỗ (thay dòng “ĐỔI CHƯƠNG”) |
| **Thẻ chương** | `ChapterBanner` | 0.044 · 0.202 · 0.957 · 0.286 | `Title` + `Subtitle` + `Stars` (“x / y STARS”) + `Levels` (“9/9 levels”); `ChangeChapter` **ẩn** |
| **Rail thưởng DỌC** | `Rail` — `nodes/chapters/chapter_rail.tscn` | 0.015 · 0.305 · 0.265 · 0.815 | `ChapterProgress` với `vertical = true` |
| Bản đồ | `MapArea` (node dùng chung `scenes/levels.tscn`) | — · 0.31 · — · 0.82 | `LevelMap` bố cục **RẮN** |
| **Thẻ màn kế** | `NextCard` — `nodes/level_selection/next_level_card.tscn` | 0.048 · 0.845 · 0.952 · 0.945 | CHƠI / CHUYỂN CHƯƠNG thay nút chân trang cũ |
| **Sheet khoá** | `LockSheet` — `nodes/level_selection/chapter_lock_sheet.tscn` (`z_index = 20`) | full rect | Lớp phủ khi bấm tab chương KHOÁ |

Bản dọc **bỏ hẳn** node `Progress` (thanh ngang) và `ContinueButton` (nút chân trang) — export vẫn còn trên
`LevelsLayout` cho bản NGANG nên script phải chịu được `null` (xem `reward_bar()`).

**1. `ChapterTab` / `ChapterTabs`** (`scripts/nodes/level_selection/chapter_tab.gd` · `chapter_tabs.gd`)

| Trạng thái `ChapterTab.State` | Điều kiện | Tab hiện |
|---|---|---|
| `SELECTED` | chương đang xem **và** đã mở | Nhãn `CHƯƠNG n` (dài) · viền xanh · nền giấy đậm |
| `OPEN` | đã mở, có màn | Số chương |
| `READY` | chưa mở nhưng `total_stars >= star_cost` | Số chương + **badge “!” nhấp nháy** (`PulseAnim`) |
| `LOCKED` | chưa mở **và** thiếu Sao | Số chương + **ổ khoá** |
| `COMING` | đã mở nhưng chương chưa có màn nào | Số chương + ổ khoá mờ |

- `ChapterTabs.setup(chapters, selected_id)` dựng tab từ `Array[ChapterData]`, tự cuộn tab đang chọn vào giữa
  (`Scroll` đặt `horizontal_scroll_mode = 3` = **cuộn được nhưng ẩn thanh cuộn**).
- Tín hiệu: `chapter_selected(id)` (tab mở) · `locked_chapter_requested(id)` (tab khoá).
- API kiểm thử: `tab_count()` · `tab_for(id)` · `selected_id()`.

**2. `ChapterLockSheet`** — lớp phủ bấm từ tab KHOÁ: nền mờ + thẻ giấy gồm icon chương · `CHƯƠNG n` ·
`CẦN n SAO` / **`ĐÃ ĐỦ`** (theo `total_stars`, **không tiêu Sao** — §12.3) · thanh tiến độ mở khoá ·
nút **MỞ KHOÁ** (chỉ bật khi đủ Sao) · nút ✕. `open_chapter(id)` · `close_sheet()` · `is_open()`;
tín hiệu `unlock_requested(id)` · `closed`. Phím **Back/ESC** (`ui_cancel`) cũng đóng sheet
(`levels.gd::_unhandled_input`).

**3. Rail thưởng DỌC** (`ChapterProgress`, thêm `@export vertical := false`)

- `fill_mode = 3` (**bottom → top**): 0★ ở **ĐÁY**, 100% ở **ĐỈNH**; rương mốc xếp **từ đáy lên**
  (`_layout_chips_vertical()`), tâm chip theo trục dọc của thanh, `EDGE_MARGIN_V = 14` để rương 0%/100%
  không bị cắt.
- Khung rail 112×420 nằm ở **lề trái**, nhường chỗ cho bản đồ dịch sang phải (`LevelMap.snake_center_shift = 50`).
- Nhãn “THƯỞNG CHƯƠNG” + “x / y SAO” viết lại khi đổi ngôn ngữ (§12.4b mục 1).

**4. Bản đồ RẮN** (`LevelMap` thêm `columns = 3` · `column_spacing = 120` · `row_spacing = 170` ·
`turn_bulge = 34` · `snake_center_shift = 50`)

- `effective_columns()` = 0 khi `is_wide()` ⇒ **bản ngang vẫn dùng zigzag cũ**, bản dọc mới dùng rắn.
- Hàng 0 ở **đáy** đi **trái → phải**, hàng 1 đi **phải → trái**… (`_snake_positions()`) nên 1-2-3 dưới,
  4-5-6 giữa (6-5-4), 7-8-9 trên như mockup.
- Đường nối: trong cùng hàng **thẳng**, mỗi lần **chuyển hàng** chèn một **điểm uốn nằm NGOÀI dải cột**
  (`turn_bulge`) ⇒ sợi dây quấn quanh mép bản đồ; số điểm kiểm soát = `n` nút + 1 điểm uốn/lần chuyển hàng.
- Giới hạn cuộn lấy theo **vị trí thật** của các nút nên đúng cả 2 kiểu.

**5. `NextLevelCard`** — thẻ chân màn: huy hiệu số màn · `MÀN TIẾP THEO` / **`HOÀN THÀNH CHƯƠNG`** ·
3 ngôi sao đã đạt · nút **CHƠI** (`play_requested`) hoặc **CHUYỂN CHƯƠNG ›** (`next_chapter_requested`).
`setup(level_id, stars_earned, cleared, has_next)`; nhãn lấy từ `STR_LEVEL_NEXT_CARD_TITLE` ·
`STR_LEVEL_PLAY` · `STR_LEVEL_START_LABEL` · `STR_CHAPTER_DONE_TITLE` · `STR_CHAPTER_GO_NEXT`.

**6. Nối dây (`scripts/scenes/levels.gd`)**

| Hàm | Việc |
|---|---|
| `_wire_chapter_ui()` / `_refresh_chapter_ui()` | Nối + vẽ lại `tabs` / `rail` / `next_card` / thẻ chương (gọi khi vào màn, khi màn được kích hoạt lại, khi xoay màn hình) |
| `_on_chapter_tab_selected(id)` | `GameManager.current_chapter = id` → `_rebuild_for_chapter()` (**không đổi scene**) |
| `_on_locked_chapter_requested(id)` | Mở `ChapterLockSheet` |
| `_on_unlock_chapter_requested(id)` | `unlock_chapter(id)` → vẽ lại tab/rail/sheet |
| `_on_next_chapter_requested()` | Sang chương kế (hoặc màn Chọn chương nếu chương kế chưa có) |
| `is_sheet_open()` · `_unhandled_input()` | Back/ESC đóng sheet trước khi rời màn |
| `_on_continue_pressed()` | Bản ngang: nút `ContinueButton`; bản dọc: `NextLevelCard.play_requested` |

**7. Khoá dịch mới** (`string_extra.csv`): `STR_LEVEL_NEXT_CARD_TITLE` · `STR_LEVEL_PLAY` ·
`STR_LEVEL_START_LABEL` · `STR_CHAPTER_LOCK_TITLE` · `STR_CHAPTER_READY_TITLE` ·
`STR_CHAPTER_DONE_TITLE` · `STR_CHAPTER_GO_NEXT`.

**8. Kiểm thử:** `scripts/test_case/test_level_screen.gd` (**59 check**): trạng thái 5 loại tab · bấm tab
đổi chương **không đổi scene** · sheet mở/đóng + mở khoá **không trừ Sao** · vị trí rắn cho 9 và 14 màn ·
nhận rương trên màn Chọn màn · thẻ màn kế khi đã xong chương · xoay màn hình vẫn giữ Sao/tỉ lệ.
Cập nhật theo thiết kế mới: `test_levels_map` (bố cục rắn + đường nối chuyển hàng) ·
`test_chapter_rewards` (rail dọc) · `test_layout_bindings` (export của hướng còn lại là **tuỳ chọn**).

**9. Việc còn lại (câu hỏi mở của guide §8):** `chapter_4.tres` đã có màn chưa (tab hiện `COMING` nếu rỗng) ·
số màn từng chương 2+ (bản đồ rắn cần ≥ 3 màn mới đẹp) · thời điểm dựng lại **bản NGANG** (xong mới xoá được
màn Chọn chương).

### 12.4d. Art “vòng 1” của màn Chọn màn — đã nối vào scene (v2.48 — 2026-10-23)

Bộ 28 asset trong `art_level_round1/` (spec: `art_level_round1/ART_LEVEL_README.md`) được đặt vào
`assets/images/level_selector/` (SVG — nguồn, có trong git) và `assets/images-png/level_selector/`
(PNG 2× — sinh bởi `tools/svg_to_png.py`, **git-ignored**).

> **Quy tắc 9-slice của dự án:** PNG là **2×** cỡ thiết kế trong khi scene dùng **đơn vị thiết kế (1×)**
> ⇒ `patch_margin_*` (NinePatchRect), `texture_margin_*` (StyleBoxTexture) và `stretch_margin_*`
> (TextureProgressBar) phải bằng **NỬA** giá trị “px PNG” ghi trong README của art. Dùng nguyên giá trị
> px PNG sẽ làm góc bị cắt/đè (đã gặp thật ở `tab_locked`: 24+24 > 38 px cao ⇒ tab bị sọc).

| Nơi dùng | Art | Chi tiết |
|---|---|---|
| `chapter_tab.tscn` · `Bg` | `tab_selected` / `tab_normal` / `tab_locked` | `patch_margin = 0` (**tỉ lệ art khớp đúng nút** 150×46 · 70×38 ⇒ không cần 9-slice, patch > 0 làm góc bị vát) |
| `chapter_tab.tscn` · `ReadyBadge` | `badge_ready` | **TextureRect 20×20** (trước là Label “!”) ở góc trên-phải, `pivot_offset = (10,10)` cho `PulseAnim` phóng to |
| `chapter_tab.tscn` · `Lock` | `icon_lock_small` | TextureRect 20×20 |
| `theme_default.tres` | `ChapterTabTitle` (navy #164663) · `ChapterTabTitleSelected` (trắng) · `ChapterTabTitleLocked` (xám #9AAEBD) | 15px · Bold/Black; `ChapterTab._title_variation()` gán theo State (SELECTED → Selected · LOCKED/COMING → Locked · còn lại → Title) |
| `chapter_rail.tscn` · `Bar` | `rail_track_v` / `rail_fill_v` | `stretch_margin = 12`, thanh rộng **28 px**, `fill_mode = 3` (đáy → đỉnh) |
| `next_level_card.tscn` · `Paper` | `card_next_level` | `patch_margin = 18 / 18 / 18 / 20` |
| `next_level_card.tscn` · `Badge` | `level_badge_gold` | **TextureRect 60×60** (trước là NinePatch `card_paper`), số màn đổi sang màu navy để nổi trên nền vàng |
| `next_level_card.tscn` · `Play` | `btn_play_blue_{normal,pressed,focus,disabled}` | 4 `StyleBoxTexture` riêng (`texture_margin = 16/14/16/18`); **chữ TRẮNG** (override `font_color`) vì `PaperCtaLabel` là navy |
| `next_level_card.tscn` · `Star1..3` | `star_pill_full` / `star_pill_empty` | anchor `0.5` (dời sang trái) + nhãn tiêu đề rút về `0.46` ⇒ 3 sao không bị nút CHƠI che |
| `chapter_lock_sheet.tscn` · `Card` | `card_lock_sheet` | `patch_margin = 20 / 20 / 20 / 22` (băng dính vàng ở mép trên) |
| `chapter_lock_sheet.tscn` · `Unlock` | `btn_green_normal` / `btn_green_pressed` / `btn_grey_disabled` | `texture_margin = 16/14/16/18`; `disabled` dùng art xám nét đứt (đúng trạng thái “chưa đủ sao”) |
| `scenes/layout/portrait/levels.tscn` · `ChapterBanner` | `card_chapter` (thay `chapter_banner.png`) | `patch_margin = 18/18/18/20`; layout gán **`banner_normal` = `banner_focus` = `card_chapter`** để `_refresh_chapter_banner()` không đổi về art focus cũ; nhãn trong thẻ dời lên (`Subtitle` 0.42–0.62 · `Stars` 0.36–0.64 · `Levels` 0.64–0.84) cho khỏi đè viền dưới. **Bản NGANG giữ nguyên `chapter_banner`** |
| `level_node.tscn` · `Button` | `level_node_normal/hover/pressed/disabled` + **`level_node_current`** | `LevelMapNode` thêm export `art_normal` / `art_current`; `_apply_state_look()` đổi `texture_normal` theo State ⇒ màn đang chơi có **nền VÀNG** (trước chỉ có vòng halo) |
| `level_node.tscn` · `Halo` | `level_node_halo` (art mới) | 224×224 @ `scale 0.5` ⇒ 112 px, **bỏ `position.y = -3`** (art mới cùng lưới 112 với nút) |
| `level_node.tscn` · `Lock` | `icon_lock_small` | Sprite2D @ `scale 0.5` ⇒ 24×24 |
| `level_node.tscn` · sao | `star_pill_full` / `star_pill_empty` | 44×44 @ ô 22×22 |
| `level_map.tscn` · `Marker` | `map_marker_pencil` (thay `map_marker_arrow`) | `Sprite2D.scale = 0.5` ⇒ 28×56; `marker_face_gap` **35** để đầu bút chì nằm trên mặt nút 7 px |
| `level_map.tscn` · `Goal` | `map_goal_flag` (art mới) | `Sprite2D.scale = 0.5` ⇒ 40×52; `flag_half_height` **26**, `flag_pole_offset` **10** (cột cờ art mới lệch tâm 10 px) |

**Kiểm chứng:** `--import` + boot `--quit-after` sạch; `test_level_screen` 59/59 · `test_levels_map` ·
`test_chapter_rewards` 74/74 · `test_chapters` 238/238 PASS; ảnh dựng ở 540×960, 540×1200 và 1920×1080
(bản NGANG không đổi bố cục, chỉ đổi art ô màn/cờ/mũi chỉ).

### 12.5. Asset · theme · chuỗi dịch

- `assets/images/chapters/` (25 SVG): 3 nền thẻ (`card_open`/`card_ready`/`card_locked`) · `halo_ready` · `ribbon` · `chip_size`/`chip_need`/`chip_have` · `bar_track`/`bar_fill` · `wallet_chip` · `banner_rule` · 3 nút 250×100 (`btn_play_*`, `btn_unlock_*`, `btn_locked`) · **4 icon riêng theo chương** (`icon_intro`/`logic`/`trap`/`master`) · 3 doodle theo cỡ (`maze_small`/`medium`/`large`) · `icon_star_white` · `lock_overlay`.
- `assets/images/level_selector/` — **art “vòng 1” của màn Chọn màn** (28 SVG mới, mỗi file PNG 2× ở `assets/images-png/level_selector/`): `tab_selected`/`tab_normal`/`tab_locked` · `badge_ready` · `rail_track_v`/`rail_fill_v` · `level_badge_gold` · `btn_play_blue_{normal,pressed,focus,disabled}` · `btn_green_{normal,pressed}`/`btn_grey_disabled` · `card_chapter`/`card_next_level`/`card_lock_sheet` · `level_node_{normal,hover,pressed,current,disabled}` + `level_node_halo` · `icon_lock_small` · `map_goal_flag` · `map_marker_pencil` · `star_pill_full`/`star_pill_empty` — bảng nối art ⇄ scene: §12.4d.
- Theme variations (`resources/settings/theme_default.tres`): `ChapterCardTitle(Locked)` · `ChapterCardSubtitle(Locked)` · `ChapterChipSize(Amber/Muted)` · `ChapterRibbon` · `ChapterStars(Muted/Sub)` · `ChapterNeedChip`/`ChapterHaveChip` · `ChapterAction(Sub/SubAmber/Locked/LockedSub)` · `ChapterWalletCount`/`ChapterWalletLabel` · `ChapterBannerText` — bản dọc màn Chọn màn (§12.4c) dùng lại `ChapterCardTitle` · `ChapterCardSubtitle` · `ChapterChipSize` · `ChapterNeedChip` · `ChapterStars(Muted)` · `ChapterWalletCount` · `PopupStatLabelMuted` · `PaperCtaLabel` · **`ChapterTabTitle` / `ChapterTabTitleSelected` / `ChapterTabTitleLocked`** (mới — nhãn tab chương, §12.4d).
- Chuỗi mới trong `string_extra.csv`: `STR_CHAPTER_SCREEN_TITLE` · `STR_CHAPTER_TITLE_FORMAT` · `STR_CHAPTER_RIBBON_{PLAYING,OPEN,READY,LOCKED,COMING}` · `STR_CHAPTER_SIZE_FORMAT` · `STR_CHAPTER_STARS_FORMAT` · `STR_CHAPTER_LEVELS_FORMAT` · `STR_CHAPTER_NEED_FORMAT` · `STR_CHAPTER_REQUIRE_FORMAT` · `STR_CHAPTER_HAVE_FORMAT` · `STR_CHAPTER_PLAY(_SUB)` · `STR_CHAPTER_UNLOCK` · `STR_CHAPTER_NOT_ENOUGH` · `STR_CHAPTER_STARS_HELD` · `STR_CHAPTER_BANNER` · `STR_CHAPTER_CONTINUE_FORMAT` · **`STR_CHAPTER_PROGRESS_TITLE` · `STR_CHAPTER_CHEST_TOOLTIP` · `STR_CHAPTER_CHEST_LIFE` · `STR_CHAPTER_CHEST_POPUP_TITLE` · `STR_CHAPTER_CHEST_POPUP_SUB`** (§12.4b) · **`STR_LEVEL_NEXT_CARD_TITLE` · `STR_LEVEL_PLAY` · `STR_LEVEL_START_LABEL` · `STR_CHAPTER_LOCK_TITLE` · `STR_CHAPTER_READY_TITLE` · `STR_CHAPTER_DONE_TITLE` · `STR_CHAPTER_GO_NEXT`** (§12.4c).

### 12.6. File liên quan

| File | Vai trò |
|---|---|
| `scripts/resources/chapter_data.gd` + `resources/chapters/chapter_*.tres` | Schema + dữ liệu chương |
| `scripts/core/level_manager.gd` | Quét chương · gom màn theo chương · số liệu Sao/màn |
| `scripts/core/game_manager.gd` | `unlocked_chapters`/`current_chapter` · điều kiện + mở khóa · `total_stars`/`next_level_in_chapter`/`can_play_level`/`has_unlockable_chapter` · `go_to_levels()` |
| ~~`scripts/nodes/chapters/chapter_card.gd` + `.tscn`~~ | **ĐÃ XOÁ 2026-10-23** cùng màn Chọn chương (§12.8) |
| `scripts/nodes/chapters/chapter_progress.gd` + `nodes/chapters/chapter_progress{,_h}.tscn` | Thanh tiến độ Sao + 3 rương mốc thưởng của chương — hiển thị ở màn **Chọn màn** (§12.4b) |
| `scripts/nodes/chapters/chest_chip.gd` + `nodes/chapters/chest_chip.tscn` | Chip rương mốc (đủ Sao → bấm nhận, đã nhận → rương mở + ✓) |
| ~~`scripts/scenes/chapters.gd` + `scenes/chapters.tscn`~~ | **ĐÃ XOÁ 2026-10-23** — thay bằng tab + khung khoá trong màn Chọn màn (§12.8) |
| `scripts/scenes/levels.gd` | Lọc màn theo chương · TAB chương + thẻ chương + rail/thanh thưởng + thẻ màn kế + sheet khoá (§12.4c) |
| `scripts/nodes/level_selection/chapter_tab.gd` + `chapter_tabs.gd` (+`.tscn`) | Tab chương 5 trạng thái + dải tab cuộn ngang (§12.4c) |
| `scripts/nodes/level_selection/chapter_lock_sheet.gd` + `.tscn` | Sheet “chương còn khoá”: tiến độ sao + nút MỞ KHOÁ (§12.4c) |
| `scripts/nodes/level_selection/next_level_card.gd` + `.tscn` | Thẻ “MÀN TIẾP THEO / HOÀN THÀNH CHƯƠNG” ở chân màn dọc (§12.4c) |
| `scripts/nodes/level_selection/level_map.gd` + `nodes/level_selection/level_map.tscn` | Bản đồ màn: RẮN 3 cột (bản dọc) / zigzag (bản ngang) — `columns`/`row_spacing`/`turn_bulge`/`snake_center_shift` |
| `scripts/nodes/level_selection/level_node.gd` + `nodes/level_selection/level_node.tscn` | Ô màn trên bản đồ: 5 trạng thái, export `art_normal`/`art_current`, halo, ổ khoá, 3 sao (§12.4d) |
| `nodes/chapters/chapter_rail.tscn` | Rail thưởng DỌC = `ChapterProgress` với `vertical = true` (§12.4c) |
| `scripts/utils/nav.gd` · `scripts/manager/SceneManager.gd` | Route `SCENE_LEVELS`/`goto_levels()` — **không còn** `SCENE_CHAPTERS`/`goto_chapters()` (§12.8) |
| `tools/level_designer/` | Tool Python: menu **Chương** (quản lý chương + gán màn vào chương) — xem 12.7 |
| `scripts/test_case/test_chapters.gd` | **123 check**: dữ liệu chương · gom màn · mở khóa bằng Sao · lưu/tải/xoá tiến trình · khoá theo chương · popup thắng · nối dây (gác luôn “màn Chọn chương đã xoá”) |
| `scripts/test_case/test_chapter_rewards.gd` | **73 check**: thanh tiến độ + 3 rương mốc thưởng của chương (§12.4b) — bản dọc kiểm **rail dọc** (rương xếp từ đáy lên) |
| `scripts/test_case/test_level_screen.gd` | **59 check**: tab chương · sheet khoá · rail dọc · bản đồ rắn · thẻ màn kế (§12.4c) |

### 12.7. Tool Level Designer (Python) — hỗ trợ chương

- `app/models/chapter.py` (`ChapterModel`) · `app/services/chapter_io.py` (đọc/ghi `.tres` **cùng định dạng game**) · `app/models/chapter_repository.py` (`ChapterRepository`).
- Menu **Chương**: *Quản lý chương…* (Ctrl+Shift+C) · *Tạo chương theo dữ liệu màn* · *Gán màn đang mở vào chương…* · *Mở thư mục chapters*; thanh công cụ có nút **Chương…**.
- Hộp thoại quản lý chương (`app/views/chapter_dialog.py`): danh sách chương (số · tiêu đề · phí sao · **danh sách màn**) · sửa tiêu đề/mô tả/nhãn kích thước/phí sao/**icon** (combobox `intro · logic · trap · master`, để trống = game tự chọn) · **Chương mới** · **Tạo chương theo dữ liệu màn** · **Xoá file chương** · gán màn vào chương bằng danh sách (`1, 2, 3`) hoặc nút **Gán MÀN ĐANG MỞ** · **Gợi ý nhãn kích thước theo màn**.
- Danh sách màn ở panel trái hiện thêm cột chương (`#7  C2  5x5  Level 2-7`); màn tạo mới nằm cùng chương với màn đang mở.
- Test: `tools/level_designer/tests/test_chapters.py` + phần **CHƯƠNG** trong `python main.py --selftest` (kiểm tra luôn dữ liệu chương thật của game).

### 12.8. XOÁ màn “CHỌN CHƯƠNG” (v2.49 — 2026-10-23)

Màn Chọn chương ra đời 2026-02 khi chưa có tab chương. Từ v2.47 tab + khung khoá đã làm được **mọi**
việc của màn đó **ngay trong màn Chọn màn** (ở cả 2 hướng), nên màn riêng thành thừa và gây 2 vấn đề:
thêm 1 bước điều hướng cho mỗi lần đổi chương, và 2 màn phải giữ 2 bộ UI song song.

**Đã xoá**

| Loại | File / API |
|---|---|
| Scene + layout | `scenes/chapters.tscn` · `scenes/layout/portrait/chapters.tscn` · `scenes/layout/landscape/chapters.tscn` |
| Script | `scripts/scenes/chapters.gd` (`ChaptersScene`) · `scripts/scenes/layout/chapters_layout.gd` (`ChaptersLayout`) |
| Component thẻ | `nodes/chapters/chapter_card.tscn` · `scripts/nodes/chapters/chapter_card.gd` (`ChapterCard`) |
| Route | `Nav.SCENE_CHAPTERS` + `Nav.goto_chapters()` · `SceneManager.SCENE_CHAPTERS` + `goto_chapters()` · `GameManager.go_to_chapters()` |
| Caller | `GameController` (2 chỗ: hết chương sau khi thắng màn, và Skip khi hết màn) → nay `GameManager.go_to_levels()`; Debug Console bỏ mục **“Select Chapter”** |

**GIỮ LẠI** (màn Chọn màn đang dùng): `nodes/chapters/chest_chip.tscn` · `chest_chip.gd` ·
`chapter_progress.gd` + `chapter_progress.tscn`/`chapter_progress_h.tscn` · `chapter_rail.tscn` ·
`scripts/resources/chapter_data.gd` + `resources/chapters/*.tres` (dữ liệu chương vẫn nguyên).

**Dọn theo (dọn luôn cho sạch, không chỉ xoá file)**

- `LevelsLayout`: bỏ 5 export đã chết `btn_continue` · `lbl_continue` · `lbl_stars` · `lbl_stars_total` ·
  `lbl_change_chapter` (cả 2 bố cục đã chuyển sang `StarsPill` của thẻ chương ⇒ không node nào bind).
  `levels.gd::_refresh_header()` chỉ còn ghi `lbl_chapter`.
- `chapter_rail.tscn` (bản dọc) chỉ còn `bar` + `chips_host` ⇒ test **không** đòi nhãn “x / y SAO” trên
  rail nữa, thay bằng kiểm số Sao trên **thẻ chương** (`card_stars`).
- Thẻ chương ở màn Chọn màn **không còn dây `gui_input`** (test `test_levels_map` gác điều này).
- Test: `test_chapters` **238 → 123 check** (bỏ mục 5 thẻ chương · 6 màn Chọn chương · 7 màn Chọn màn
  bản cũ · 10 vòng Back Chọn màn ⇄ Chọn chương; **thêm 6 check gác “đã xoá sạch”**), `test_splash_title_shop_chapters`
  bỏ khối Chapters, `test_layout_bindings` bỏ màn `chapters` (+ sửa `OPTIONAL` của màn `levels`),
  `test_life_points` đổi mẫu “màn có ví Xu” từ `chapters` sang `levels`, `test_chapter_rewards` bỏ check
  “màn Chọn chương không còn thanh thưởng” (màn không còn tồn tại), `test_ui_scenes`/`dev_aspects` bỏ
  `scenes/chapters.tscn` khỏi danh sách quét.

---

## 13. CỬA HÀNG (SHOP) — TIỆM VĂN PHÒNG PHẨM

### 13.1. Vai trò & lối vào

- Nút **CỬA HÀNG** ở màn Main (`Panel/Other/Shop`) → `main.gd::_on_shop_pressed()` → `Nav.goto_shop()`.
- Cửa hàng bán 4 nhóm: **ngòi bút**, **giấy vở (chủ đề)**, **dụng cụ**, **gói nạp Xu**. Mọi thứ mua bằng **Xu Mực** — dùng CHUNG một ví với Sổ tay thành tựu (`ArchivementManager.coins`), nhờ vậy Xu kiếm được khi chơi/hoàn thành nhiệm vụ đều tiêu được ở đây.
- `ShopManager` là autoload (`project.godot`) + facade tĩnh `Shop` (`scripts/utils/shop.gd`) để test/UI gọi qua `/root` mà không cần identifier autoload.

### 13.2. Bốn ngăn hàng

`ShopManager.CATEGORIES = [pen, theme, tool, coin]`; `EQUIP_CATEGORIES = [pen, theme]` (chỉ 2 nhóm này mới "mặc" được).

| Ngăn (tab) | Số món | Cách bán | Ghi chú |
|---|---|---|---|
| **BÚT & MỰC** (`pen`) | 10 | mở khoá vĩnh viễn | xếp lưới 2 cột, 4 thẻ/trang → 3 trang; chỉ 1 ngòi "đang dùng" |
| **GIẤY VỞ** (`theme`) | 8 | mở khoá vĩnh viễn | xếp lưới 2 cột, 4 thẻ/trang → 2 trang; mỗi chủ đề có `paper` + `line` (bảng màu) |
| **DỤNG CỤ** (`tool`) | 7 | **dùng theo lượt** | mua lại được (cộng dồn), mỗi món có `amount` = số lượt; riêng `life_x1` cộng **LƯỢT CHƠI** (đầy lượt thì không mua được — §5.10b) |
| **NẠP XU** (`coin`) | 6 | IAP (STUB) | hàng VIP “Xoá quảng cáo” trên cùng + 5 gói Xu xếp lưới 2 cột; nút ghi giá **VNĐ**; `bonus` = Xu Mực tặng thêm; mỗi gói 1 **icon cấp Xu** (`coin_t1`→`coin_t5`) |

Danh mục (giá tính bằng Xu Mực, trừ ngăn NẠP XU tính bằng VNĐ):

| id | Tên | Giá | Ghi chú |
|---|---|---|---|
| `pen_blue` | Mực Xanh Học Trò | 0 | **mặc định** (đã có sẵn) |
| `pen_purple` | Mực Tím Hoa Cà | 0 | đã mở khoá sẵn (quà tân thủ) |
| `pen_pencil_2b` | Bút Chì Gỗ 2B | 350 | hiệu ứng sột soạt |
| `pen_red_teacher` | Bút Đỏ Giáo Viên | 500 | nét chấm bài |
| `pen_highlighter` | Bút Dạ Quang | 450 | |
| `pen_gold_ink` | Mực Ánh Kim | 1200 | VIP |
| `pen_green_tea` | Mực Xanh Trà | 400 | |
| `pen_pink_diary` | Mực Hồng Nhật Ký | 380 | |
| `pen_graphite_4b` | Chì Than 4B | 600 | |
| `pen_navy_night` | Mực Đêm Xanh | 800 | |
| `theme_gride_4ly` | Vở Ô Ly 4 Ly | 0 | **mặc định** |
| `theme_blackboard` | Bảng Đen Phấn Trắng | 700 | giấy `#1E293B` · kẻ `#94A3B8` |
| `theme_campus` | Vở Kẻ Ngang Campus | 500 | |
| `theme_bullet` | Bullet Journal | 550 | |
| `theme_tech_grid` | Giấy Kẻ Toán Kỹ Thuật | 800 | |
| `theme_kraft` | Giấy Kraft Cổ Điển | 900 | |
| `theme_pastel_caro` | Caro Pastel Hàn Quốc | 1000 | |
| `theme_exam` | Tờ Giấy Thi Học Trò | 1200 | |
| `life_x1` | Lượt Chơi (x1) | 300 | **+1 LƯỢT CHƠI** (life dùng chung — §5.10b); đầy 5 lượt thì nút ghi `ĐÃ ĐẦY LƯỢT` |
| `tool_undo_x10` | Gôm Tẩy 4B (x10 Lượt) | 150 | hoàn tác không bị tính lỗi |
| `tool_hint_x5` | Kính Lúp Soi Lối (x5) | 200 | |
| `tool_reveal_x3` | Bút Xoá Tường Mờ (x3) | 320 | |
| `tool_time_x3` | Đồng Hồ Cát Lật Nhanh (x3) | 280 | +30 giây |
| `tool_revive_x1` | Kẹp Giấy Giữ Mạng (x1) | 450 | |
| `tool_shield_x2` | Băng Dính Vá Giấy (x2) | 600 | |
| `coin_500` | Túi Xu 500 | 19.000 VNĐ | icon cấp 1 `coin_t1` (xu đơn) |
| `coin_2000` | Rương Xu 2,000 | 69.000 VNĐ | bonus +200 · icon cấp 2 `coin_t2` (cọc xu) |
| `coin_3500` | Hộp Bút Xu 3,500 | 99.000 VNĐ | bonus +500 · icon cấp 3 `coin_t3` (đống xu) |
| `coin_8000` | Cặp Sách Xu 8,000 | 199.000 VNĐ | bonus +1,600 · icon cấp 4 `coin_t4` (túi tiền) |
| `coin_20000` | Kho Xu Khổng Lồ 20,000 | 399.000 VNĐ | bonus +5,000 · icon cấp 5 `coin_t5` (rương vàng) |
| `coin_no_ads` | Gói Xoá Quảng Cáo | 49.000 VNĐ | mua 1 lần, kèm skin bút, nằm RIÊNG 1 HÀNG trên cùng

### 13.3. Trạng thái thẻ & nút

- **Thẻ dọc** (`nodes/shop/item_row.tscn`, 980×180) dùng cho DỤNG CỤ: Badge · Icon · Tên · Mô tả (**2 dòng**, ellipsis) · dòng phụ · nút 270×75.
- **Thẻ ô** (`nodes/shop/item_tile.tscn`, **475×294** — rút gọn chiều cao từ **315 → 294** để cả lưới vừa khung nhìn, giữ đúng tỉ lệ mockup `shopping_pencil.svg`) dùng cho BÚT & MỰC + GIẤY VỞ:
  lề trái màu món · **nhãn góc trên-trái** (bề ngang tự co theo chữ) · **vòng icon** (`IconCircle`, alpha 0.16) + icon + **nét mực vẽ thử** (`ink_stroke`) · tên (24) · mô tả · dòng trạng thái · nút **200×46**.
  Lưới 2 cột × 3 hàng = **6 ô/trang** (10 bút → 2 trang; 8 giấy vở → 2 trang). **Khe lưới: ngang 30 (475×2 + 30 = 980 khít khung) · dọc 24** — cố ý chọn để mọi tab **VỪA khung nhìn 1200px, không cần vuốt dọc** (bàn nháp 215 + khe list 20 + lưới 3×294+2×24 = 1165 ≤ 1200).
- **Thẻ gói nạp** (`nodes/shop/coin_tile.tscn`, **475×240**) dùng cho tab NẠP XU: vòng icon + **icon cấp Xu** (art riêng, không modulate) · tên 24 · mô tả · dòng ưu đãi (hổ phách) · nút giá VNĐ 419×56.
- **Hàng VIP** (`nodes/shop/noads_row.tscn`, **980×200**) cho gói Xoá quảng cáo: nhãn đỏ `chip_red` · tiêu đề 32 · mô tả 17 · nút đỏ 230×80 (mua rồi → `ĐÃ SỞ HỮU` và khoá nút).
- Nút đổi theo trạng thái: **giá Xu** (hổ phách + icon Xu; món VIP dùng nút hổ phách đặc chữ trắng) · **SỬ DỤNG** (đã sở hữu, art TRẮNG + `modulate` màu món hàng) · **ĐANG DÙNG ✓** (đang mặc, nút xanh lá, khoá) · **MUA THÊM N** (dụng cụ) · **giá VNĐ** (gói nạp) · chưa đủ Xu → **nút mờ + note "Chưa đủ Xu Mực"**.
- Dòng phụ: dụng cụ → `Đang có: N lượt`; gói nạp có `bonus > 0` → `Tặng thêm +N xu mực` (không có bonus thì ẩn).

### 13.4. Kinh tế Xu Mực

- Xu vào: thưởng màn chơi + nhiệm vụ trong Sổ tay thành tựu (`claim()`) + gói nạp; Xu ra: mua bút/chủ đề/dụng cụ.
- Ví trên góc phải — dùng **`CoinChip` dùng chung** (`nodes/main/coin_chip.tscn`), không còn `Wallet` riêng của Shop: icon Xu + số (định dạng `1,250`, `Shop.thousands()`) + nút **+** (nhảy sang ngăn NẠP XU nhờ `navigate_on_plus = false`). Xem §4.2.
- Banner chân trang `GÓC TIẾP SỨC HỌC TẬP`: xem bài giảng ngắn mỗi ngày nhận +50 Xu (nút `+50 XU ▶`).
- `purchase_log` ghi lại id đã mua (phục vụ thống kê/test); nút **+** và gói nạp hiện là **STUB IAP** (`purchase_coin_pack`) — khi ghép Google Play Billing thì chỉ cần thay thân hàm này.
- API ví: `coins/can_afford/buy/purchase_coin_pack/is_consumable/use_tool/tool_count/equip/is_owned/is_equipped`.

### 13.5. Chủ đề & ngòi bút: ĐÃ CHUẨN BỊ nhưng CHƯA áp dụng

Theo yêu cầu "chuẩn bị sẵn việc Apply Theme và Pen, chưa cần apply vội":

- `scripts/manager/ThemeManager.gd` (autoload) + facade `scripts/utils/theme_skin.gd` (`class_name ThemeSkin`):
  `sync_from_shop()` · `theme_id()` · `pen_id()` · `pen_color()` · `palette()` (paper/paper_alt/line/margin/ink/ink_soft/accent) · `color(key)` · `apply_theme(id)` · `apply_pen(id)` · signal `skin_changed(theme_id, pen_id)`.
- Công tắc **`apply_enabled := false`** — mọi thứ đã nối (chọn là lưu + phát signal + cập nhật `ThemeManager`), chỉ còn `_apply_now()` là stub TODO: khi bật sẽ đổi nền giấy/đường kẻ/màu mực của màn chơi theo `palette()`.
- LƯU Ý ĐẶT TÊN: ban đầu file facade đặt `class_name Skin` → **trùng class native của Godot** (`Skin`) nên parse lỗi; đã đổi thành `ThemeSkin`.

### 13.6. Giao diện (đo từ scene thật)

`scenes/shop.tscn` (script `scripts/scenes/shop.gd`, `class_name ShopScene extends BaseScene`):

| Thành phần | Vị trí | Ghi chú |
|---|---|---|
| TopBar/Back | (50, 85) 70×70 | `btn_header_back_*` → về Main |
| Eyebrow + Title | giữa, y ≈ 92/119 | "TIỆM VĂN PHÒNG PHẨM" (đỏ) + "CỬA HÀNG" (`STR_SHOP_*`) |
| Ví Xu | (775, 85) 255×70 | icon Xu + số + nút **+** |
| 4 tab nhãn vở | y=185 (tab chọn, 240×65) / y=195 (tab thường, 240×55) | dựng **bằng code** (TextureButton + Label), art `tab_active/tab_inactive`; vạch đáy `TabLine` y=250 |
| Content (cuộn) | (50, 270) 980×**1200** | lưới 2 cột 6 ô/trang (bút/giấy) · thẻ gói nạp 2 cột + hàng VIP trên cùng (nạp xu) · danh sách thẻ dọc (dụng cụ) — **mọi tab vừa khung nhìn**, không cần cuộn (dụng cụ: 6×180+5×20 = 1180) |
| Pager | y ≈ 1500 | "TRANG x / y" + chấm + 2 mũi tên (ẩn khi 1 trang) |
| GiftBanner | (50, 1545) 980×115 | viền đỏ + icon quà + nút `+50 XU` |
| Footer | y ≈ 1710 | câu đề tựa chân trang |

**Vuốt / cuộn** (tự xử lý ở `_input` — nút trên thẻ "ăn" sự kiện kéo nên `ScrollContainer` không tự cuộn được):
vuốt **ngang** → đổi trang (khi tab có >1 trang) · vuốt **dọc** → cuộn danh sách món · chọn trục theo hướng di chuyển đầu tiên
(ngưỡng 14px) · vuốt đủ xa (≥70px) mới đổi trang · sau mỗi lần vuốt **KHOÁ bấm nút 0.35s** (`clicks_locked()`) để không mua nhầm.
**Từ 2026-09-19:** cả 4 tab đều **vừa khung nhìn** nên vuốt dọc không còn cần thiết — handler dọc vẫn giữ làm dự phòng (nội dung ngắn hơn khung thì `scroll_vertical` đứng yên).

Mọi node gốc của scene đều có `index="1".."8"` để node `Popups` của `base.tscn` vẫn nằm TRÊN CÙNG.

### 13.7. Asset · theme · chuỗi dịch

- `assets/images/shop/` (30 SVG): `tab_active`/`tab_inactive` · `card_row` (980×180) · **`card_tile` (475×294 — thẻ ô)** · **`card_coin` (475×240)** · **`card_noads` (980×200)** · `chip_price` · `chip_red` (nhãn đỏ no-ads) · `btn_action_{normal,pressed,amber}` · `btn_equipped` · **`btn_tile_{normal,done,price,price_vip}` (200×46)** · **`btn_coin` (419×56)** · **`btn_noads` (230×80)** · ~~`wallet_chip`~~/~~`btn_plus`~~ (không còn dùng — ví dùng `nodes/main/coin_chip.tscn`) · `banner_gift` · `gift_box` · `icon_box` · **`icon_circle`** · `ink_stroke` · `icon_{pen,ink,paper,coin}` · `icon_tool_{undo,hint,reveal,time,revive,shield}` (art TRẮNG → `modulate`) · **`icon_coin_t1..t5`** (icon cấp Xu: xu đơn · cọc xu · đống xu · túi tiền · rương vàng — lấy từ `mockup/coin_tiers.svg`).
- Theme variations (`theme_default.tres`, nhóm `Shop*`, 27 cái): `ShopTitle` · `ShopEyebrow` · `ShopTabLabel(Active)` · `ShopName(Tile)` · `ShopDesc` · `ShopStock` · `ShopPrice(Amber)` · `ShopBadge(Danger)` · `ShopBonus` · `ShopNoads{Title,Desc,Price}` · `ShopBtnText(Amber/Done)` · `ShopWalletCount/Label` · `ShopBannerTitle/Desc/Btn` · `ShopPageLabel` · `ShopFooter`.
- Chuỗi mới (`string_extra.csv`): `STR_SHOP_TITLE/EYEBROW` · `STR_SHOP_TAB_{PEN,THEME,TOOL,COIN}` · `STR_SHOP_PAGE_FORMAT` · `STR_SHOP_STOCK_FORMAT` + `STR_SHOP_UNIT_{PACK,TURN,COIN}` · `STR_SHOP_BONUS_TAG` · `STR_SHOP_USE` · `STR_SHOP_BUY_MORE` · `STR_SHOP_EQUIPPED` · `STR_SHOP_OWNED_BTN` · `STR_SHOP_NOT_ENOUGH` · `STR_SHOP_PRICE_FORMAT` · `STR_SHOP_BANNER_*` · 23 nhãn `STR_SHOP_BADGE_*` · 60 khoá tên/mô tả món hàng (`STR_SHOP_ITEM_*`, `STR_SHOP_THEME_*`, `STR_SHOP_TOOL_*`, `STR_SHOP_COIN_*`).
- Mockup: `mockup/shopping_pencil.svg` · `shopping_tool.svg` · `shopping_coin.svg` (hàng VIP + lưới 5 gói Xu có icon cấp) · `shopping_theme_page_1/2.svg` (**thẻ ô, 6 thẻ/trang**) · `coin_tiers.svg` (5 cấp icon, số Xu = 500/2,000/3,500/8,000/20,000 khớp gói nạp thật) — **cùng một bộ khung** (status bar · Back (50,85) · eyebrow + CỬA HÀNG · ví 255×70 tại (775,85) · 4 tab nhãn vở với tab đang chọn nổi lên + vạch đáy y=250 · banner (50,1545) · chân trang y≈1710 · thanh gesture home).

### 13.8. File liên quan & kiểm thử

| File | Vai trò |
|---|---|
| `scripts/manager/ShopManager.gd` | Autoload: catalog 30 món · ví Xu (dùng chung Xu Mực) · mua/mặc/dùng · `export/import/reset_progress` |
| `scripts/utils/shop.gd` (`class_name Shop`) | Facade tĩnh: `items/item/buy/equip/use_tool/coins/tool_count/thousands/vnd_text`… |
| `scripts/manager/ThemeManager.gd` + `scripts/utils/theme_skin.gd` (`ThemeSkin`) | Chuẩn bị việc áp chủ đề/ngòi bút (`apply_enabled = false`) |
| `scripts/manager/ArchivementManager.gd` | Thêm `notify_coins_changed()` + `spend_coins(amount)` để ví Xu dùng chung |
| `scripts/manager/SaveManager.gd` | Đăng ký `ShopManager` là provider (autosave khi `item_purchased`) |

### 13.9. Skin ngòi bút (con trỏ + chất liệu nét mực) + Bàn nháp thử bút — 2026-09

**Nguồn sự thật:** `scripts/utils/pen_skins.gd` (`class_name PenSkin`) — bảng `SKINS` map 1-1 mỗi món `category = "pen"` trong ShopManager với
`{ cursor: assets/images/game/player_cursor/*.svg · icon: assets/images/game/pen_type/*.svg · ink: màu mực · style: chất liệu }`:

| Bút | Con trỏ trong game | Hình ngòi bút (shop/thẻ) | Màu mực | Chất liệu nét |
|---|---|---|---|---|
| `pen_blue` (mặc định) | `player_cursor_1` | `pen_fountain_pen_nib` | `#2575A7` | ink |
| `pen_purple` | `player_cursor_7` | `pen_fountain_pen_nib` | `#7C3AED` | ink |
| `pen_pencil_2b` | `player_cursor_2` | `pen_pencil` | `#4B5563` | pencil (nét đứt) |
| `pen_red_teacher` | `player_cursor_3` | `pen_fountain_pen_nib` | `#DC2626` | ink |
| `pen_highlighter` | `player_cursor_4` | `pen_stabilo_highlighter` | `#F59E0B` | highlighter (rộng 1.75× · đầu vuông · alpha thấp) |
| `pen_gold_ink` | `player_cursor_6` | `pen_calligraphy_brush` | `#B45309` | gold (quầng sáng 2.3×) |
| `pen_green_tea` | `player_cursor_8` | `pen_art_brush` | `#15803D` | brush |
| `pen_pink_diary` | `player_cursor_9` | `pen_felt-tip_marker` | `#DB2777` | marker |
| `pen_graphite_4b` | `player_cursor_5` | `pen_drafting_pencil` | `#374151` | graphite (nét đứt + quầng nhẹ) |
| `pen_navy_night` | `player_cursor_10` | `pen_needle_point_gel` | `#1E3A8A` | gel (mảnh 0.85× + quầng nhẹ) |

**Chất liệu** (`PenSkin.STYLES`): `width` (× bề rộng nét gốc) · `alpha` · `cap` · `dash/gap` · `glow_width/glow_alpha`.
Nét đứt = **texture lặp sinh trong code** (`dash_texture_for(period_px, height)`), BẮT BUỘC bật `texture_repeat = ENABLED` trên Line2D
(không bật thì Godot kẹp mép texture → nét gần như vô hình; Line2D cũng KHÔNG sinh UV khi không có texture nên shader-theo-UV không dùng được).
Quầng sáng = Line2D con (`name = "Glow"`, blend CỘNG) nằm dưới nét chính.

**Nối vào game:** `nodes/game/moving_line.tscn` gắn script `scripts/nodes/game/ink_stroke.gd` (`class_name InkStroke`):
`apply_pen(pen_id)` + `set_base_width(w)` + `set_stroke(points)`; `Board.apply_pen_skin()` (gọi trong `setup_maze()` và khi `ThemeManager.skin_changed`)
đổi icon con trỏ (`PlayerCursor.apply_pen`), nét `moving_line`, vệt bút mờ lịch sử (`InkStroke.style_plain`) và vết bước chân theo màu/icon bút.

**Cỡ con trỏ người chơi (2026-09-19):** `nodes/game/player_cursor.tscn` đặt **132×132** — **gấp 3 lần cỡ cũ 44×44** (bằng 3/4 cỡ ô 176 nên nổi rõ giữa ô).
`board.gd` đọc cỡ thật từ scene (`_read_scene_size(PLAYER_CURSOR_SCENE, FALLBACK_CURSOR_SIZE)` với `FALLBACK_CURSOR_SIZE = 132`) rồi co theo `_fit_scale` của board (sàn `MIN_CURSOR_SIZE = 18px`), pivot luôn ở tâm để chạy giữa 2 ô đúng vị trí.

**Bàn nháp thử bút** (mockup `shopping_pencil.svg` khu 5): `nodes/shop/doodle_pad.tscn` + `scripts/nodes/shop/doodle_pad.gd` (`class_name ShopDoodlePad`),
kích thước **980×215**, chỉ hiện ở tab BÚT & MỰC, nằm **TRÊN lưới thẻ**. Vẽ thử bằng ngón tay (mỗi nét là 1 `InkStroke` cùng chất liệu với game),
có nét mẫu tự vẽ khi đổi ngòi, ngòi bút chạy theo tay, thẻ **ĐANG XEM THỬ** (tên bút + icon con trỏ + con dấu `DÙNG THỬ ✓` / `ĐANG DÙNG ✓`).
Chạm vào THÂN thẻ bút → xem thử ngòi đó (nút hành động trên thẻ vẫn là mua/dùng); vùng bàn nháp **chặn cuộn/vuốt trang** (`blocks_scroll_at`).
Thẻ bút trong lưới hiện đúng icon con trỏ của chính nó. Art: `assets/images/shop/doodle_pad.svg` + `doodle_badge.svg` (sinh bằng `tools/mockup/gen_doodle_pad.py`).
Chuỗi mới: `STR_SHOP_TRY_{TITLE,HINT,BADGE,STAMP,USING}`.

**Kiểm thử:** `scripts/test_case/test_pen_skin.gd` (89 check: bảng skin + con trỏ/nét mực thật trong màn chơi theo từng bút) và mục bàn nháp trong `test_shop.gd` (243 check).
| `scripts/nodes/shop/item_row.gd/.tscn` · `item_tile.gd/.tscn` · `coin_tile.gd/.tscn` · `noads_row.gd/.tscn` | 4 loại thẻ: thẻ dọc (dụng cụ) · thẻ ô 475×294 (bút/giấy vở) · thẻ gói nạp 475×240 · hàng VIP 980×200 |
| `scripts/scenes/shop.gd` + `scenes/shop.tscn` | Màn Cửa hàng: dựng 4 tab bằng code, đổi ngăn, phân trang 6 ô/trang, mua/mặc/dùng, **vuốt ngang đổi trang + vuốt dọc cuộn danh sách** |
| `scripts/utils/nav.gd` · `scripts/manager/SceneManager.gd` | `SCENE_SHOP` + `goto_shop()` (Debug Console có mục mở Cửa hàng) |
| `scripts/test_case/test_shop.gd` | **247 check**: catalog (đủ 30 món, giá, icon, khoá dịch) · ví Xu · dụng cụ (cộng dồn lượt) · trang bị bút/chủ đề (`ThemeSkin`) · lưu/tải/xoá · scene (4 tab, thẻ ô 475×294 + nút 200×46, hàng VIP no-ads trên cùng, icon cấp Xu của từng gói, mua thật qua nút thẻ) · **mọi tab vừa khung nhìn — không cần cuộn · vuốt ngang đổi trang · không mua nhầm khi vừa vuốt** · nối dây điều hướng |

---

### 13.10. Hỗ trợ MỌI TỈ LỆ MÀN HÌNH — portrait & landscape (2026-09-19)

**Yêu cầu:** app chạy chuẩn ở mọi tỉ lệ điện thoại/máy tính bảng — 9:16 · 9:18 · 9:19.5 · 9:21 · 3:4 · 4:3 · 16:9 · 18:9 · 19.5:9 (CẢ dọc lẫn ngang).

**Cơ chế — 1 chỗ duy nhất, mọi màn tự hưởng** (`scripts/scenes/base.gd`, root của `scenes/base.tscn` — mọi màn hình đều instance base):
- Giữ `stretch/mode = "canvas_items"` + `stretch/aspect = "expand"` (canvas giãn theo màn hình).
- Root Control tự co thành **CỘT NỘI DUNG 1080px CANH GIỮA**: `size = (1080, canvas_height)`, `position.x = (canvas_width − 1080) / 2`.
  · Màn DỌC cao (9:18 → 9:21): cột đúng bề rộng thiết kế, giãn DỌC (phần tử neo đáy bám đáy màn hình).
  · Màn RỘNG hơn 9:16 (3:4 · 4:3 · 16:9 · 18:9… kể cả LANDSCAPE): nội dung nằm gọn trong cột giữa — **không bị kéo giãn ngang, không lệch vị trí**.
- `Background` (index 0, nằm DƯỚI mọi nội dung) giữ đúng cột (lề đỏ ở lề cột) + 2 dải `SideL`/`SideR` con của Background tô màu giấy `#FAF5EB` phủ hai bên → nhìn như trang vở trải rộng, **không có thanh đen letterbox**.
- Đặt trong `_enter_tree()` + `_notification(READY/RESIZED)` + `viewport.size_changed` — vì mọi màn con override `_ready()` (không gọi super) nên `_ready` của BaseScene không chạy.
- Popup (`scripts/nodes/popups/base.gd`): thẻ popup canh giữa theo cột, `Dim` phủ **toàn màn hình** (cả 2 bên cột); tính lại khi mở popup/đổi cỡ.
- Android: `display/window/handheld/orientation = 6` (**Sensor** — xoay tự do 2 chiều).

**Đổi cả mockup HUD Time Attack theo tỉ lệ:** thẻ THỜI GIAN của `time_attack_hud.tscn` dùng **anchors tỉ lệ** (0.352..0.648 × 0.085..0.911 của khung 980×249 ≈ 291×206, canh giữa) + số `resize_font_to_fit`; mockup `matchup_time_attack.svg` sinh lại tương ứng.

**Công cụ kiểm thử (Windows/Android, cần render thật):**
```bash
godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_aspects.gd
# tuỳ chọn: --shots=1  --only=main,game  --sizes=1920x1080  --modes=play
```
- Quét **10 tỉ lệ × (12 màn + 9 chế độ game + popup pause)** = 220 lượt kiểm tra: cột canh giữa · nền giấy phủ kín · KHÔNG node nào tràn màn hình · board/HUD/thanh nút trong cột · popup Dim phủ canvas & thẻ giữa tâm. **Kết quả 220/220 PASS.**
- `--shots=1` lưu PNG nửa phân giải vào `tmp_aspect/<WxH>/<id>.png` để soi bằng mắt.

**Bug thật phát hiện khi quét (đã sửa):** `nodes/daily/calendar.tscn` — hàng thứ `DayTitle` để `offset_right = 1366` (lệch **380px** so với lưới ngày `Days` 76..986) → 7 nhãn T2..CN bị lệch khỏi cột ngày và nhãn CN **tràn ra ngoài màn hình 1080** ở MỌI tỉ lệ (lỗi có sẵn từ trước). Sửa `offset_right = 986` = khớp đúng 7 cột × 130px của lưới ngày.

**Kiểm chứng trên MÁY ẢO ANDROID THẬT** (tablet `Medium_Tablet_API_28`, 2560×1600 dpi 320 — APK debug ~422MB):
```bash
emulator -avd Medium_Tablet_API_28 -no-snapshot-load -no-snapshot-save -no-boot-anim \
         -gpu host -feature GLESDynamicVersion -memory 4096
adb install -r -d build/inkmaze_tablet_debug.apk
adb shell settings put secure immersive_mode_confirmations confirmed   # bỏ overlay "GOT IT"
adb shell monkey -p com.invisiblegear.inkmaze -c android.intent.category.LAUNCHER 1
```
- **`-gpu host` là bắt buộc trên máy này:** `swiftshader_indirect` + `GLESDynamicVersion` cho app khởi động nhưng **SIGSEGV ngay trong GLThread** (crash render của SwiftShader → màn hình xám). Thiếu `GLESDynamicVersion` thì guest chỉ có ES 2.0 → `eglCreateContext EGL_BAD_CONFIG: no ES 3 support`. Dùng `-gpu host` (thẳng NVIDIA RTX 3060, GLES 3.0 trên driver 4.5 + Vulkan 1.3) → chạy ổn định, không crash.
- Ảnh chụp máy ảo (lưu ngoài project `d:\godot-phone-game\inkmaze_shots_android\`): splash · main · game (Play) · popup Tạm dừng · Cài đặt — **mỗi màn ở CẢ landscape 2560×1600 lẫn portrait 1600×2560**: cột 1080 canh giữa, 2 dải giấy `#FAF5EB` hai bên, xoay máy reflow tức thì, Dim popup phủ kín toàn màn hình.

---

### 13.11. Sửa lỗi LỆCH HƯỚNG CỬA SỔ ↔ MÀN HÌNH trên Android (2026-09-19)

**Triệu chứng user báo (chơi trên máy ảo tablet):**
- Đâm vào tường → ván kết thúc nhưng **popup Game Over không hiện**, không đi tiếp được (thực chất popup đang nằm NGOÀI vùng nhìn thấy, lớp Dim vẫn chặn input).
- Popup "Phiếu thông qua tầng" (Dungeon) hiển thị **lệch/trôi**, mép phải giao diện bị cắt.
- **Màn hình loading bị lỗi** (không phủ đúng).

**Nguyên nhân gốc (đo được bằng log tạm in lên màn hình):** app có thể giữ cửa sổ ở **hướng cũ trong khi màn hình đã xoay hướng khác** —
`window_get_size()=(2560,1600)` (ngang) nhưng màn hình đang `1600×2560` (dọc) ⇒ canvas = **3072×1920 ngang** trong khi vùng nhìn thấy chỉ là 1600×2560 ⇒
- nội dung vẽ tràn ra ngoài mép phải (thấy đúng như ảnh user chụp: hộp stats thứ 3 và nút cuối bị cắt),
- popup canh giữa canvas 3072 ⇒ tâm popup nằm ngoài màn hình ⇒ "không thấy popup",
- lớp loading (CanvasLayer full-rect) cũng vẽ theo canvas sai ⇒ "màn loading lỗi".

Hoàn cảnh gây lệch: xoay màn hình bằng **khoá xoay / `settings put user_rotation`** (cảm biến không đổi nên app kiểu Sensor không tự xoay theo), hoặc mở app lúc máy đang xoay.

**Cách sửa (tự chữa, không cần người dùng làm gì):**
- `scripts/manager/AppManager.gd` → `sync_window_orientation()`: watchdog 0,5s — nếu `window_get_size()` **khác hướng** `screen_get_size()` (một bên ngang, một bên dọc) thì gọi `DisplayServer.window_set_size(screen_size)` để cửa sổ khớp màn hình thật.
  (Chỉ chạy khi `OS.has_feature("mobile")` — desktop không bị ảnh hưởng.)
- `scripts/manager/PopupManager.gd` → `get_host()` **không dùng lại host đã cache nếu host không còn thuộc scene hiện tại** (scene vừa đổi ⇒ host cũ sắp bị xoá ⇒ popup sẽ nằm trong scene chết và người chơi không thấy gì).
- `scripts/scenes/base.gd`: `_enter_tree()` gọi `set_anchors_preset(PRESET_TOP_LEFT, true)` để Root tự quản size/position (hết cảnh báo "non-equal opposite anchors").

**Kiểm chứng trên máy ảo:** đặt màn hình dọc rồi mở app ⇒ app tự về dọc (canvas 1200×1920, cột canh giữa 60), mọi màn/popup hiển thị đủ, không còn cắt mép; xoay ngang ⇄ dọc nhiều lần popup vẫn đúng tâm.

### 13.12. Hotfix 7 lỗi layout khi test trên máy ảo ĐIỆN THOẠI 1080×2424 (Pixel_9_API_35) — 2026-09-17

Bối cảnh: các màn được thiết kế cho canvas **1080×1920**; trên máy ảo điện thoại canvas cao **2424** nên mọi khối neo theo OFFSET
thiết kế bị trôi/lệch, còn khối neo theo TỈ LỆ thì giãn đúng. Danh sách user gửi (`hotfix/need_to_fix.txt` + 5 ảnh):

**1. Popup "Game Over" NHÁY HIỆN RỒI BIẾN MẤT (Ảnh 1)** — thủ phạm là **đua tween + mở trùng id**, không phải lỗi vẽ:
`UıController.show_game_over()` gọi `Popups.close_all()` rồi mở lại **cùng id** ngay khi tween đóng của popup cũ còn chạy;
callback `_finish_close()` của tween cũ chạy sau đó và **xoá popup vừa mở**. Ngoài ra `GameController._game_over()` bị gọi
2 lần trong cùng khung hình (đâm tường + hết giờ). Sửa:
- `scripts/nodes/popups/base.gd`: giữ `_tween`, thêm `_kill_tween()` huỷ tween cũ trước khi chạy hiệu ứng mới;
  `close()` chặn đóng trùng (`if _closing: return`); `_finish_close()` chỉ giải phóng khi **vẫn đang đóng**
  (`if not _closing: return`) ⇒ mở lại giữa lúc đang đóng thì popup mới không bị xoá oan.
- `scripts/core/controllers/game_controller.gd`: `_game_over()` mở đầu bằng `if not _run_active: return`.
- Kiểm chứng: `dev_popup_repro.gd` thêm ca *"gọi 2 lần liên tiếp"* + *"mở lại giữa lúc đang đóng"* → **4 PASS · 0 FAIL**;
  trên emulator: kéo vào tường vô hình ⇒ popup "ĐÂM VÀO TƯỜNG VÔ HÌNH!" vẫn hiện ổn định, bấm được nút.

**2. Lưới ô bị đẩy LÊN, không giữa thẻ bàn (Ảnh 2):** `BoardView._panel_insets` lưu insets của ảnh `card_board.svg`
theo PIXEL nhưng được dùng như đơn vị panel-local; panel cao 1288 (màn 2424) ⇒ vùng lưới tính thiếu ⇒ tâm lưới lệch lên ~160px.
Sửa: insets đổi sang **TỈ LỆ 0..1**, `panel_inner_rect()` nhân với `panel.size` ⇒ tâm lưới = tâm panel (đo lại: 623,7 = 623,7).

**3. HUD lệch lên trên:** gốc `Hud` neo offset thiết kế (y=175) nên trên màn cao dính sát status bar.
Sửa `nodes/hud/base.tscn`: `anchor_top = anchor_bottom = 0.072` + offset giữ **37px** khoảng cách dưới status bar ở mọi tỉ lệ.

**4. Popup không ở giữa:** `BasePopup._apply_canvas_layout()` chỉ canh giữa NGANG (theo cột nội dung), chiều dọc vẫn theo
offset thiết kế ⇒ màn 2424 thẻ nằm cao hơn tâm 262px. Sửa: canh giữa **cả hai chiều** theo canvas (`Dim` vẫn phủ kín canvas).

**5. Text nút công cụ "Vẽ đường" / "Ghi nhớ" dùng STR_ID + có dòng phụ:** `scenes/game.tscn` chuyển `Button/Tool` →
`STR_TOOL_DRAW_PATH`, `Button/Wall` → `STR_TOOL_MARK_WALL`, thêm node `Sub` (`STR_TOOL_DRAW_PATH_DESC` /
`STR_TOOL_MARK_WALL_DESC`, alpha 0.72) + LabelSettings mới `resources/settings/text/text_game_button_sub.tres`
(BeVietnamPro-Black 22). Nhãn chính canh giữa, dòng phụ nằm dưới.

**6. Màn DAILY: Mission lệch & ĐÈ LÊN NHAU (Ảnh 4):** `Calendar` bị anchor giãn thành 1275px (đè 350px lên `Missions`)
và để lại 692px trống dưới trên màn dọc. Sửa `scenes/daily.tscn`: Calendar cao **cố định 1010**, `Missions` đặt
`expand_mode = 1` (ảnh 1020×592 trước đây CHẶN không cho node co nhỏ — đúng bẫy "TextureRect clamp size").
`scripts/scenes/daily.gd::_layout_responsive()` (chạy khi READY/RESIZED + `size_changed`): nút CHƠI neo đáy 60px;
`Missions` nằm giữa Calendar và nút CHƠI (cách 24px); hàng nhiệm vụ co lại khi màn thấp, giãn nhẹ (≤1.35×) khi màn cao;
hàng tiến độ dời theo chiều cao panel. Đo lại: dọc 1080×2424 Missions 1251..2220 (nút CHƠI 2243), ngang 2400×1080 Missions cao 520.

**7. Màn SHOP: khoảng trống dưới + phân trang theo màn (Ảnh 5):**
- `scenes/shop.tscn`: `Content` (ScrollContainer) kéo tới **đáy canvas**; `Pager`, banner "NHẬN XU MIỄN PHÍ", `Footer`
  neo vào đáy (banner luôn nằm CUỐI như user yêu cầu).
- `scripts/scenes/shop.gd`: số ô mỗi trang **tính từ chiều cao thật của khung cuộn** (`_grid_per_page()`:
  trừ `doodle_pad` khi ở tab BÚT & MỰC, `rows = floor((cao + SEP) / (ô + SEP))`, ×2 cột) ⇒ 10 cây bút vừa **8 ô/trang, 2 trang**
  trên điện thoại, 6 ô/trang trên màn ngang — không sinh trang thừa.
  Khi xoay màn hình: `_on_viewport_resized()` → `_refresh_pagination_if_needed()` dựng lại lưới nhưng **giữ trang theo item
  đang xem** (`_page_first_id`).

**8. Công cụ & kiểm thử:** thêm `scripts/test_case/dev_back_probe.gd` (kiểm tra Back/Esc với popup);
`dev_aspects.gd` nay gán `current_scene` khi thêm scene vào cây — vì `PopupManager.get_host()` tìm host theo `current_scene`,
nếu không gán thì popup rơi vào host tạm ngoài scene và 10 check "bấm pause không mở được popup" FAIL **oan**.
Kết quả sau sửa: **29/29 suite PASS** · harness tỉ lệ **220/220 PASS** · APK debug build lại và xác nhận trên Pixel_9_API_35
(grid giữa thẻ, HUD đúng, nút có dòng phụ, popup Game Over giữ nguyên, Daily không đè, Shop hết khoảng trống + banner cuối trang).

**9. Ghi nhận còn lại (chưa sửa, chờ quyết định):**
- ~~Nút **Back trên Android đang thoát app** khi màn chơi đang mở popup~~ → **ĐÃ SỬA 2026-10-14** (§13.25 mục 5:
  `quit_on_go_back=false` + `ScreenManager` bắt `NOTIFICATION_WM_GO_BACK_REQUEST`; popup đang mở thì Back đóng popup).
- Màn chính còn khoảng trống dưới thanh điều hướng trên màn dọc cao (nav ở y≈1800 trong canvas 2424).
- Còn `print()` debug của user: `Close Popup …`, `Show Game Over because …`, `GAME_OVER because …`.

### 13.13. Shop: TAB & THẺ Ô cao ×1,5 và TỰ CO GIÃN theo màn hình (2026-09-17)

Yêu cầu user: "Tăng chiều cao của Tab lên 1.5 lần để người dùng dễ chọn, và cho nó tự resize chiều cao dựa vào
kích cỡ màn hình hiện tại" + (vòng sau) "chỉnh lại Card ... thành 1.25 thôi, và thay vì chỉnh code cứng kích cỡ
của Card Item vào bên trong script, tôi muốn lấy từ Layout của card item".

**Hệ số co giãn dùng chung** (`ShopScene.screen_scale()`): `clampf(cao_canvas / 1920, 0.85, 1.5)` —
màn dọc siêu cao (điện thoại 1080×2424 → 1,26) thì tab/thẻ cao hơn, màn ngang thấp thì nhỏ nhất còn 0,85.

**Tab** (`_apply_tab_metrics()`):
- Art viết lại cao gấp 1,5: `tab_active.svg` **240×98** (65×1,5 — tab đang chọn, nhô lên) và
  `tab_inactive.svg` **240×83** (55×1,5 — tab chưa chọn). Script **đọc thẳng chiều cao từ art** rồi nhân hệ số
  màn hình (§13.14) nên muốn đổi cỡ tab chỉ cần sửa file SVG. `stretch_mode = STRETCH_SCALE` để art lấp đầy node
  (art không còn cùng tỉ lệ với node khi màn hình đổi chiều cao).
- Hàng tab: đỉnh **172** (trước 185) để hàng cao thêm 30px **không lấn vùng danh sách**; tab đang chọn cao
  hết hàng (`tab_height()` = 98 × hệ số), tab chưa chọn thấp hơn và canh **ĐÁY** hàng (`SIZE_SHRINK_END`);
  chữ của MỌI tab cùng một đường ngang (theo tâm tab đang chọn); `TabLine` chạy theo đáy hàng; `Content.offset_top`
  = đáy hàng + 8. Kết quả: vùng danh sách ở canvas 1920 vẫn cao **1192** → tab DỤNG CỤ (6 hàng = 1180) vẫn vừa khung.

**Thẻ ô Bút & Mực / Giấy vở** (`tile_size()` — cỡ lấy từ LAYOUT của `nodes/shop/item_tile.tscn`):
- Cao = `cỡ thiết kế (294) × TILE_SCALE (1,25) × hệ số màn hình` → canvas 1920: **368**; điện thoại 1080×2424: **464**;
  rộng giữ đúng cỡ thiết kế trong scene (475) để 2 cột vẫn vừa cột nội dung 980.
- Các khối BÊN TRONG thẻ dùng **ANCHORS trong scene** (không dàn bằng code nữa):
  `Bg` full-rect · `Bar` neo 2 đầu (cách mép trên/dưới 18) · cụm icon neo theo TỈ LỆ chiều cao
  (IconCircle 29,93% · Icon 29,25% · Stroke 46,94%) · Name/Desc/Note/Action/ActionLabel/CoinIcon **neo ĐÁY**
  (cách đáy cố định). Nhờ vậy muốn đổi cỡ thẻ hay vị trí khối chỉ cần sửa/ kéo trực tiếp trong Editor.
- Số món/trang vẫn suy từ chiều cao thật của khung cuộn (`_grid_per_page()`), nên thẻ cao lên thì ít hàng hơn:
  điện thoại 1080×2424 → **4 thẻ/trang** (10 bút = 3 trang), canvas 1920 → 4 thẻ/trang, màn ngang thấp → 2 thẻ/trang
  (khi đó lưới được phép cuộn dọc — kiểm tra "vừa khung nhìn" trong test đã nới đúng trường hợp 1 hàng tối thiểu).
- Xoay màn hình: `_on_viewport_resized()` → `_apply_tab_metrics()` + `_apply_card_metrics()` + phân trang lại,
  vẫn **giữ trang theo món đang xem** (`_page_first_id`).

### 13.14. Quy ước: CỠ & BỐ CỤC LẤY TỪ LAYOUT (scene/art) — không hard-code trong script (2026-09-17)

Yêu cầu user: *"thay vì chỉnh code cứng kích cỡ ... vào bên trong script, tôi muốn bạn lấy từ Layout ... để tôi có thể
dễ dàng edit/chỉnh lại size tôi muốn. Làm như thế đối với các node đang sử dụng code cứng làm size mà không sử dụng
transform"*. Quy ước áp dụng từ đây:

| Nơi | Cỡ lấy từ | Script chỉ làm gì |
|---|---|---|
| Tab shop (BÚT & MỰC / GIẤY VỞ / DỤNG CỤ / NẠP XẠ) | **ART**: `tab_active.svg` 240×98 · `tab_inactive.svg` 240×83 | `tab_height()` = cao art × hệ số màn hình; hàng tab/vạch kẻ/khe danh sách đọc từ `shop.tscn` (`_capture_tab_layout`) |
| Thẻ ô shop | **LAYOUT**: `nodes/shop/item_tile.tscn` (475×294) + anchors của các khối con | `tile_size()` = cỡ scene × `TILE_SCALE` (1,25) × hệ số màn hình; chỉ đặt `custom_minimum_size` cho thẻ |
| Bàn nháp thử bút | `nodes/shop/doodle_pad.tscn` | đọc cỡ để tính số hàng vừa khung |
| Bảng nhiệm vụ Daily | `scenes/daily.tscn` (Missions 1020×592 · Rows đầu 112 · ProgressLabel 528 · Play cách đáy 60) + `mission_row.tscn` (110) | `_capture_design()` đọc 1 lần lúc mở màn; script chỉ co/giãn theo màn hình (`MIN_ROW_FACTOR` 0,7 · `MAX_ROW_FACTOR` 1,35 là CHÍNH SÁCH co giãn) |
| Khối HUD (3 sheet) | art riêng `card_*_block_*.svg` + rect của node trong `*_hud.tscn` (§10.2b) | — (không code) |

Nguyên tắc: **art/scene là nguồn số thật**, script chỉ giữ (a) hệ số phóng to theo màn hình, (b) chính sách khe/độ co
giãn tối thiểu–tối đa, (c) tính số món mỗi trang. Kiểm thử cũng đọc lại từ scene (`test_shop.gd`:
`tile_design_size() == (475, 294)` · `tab_height()` = 98 × hệ số · số món/trang động).


### 13.15. Quy ước: MỌI NODE UI PHẢI CÓ SCENE + SCRIPT — script chỉ instantiate (2026-09-17)

Yêu cầu user: *"tránh trường hợp tạo ra scene trong quá trình khởi động mà không có tscn/script tương ứng (VD: tạo cell
trong khởi động là được, nhưng tạo tab mà không có scene, chỉ có đoạn script added node vào bên trong control thì không
được). Đối với trường hợp đó, bạn hãy tạo ra một scene và script của nó và rồi trong script mới khai khởi tạo nó."*
Từ đây, node UI nào xuất hiện lúc chạy cũng phải có `.tscn` riêng + script của nó; script màn chỉ làm 3 việc:
`instantiate()` → `add_child()` → `setup()`.

| Màn / khối | Scene con (mỗi scene 1 script `class_name`) | Script giữ gì |
|---|---|---|
| Cửa hàng | `nodes/shop/{tab_button,item_grid,page_dot}.tscn` | `ShopTabButton` (art 240×98 · `apply_row_layout` canh đáy) · `ShopItemGrid` (2 cột · khe 30/24) · `ShopPageDot` (34×24 / 12×24) |
| Sổ tay | `nodes/archivements/{tab_button,page,page_dot}.tscn` | `AchTabButton` (134×46) · `AchPage` (cột `Column` · khe 20) · `AchPageDot` |
| Chọn màn | `nodes/level_selection/{page,page_dot}.tscn` | `LevelsPage` (lưới 3 cột · khe 46/24 · gốc 10.08/11.04) · `LevelsPageDot` |
| Xếp hạng | `nodes/ranking/tab_button.tscn` | `RankTabButton` (cao 52 theo scene · bề rộng riêng từng bảng) |
| Popup | `nodes/popups/{host,language_row}.tscn` | `PopupHost` (lớp phủ dự phòng) · `LanguageRow` (cờ · tên · phụ đề · dấu tích) |
| Bàn mê cung | `nodes/game/{board_layers,ink_footstep}.tscn` | `BoardLayers` (5 lớp vẽ Cells→Lines→Walls→Anchors→Markers) · `InkFootstep` (vệt mực bước chân) |
| HUD đếm ngược | `nodes/hud/countdown_segment.tscn` | `CountdownSegment` (`set_width` · `set_used`) — art xám/cam nằm trong scene |

Nhờ vậy cỡ/khe/art của từng khối nhỏ (tab · chấm trang · hàng ngôn ngữ · vạch ngân sách · lớp vẽ…) sửa được **ngay
trong scene**, không phải lần theo script. `scripts/test_case/test_ui_scenes.gd` (50 check) kiểm cả hai mặt: dựng từng
scene để xác nhận cấu trúc con (`Column`/`Grid`/`Label`…) và **quét mã nguồn** `scripts/scenes` + `scripts/nodes` để
chặn `.new()` cho lớp UI về sau (ngoại lệ duy nhất: `scripts/scenes/debug.gd` — màn debug dev-only).

**Bẫy đã dính khi viết `.tscn` bằng tay**: node con của root phải ghi `parent="."`; thiếu nó scene vẫn *load* nhưng con
không được gắn → `$Grid`/`$Column` trả về `null` (test Sổ tay/Chọn màn FAIL oan). Và `@onready` chỉ có sau khi node
vào cây → luôn `add_child()` trước rồi mới gọi `setup()`.


### 13.16. Fog of War: 3 LƯỢT THỬ LẠI + HUD "BẢNG SƯƠNG MÙ" (2026-09-18)

Luật mới (user yêu cầu): đâm tường vô hình **không** thua ngay — mỗi lần đâm bị đưa về ô S và **trừ 1 LƯỢT THỬ LẠI**;
hết 3 lượt là thua. **Hồi sinh** (xem quảng cáo) cộng thêm **1 lượt thử** rồi chơi tiếp.

| Nơi | Thay đổi |
|---|---|
| `BaseGameMode` | `max_retries` · `retries_left` · `uses_retries()` · `reset_retries()` · `register_hazard()` (true = hết lượt → thua) · `on_revive()` (+1 lượt) · hook `on_respawned()` |
| `FogOfWarGameMode` | `RETRY_LIVES = 3`; bỏ thua-ngay khi đâm tường; sương mù mở lại quanh ô S sau mỗi lần hồi sinh/đâm tường |
| `GridController` / `GameController` | gọi `register_hazard()` + `on_respawned()`; dữ liệu popup thua thêm `max_retries`/`retries_left`; nút HỒI SINH đổi mô tả sang `STR_REVIVE_DESC_RETRY` |
| HUD | `nodes/hud/fog_of_war_hud.tscn` (`FogOfWarHUD`): THỜI GIAN 250×156 + BẢNG SƯƠNG MÙ 690×156 (lượt thử "n/3" · tầm nhìn bán kính 1 ô · 2 dòng cảnh báo) — KHÔNG có thẻ THỬ THÁCH |
| Nút công cụ | nhãn phụ đổi theo chế độ (`GameScene.TOOL_SUB_KEYS`): Fog of War → "Dò trong sương" / "Cắm cờ mép ô" |

Kiểm chứng: `test_fog_of_war.gd` **28/28** · `test_hud_modes` §4c (HUD fog) · harness tỉ lệ OK ở cả 10 cỡ màn hình
(ảnh render `tmp_aspect/<size>/game_fog_of_war.png`).

---

### 13.17. Hai bộ luật mới: One Stroke & Wall Builder (2026-09-18) — ĐẶC TẢ, chưa lập trình

Yêu cầu user:
> *"Ở Mode 1, Cell không cần hiển thị số nữa, nhưng vẫn hiện ra tường. Nhiệm vụ của người chơi là phải đi hết tất cả các cell
> mới đến đích, và không được đi vào đường đã đi rồi."*
> *"Ở Mode 2, sẽ không có di chuyển đường đi từ nơi Start đến nơi Finish nữa, mà nhiệm vụ hiện tại là vẽ ra tường dựa vào
> số trên ô Grid. Trò chơi sẽ cho người chơi biết cần tạo bao nhiêu tường, và người chơi phải nối vào tường. Sau khi đã nối
> xong, thì ấn gửi. Nếu thành công thì trò chơi kết thúc. Nếu thất bại thì sẽ mất một lượt — chỉ có 3 lượt chơi."*

**Tên gọi đã chọn** (ngắn, theo đúng lối đặt tên hiện có: EN 2 từ · VI 2 từ):

| # | `mode_id` | EN | VI | Vì sao chọn | Phương án khác |
|---|---|---|---|---|---|
| 1 | `one_stroke` | **One Stroke** | **MỘT NÉT** | Đúng bản chất "vẽ 1 nét đi hết bàn, không nhấc bút, không quay lại" (đường Hamilton) và khớp chủ đề bút – vở của game | Full Page · KÍN TRANG · Cover All · PHỦ KÍN |
| 2 | `wall_builder` | **Wall Builder** | **XÂY TƯỜNG** | Người chơi đóng vai "thợ xây": đọc số trên ô để dựng đủ tường rồi nộp bài | Bricklayer · THỢ XÂY · Draw the Walls · ĐẮP TƯỜNG |

**Đã cập nhật trong tài liệu:** §1 (11 bộ luật) · §2 (quy ước số/tường) · §3.1 (thêm thử thách `no_wrong_submit`, 17 loại) ·
§4 (9 bộ luật Daily) · bảng tổng quan mục 5 (2 dòng mới) · §5.10 (hàng "chế độ có LƯỢT THỬ" trong quy ước hồi sinh) ·
§6 (vòng xoay **9 ngày** + cảnh báo hồi quy ngày → luật) · §9.1 (9 chế độ Special) · §10.1 (bảng HUD + mockup cần vẽ) ·
§10.2d (2 popup hướng dẫn mới) · §10.3 (ghi chú tool mockup).

**Chưa lập trình (việc cần làm khi triển khai):**

1. ~~`scripts/modes/one_stroke_game_mode.gd`~~ **XONG 2026-09-19 (§13.18)** · ~~`wall_builder_game_mode.gd`~~ **XONG 2026-09-19 (§13.19)**.
2. Bộ sinh bàn: ~~**Hamilton generator** cho One Stroke~~ **XONG**; ~~mode Wall Builder~~ **XONG** (bàn tường ẩn + loại bàn quá dễ);
   còn **solver đếm nghiệm** để ưu tiên bàn ≥ 2 nghiệm.
3. HUD: ~~`nodes/hud/one_stroke_hud.tscn` + `nodes/hud/wall_builder_hud.tscn`~~ **XONG 2026-09-19** (kèm art `card_stroke_*.svg` / `card_wall_*.svg`).
4. Thanh công cụ: ~~nhãn phụ theo chế độ + ẩn nút GHI NHỚ cho One Stroke~~ **XONG**; ~~nút GỬI cho Wall Builder~~ **XONG**
   (`GameScene.TOOL_FULL_KEYS` + `_on_secondary_tool_pressed`).
5. Localization: ~~`STR_MODE_ONE_STROKE` · `STR_HINT_ONE_STROKE` · `STR_HUD_OS_*` · `STR_GAME_OVER_REVISIT`~~ **XONG**;
   ~~`STR_REVIVE_DESC_SUBMIT` · `STR_HUD_WB_*` · `STR_GAME_OVER_OUT_OF_SUBMITS`~~ **XONG**; còn `STR_CHALLENGE_NO_WRONG_SUBMIT`
   (chỉ cần khi gắn thử thách riêng cho Wall Builder).
6. Mockup: ~~`matchup_one_stroke.svg` · `nodes/popups/instruction/one_stroke.tscn`~~ **XONG**;
   ~~`matchup_wall_builder.svg` + `wallbuilder.tscn`~~ **XONG 2026-09-19** (`wall_builder.tscn`).
7. `GameManager.DAILY_MODES` thêm 2 id (**nhớ cập nhật test ngày→luật** — bộ 7 cũ đổi nghĩa, xem §6).
   *Cả 2 mode hiện vào được qua Debug Console (SPECIAL MODES) / `GameScene.switch_mode(...)`; chưa gắn vào vòng xoay Daily.*

---

### 13.18. One Stroke đã lập trình xong (2026-09-19) — mode + HUD + popup hướng dẫn

**Bối cảnh:** user gửi 7 SVG (1 mockup mode `matchup_one_stroke.svg` + 3 mockup popup hướng dẫn + 3 ảnh guideline) và yêu cầu
*"apply One Stroke và Instruction của nó"*. Đối chiếu mockup cho thấy **2 luật của bản đặc tả §5.12 cũ chưa đúng** nên đã sửa lại (xem dưới).

**Luật đã chốt lại theo mockup (khác §13.17):**

| Điểm | Bản cũ (§13.17) | Bản chốt theo mockup |
|---|---|---|
| Bước vào ô đã đi | bị **chặn**, không mất bước | **THUA NGAY** (`GAME OVER`) — ô cũ là tử huyệt |
| Bàn cờ | 3×3 / 4×4 / 5×5 | **3×3 / 5×5 / 7×7** (chỉ bàn **lẻ ô** để có đường Hamilton S=(0,0)→F=(n-1,n-1)) |
| Chạm F sớm | bị chặn | vẫn **bị chặn** (không thua) + hiện chữ nổi `CÒN n Ô CHƯA ĐI!` |
| Hết đường | popup `HẾT ĐƯỜNG ĐI!` | giữ nguyên (`is_dead_end`, coi F như tường) |
| Tiêu đề thua mới | — | `ĐI LẠI Ô CŨ!` (`STR_GAME_OVER_REVISIT`, lý do `revisit`) |

**Đã làm:**

1. **Mode** `scripts/modes/one_stroke_game_mode.gd` (`OneStrokeGameMode`): sinh bàn **đường rắn phủ kín** rồi rải tường ngẫu nhiên
   **không cắt đường mẫu** (18/34/50% theo độ khó) + `reveal_wall()` cho hiện rõ 100%; `get_cell_text()` không số; `evaluate_move()`
   chặn F sớm / hazard `revisit`; `is_dead_end()` (bỏ F khỏi vùng ô trống rồi kiểm tra liên thông); `on_move_undone()` mở lại ô;
   `hint_next_cell()` (đường mẫu, hoặc DFS cắt tỉa 60k nút); `on_move_blocked()` hiện cảnh báo F bị chặn.
2. **Hạ tầng dùng chung:** `BaseGameMode.on_move_blocked()` + `hint_next_cell()` (mặc định `(-1,-1)`); `GridController`
   ưu tiên hint của mode, **không vẽ đoạn tường gãy** khi hazard là `revisit`, báo mode khi nước đi bị luật chặn;
   `GameController._hazard_game_over_reason()` → popup thua mở đúng tiêu đề; `gameover_level.gd` nhận thêm lý do `revisit`.
3. **HUD** `nodes/hud/one_stroke_hud.tscn` + `scripts/nodes/hud/one_stroke_hud.gd` (`OneStrokeHUD`): THỜI GIAN 270×156 (chip
   `ĐANG TÍNH GIỜ`) + BẢNG TIẾN ĐỘ 690×156 (`📐 ĐÃ PHỦ KÍN` · `x/y Ô` · `CÒN LẠI n Ô` · `✍️ MỘT NÉT KHÔNG LẶP` · chip `p% KÍN` ·
   thanh tiến độ cắt bằng `clip_contents` · 2 dòng nhắc luật) + `challenge_card() = null`; art mới `card_stroke_sheet/row/chip/
   slider_track/slider_fill/time_chip.svg`; theme thêm 7 variation `HudStroke*`; tool bar **ẩn nút GHI NHỚ** (`TOOL_HIDE_WALL_MODES`)
   + nhãn phụ `STR_TOOL_DRAW_PATH_STROKE`.
4. **Board:** `MazeCell` thêm lớp `Visited`/`VisitedLabel` (`cell_visited_hatch.svg` + LabelSettings `text_game_cell_visited.tres`,
   nhãn `ĐÃ ĐI` co theo cỡ ô) · `BoardView.refresh_cell_texts()` tự vẽ lớp này khi mode có `is_cell_visited()` (ô S/F giữ nguyên art).
5. **Nối dây:** `GameModeController` (`one_stroke`), `GameScene` (HUD preload/map + tool bar), `HintGuide` (`STR_HINT_ONE_STROKE`),
   `GameController.INSTRUCTION_SCENES` (`one_stroke` → `one_stroke.tscn`).
6. **Popup hướng dẫn 3 trang:** sinh bằng pipeline tool (thêm `one_stroke` vào `MODES` của `instruction_mockup.py`, thêm bản EN vào
   `guide_text_en.py`, chạy `prepare_guideline_images.py` + `build_instruction_data.py` + `gen_instruction_popups.py`) → `one_stroke.tscn`
   (121 node) + 74 khoá `STR_GI_ONE_STROKE_*`; **3 ảnh guideline phải import lại** (xoá `.import` cũ thiếu `path=`) nếu không popup
   báo `Failed loading resource`.
7. **Kiểm thử:** suite mới `scripts/test_case/test_one_stroke.gd` **34/34 PASS** (không số trên ô · tường hiện 100% · 20 lần sinh bàn
   đều có đường phủ kín · F bị chặn sớm · đi theo Gợi ý là **thắng** · đi lại ô cũ → popup `ĐI LẠI Ô CŨ!` · Undo mở lại ô + tắt lớp
   `ĐÃ ĐI` · cắt ngang → `is_dead_end` · HUD đủ chỉ số + thanh tiến độ + nhãn phụ nút); `test_instruction` **326 PASS** (10 popup),
   `test_hud_modes` thêm mục **[4d]** (7 check đỏ còn lại là lỗi cũ Sum Path/Fading Ink), `test_game_scene_integration` thêm mode.
   Toàn bộ 32 suite: **30 xanh**, 2 đỏ là lỗi **có từ trước** (`test_challenge_controller` 3 check · `test_hud_modes` 7 check).

**Còn lại của One Stroke (chưa làm):** gắn vào `GameManager.DAILY_MODES` (§6) · mockup matchup chưa thêm vào `HAND_DRAWN` ·
nút VẼ ĐƯỜNG chưa có art bản bè ngang 680px như mockup (đang giữ nguyên art 360px + ẩn nút GHI NHỚ).

---

### 13.19. Wall Builder đã lập trình xong (2026-09-19) — mode + nút GỬI BÀI + HUD + popup hướng dẫn

**Bối cảnh:** user yêu cầu *"làm tiếp cho tôi Wall Builder"* sau khi One Stroke xong. Bộ art đã có sẵn từ trước:
`mockup/matchup_wall_builder.svg` · `mockup/instruction/popup_instruction_wallbuilder_page{1,2,3}.svg` ·
`assets/images/instructions/guideline_image/image_guideline_instruction_wall_builder_page{1,2,3}.svg`.

**Đã làm:**

1. **Mode** `scripts/modes/wall_builder_game_mode.gd` (`WallBuilderGameMode`): bàn tường **ẩn hoàn toàn** (`generate(size, size, 0.0)`),
   **loại bàn quá dễ** (quá nhiều ô 0/4 — thử tối đa 12 lần); hiện số tường trên **MỌI ô** (không S/F) · **không nhân vật, không di chuyển**;
   `required_segments = Σ(số)/2`; `evaluate_submit()` trả `{solved, wrong}` với `wrong = Σ|chênh lệch từng ô| / 2`;
   `can_draw_wall()` (chỉ khe giữa 2 ô thuộc board) · `is_wall_locked()` + `hint_wall()` (mở + khoá 1 đoạn tường thật) ·
   `undo_drawn_wall()` (bỏ qua đoạn đã khoá) · `wall_draw_state() = "built"` · `revive_desc_key() = STR_REVIVE_DESC_SUBMIT`.
2. **Hạ tầng dùng chung:** `BaseGameMode` thêm `register_failed_submit()` (hết LƯỢT GỬI ⇒ thua) · `can_draw_wall()` ·
   `is_wall_locked()` · `on_wall_toggled()` · `undo_drawn_wall()` · `hint_wall()` · `shows_player()` · `revive_desc_key()`;
   `GridController.handle_anchor_connected()` kiểm tra luật mode trước khi đổi trạng thái + báo mode sau khi đổi;
   `GameController` thêm **`submit_build()`** (đúng ⇒ `_on_reached_end()` · sai ⇒ trừ lượt + `shake_board()` + chữ nổi
   `CÒN LỆCH n ĐOẠN!` · hết lượt ⇒ `_game_over("out_of_submits")`) và định tuyến `undo()`/`hint()` sang hành vi kiểu tường;
   `GameOverLevelPopup` nhận `revive_desc` + lý do `out_of_submits`; `WallSegment` thêm trạng thái **`built`** (xanh lá);
   `BoardView` thêm `set_player_visible()` (ẩn nhân vật) + `shake_board()` + dùng `wall_draw_state()` của mode khi nối tường.
3. **HUD** `nodes/hud/wall_builder_hud.tscn` + `WallBuilderHUD`: THỜI GIAN 270×156 (chip `ĐANG SUY LUẬN`) + BẢNG TƯỜNG ĐÃ VẼ
   690×156 (viền xanh lá): `🧱 ĐÃ DỰNG` · `x/y ĐOẠN` · `CÒN THIẾU n ĐOẠN` · `❤️ LƯỢT GỬI: n / 3 LẦN` · chip trạng thái
   (`ĐANG NỐI TƯỜNG` / `ĐỦ TƯỜNG` / `SẴN SÀNG GỬI`) · thanh tiến độ + 2 dòng nhắc luật; `challenge_card() = null`.
   Art mới `card_wall_{sheet,row,chip,slider_track,slider_fill}.svg`; theme thêm `HudWallCoverHead` + `HudWallSubmitRow`.
4. **Thanh công cụ đổi công dụng:** `GameScene.TOOL_FULL_KEYS["wall_builder"]` đổi **cả nhãn chính + nhãn phụ** của 2 nút
   thành **VẼ TƯỜNG** (*"Nối tường theo số"*) và **GỬI BÀI** (*"Kiểm tra kết quả"*); nút thứ 2 được nối thêm vào
   `GameScene._on_secondary_tool_pressed()` → `GameController.submit_build()` khi đang ở chế độ này.
5. **Nối dây:** `GameModeController` (`wall_builder`) · `GameScene` (HUD preload/map) · `HintGuide` (`STR_HINT_WALL_BUILDER`) ·
   `GameController.INSTRUCTION_SCENES` (`wall_builder` → `wall_builder.tscn`) · Debug Console (SPECIAL MODES thêm cả
   `one_stroke` + `wall_builder`) · `dev_aspects.GAME_MODES` · `dev_fix_shots` (ảnh HUD).
6. **Popup hướng dẫn 3 trang:** `nodes/popups/instruction/wall_builder.tscn` (142 node) sinh bằng pipeline tool
   (thêm `wall_builder` vào `MODES` + ~35 bản EN vào `guide_text_en.py` + build/gen) → 83 khoá `STR_GI_WALL_BUILDER_*`;
   3 ảnh guideline ThorVG-safe (đã xử lý ở vòng One Stroke).
7. **Kiểm thử:** suite mới `scripts/test_case/test_wall_builder.gd` **47/47 PASS** (mọi ô hiện số 0..4 · không nhân vật +
   không di chuyển · `y = Σ/2` = số tường thật · kéo Anchor tạo đoạn kiểu `built` · viền ngoài không vẽ được ·
   Gợi ý khoá đoạn tường thật · Undo chỉ xoá đoạn không khoá · GỬI sai 3 lần ⇒ popup `HẾT LƯỢT GỬI!` + dòng HỒI SINH `+1 LƯỢT GỬI` ·
   Hồi sinh +1 lượt · dựng đúng mê cung ⇒ THẮNG · HUD + nhãn thanh công cụ); `test_instruction` 358 check (11 popup — *nay 326 check / 10 popup sau khi bỏ Time Attack*) ·
   `test_hud_modes` thêm mục **[4e]** · `test_game_scene_integration`/`test_all_game_modes` phủ mode mới.
   Toàn bộ **33 suite: 31 xanh**, 2 đỏ là lỗi **có từ trước** (`test_challenge_controller` 3 check · `test_hud_modes` 7 check).

**Còn lại của Wall Builder (chưa làm):** gắn vào `GameManager.DAILY_MODES` (§6) · mockup chưa thêm vào `HAND_DRAWN` ·
chưa tô nền xanh nhạt cho ô đã khớp số (mockup có gợi ý trực quan này — chỉ là trang trí) · chưa có solver đếm nghiệm
để ưu tiên bàn ≥ 2 nghiệm (hiện chỉ loại bàn quá dễ).

---

### 13.20. Gắn 2 chế độ mới vào Daily + thử thách riêng + polish art (2026-09-19)

**Bối cảnh:** user yêu cầu *"trừ test trên máy ảo và APK, làm tiếp"* — tức làm nốt các việc còn lại của 2 chế độ mới
(One Stroke & Wall Builder) đã ghi ở §13.18–13.19.

**Đã làm (6 việc):**

1. **Vòng xoay Daily 9 ngày ĐÃ CHẠY THẬT:** `GameManager.DAILY_MODES` thêm `one_stroke` + `wall_builder`
   (`[time_attack, minesweeper, sum_path, countdown_cost, blind_memory, fog_of_war, fading_ink, one_stroke, wall_builder]`)
   *(Cập nhật 2026-09-19: Time Attack đã bỏ khỏi game → vòng xoay còn 8 ngày, xem §6.)*
   → ngày *N* = `DAILY_MODES[(N-1) % 9]`; màn Daily đọc tên luật qua `tr("STR_MODE_<ID>")` nên 2 tên mới đã có sẵn.
   **Lưu ý hồi quy:** bản đồ ngày → luật đổi so với bộ 7 cũ (VD ngày 13 trước là SƯƠNG MÙ, nay là CHI PHÍ ĐẾM NGƯỢC);
   `test_daily` dùng công thức động nên vẫn xanh.
2. **Mockup art tay:** thêm `matchup_one_stroke` + `matchup_wall_builder` vào `HAND_DRAWN` của `tools/mockup/gen_matchup.py`
   (chạy tool sẽ không ghi đè 2 bản này nữa).
3. **Thử thách `no_wrong_submit` (loại thứ 17):** `ChallengeTypes` + nhánh chấm trong `ChallengeController`
   (đếm `submit_misses` của mode) + chuỗi `STR_CHALLENGE_NO_WRONG_SUBMIT` / `STR_CHALLENGE_ST_SUBMIT_MISSED`;
   thêm cơ chế **bộ thử thách mặc định riêng của chế độ** — `BaseGameMode.default_challenges()` +
   `ChallengeController.setup_for_floor(..., mode)` (One Stroke: `time_max · no_hint · no_undo`;
   Wall Builder: `no_wrong_submit · time_max · no_hint`).
4. **Wall Builder — ô "ĐÃ KHỚP SỐ":** `WallBuilderGameMode.is_cell_satisfied()` + art `cell_satisfied_wash.svg` +
   node `Satisfied` trong `nodes/game/cell.tscn` + `MazeCell.set_satisfied()`; `BoardView.refresh_cell_texts()` tự vẽ lớp này
   và `GridController.handle_anchor_connected()` vẽ lại sau mỗi đoạn tường được nối (đúng gợi ý trực quan của mockup).
5. **Wall Builder — solver ĐẾM NGHIỆM:** `count_solutions(maze, cap)` (backtracking theo từng khe + cắt tỉa
   `counts ≤ clue ≤ counts + khe còn lại`, ngân sách 80.000 nút) → bộ sinh bàn **loại bàn quá dễ**
   (số đoạn tường < cạnh bàn, quá nhiều ô 0/4) và **ưu tiên bàn ≥ 2 nghiệm** (phải suy luận thật, đúng §5.13).
   *Đã dính bug:* bản đầu chỉ lọc "≥ 2 nghiệm" nên sinh ra bàn 3×3 **chỉ 2 đoạn tường** → test báo "bàn đã đúng sẵn";
   đã sửa bằng cách chấm điểm bàn (ưu tiên nhiều ô phải suy luận) + sàn số đoạn tường.
6. **Art nút công cụ theo mockup:** `ToolController.set_mode_textures()` (ghi đè art 2 nút theo chế độ) +
   `btn_tool_path_stroke_active.svg` (nút **VẼ ĐƯỜNG ĐI bè ngang 680px** cho One Stroke — khớp luôn bề ngang còn lại
   của thanh công cụ) + `btn_tool_submit_normal/pressed.svg` (nút **GỬI BÀI xanh lá** cho Wall Builder).

**Kiểm chứng:** `test_wall_builder` **53/53** (thêm check solver đếm nghiệm + ô đã khớp số + thử thách mặc định + art nút) ·
`test_one_stroke` **35/35** (thêm check nút bè ngang) · `test_challenge_types` **17 loại** · `test_debug_modes` **48 check**
(SPECIAL MODES giờ 9 chế độ) · `test_daily` 87/87 · **33 suite: 31 xanh** (2 đỏ là lỗi cũ).

**Còn lại:** chỉ còn **test trên máy ảo + build APK** (user yêu cầu để sau) và vài việc nhỏ không bắt buộc
(nút VẼ ĐƯỜNG của One Stroke có thể tinh chỉnh vị trí chữ cho khớp mockup, Wall Builder chưa có bảng xếp hạng riêng).

---

### 13.21. BỎ hẳn chế độ Time Attack Maze (2026-09-19)

**Bối cảnh:** user yêu cầu *"Hiện tại, tôi có thay đổi — Hãy xóa Time Attack Mode ra khỏi game"*.

**Đã xoá (khỏi game, không còn đường vào):**

1. **Code:** `scripts/modes/time_attack_game_mode.gd` (cả file) · `scripts/nodes/hud/time_attack_hud.gd` (cả file) ·
   `nodes/hud/time_attack_hud.tscn` · `nodes/popups/instruction/time_attack.tscn` (popup hướng dẫn).
2. **Asset:** `assets/images/instructions/mode_time_attack.svg` (icon mode) +
   `assets/images/instructions/guideline_image/image_instruction_time_attack_page{1,2,3}.svg` (ảnh guideline — chỉ popup này dùng).
3. **Nối dây:** `GameModeController.set_mode_by_name()` (case `time_attack`) · `GameScene` (`HUD_TIME_ATTACK` + 2 map HUD) ·
   `HintGuide` (`STR_HINT_TIME_ATTACK`) · `GameController.INSTRUCTION_SCENES` (`time_attack`) ·
   nhánh `if mode is TimeAttackGameMode` trong `start_new_run()` (**đồng hồ giờ LUÔN chạy đếm lên** — `TimerController.start_countdown()` thành API không còn ai gọi, giữ lại phòng khi cần).
4. **Vòng xoay Daily:** `GameManager.DAILY_MODES` còn **8 chế độ** —
   `[minesweeper, sum_path, countdown_cost, blind_memory, fog_of_war, fading_ink, one_stroke, wall_builder]` → ngày *N* = `DAILY_MODES[(N-1) % 8]`.
   **Lưu ý hồi quy:** mọi ngày dịch lên 1 bậc so với bộ 9 (VD ngày 1 trước là TIME ATTACK, nay là MINESWEEPER); tiến trình đã lưu **không hỏng**.
5. **Tool:** bỏ entry `time_attack` khỏi `tools/mockup/gen_matchup.py` (MODES + danh sách scene của `dump()`),
   `tools/mockup/instruction_mockup.py` (MODES), `tools/level_designer/app/config.py` (MODE_IDS) → chạy lại
   `build_instruction_data.py` + `gen_instruction_popups.py`: CSV còn **730 dòng STR_GI_*** (bỏ 75 khoá `STR_GI_TIME_ATTACK_*`) và
   generator sinh **10 popup** (không sinh lại `time_attack.tscn`).
6. **Test:** `test_hud_modes` (bỏ mục **[4b]** Time Attack + map script) · `test_instruction` (bỏ khỏi MODES/MODE_IDS + case tích hợp
   → **326 check / 10 popup**) · `test_all_game_modes` (**8 Game Modes**) · `test_debug_modes` (**8 chế độ Special**, ván test đổi sang
   `minesweeper`) · `test_game_scene_integration` + `dev_aspects.GAME_MODES` (bỏ `time_attack`).
7. **Giữ lại có chủ ý:** mockup thiết kế trong `mockup/` (`matchup_time_attack.svg` · `popup_instruction_time_attack_page*.svg` ·
   ảnh trong `mockup/instruction/_extracted_source/`) và bản dịch trong `tools/content/guide_text_en.py` — chỉ là tài liệu lịch sử, **không nằm trong build UI**;
   khoá `STR_MODE_TIME_ATTACK` / `STR_HINT_TIME_ATTACK` vẫn giữ trong `string_extra.csv` để **save cũ không hiện khoá thô**.

**Kiểm chứng:** `test_instruction` 326 PASS · `test_hud_modes` **7/146 FAIL — vẫn đúng 7 lỗi CŨ của Sum Path/Fading Ink** (không phát sinh lỗi mới) ·
`test_debug_modes` 46/46 · `test_daily` 87/87 · `test_all_game_modes` 14/14 · `test_game_scene_integration` PASS · **toàn bộ 33 suite: 31 xanh**.


### 13.23. NỀN TẢNG ĐA TỈ LỆ THEO `guide/GUIDE.MD` + MAIN SCENE 2 LAYOUT (2026-02)

**Yêu cầu (user):** bỏ hướng “tạo riêng 1 game scene cho landscape”; làm theo guide mới — aspect ratio cho TỪNG scene,
ưu tiên container/anchors/9-slice/AutoFit, hạn chế hard-code trong script; **Main Scene làm trước để kiểm thử**.

**1. Cơ chế chung (`scripts/scenes/base.gd`):** mỗi màn = root (BaseScene) + 2 layout con CÙNG CẤP:
`Portrait` (KẾ THỪA `scenes/orientation/portrait/portrait.tscn`) và `Landscape` (KẾ THỪA `scenes/orientation/landscape/landscape.tscn`).
BaseScene tự bật/tắt theo hướng canvas + phát `orientation_changed(is_landscape)`. Khung nội dung:
· màn **DỌC** = cột `clamp(canvas.x, 1080, 1440)` canh giữa (tablet 3:4 dùng hết bề ngang, thay cột 1080 cứng trước đây)
· màn **NGANG có layout ngang** → root phủ kín canvas · màn **chưa tách layout** → giữ nguyên cột 1080 (tương thích ngược).
Màn con lấy node bằng **`ui("Tên")` / `ui_child("Cha","Con")`** (2 layout dùng cùng tên node nên KHÔNG dùng được `%UniqueName`).
Helper mới: `scripts/utils/auto_fit_label.gd` (`class_name AutoFitLabel`).

**2. ĐO CANVAS THẬT** (`scripts/test_case/dev_size_probe.gd` — phải chạy opengl3 mới đổi được cửa sổ):
`9:16→1080×1920 · 9:18→1080×2160 · 9:19.5→1080×2340 · 9:21→1080×2520 · 3:4 (1080×1440 và 1200×1600)→1440×1920 ·
4:3→2560×1920 · 16:9→3413×1920 · 18:9→3840×1920 · 19.5:9→4160×1920`.
⇒ Màn NGANG có canvas CAO ĐÚNG **1920** → cỡ chữ/khung trong layout ngang lấy **× 1.778** so với số px trong spec.

**3. Main Screen ngang** (theo `mockup/aspect/scene/mainscreen_layout_spect.md`): tờ giấy `NinePatchRect`
(patch 115/96/64/64 đọc từ `main_menu_paper.svg`) neo 0.026→0.974 × 0.046→0.954 · **2 cột**: `Hero`
(logo + tag + slogan + nút DANH HIỆU + con dấu) và `Menu` (3 thẻ chế độ `VBoxContainer` + hàng 3 nút công cụ `HBoxContainer`).
Bản dọc giữ NGUYÊN bố cục cũ, nay nằm ở `scenes/orientation/portrait/main.tscn` (bản ngang: `scenes/orientation/landscape/main.tscn`,
cả hai KẾ THỪA scaffold `portrait.tscn` / `landscape.tscn` trong cùng thư mục);
`main.gd` gắn lại node mỗi lần đổi hướng.

**4. Kiểm chứng:** `test_main_layout` (đã cập nhật theo 2 layout) PASS · harness `dev_aspects.gd -- --only=main`
**10/10 tỉ lệ OK** (ảnh chứng cứ `tmp_aspect/<WxH>/main.png`) · toàn bộ **33 suite: 31 xanh** — 2 suite đỏ vẫn là lỗi CŨ (Sum Path/Fading Ink HUD).

**5. ~~CÒN LẠI~~ ĐÃ ĐÓNG (v2.21):** art thẻ chế độ từng bị KÉO NGANG ở layout ngang (thẻ 1848×414 so với art 804×310)
→ đã chuyển **2 thẻ chế độ + nút dock sang `StyleBoxTexture` 9-slice** (xem **§13.24**).
Còn lại: các màn khác chưa tách layout ngang · chưa áp safe-area (tai thỏ).

---

### 13.24. MAIN SCREEN BỐ CỤC MỚI 2 HƯỚNG + THẺ GIẤY 9-SLICE (v2.21, 2026-10-11)

**Yêu cầu (user):** đổi giao diện Main theo mockup mới + thêm khối Sự kiện (xem **§15**).

**1. Bố cục dọc** (`scenes/layout/portrait/main.tscn`) — `Body` (VBoxContainer, lề 12/10/12/12, khe 8):
`TopBar` (cao 68: `ProfileCard` co giãn · `CoinChip` 126×52 · `StarChip` 96×52 · `Settings` 64×64) →
`Scroll` (ScrollContainer dọc, chế độ AUTO) → `Column` (logo 36 · `EventHeader` 34 · `EventCarousel` 540 · `Modes` 2×`ModeCard` 150 · con dấu phiên bản) → `Dock` (4×`DockButton` 115×92).
Cuộn dọc chỉ bật khi máy thấp — máy cao (9:19.5 trở lên) hiện đủ 100% trong một màn.

**2. Bố cục ngang** (`scenes/layout/landscape/main.tscn`) — `Body` VBox:
`TopBar` (logo trái · đẩy phải: hồ sơ · Xu · Sao · Cài đặt) → `Mid` (HBox: **Left** = tiêu đề + carousel co giãn · **Right** 380px = 2 thẻ chế độ + con dấu) → `Dock` (4 nút).

**3. Thẻ giấy `ModeCard`** (`nodes/main/mode_card.tscn`, `scripts/nodes/mode_card.gd`): root **LÀ nút** (kế thừa `NinePatchButton`) với 4 trạng thái `card_mode_{normal,pressed,focus,disabled}` qua **9-slice** (margin 40/30/60/24) ⇒ art không méo ở mọi bề rộng. Bên trong: `Tape` (băng dính nhận diện) · `IconBox` 76×76 · chip · tiêu đề · phụ đề · hàng thông tin · khối phải (nhãn số · giá trị · nút CTA). Cấu hình bằng `setup(data)`, **không tạo node lúc chạy**.
Mọi nhãn đặt **`clip_text = true`** ⇒ chữ dài (tiếng Việt) KHÔNG đẩy bề rộng tối thiểu của thẻ, tránh tràn ở layout ngang.

**4. Node con mới** (`nodes/main/`): `profile_card.tscn` · `coin_chip.tscn` · `star_chip.tscn` · `event_header.tscn` · `event_dots.tscn` · `mode_card.tscn` · `dock_button.tscn` (mỗi scene 1 script `class_name`).
`MainLayout` (`scripts/scenes/layout/main_layout.gd`) đổi `@export` sang bộ node mới; `scripts/scenes/main.gd` gắn lại dây nút + nạp dữ liệu (Xu · Sao · hồ sơ · 2 thẻ chế độ · carousel).
`DockButton.set_badge()` hiện chấm đỏ "có thứ chưa nhận"; `EventHeader` ẩn link "Xem tất cả" ở giai đoạn 1.

**5. Kiểm chứng:** `test_main_layout` viết lại theo bố cục mới · `test_ui_scenes` 139/139 · `test_layout_bindings` 84/84 · harness
`dev_aspects.gd -- --only=main,event` **20/20 OK** (ảnh `tmp_aspect/<WxH>/main.png` · `event.png`) · toàn bộ suite mặc định **20/20 xanh**
(lỗi `game/*` HUD của harness là lỗi CÓ TỪ TRƯỚC, không liên quan — xem §13.23 mục 4).

---

### 13.25. KHỞI ĐỘNG "SPLASH TRƯỚC, NẠP SAU" + `LoadingManager` + NÚT BACK CỨNG ANDROID (v2.23 → v2.24, 2026-10-14)

**Yêu cầu (user):** *"sau khi hiện ra icon app thì màn hình màu đen, do phải loading rồi mới sang splash screen"*
→ muốn Splash hiện TRƯỚC, việc nạp chạy nền trong lúc Splash đang hiển thị, nạp xong mới sang màn kế tiếp.
Kèm: *"ở màn hình levels, sau khi ấn nút back về thì nó không back về được"*.
(Vòng sau) *"tạo thêm Loading Manager… đưa nó xử lý việc Load Assets/Booting; ở splash scene nên thêm loading progressing"*.

**1. Vì sao có màn hình đen (đo được, không phải phỏng đoán).** `_ready()` của autoload chạy TRƯỚC frame vẽ đầu tiên.
Đo trên máy dev (`tools/…` probe tạm, debug build): **frame đầu mất 1216 ms**, trong đó `LocalizationManager._load_translations()`
**192 ms** · `PlayerProfileManager._load_catalog()` **175 ms** · `EventManager._load_all_events()` **99 ms** ·
`ArchivementManager._load_catalog()` **24 ms**. Bốn việc này (≈ 0,5 s máy dev, lâu hơn trên Android) nằm TRƯỚC frame đầu
⇒ người chơi thấy màn trống ngay sau icon app. Trên Android còn 2 chỗ đặt màu ĐEN trong `export_presets.cfg`:
`splash_screen/background_color` (nền system splash) và `screen/background_color` (nền cửa sổ Activity) — xem §13.11 về việc
nền cửa sổ lộ ra khi canvas lệch tỉ lệ.

**2. Autoload `LoadingManager`** (`scripts/manager/LoadingManager.gd`, đứng ĐẦU danh sách autoload) — gom **2 loại** việc nạp:
- **Booting** (autoload): manager nặng gọi `add_step(Callable(self, "initialize"), "tên-bước")` trong `_ready()` thay vì tự nạp.
- **Load assets**: `PRELOAD_SCENES` (`title` · `main` · `levels`) được nạp sẵn — giữ tham chiếu trong `_preloaded` nên tài nguyên
  không bị thu hồi khỏi cache, `SceneManager` vào màn sau tức thì (`ResourceLoader.has_cached()` = true).
- Màn Splash gọi `start()`; mỗi bước chạy **1 bước/frame** sau frame Splash đầu tiên (`FIRST_FRAME_DELAY`) ⇒ hoạt ảnh + thanh
  tiến trình vẫn chạy trong lúc nạp nền. API: `progress()` · `pending_steps()` · `current_label()` (dev) ·
  `is_loading_done()` · signal `progress_changed(progress, label)` + `loading_finished`.
  (v2.51: thêm `VISUAL_GRACE_SEC` + nạp scene ở **luồng nền** — xem §13.25a.)
- Chạy **headless** (`godot --headless --script`, test/CI) hoặc khi không thấy màn Splash ⇒ nạp + preload **NGAY** như trước
  (`add_step` sau khi xong sẽ gọi hàm ngay) ⇒ **test/harness không đổi hành vi**.
- 4 autoload chuyển việc nạp sang `initialize()` (idempotent): `LocalizationManager` (có `is_ready()`) · `PlayerProfileManager` ·
  `EventManager` · `ArchivementManager`. Thứ tự tương đối với `SaveManager.load_all()` **giữ nguyên** như trước.

**3. Ảnh boot splash + màu nền.** Thêm `tools/make_boot_splash.py` sinh `assets/images-png/boot_splash.png`
(720×1280 = nền giấy `#FAF5EB` + logo + chữ "Invisible Gear", khớp tỉ lệ màn Splash động) — chạy lại khi đổi logo/tên hãng.
⚠️ `assets/images-png/` **bị .gitignore** (mọi PNG ở đây do tool sinh ra, xem `.gitignore`): dựng máy mới thì phải chạy
tool này **cùng** `tools/svg_to_png.py`, nếu thiếu file thì engine chỉ hiện **nền giấy** (không đen, xem `boot_splash/bg_color`).
`project.godot`: `boot_splash/bg_color = #FAF5EB` · `boot_splash/image = boot_splash.png` · `fullsize = true` · `use_filter = true`.
`export_presets.cfg` (Android): `splash_screen/background_color` và `screen/background_color` đổi từ **đen → `#FAF5EB`**.
Nhờ vậy chuỗi hình khi mở app liền mạch: icon app → system splash (nền giấy) → boot splash (nền giấy + logo) → màn Splash động.

**4. Màn Splash: THANH TIẾN TRÌNH + chờ nạp xong mới đi.** Node khai trong CẢ 2 bố cục
(`scenes/layout/{portrait,landscape}/splash.tscn`) — `Panel/LoadingBox` (`VBoxContainer`) → `LoadingBar` (`ProgressBar`,
`max_value = 1.0`, 2 `StyleBoxFlat` khai trong scene: nền `#E5DECF` + fill mực `#3D83AE`) + `LoadingLabel`
(theme variation **`SplashLoadingLabel`**). `SplashLayout` bind 3 node bằng `@export`; `splash.gd` nối `progress_changed`/
`loading_finished` của `LoadingManager`:
- Nhãn hiện **`STR_LOADING_PROGRESS`** (`"Đang nạp {0}%"`) — nhưng **chỉ khi bảng dịch đã nạp xong**
  (`LocalizationManager.is_ready()`, là bước ĐẦU của `LoadingManager`); trước đó hiện mỗi phần trăm ⇒ không lộ khoá thô.
- `_on_touch_pressed()` (chạm màn hình **hoặc** `AutoAdvanceTimer` 2,2 s) chỉ ĐẶT `_advance_pending` nếu còn đang nạp;
  `_on_loading_finished()` giữ Splash đủ `MIN_DISPLAY_SEC` (1,2 s) rồi mới chạy hoạt ảnh thoát sang Title.
- Nếu nạp đã xong TRƯỚC khi Splash kịp dựng (test/headless) thì ẩn `LoadingBox` và đặt thanh ở 100 %.

**5. Nút Back cứng Android.** Gốc lỗi: project để mặc định `application/config/quit_on_go_back = true` ⇒ Back **THOÁT APP**;
engine còn KHÔNG phát `ui_cancel` cho Android (xem `platform/android/android_input_handler.cpp`: gửi `WINDOW_EVENT_GO_BACK_REQUEST`
+ phím `Key::BACK`) nên `ScreenManager._unhandled_input` (chỉ bắt `ui_cancel`) không bao giờ chạy.
Sửa: `project.godot` đặt `config/quit_on_go_back=false`; `ScreenManager._notification()` bắt `NOTIFICATION_WM_GO_BACK_REQUEST`
(engine lan tới MỌI node — `Window::_propagate_window_notification`) và gọi **một chỗ duy nhất** `_handle_back(allow_quit)`:
popup đang mở ⇒ đóng popup trên cùng · còn lịch sử ⇒ lùi màn trước · hết lịch sử ⇒ về Main (không ghi thêm lịch sử) ·
đang ở Main ⇒ **thoát app** (lưu dữ liệu trước). Cờ `_back_busy` chống xử lý 2 lần cho cùng một lần bấm.
`SceneManager`: thêm `is_main_scene()`; `go_back()` khi hết lịch sử về Main **không ghi lịch sử**
(trước đây gọi `goto_main()` ⇒ Main bị đẩy vào lịch sử, bấm Back ở Main nhảy ngược lại màn vừa rời).
`scripts/scenes/levels.gd` `_on_back_pressed()`: lùi theo **lịch sử** (về Main, hoặc về Chọn Chương nếu vào từ đó) và không ghi thêm lịch sử.

**6. Kiểm chứng.** Probe chạy máy thật (không headless), đo lại sau khi thêm `LoadingManager` + thanh tiến trình:
- Frame đầu **397 ms** (đo lại vòng này **411 ms**), lúc đó `done=false`, `pending=4`, `progress=0.00`, `event_init=false`
  ⇒ Splash hiện TRƯỚC, việc nạp nằm sau frame đầu. Tiến độ chạy **0 → 0,43 → 0,57 → 0,71 → 0,86 → 1,0** (mỗi bước 1 frame),
  nhãn hiện `"Đang nạp 29%"` → `"Đang nạp 100%"` (đã dịch, không lộ khoá), `_preloaded` = **3** scene, và
  `ResourceLoader.has_cached("res://scenes/title.tscn")` = **true** ⇒ sang Title tức thì. Splash ở lại đúng `MIN_DISPLAY_SEC`
  rồi mới sang Title (tổng ≈ 1,2 s kể từ lúc mở Splash).
- Back Android mô phỏng bằng `root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)`: ở Chọn Màn ⇒ về Main
  (lịch sử sạch `[]`), ở Main ⇒ thoát app.
- Ảnh: `dev_aspects.gd -- --only=splash --shots` OK ở cả 2 hướng (`tmp_aspect/<WxH>/splash.png`).
- Full suite headless **20/20 PASS** (`test_splash_title_shop_chapters` nay gác thêm `LoadingManager` + node thanh tiến trình);
  `godot --export-debug "Android"` **build thành công** và APK có `assets/.godot/imported/boot_splash.png-*.ctex`
  (import lossless, `vram_texture=false` — điều kiện để engine nạp được lúc khởi động).

---

### 13.25a. MÀN SPLASH HẾT "GIẬT CỤC": HOẠT ẢNH THẬT + NẠP LUỒNG NỀN (v2.51, 2026-10-24)

**Yêu cầu (user):** *"ở màn hình splash, khi đang booting, thì tôi thấy hiển thị icon nó đang giật cục"*.

**1. Đo trước khi sửa (probe chạy máy dev, không headless).** Ghi `Time.get_ticks_msec()` mỗi frame + `LogoContainer.scale`:
các frame **126 · 230 · 91 · 42 · 211 · 229 ms**, và `scale` nhảy **0,300 → 1,048 trong MỘT frame**, rồi 1,058 → 1,045 → 1,008 → 1,000
(tức logo phóng VỌT quá cỡ rồi co lại theo từng cục). Hai nguyên nhân ĐỘC LẬP:

**2. Nguyên nhân A — thư viện hoạt ảnh của layout RỖNG (lỗi cú pháp `.tscn`).**
Cả 2 layout khai:

```
[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries/ = SubResource("AnimationLibrary_splash")     # SAI
```

`libraries` là `HashMap<StringName, Ref<AnimationLibrary>>` nên phải ghi
`libraries = { "": SubResource("AnimationLibrary_splash") }`. Với dạng `libraries/ = …`, Godot tạo **library rỗng**:
`get_animation_list()` trả `[]` ⇒ `has_animation("play_entrance")` = **false** ⇒ `splash.gd` rơi vào nhánh **dự phòng**
(`create_tween()` + `TRANS_BACK`) — chính là kiểu phóng vượt rồi co lại, và `play_exit` cũng không bao giờ chạy.
Đã sửa cả 2 layout ⇒ `RESET` · `play_entrance` (2,5 s, 4 track) · `play_exit` (0,28 s) hoạt động lại; hoạt ảnh thật dùng
`transitions = 0.5` (ease-out, **không** vượt cỡ) nên logo dừng đúng ở `scale = 1`.

**3. Nguyên nhân B — `LoadingManager` chặn main thread ngay từ frame thứ 2.** 7 bước (4 `initialize()` của autoload +
3 `ResourceLoader.load()` đồng bộ của `PRELOAD_SCENES`) chạy cách nhau đúng 1 frame ⇒ mỗi bước làm rơi 40–230 ms khung hình
đúng lúc logo đang bung. Sửa 2 việc:
- `VISUAL_GRACE_SEC = 0.82`: **nhường thời gian** trước bước nặng đầu tiên cho `play_entrance` (0,15 → 0,8 s) chạy trọn.
  Không tốn thời gian khởi động vì tổng thời gian Splash đã bị chặn dưới bởi `MIN_DISPLAY_SEC` 1,2 s.
- **Nạp luồng nền**: `_request_preloads()` gọi `ResourceLoader.load_threaded_request()` ngay trong `_ready()` (giải nén
  3 scene song song trong lúc chờ hoạt ảnh), bước preload đổi sang `_load_scene_threaded()` = poll
  `load_threaded_get_status()` + `await process_frame` ⇒ main thread không bị chặn. Lỗi/không hỗ trợ thì tự lùi về
  `_load_scene()` đồng bộ. **Headless giữ nguyên** `_run_all_now()` (nạp đồng bộ ngay trong `_ready()`) nên test không đổi.
- `SplashScene` đặt `pivot_offset` **giữa** cho cả `logo_container` và `title_label` (`Title` chỉ có `size` sau lượt layout
  đầu ⇒ đặt qua `_center_pivot_deferred.call_deferred()`).

**4. Đo lại sau khi sửa** (`--resolution 1080x1920` và `1920x1080`, opengl3):

| | Trước | Sau |
|---|---|---|
| Khung hình trong lúc logo bung | 126 · 230 · 91 · 42 ms (nhảy cóc) | **16–17 ms đều** từ 0 → 0,8 s |
| `scale` của logo | 0,300 → **1,048** → 1,058 → 1,045 → 1,008 → 1,000 | 0,300 → 0,477 → 0,675 → 0,825 → 0,929 → 0,987 → **1,000** |
| Vượt cỡ (overshoot) | có (≈ +5,8 %) | **không** |
| Tổng thời gian tới màn Title | ≈1,37 s | ≈1,5 s (chặn dưới `MIN_DISPLAY_SEC`, nạp xong ở ≈1,14 s) |

Các bước nặng còn lại (117 · 175 · 64 ms) rơi vào **sau** khi hoạt ảnh kết thúc (t ≈ 0,80–1,06 s) nên chỉ còn thanh tiến trình
nhảy, không còn hiện tượng icon giật. `_preloaded` = **3** scene (`title` · `main` · `levels`), `is_loading_done()` = true,
`--import` exit 0, boot headless `--quit-after 150` exit 0, `test_splash_title_shop_chapters` PASS.

⚠️ **Cùng lỗi cú pháp đã được sửa ở TOÀN BỘ 25 scene còn lại** (49 dòng `libraries/ =` → `libraries = { "": … }`):
`title` · `daily` (×2 hướng) · `levels` (×2) · `ranking` (×2) · `shop` (×2) · `archivement` · `loading` ·
`level_map` · `level_node` · `popups/base` · `popups/memory_countdown` · `popups/next_floor` · `popups/daily_milestone` ·
`daily/daily_milestone` · `daily/action_card` · `daily/milestone_chip` · `daily/reward_tip` · `daily/road_chip` ·
`daily/star_bar_fx` · `tutorials/base_tutorial` · `hud/portrait/game/action_bar`.
Trước đó các hoạt ảnh này **chưa bao giờ chạy** (code rơi vào nhánh tween dự phòng). Sau khi sửa, đã kiểm từng bộ khoá:
`popups/base` `open` 0,22 s kết ở `Panel:scale = 1` + alpha 1, `close` 0,14 s kết ở alpha 0 (nên `_finish_close()` vẫn đúng);
`level_node` `pop_in`/`press` đều kết ở `scale = 1` (không kẹt trạng thái nhún); `level_map` `bob` và `daily` `idle` là loop;
`daily`/`levels` `enter` fade `TopBar` → `Tabs` → `Banner` → `Rail` → `NextCard` so le 0,04–0,2 s và kết ở alpha 1.
**Không hồi quy**: chạy lại 19 test từng FAIL trước/sau khi sửa cho kết quả **giống hệt** (cùng số check FAIL), riêng
`test_daily` **3 → 1 lỗi** (2 check "Thẻ CHƠI chạy hiệu ứng Sao" + "Thẻ THỬ THÁCH chạy hiệu ứng Sao" nay PASS vì `FxAnim/celebrate_*`
đã chạy thật); `game/popup` OK; ảnh `dev_aspects --shots` của `title · levels · daily · shop · archivement` dựng đủ nội dung
(không màn nào kẹt trạng thái trong suốt).

---

### 13.25b. LỖI "BACK Ở MÀN CHỌN MÀN QUAY LẠI ĐÚNG VÁN VỪA CHƠI" (v2.52, 2026-10-25)

**Yêu cầu (user):** *"Khi tôi hoàn thành màn 9, sau đó ấn chọn chương, và ấn nút back về, thì nó quay lại màn 9"*.

**1. Tái hiện (probe headless, in ra lịch sử `ScreenManager`).**

```
[1] vào ván:        history=["main.tscn", "levels.tscn"]                  scene=game.tscn
[2] sau khi thắng:  history=["main.tscn", "levels.tscn", "game.tscn"]     scene=levels.tscn   ← SAI
[3] bấm Back:       scene=game.tscn                                       ← quay lại màn 9
```

**2. Nguyên nhân.** `SceneManager.change_scene()` đẩy **màn hiện tại** vào lịch sử khi
`record_history = true` (mặc định). Khi ván kết thúc, `GameController` gọi
`GameManager.go_to_levels()` — hàm này dùng `Nav.change_scene()` nên bị tính là điều hướng
**ĐI TIẾN**: nó đẩy `game.tscn` (ván vừa chơi) lên đỉnh lịch sử. Vào ván trước đó
`Nav.goto_game()` đã đẩy `levels.tscn`, nên lịch sử thành `[main, levels, game]`;
`levels.gd::_on_back_pressed()` lùi theo lịch sử ⇒ pop `game` ⇒ mở lại màn 9 (ván đã kết thúc).

**3. Cách sửa — "quay về màn nguồn" là thao tác BACK, không phải đi tiếp.**
- `ScreenManager`: thêm `drop_history(path)` (gỡ mục cuối nếu đúng bằng `path`) + `peek_history()`;
  `pop_history()` giữ nguyên cho Back.
- `GameManager`: thêm `return_to_levels()` · `return_to_daily()` dùng chung `_return_to(path)`:
  gỡ mục `path` còn sót trên đỉnh lịch sử (do lúc vào ván đã đẩy) rồi `Nav.back_to(path)` — **không** ghi lịch sử.
  `go_to_levels()` / `go_to_daily()` vẫn là điều hướng ĐI TIẾN (Main → Chọn màn, Event → Daily…).
- `GameController` dùng `return_to_*` ở **5 chỗ kết thúc ván**: Continue khi hết chương · Skip khi hết
  chương · popup thắng Daily ("VỀ DAILY") · nhánh `daily_variant` và nhánh dự phòng của "TRỞ VỀ".
  Các nhánh đi tiếp trong cùng chương (`start_level(next)`) **không** đổi (cùng scene ⇒ không đẩy lịch sử).

**4. Sau khi sửa (cùng probe).**

```
[2] sau khi thắng:  history=["main.tscn"]    scene=levels.tscn
[3] bấm Back:       scene=main.tscn          history=[]        ← về Main, hết lỗi
```

**5. Kiểm chứng.** `test_scene_transition` thêm mục 6 (3 check: vào ván giữ `levels` trong lịch sử ·
`return_to_levels()` gỡ `levels` và không đẩy `game` · Back ở Chọn màn về Main · `return_to_daily()`
sạch lịch sử) — PASS; `test_chapters` 123 → **124 check** (gác thêm `return_to_levels`);
`test_floor_records` · `test_challenge_mode` · `test_popup_ui` giữ nguyên số lỗi cũ; boot headless +
chạy thật (opengl3) exit 0, không lỗi script.

---

### 13.26. BẢN ĐỒ CHỌN MÀN: HƯỚNG MÀN HÌNH LẤY THEO CANVAS + NÉT NỐI DÀY HƠN + BẢN NGANG HẾT TỰ CẮT (v2.25 → v2.26, 2026-10-14)

**Yêu cầu (user):** *"ở màn Levels Scene, phần Portrait, đường nối giữa các node đang bị sai… có một trường hợp ở
Portrait size khác nhau thì hiển thị lỗi… tăng kích cỡ của đường nối"* (kèm 2 ảnh: đường nối vẽ sai + nút màn lòi ra
ngoài khung ở bản dọc).

**1. Nguyên nhân (đo bằng probe, không phải phỏng đoán).** `LevelMap.is_wide()` cũ so **khung `MapArea`** với chiều cao
của nó: `area.x > area.y`. Nhưng khung này chỉ cao **~62 % canvas** và nằm trong **CỘT NỘI DUNG canh giữa** (§13.10 —
`scripts/scenes/base.gd`), nên với mọi màn DỌC có tỉ lệ rộng hơn **0,62** (3:4 tablet, cửa sổ lớn khi test…) khung vẫn
"rộng hơn cao" ⇒ bản đồ lỡ coi là màn NGANG:
- dùng `zigzag_landscape = 320` (thay vì 74) ⇒ **nút màn lòi ra ngoài khung** (ảnh 3: nút 4 và 2 bị cắt ở mép trái);
- đổi cả **trục uốn** của điểm giữa: đoạn nối chủ yếu NGANG (delta x = 640 > delta y = 200) nên uốn theo trục DỌC,
  Catmull-Rom cho tiếp tuyến rất lớn ở nút ⇒ đường nối vẽ thành **vòng quét rộng** sai hẳn dáng chữ S (ảnh 1);
- `sway` bị kẹp còn 28 (do `room` âm) nên càng mất dáng.

Probe in ra đúng bệnh: cửa sổ `850×1090` → canvas `717×920` (DỌC) nhưng `MapArea 717×570` ⇒ `is_wide=true`, zigzag 320,
nút 1 và 2 ở `x = 678` và `38` trong khung rộng 717 (art nút 143 px ⇒ nút bị cắt). Còn ở canvas `540×960` (tỉ lệ 0,5625)
thì `540 > 595` = false ⇒ đúng — vì vậy bug chỉ hiện ở **một số** cỡ dọc.

**2. Sửa: hướng lấy theo CANVAS** (`get_viewport_rect().size.x > .y`) — khớp cách `BaseUI`/`BaseScene` quyết định layout;
chỉ khi canvas chưa sẵn sàng mới quay về so khung. Thêm `LevelMap._zigzag()` **KẸP** zigzag theo bề rộng khung thật
(`area.x/2 − node_half_width×scale − sway_edge_margin`, tham số mới `node_half_width = 56`) để nút không bao giờ lòi ra
ngoài, kể cả khi ai đó chỉnh số trong Inspector. `_road_sway()` và `_rebuild()` dùng chung `_zigzag()`.

**3. Nét nối DÀY HƠN** (`scripts/nodes/level_selection/level_path.gd`, đơn vị px canvas 540): `width_complete` 5 → **8** ·
`width_skipped` 4,5 → **7** · `width_upcoming` 4 → **6,5** · `width_locked` 3,5 → **5,5**; gạch đứt dài hơn cho khớp nét dày:
`dash_length` 10 → **15** · `dash_gap` 7 → **11**.

**3b. Bản NGANG: đường nối TỰ CẮT nhau (sửa tiếp cùng ngày).** Sau khi sửa mục 2, bản NGANG vẫn sai: các đoạn nối
"bóp" vào giữa rồi **cắt nhau thành hình chữ X**. Nguyên nhân: ở bản ngang 2 nút liền nhau lệch **640 px ngang / 200 px dọc**,
mà điểm uốn lại đặt **vuông góc** (trục Y, ±`sway`) ⇒ tiếp tuyến Catmull-Rom tại nút (tính trên khoảng cách lớn) quá lớn ⇒
đường vượt tầm và **tự cắt**. Probe đếm được **3 chỗ tự cắt** (độ võng thật 1527 px — không còn là đường nối nữa).
Sửa: thêm `sway_flat_ratio` — bản NGANG uốn rất nhẹ thay vì uốn vuông góc mạnh. Quét thử ở canvas 1635×920:

| `sway_flat_ratio` | sway | tự cắt | độ võng đoạn |
|---|---|---|---|
| 0,00 | 0 px | 0 | 28 px |
| 0,15 | 30 px | 0 | 30 px |
| **0,30** | **60 px** | **0** | **57 px** |
| 0,45 | 90 px | **3** | 86 px |
| 0,60 | 120 px | **3** | 114 px |

⇒ chọn **0,30** (có dáng uốn mà vẫn sạch). Đo lại sau sửa: bản ngang **0 chỗ tự cắt**, bản dọc giữ **0**; độ võng đoạn
dọc 69 px · ngang 57 px.

**4. Kiểm chứng.** Probe (headless, đặt `root.size` trực tiếp) sau khi sửa: **mọi cỡ DỌC** (canvas 540×960 · 717×920 ·
690×920) đều dùng bộ số DỌC (zigzag 74 · spacing 158 · sway 95), **nút TRÀN khung = 0/9**; cỡ NGANG (canvas 1635×920)
vẫn dùng bộ NGANG (zigzag 320 · spacing 200). Ảnh chụp máy thật: canvas 690×920 (đúng ca đã lỗi) khớp dáng mong muốn,
bản ngang (1920×1080) nay là **một đường uốn liền mạch** từ nút 2 → 3 → 4, không còn chữ X.
`test_levels_map` thêm mục **`_check_portrait_wide_column()`** (canvas 690×920 — khung "rộng hơn cao" — phải vẫn là bố cục
DỌC, nút trong khung, zigzag ≤ 120, spacing ≤ 180) và **`road_crossings()`** chặn đường TỰ CẮT ở cả 3 phép thử (dọc · ngang ·
dọc-rộng); thử phá (đặt `sway_flat_ratio = 0,6`) thì test **FAIL** đúng như thiết kế ("Duong noi TU CAT 5 cho").
Full suite headless **20/20 PASS**.

> **Bài học quy trình:** đừng sửa file nguồn có tiếng Việt bằng `Get-Content | Set-Content` của Windows PowerShell —
> nó đọc/ghi khác bảng mã và làm hỏng cả file. Lần này `test_localization` phát hiện ngay (báo `level_map.gd (63)` ký tự C1
> + 693 dấu mojibake) và file đã được `git checkout` rồi áp lại thay đổi bằng công cụ sửa file theo từng đoạn.

---

## 14. ĐA NGÔN NGỮ (LOCALIZATION) — CSV · CÔNG CỤ QUÉT · CHỐNG MOJIBAKE (v2.20, 2026-09-28)

**Yêu cầu user:** “tìm tất cả string cứng bên trong, đưa vào translate; String ID nào không dùng thì loại bỏ” — kèm sửa lỗi chữ bị **mojibake**.

### 14.1. Chuỗi lấy từ đâu (nguồn sự thật)

| File | Vai trò |
|---|---|
| `resources/localization/string.csv` | Bảng CHÍNH — 19 ngôn ngữ: `id,en,vi,zh_TW,zh_CN,es,ar,de,fr,hi,id,it,ja,ko,ms,pt,pt_BR,ru,th,tr` |
| `resources/localization/string_extra.csv` | Bảng PHỤ (`id,en,vi`) — nạp SAU nên **ghi đè** bản en/vi (1 ghi đè có chủ đích: `STR_DAILY_TOTAL_PROGRESS`) |
| `*.translation` | Do bộ nhập CSV của Godot sinh — chỉ là **ĐƯỜNG DỰ PHÒNG** cho build export (khi gói không kèm `.csv`) |

- `LocalizationManager` (autoload) **đọc thẳng CSV lúc chạy** ⇒ sửa chuỗi chỉ cần chạy lại game, KHÔNG cần Import lại trong editor.
  Nếu gói export không có `.csv`, manager tự nạp các file `<tên>.<locale>.translation` nằm cạnh CSV (`_load_translation_files()`).
- Ngôn ngữ mặc định `vi`; người chơi đổi trong Cài đặt → `SettingManager` khoá `locale`. `LOCALE_INFO` phải có ĐỦ 19 mã (thiếu ⇒ popup hiện mã thô + cờ `generic`).
- Quy ước khoá: `STR_<NHÓM>_<TÊN>`; **chuỗi có tham số phải `.format()`**, không cộng chuỗi — VD `STR_TUT_SUM_HUD_FORMAT` = `Tổng: {0}  |  Mục tiêu: = {1}`.

### 14.2. Chữ của UI lấy từ resource, không nhúng trong node

- **Thành tựu**: mỗi file `resources/archivements/*.tres` (**28 file**) thêm `title_key` + `desc_key` (`STR_ACH_*_TITLE` / `_DESC`); `title`/`desc` chữ cứng chỉ còn là phương án dự phòng.
- **Chương**: `resources/chapters/chapter_1..4.tres` + `scripts/resources/chapter_data.gd` thêm `@export title_key`/`subtitle_key` và **`display_title()` / `display_subtitle()`** ⇒ `chapter_card.gd` và `scenes/levels.gd` đọc qua 2 hàm này (đổi ngôn ngữ là đổi chữ ngay).
- **Scene**: 16 chỗ `text = "…"` chữ cứng đổi thành khoá dịch (`nodes/hud/**`, `nodes/game/cell.tscn`, HUD tutorial…).
- **Script**: chữ HUD/ô dùng `tr(khoá)` + `.format(...)` — VD `next_floor.gd` dùng `STR_RANK_POINTS` cho “0 PTS”, HUD tutorial dùng `STR_TUT_SUM_HUD_FORMAT`/`STR_TUT_WB_COUNTER_FORMAT` (cắt chuỗi quanh `{0}` để hiệu ứng đếm số `UIAnim.animate_counter` vẫn chạy ở mọi ngôn ngữ).

### 14.3. Bộ công cụ `tools/content/` (chạy bằng venv Python của project)

```bash
# 1) QUÉT + CHẶN HỒI QUY (exit 1 nếu vùng gác còn chuỗi cứng HOẶC còn khoá chết)
python tools/content/audit_localization.py --check --out=tmp_audit.txt
# 2) Xem / xoá khoá không dùng
python tools/content/audit_localization.py --unused
python tools/content/audit_localization.py --drop-unused
# 3) Sửa CSV bị mojibake (theo TỪNG Ô)
python tools/content/fix_mojibake.py
```

- `audit_localization.py`: quét `.gd/.tscn/.tres/.json/.py` trong `scripts/ scenes/ nodes/ resources/ tools/`; nhận diện khoá dùng trực tiếp + **họ khoá động** (`STR_X_%`, `STR_%02d` — chỉ tính từ file KHÔNG thuộc `tools/`); bỏ qua `.tres` đã có bạn `*_key`, bỏ qua chuỗi < 2 ký tự chữ (nên `'/%d ✓'` không bị báo oan).
- **Vùng GÁC (gated)** — chuỗi cứng ở đây làm `--check` **ĐỎ**: `scripts/nodes/tutorial/`, `scripts/nodes/hud/`, `nodes/hud/`, `nodes/tutorials/`, `nodes/game/cell.tscn`. Ngoài vùng gác (mockup/demo, `tools/`) chỉ liệt kê để dọn dần.
- **Kết quả hiện tại**: `KEY CHẾT HẮN 0` · `VÙNG GÁC 0 chuỗi cứng` · 198 chuỗi còn lại đều NGOÀI vùng gác · 14 khoá chỉ test dùng (giữ lại).

### 14.4. Vòng này đã làm gì (số liệu)

| Việc | Kết quả |
|---|---|
| Chuỗi cứng → khoá dịch | 16 chỗ trong scene + chữ HUD/ô/nút công cụ/HUD tutorial trong script |
| Thành tựu lấy chữ qua khoá | **28/28** `.tres` có `title_key` + `desc_key` |
| Chương lấy chữ qua khoá | **4/4** `.tres` + `display_title()/display_subtitle()` |
| Khoá mới thêm | **+73** dòng (`string_extra.csv`, en + vi) |
| Khoá chết đã xoá | **76** (`string.csv` 118→91 dòng · `string_extra.csv` 1282→1233 dòng) |
| Lỗi CSV thật đã sửa | 2 dòng thiếu dấu nháy (phá cột) · 1 khoá khai 2 lần (`STR_HUD_TIME`) |
| Mojibake | `string.csv` sửa ở **cả 19 ngôn ngữ** (kể cả ja/ko/zh/ar/th) |

### 14.5. 🐞 Bài học: CSV “hợp lệ UTF-8” mà chữ vẫn rác

- Triệu chứng: file vẫn là UTF-8 hợp lệ nhưng **nội dung** là chữ rác (`HẰNG NGÀY` → `Háº°NG NGÃ€Y`) — dấu hiệu UTF-8 bị đọc bằng CP1252/CP1258 rồi ghi lại; nặng hơn thì **2 lớp** (rác của rác).
- Vì sao codec chuẩn bó tay: byte `0x81` (C1 `U+0081`) **không có ánh xạ trong CP1252** ⇒ mọi vòng `encode/decode` bằng codec có sẵn đều lỗi/không hoàn tác được ⇒ phải dùng **bảng nghịch đảo tự viết đủ 256 byte**, chạy tối đa 2 lượt.
- Phải sửa theo **TỪNG Ô CSV** (không theo dòng/file): chỉ cần 1 ô không sửa được là cả dòng bị bỏ qua.
- Chỉ nhận kết quả khi **số dấu hiệu rác GIẢM**; và **kiểm chứng bằng hex dump file log đã redirect ra file** — scrollback của PowerShell có thể “dịch” sai khiến bạn tưởng đã hỏng/đã xong.
- ⚠️ Bẫy khi migrate hàng loạt: công cụ đổi `"chuỗi"` → `"STR_KHOÁ"` đã **đổi luôn TÊN NODE** `Submit` trong `nodes/hud/portrait/game/action_bar.tscn` (test bắt được ngay). Nếu viết lại tool: **chỉ thay trong dòng `text = "…"`**.

### 14.6. Hàng rào test — `scripts/test_case/test_localization.gd` (50 check)

1. CSV đúng dạng: đủ cột header, mọi dòng đủ ô, `id` đúng dạng `STR_…`, **không trùng khoá** giữa 2 file (trừ ghi đè có chủ đích), `en` không rỗng.
2. **Chống mojibake**: quét dấu hiệu rác (`á»`/`áº`/`Ä‘`/`Æ°`/`Æ¡`/`â€`) trong CSV lẫn `.tscn/.gd/.tres` + chặn ký tự điều khiển C1.
3. Mọi khoá `STR_…` dùng trong scene/code phải **có thật** trong CSV.
4. **Tên node không được là khoá dịch** (bẫy §14.5).
5. `title_key`/`desc_key` của thành tựu + chương phải trỏ tới khoá có thật.
6. `TranslationServer` trả chuỗi đã dịch thật (vi + en), **không trả lại khoá thô**.
7. `[INFO]` báo số khoá chưa dùng (không làm đỏ test).

⇒ Suite nay **15 test**: `… test_level_special_modes · test_localization` — **15/15 PASS**.

### 14.7. Còn lại

- **198 chuỗi cứng ngoài vùng gác** (chủ yếu scene mockup/demo + `tools/`) — muốn dọn thì mở rộng `GATED_PREFIXES`.
- 14 khoá chỉ test dùng: giữ tới khi dọn test.
- 17 ngôn ngữ còn lại mới chỉ được **sửa mã hoá**, chưa soát nghĩa (vòng này chỉ soát tay `en`/`vi`).
- ~~`scripts/scenes/tutorial.tscn` (chỉ là vỏ instance `scenes/tutorial.tscn`, không nơi nào tham chiếu)~~ — **đã xử lý 2026-10-23**: màn tutorial nay tách đôi (`scenes/tutorial_list.tscn` + `scenes/tutorial.tscn`), không còn file vỏ trùng tên (§10.2i).

---

## 15. EVENT SYSTEM — HỆ THỐNG SỰ KIỆN (v2.22, 2026-10-13; bổ sung 8 EventData mùa vụ)

**Yêu cầu (user):** thêm hệ thống Sự kiện (event) hiện thành **thẻ dọc** trong carousel Main Screen, có **theme riêng**, quản lý **thời hạn · tiến độ · phần thưởng** — và **thêm event mới KHÔNG phải sửa script** (data-driven).

### 15.1. Khái niệm

**Event** = nội dung có **thời hạn** (trừ Daily), hiện thành **1 thẻ dọc 340×504** trong carousel, có **theme riêng** (nền, màu, trang trí). Một event thuộc đúng 1 loại:

| `event_type` | Mô tả | Cách đo tiến độ (hiện bằng CHỮ, KHÔNG thanh) |
|---|---|---|
| `SPECIAL_SERIES` | Chuỗi màn dùng **luật Special** (mỗi màn khai `mode_id` trong `LevelData`) | `màn đã xong / tổng màn` + đơn vị `chế độ`/`màn` |
| `STANDARD_SERIES` | Chuỗi màn **chuẩn** (luật Play), có thể có biến thể | `đã xong / tổng` + `màn` |
| `DUNGEON` | Sự kiện trên **Dungeon**: hệ số thưởng + mốc tầng | `tầng cao nhất / tầng mốc cuối` + `tầng` |
| `LOGIN_STREAK` | Vào game mỗi ngày trong N ngày | `ngày đã đạt / N` + `ngày` |
| `DAILY` | **Daily Challenge** — event ẢO, **ghim đầu**, làm mới 00:00 giờ máy | `Sao hôm nay / 6` |

> **Daily KHÔNG bị viết lại.** `EventManager` tạo một `EventData` **ảo** (không phải file `.tres`) từ logic Daily có sẵn (`DailyManager`): tiến độ = **Sao của hôm nay** (`get_day_stars()` / `EventData.DAILY_STARS_TOTAL = 6` — 3 Sao CHƠI + 3 Sao THỬ THÁCH, xem §6).
> **Bấm thẻ Daily trên Main (2026-10-15):** mở **THẲNG** `scenes/daily.tscn` — `MainScene._on_event_card_pressed()` tra loại event qua `EventManager.get_event()` và định tuyến `type == DAILY` sang `Nav.goto_daily()`, các loại khác (kể cả `LOGIN_STREAK`) vẫn mở màn chi tiết `scenes/event.tscn`. Trước đây MỌI thẻ đều đi qua `Nav.goto_event()` nên bấm Daily lại mở màn Event (phải bấm thêm 1 lần ở CTA mới tới Daily) — `test_main_layout` nay gác: bấm thẻ Daily phải ra `res://scenes/daily.tscn`.

### 15.2. Dữ liệu (Resource, data-driven)

| Thư mục | Nội dung |
|---|---|
| `resources/events/themes/<theme_id>.tres` | `EventTheme` — gradient nền, art, màu chip/tiêu đề/panel/CTA |
| `resources/events/<event_id>.tres` | `EventData` — loại · theme · khoá chữ · thời hạn · màn · quà |
| `resources/levels/events/<event_id>/level_<n>.tres` | `LevelData` của màn event (id **1000+**, KHÔNG nằm trong danh sách chương) |

- `EventData`: `id · type · theme · sort_order · enabled · chip_key · title_key_1/2 · sub_key_1/2 · unit_key · cta_key · start_utc · end_utc · levels · dungeon_coin_multiplier · dungeon_milestones · login_days_required · rewards`.
- `EventReward`: `kind` (COIN · PEN_SKIN · AVATAR_FRAME · COIN_MULTIPLIER) · `amount` · `item_id` · `label_key`. Thẻ chỉ hiện **tối đa 2** phần thưởng.
- **Mọi chữ qua khoá dịch** (`STR_EVENT_<ID>_*`), không chữ cứng (§14).

**8 theme đang dùng bởi các event hiện có** (`theme_id` → art nền full-card):

| `theme_id` | Event | Nền (trên→dưới) | Tiêu đề | Viền tiêu đề | Art |
|---|---|---|---|
| `daily` | Daily Challenge (ghim đầu) | `#FFFDF8 → #FFF3EE` | `#A8323C` | `#FFFDF8` | `daily_card_background` |
| `halloween` | Đêm Mực Ma Quái | `#1B0B33 → #3B1668 → #220B3F` | `#FFFFFF` | `#2A0F4F` | `halloween_event_card_background` |
| `mansion` | Biệt Thự Ma Ám | `#0F2A2E → #0C1C20 → #070D0F` | `#BFFFDC` | `#04100F` | `haunted_house_card_background` |
| `tomb` | Thám Hiểm Mộ Cổ | `#FFE2A0 → #E7A95A → #3A210E` | `#4A2A0C` | `#FFF3D6` | `explore_pyramid_card_background` |
| `newyear` | Chào Năm Mới | `#C62828 → #B71C1C → #6D0E12` | `#FFE082` | `#6D0E12` | `chinese_new_year_card_background` |
| `april` | Màn Lộn Ngược | `#FFF176 → #FFC4EA → #FF9ADD` | `#3B0A45` | `#FFFFFF` | `april_fool_card_background` |
| `winter` | Mùa Tuyết Trắng | `#E3F4FF → #9CCDF4 → #6FA8E0` | `#0F2F5C` | `#FFFFFF` | `winter_card_background` |
| `dungeon` | Tuần Lễ Hầm Ngục | `#2A1E12 → #17120D` | `#FDE68A` | `#17120D` | `dungeon_card_background` |

*(Theme được khai trong `resources/events/themes/<theme_id>.tres`; `back_art` và `front_art` tham chiếu các lớp SVG nguồn trong `assets/images/events/`. Bảng màu tham chiếu spec `Agent_Spec_MainScreen_EventSystem.md` §B2.)*

**Màu tiêu đề theo theme (2026-10-14):** mỗi theme có cặp `title_color` / `title_outline` riêng, chọn theo tông thật của vùng chữ trên `*_card_background` — nền sáng dùng chữ đậm + viền sáng, nền tối dùng chữ sáng + viền đậm. Độ dày viền 5px (scene K=0.5). Không theme nào trùng cặp màu, và mọi cặp đạt tương phản chữ↔viền ≥ 4.5:1 (đo bằng `tools/run_tests.py test_event_manager`):

| Theme | Nền vùng chữ | `title_color` | `title_outline` |
|---|---|---|---|
| `daily` | sáng (giấy kẻ ô) | `#A8323C` | `#FFFDF8` |
| `halloween` | tối (tím/đen) | `#FFFFFF` | `#2A0F4F` |
| `mansion` | tối (xanh mực) | `#BFFFDC` | `#04100F` |
| `tomb` | sáng (cát) | `#4A2A0C` | `#FFF3D6` |
| `newyear` | tối (đỏ) | `#FFE082` | `#6D0E12` |
| `april` | sáng (vàng/hồng) | `#3B0A45` | `#FFFFFF` |
| `winter` | sáng (tuyết) | `#0F2F5C` | `#FFFFFF` |
| `dungeon` | tối (nâu/hầm) | `#FDE68A` | `#17120D` |
| `anniversary` | tối (tím đêm) | `#D9C6FF` | `#3A1A55` |
| `autumn` | tối (nâu) | `#FFCFA0` | `#2B0F03` |
| `easter` | sáng (kem/lục) | `#12472A` | `#FFFBEC` |
| `new_year` | tối (xanh đêm) | `#CFE8FF` | `#06122E` |
| `spring` | sáng (xanh băng) | `#6D1639` | `#FFFFFF` |
| `summer` | sáng (lam) | `#06384A` | `#FFF6DE` |
| `thanksgiving` | tối (nâu) | `#FFB65C` | `#2E0B03` |
| `valentine` | tối (hồng đậm) | `#FFD3E0` | `#4A0A22` |

**Event mùa vụ bổ sung (2026-10-13):** artwork được tách thành SVG `*_card_background.svg` + `*_card_frontground.svg` khi có foreground. Tám theme mới hiện đã có `EventTheme` và `EventData` tương ứng. Các event mới đều là chuỗi màn đang được hỗ trợ; mỗi event dùng ba `LevelData` đã có, có thưởng xu và lịch UTC:

| Event / `theme_id` | Loại | Thời gian UTC | Tiến độ | Thưởng xu |
|---|---|---|---|---|
| `anniversary` | `STANDARD_SERIES` | 2027-06-01 → 2027-06-15 | 3 màn | 500 + 150 |
| `autumn` | `STANDARD_SERIES` | 2026-11-08 → 2026-11-22 | 3 màn | 300 + 100 |
| `easter` | `SPECIAL_SERIES` | 2027-03-26 → 2027-04-05 | 3 màn | 350 + 150 |
| `new_year` | `STANDARD_SERIES` | 2027-01-11 → 2027-01-25 | 3 màn | 400 + 200 |
| `spring` | `SPECIAL_SERIES` | 2027-04-20 → 2027-05-04 | 3 màn | 350 + 150 |
| `summer` | `STANDARD_SERIES` | 2027-07-01 → 2027-07-15 | 3 màn | 400 + 200 |
| `thanksgiving` | `STANDARD_SERIES` | 2026-11-23 → 2026-12-01 | 3 màn | 350 + 150 |
| `valentine` | `SPECIAL_SERIES` | 2027-02-10 → 2027-02-20 | 3 màn | 350 + 150 |

Mốc bắt đầu/kết thúc dùng thời gian UTC ISO-8601; event bị ẩn khi giờ hiện tại vượt qua mốc kết thúc. `new_year` (event chuỗi màn tháng 1) khác `newyear` (event đăng nhập dịp Tết đã có). `LOGIN_STREAK` chưa dùng cho event mới vì luồng CTA/lịch nhận thưởng của loại này hiện chưa được triển khai.

**16 event đã cấu hình (bao gồm Daily ảo):** `halloween` (SPECIAL_SERIES 5 màn · luật `no_move_overlapped`/`move_limit`/`walk_number_only`/`countdown`/`backtrack_limit`) · `mansion` (STANDARD_SERIES 6) · `tomb` (SPECIAL_SERIES 4) · `newyear` (LOGIN_STREAK 7 ngày) · `april` (STANDARD_SERIES 6, luật biến thể) · `winter` (STANDARD_SERIES 10) · `dungeon` (DUNGEON, x2 Xu, mốc 5·10·15·20·25) · `daily` (ảo) · `anniversary` · `autumn` · `easter` · `new_year` · `spring` · `summer` · `thanksgiving` · `valentine`.

### 15.3. `EventManager` (autoload — `scripts/manager/EventManager.gd`)

```gdscript
signal events_changed
signal event_progress_changed(event_id: StringName)
signal event_expired(event_id: StringName)

func get_active_events() -> Array[EventData]   # Gameplay: event đang hoạt động; Daily ĐẦU → sort_order → hạn gần nhất
func get_all_events_for_preview() -> Array[EventData] # Xem thử: toàn bộ dữ liệu, không lọc thời hạn/enabled
func get_event(id) -> EventData
func get_progress(id) -> Dictionary            # {done, total, unit_key, completed, claimed}
func seconds_left(id) -> int
func on_level_won(event_id, level, stars) -> void
func on_dungeon_floor_cleared(floor_idx) -> void
func on_app_day_started() -> void
func can_claim(id) -> bool
func claim_reward(id) -> bool                  # idempotent
func get_dungeon_coin_multiplier() -> float
func now_utc() -> int                          # nguồn thời gian DUY NHẤT (đổi sang giờ server ở giai đoạn 2)
```

Quy tắc:
- **Nạp event:** quét `res://resources/events/*.tres` lúc khởi động (đọc thư mục, KHÔNG liệt kê cứng). Event lỗi (thiếu `theme`, series rỗng, `end < start`) → **bỏ qua + `push_warning`**, không crash.
- **Lưu tiến độ:** qua `SaveManager` (`export_progress`/`import_progress`), khoá `events: { "<id>": {done_levels, best_floor, login_days, claimed} }`; lưu NGAY sau mỗi thay đổi; dọn bản ghi hết hạn quá **30 ngày**.
- **Phát quà:** Xu qua `ShopManager.add_coins()` (idempotent vì `claim_reward` chặn lần 2); `COIN_MULTIPLIER` áp cho Dungeon đang chạy.
- **Chống chỉnh giờ máy:** giai đoạn 2 (ghi chú trong `now_utc()`).

### 15.4. Luồng chơi từng loại

| Loại | Bấm CTA | Trong game | Xong |
|---|---|---|---|
| `SPECIAL_/STANDARD_SERIES` | Vào màn **chưa xong đầu tiên** của event (hết → nhận quà) | `GameManager.start_level_from_event(level, event_id)` → chạy `game.tscn`; `LevelData.mode_id` quyết định luật | Gọi `EventManager.on_level_won()`; **KHÔNG ghi Sao/mở khoá** vào mạch chương thường |
| `DUNGEON` | Vào Dungeon bình thường | `get_dungeon_coin_multiplier()` nhân Xu mỗi tầng | Qua mốc tầng ghi `best_floor`; đạt mốc cuối → nhận quà |
| `LOGIN_STREAK` | (giai đoạn 2: popup lịch N ngày) | — | Đủ N ngày → nhận quà |
| `DAILY` | Mở luồng Daily hiện tại | Không đổi | Không đổi |

### 15.5. UI

| File | Vai trò |
|---|---|
| `scripts/nodes/event_card_base.gd` (`EventCardBase`) | **Phần CHUNG của 2 loại thẻ** (v2.31): tỉ lệ khung (`ratio` → `custom_minimum_size.x`), bấm/kéo để phát `card_pressed` (ngưỡng 12px, bỏ qua khi bấm trúng CTA), vòng đời `setup(data, preview)` → `_apply_card()` + `Timer` làm mới, và 5 helper tô màu theo `EventTheme` (`_paint_background/chip/title/panel/cta`). Lớp con override `_apply_card()`, `_cta_node()`, `_timer_node()`, `_refresh_live()` |
| `nodes/main/event_card.tscn` + `scripts/nodes/event_card.gd` (`EventCard`) | Thẻ **SỰ KIỆN THẬT** 340×504: nền gradient + lưới ô ly → `BackArt` (art theme) → chip theme + chip thời gian (icon đồng hồ **vẽ**, không emoji) → tiêu đề 2 dòng với màu/viền tương phản theo theme (outline 5px ở viewport K=0.5) → phụ đề 2 dòng → panel tiến độ (`x / y` + đơn vị + tối đa 2 phần thưởng) → nút CTA. Đếm ngược bằng `Timer` 45s (≥48h → ngày · ≥1h → giờ · <1h → phút). Trạng thái `normal/pressed/completed/claimed/locked`. **KHÔNG còn lá lịch Daily** |
| `nodes/main/daily_card.tscn` + `scripts/nodes/daily_card.gd` (`DailyCard`) | Thẻ **THỬ THÁCH HẰNG NGÀY** (event ẢO, ghim đầu carousel) — cùng khung 340×504 nhưng nội dung riêng: chip theme + chip **giờ còn lại tới 00:00**, **LÁ LỊCH** (tháng / ngày / thứ lấy từ giờ máy), tiêu đề 2 dòng, panel **`★ x/6` Sao hôm nay** (3 Sao CHƠI + 3 Sao THỬ THÁCH), CTA đỏ theo theme `daily` |
| `nodes/main/event_carousel.tscn` + `scripts/nodes/event_carousel.gd` | `ScrollContainer` ngang (ẩn thanh cuộn) → HBox khe 18 → danh sách gameplay hoặc toàn bộ dữ liệu khi `show_all_events_for_preview` bật; **chọn scene theo loại**: `type == DAILY` → `daily_card_scene` (`DailyCard`), còn lại → `event_card_scene` (`EventCard`); **snap theo trang** khi thả tay; rỗng/1 thẻ → canh giữa + ẩn chấm |
| `nodes/main/event_dots.tscn` + `scripts/nodes/event_dots.gd` | Tạo chấm từ `event_dot.tscn` theo đúng số trang; chấm đang chọn dài 15, còn lại 5 (scene scale K=0.5) |
| `nodes/main/event_header.tscn` + `scripts/nodes/event_header.gd` | Tiêu đề khối Sự kiện + badge cam số event đang mở + link "Xem tất cả" (giai đoạn 1 ẩn) |
| `scenes/event.tscn` + `scripts/scenes/event.gd` + `scenes/layout/{portrait,landscape}/event.tscn` + `scripts/scenes/layout/event_layout.gd` | Màn chi tiết event (2 hướng, cùng tên node): tiêu đề · phụ đề · đếm ngược · tiến độ · CTA · nút Back. Nhận `event_id` qua `SceneManager.goto_event()/consume_pending_event_id()` |

### 15.6. Quy trình thêm 1 event mới (không cần sửa script)

1. Vẽ art nền → `assets/images/events/<theme_id>_card_background.svg` → `python tools/svg_to_png.py --only <theme_id>_card_background` → mở Godot 1 lần để import PNG.
2. Tạo `resources/events/themes/<theme_id>.tres` (`EventTheme`: màu + art).
3. (Nếu là series) tạo `LevelData` cho từng màn → `resources/levels/events/<event_id>/level_<n>.tres` (id **1000+**).
4. Tạo `resources/events/<event_id>.tres` (`EventData`: loại · theme · khoá chữ · thời hạn · màn · quà).
5. Thêm các khoá `STR_EVENT_<ID>_*` (chip/title/sub/cta/reward) vào `resources/localization/string_extra.csv` (en/vi) → chạy `godot --headless --import` để sinh lại `.translation`.
6. Mở game: thẻ **tự xuất hiện** đúng thời hạn. **Nếu phải sửa `.gd` để thêm event ⇒ thiết kế sai.**

### 15.7. Kiểm thử

`scripts/test_case/test_event_manager.gd` (**33 check**): lọc theo thời gian + `enabled` · Daily luôn đầu + sắp xếp `sort_order` · tiến độ series (thắng lại không cộng) · `claim_reward` idempotent (Xu cộng đúng 1 lần) · Dungeon (hệ số xu trong/ngoài hạn + mốc `best_floor`) · login streak 1 lần/ngày · dữ liệu lỗi bị bỏ qua · lưu/nạp giữ tiến độ.
Đã thêm vào bộ mặc định `tools/run_tests.py` ⇒ suite mặc định **20 test, 20/20 PASS**.
Harness đa tỉ lệ: `dev_aspects.gd -- --only=main,event` **20/20 OK** (màn `event` đã thêm vào danh sách `SCREENS`).

### 15.8. Còn lại (giai đoạn 2)

- **LOGIN_STREAK**: popup **lịch N ngày** (ô đã/chưa/hôm nay + nút NHẬN LÌ XÌ) chưa dựng — CTA hiện là no-op (chưa có màn riêng).
- **Phần thưởng vật phẩm**: `PEN_SKIN`/`AVATAR_FRAME` chưa phát (chưa có item trong shop/profile) ⇒ 8 event đang ship **toàn bộ quà = Xu**.
- **Hệ số xu Dungeon**: `EventManager.get_dungeon_coin_multiplier()` đã có, nhưng ván Dungeon hiện **chưa cộng Xu theo tầng** ⇒ hệ số chưa có chỗ áp (chỉ ghi mốc tầng/`best_floor`).
- **"TIẾP TỤC EVENT"** trên popup kết quả (§B7) chưa thêm; `EventListScreen` (lưới tất cả + event đã kết thúc) chưa làm ⇒ link "Xem tất cả" đang ẩn.
- **Chống chỉnh giờ máy** (server time) — giai đoạn 2, đã cô lập trong `EventManager.now_utc()`.
- **Khoá dịch thừa**: bỏ thẻ Daily/tờ giấy khỏi Main khiến **7 khoá** cũ thành chết (`STR_TAG_MAIN_MODE` · `STR_TAG_ENDLESS_MODE` · `STR_TAG_DAILY_MODE` · `STR_STREAK_BADGE` · `STR_GAME_TAGLINE` · `STR_MAIN_PROFILE` · `STR_MAIN_PROFILE_HINT`) — `tools/content/audit_localization.py` báo trong mục "KEY CHẾT HẲN" (bộ này VỐN ĐÃ có khoá chết từ trước v2.21 nên `--check` vốn đã trả 1; chưa dọn vì có nhóm khoá theo tiền tố `STR_MODE_<id>_…` dùng bằng cách ghép chuỗi — xoá nhầm sẽ hỏng chữ của chế độ).
