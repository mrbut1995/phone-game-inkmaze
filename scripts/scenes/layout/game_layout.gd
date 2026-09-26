class_name GameSceneLayout
extends BaseLayout
## ============================================================================
## BỐ CỤC MÀN CHƠI — khai UI của TỪNG HƯỚNG ngay trong .tscn và BIND SẴN bằng `@export`:
##   · `status_bar`  — thanh trạng thái (Nút tạm dừng · Tên màn · Hướng dẫn)
##   · `hud_slot`    — khung chứa HUD của chế độ đang chơi (HUD đổi bằng code)
##   · `board_holder`— chỗ dành sẵn cho BÀN CỜ DÙNG CHUNG (GameScene tự gắn vào khi xoay màn hình)
##   · 2 nút trên thanh trạng thái + 2 nhãn (Tên màn · Phụ đề)
##     (nút CHƠI LẠI / RESET đã dời xuống THANH HÀNH ĐỘNG trong HUD — xem ActionBar.restart_btn)
##
## GameScene đọc `layout.<tên>` — KHÔNG tra đường dẫn. Phần KHÁC NHAU giữa 2 hướng vẫn nằm ở
## script riêng của từng hướng, cả hai đều kế thừa class này:
##   · `scripts/layout/portrait/game.gd`          (kế thừa, không đặt class_name)
##   · `scripts/layout/landscape/game_layout.gd`  (class_name `GameLayout`)
## gồm: `is_landscape_layout()` · `hud_variant()` · `mount_board()` · `fit_hud()` · `board_slot()`.
## ============================================================================

@export var status_bar: Control = null
@export var hud_slot: Control = null
@export var board_holder: Control = null
@export var pause_btn: BaseButton = null
@export var instruction_btn: BaseButton = null
@export var level_label: Label = null
@export var subtitle_label: Label = null
