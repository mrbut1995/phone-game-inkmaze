class_name MainLayout
extends BaseLayout
## ============================================================================
## Layout: Main Screen — node UI bind sẵn cho cả 2 bố cục (Portrait / Landscape).
## Script màn chỉ đọc `layout.<tên>` (xem scripts/scenes/main.gd).
##
## Bố cục GỘP: thanh trên (hồ sơ · Xu · Sao · Cài đặt)
## + KHỐI BẢN ĐỒ MÀN CHƠI (`LevelSection`: bản đồ · chip chương
## · rương mốc · nút Dungeon nổi) + dock 4 nút (Cửa hàng · Xếp hạng · Thử thách · Danh hiệu).
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
@export var btn_settings: TextureButton = null
## Tiêu đề khối Sự kiện (badge số event + "Xem tất cả")
@export var event_header: EventHeader = null
## Carousel thẻ sự kiện (Daily ghim đầu)
@export var event_carousel: EventCarousel = null
## Khối bản đồ màn chơi (nodes/main/level_section.tscn) — chứa cả chip chương, rương, nút Dungeon nổi
@export var level_section: LevelSection = null
## Dock: Cửa hàng
@export var dock_shop: DockButton = null
## Dock: Bảng xếp hạng
@export var dock_ranking: DockButton = null
## Dock: Sổ tay thành tựu (danh hiệu)
@export var dock_badges: DockButton = null
## Dock: Thử thách hằng ngày (nút giữa, mở màn Daily)
@export var dock_daily: DockButton = null
## Con dấu phiên bản
@export var stamp_panel: Control = null
@export var stamp_label: Label = null


## Thẻ hồ sơ bị bấm (dây nối trong `.tscn` của layout) — màn Main mở popup hồ sơ
signal profile_pressed


func _on_profile_card_pressed() -> void:
	profile_pressed.emit()
