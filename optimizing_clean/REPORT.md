# BÁO CÁO TỐI ƯU ASSET — ĐỢT 2 (Trùng art, khác size)

Ngày: 2026-09-25 · Người thực hiện: GitHub Copilot

## 1. Mục tiêu

Tìm các asset **cùng nội dung vẽ (cùng art) nhưng khác kích thước/viewBox**.
Quy tắc: giữ bản **to nhất**, bản nhỏ hơn đưa vào `optimizing_clean/duplicate/`.
Những chỗ asset thay thế được dùng bởi Texture (TextureRect / TextureButton / TextureProgressBar)
thì phải đổi sang **9-slice** để không bị bóp méo khi stretch.

⚠️ **LƯU Ý KỸ THUẬT QUAN TRỌNG**: class **`NinePatchTexture` KHÔNG tồn tại** trong Godot 4.7.2
(thử dùng thì scene lỗi parse: *Can't create sub resource of type 'NinePatchTexture'*) ⇒ đã dùng 3 cơ chế 9-slice THẬT của engine:

| Loại node | Cách 9-slice | Chi tiết |
|---|---|---|
| `TextureRect` | **đổi node sang `NinePatchRect`** | texture + `patch_margin_left/top/right/bottom` ngay trên node |
| `TextureProgressBar` | **`nine_patch_stretch = true`** | + `stretch_margin_left/top/right/bottom` (thuộc tính sẵn có) |
| `TextureButton` | **đổi sang `Button` + `StyleBoxTexture`** | `theme_override_styles/{normal,hover,pressed,focus}` = StyleBoxTexture (có `texture_margin_*`) |

Kèm theo: `scripts/nodes/popups/base.gd::bind_button()` nhận `BaseButton` (trước là `TextureButton`),
`winning.gd`/`winning_daily.gd` đổi type biến nút sang `BaseButton`, `language_row.gd` `extends Button`,
`test_popup_ui.gd`/`test_daily.gd`/`test_level_progression.gd` cập nhật theo.

## 2. Kết quả: 12 nhóm trùng art, khác size

| # | Giữ lại (to hơn) | Đã đưa vào `optimizing_clean/duplicate/` (nhỏ hơn) | Nơi dùng đã sửa | Cách sửa |
|---|---|---|---|---|
| 1 | `archivements/stamp_claimed.svg` (62.5×37) | `archivements/stamp_badges.svg` (75×23) | `scenes/archivement.tscn`, `scenes/layout/{portrait,landscape}/archivement.tscn` → `Sheet/Footer/Stamp/Bg` | Node vốn là `NinePatchRect` → chỉ đổi texture, giữ patch margin 7/4/8/5 |
| 2 | `game/card_wall_slider_track.svg` (200×7) | `calendar/progress_bar_bg.svg` | `scenes/layout/{portrait,landscape}/daily.tscn` → `TextureProgressBar.texture_under` | `nine_patch_stretch = true` + stretch margin **4/2/4/2** |
| 3 | `game/card_wall_slider_fill.svg` (200×7) | `calendar/progress_bar_fill.svg` | `scenes/layout/{portrait,landscape}/daily.tscn` → `texture_progress` | `nine_patch_stretch = true` + stretch margin **4/2/4/2** |
| 4 | `calendar/tag_special_mode.svg` (67.5×12) | `game/chip_price_pricey.svg` | `nodes/hud/{portrait,landscape}/game/countdown_hud.tscn` → `Bg` | **TextureRect → NinePatchRect**, margin **8/4/8/4** |
| 5 | `game/card_stroke_slider_track.svg` (205×7) | `chapters/bar_track.svg` | `nodes/chapters/chapter_card.tscn` → `Bar/Track` | **TextureRect → NinePatchRect**, margin **4/2/4/2** |
| 6 | `chapters/chip_need.svg` (97.5×16) | `shop/chip_red.svg` | `nodes/shop/noads_row.tscn` → `Badge` (NinePatchRect) | Đổi texture + chỉnh patch margin 4/4/4/4 → **8/5/8/5** |
| 7 | `popups/btn_popup_wide_normal.svg` (315×48) | `common/btn_paper_primary_normal.svg` | `nodes/popups/winning.tscn` (`NextBtn`), `winning_daily.tscn` (`DailyBtn`) | **TextureButton → Button**, StyleBoxTexture margin **18/12/18/12** (normal+hover dùng art mới; pressed/focus giữ art cũ) |
| 8 | `game/card_stroke_slider_fill.svg` (205×7) | `game/card_stroke_chip.svg` | `nodes/hud/{portrait,landscape}/game/one_stroke_hud.tscn` → `Chip` | **TextureRect → NinePatchRect**, margin **4/2/4/2** |
| 9 | `popups/box_dungeon_bonus.svg` (324×59) | `popups/lang_item_selected.svg` | `nodes/popups/language_row.tscn` → hàng ngôn ngữ (trạng thái ĐANG CHỌN) | **TextureButton → Button**, StyleBoxTexture margin **20/14/20/14** |
| 10 | `popups/btn_popup_muted_normal.svg` (150×44) | `popups/btn_lang_cancel_normal.svg` | `nodes/popups/language.tscn` → `Cancel` | **TextureButton → Button**, StyleBoxTexture margin **16/12/16/12** |
| 11 | `settings/row_button_focus.svg` (363×48) | `popups/lang_item_focus.svg` | `nodes/popups/language_row.tscn` → focus ring của hàng ngôn ngữ | **TextureButton → Button**, StyleBoxTexture margin **20/14/20/14** |
| 12 | `popups/stamp_done.svg` (80×45) | `popups/stamp_excellent.svg` (78×45) | `nodes/popups/winning.tscn`, `winning_daily.tscn` → `Stamp` | **TextureRect → NinePatchRect**, margin **10/8/10/8** |

Ghi chú:
- File nhỏ hơn được đưa vào `optimizing_clean/duplicate/` **giữ nguyên cấu trúc path** (kèm `.import`), ví dụ
  `assets/images/calendar/progress_bar_bg.svg` → `optimizing_clean/duplicate/assets/images/calendar/progress_bar_bg.svg`.
- Đã tạo lại `optimizing_clean/.gdignore` (bị xoá cùng lúc bạn dọn đợt 1) để Godot không import thư mục này.
- Nhóm 12: `popups/stamp_done.svg` trước đây **không được dùng trực tiếp ở đâu** (các chỗ khớp tên là
  `level_selector/stamp_done_completed.svg` — file khác), nên thực tế nhóm này là "lấy file to hơn đang bỏ không".
- Gặp lỗi `.tscn`: mọi `[ext_resource]` phải khai TRƯỚC `[sub_resource]` (khối StyleBoxTexture ban đầu đặt sai chỗ
  làm 2 popup báo *Unknown tag 'ext_resource'*) — đã sửa, hiện cả 46 scene load sạch.

## 3. Những chỗ tôi cần bạn kiểm tra/chỉnh lại (TODO)

1. **Margin 9-slice** — chọn theo bo góc ước lượng của art. Nếu thấy góc bị kéo giãn/bị cắt:
   - `NinePatchRect`: sửa `patch_margin_*` trong `.tscn` tương ứng (bảng trên ghi rõ margin đang dùng).
   - `Button`: sửa `texture_margin_*` trong các `[sub_resource type="StyleBoxTexture"]` (`Sb_pri_n`, `Sb_sec_n`, `Sb_row_*`).
   - `TextureProgressBar`: sửa `stretch_margin_*` trên node ProgressBar.
2. **Nhóm 7 & 10 (button)** — chỉ state `normal`/`hover` (và `pressed`/`focus` giữ art cũ) được trộn art mới;
   cần xem màu/độ sáng có lệch giữa các state không; nếu lệch thì thay luôn các state còn lại theo cùng art.
3. **Nhóm 2 & 3 (thanh tiến độ Daily)** — kiểm tra lúc 0% và 100% còn bo tròn đúng không.
4. **Nhóm 4 (countdown HUD)** — chip "pricey" giờ dùng art `tag_special_mode` (dạng tag dài hơn);
   kiểm tra nội dung/màu có hợp ngữ cảnh giá.
5. **Nhóm 1** — stamp màn Achievement đổi từ art `stamp_badges` sang `stamp_claimed`;
   tỉ lệ 2 art khác nhau (62.5×37 vs 75×23) nên có thể phải chỉnh lại margin/`axis_stretch`.
7. **Nút đã đổi từ `TextureButton` → `Button`** (NextBtn, DailyBtn, Cancel, hàng ngôn ngữ):
   Button dùng style của theme cho text/font — nếu muốn thêm state `disabled` thì cần thêm `theme_override_styles/disabled`.

## 4. Đã kiểm chứng

- Không còn tham chiếu nào (theo path hoặc uid) tới 12 asset đã move; không còn `NinePatchTexture` nào trong project.
- Cả 46 scene liên quan load sạch (`ResourceLoader.load` không lỗi) — kiểm bằng script tạm (đã xoá).
- `godot --headless --path . --import`: không có lỗi.
- Full test suite **13/13 PASS** (test_popup_ui, test_daily, test_level_progression… đã cập nhật theo Button/BaseButton).
