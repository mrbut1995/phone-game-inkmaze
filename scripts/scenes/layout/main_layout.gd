class_name MainLayout
extends BaseLayout
## ============================================================================
## Layout: Main Screen — node UI bind sẵn cho cả 2 bố cục (Portrait / Landscape).
## Script màn chỉ đọc `layout.<tên>` (xem scripts/scenes/main.gd).
##
## Bố cục mới (§A): thanh trên (hồ sơ · Xu · Sao · Cài đặt) + khối Sự kiện
## (header + carousel) + 2 thẻ chế độ (Play · Dungeon) + dock 4 nút.
## ============================================================================

## Logo/tiêu đề game (nhỏ, đầu màn)
@export var logo: TextureRect = null
## Khối hồ sơ (avatar · cấp · tên · thanh XP) — bấm mở popup Hồ sơ
@export var profile_card: ProfileCard = null
## Ví Xu Mực (+ nút `+` mở Cửa hàng)
@export var coin_chip: CoinChip = null
## Tổng Sao
@export var star_chip: StarChip = null
## Nút Cài đặt (bánh răng) — dời lên thanh trên
@export var btn_settings: BaseButton = null
## Tiêu đề khối Sự kiện (badge số event + "Xem tất cả")
@export var event_header: EventHeader = null
## Carousel thẻ sự kiện (Daily ghim đầu)
@export var event_carousel: EventCarousel = null
## Thẻ chế độ Play (chọn màn)
@export var card_play: ModeCard = null
## Thẻ chế độ Dungeon (vô tận)
@export var card_dungeon: ModeCard = null
## Dock: Cửa hàng
@export var dock_shop: DockButton = null
## Dock: Bảng xếp hạng
@export var dock_ranking: DockButton = null
## Dock: Sổ tay thành tựu (danh hiệu)
@export var dock_badges: DockButton = null
## Dock: Luật chơi (Tutorial)
@export var dock_rules: DockButton = null
## Con dấu phiên bản
@export var stamp_panel: Control = null
@export var stamp_label: Label = null
## Khối 2 thẻ chế độ (dùng cho hiệu ứng trượt)
@export var mode_box: Control = null
