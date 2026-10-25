class_name ArchivementLayout
extends BaseLayout

@export var btn_back: BaseButton = null
@export var overview_bar: Control = null
## Bản DỌC dùng TextureRect, bản NGANG dùng NinePatchRect ⇒ khai kiểu chung `Control`
@export var overview_fill: Control = null
@export var overview_pct: Label = null
@export var overview_summary: Label = null
@export var tabs_box: Container = null
@export var card_area: Control = null
@export var scroll: ScrollContainer = null
@export var pages_host: HBoxContainer = null
@export var dots_box: HBoxContainer = null
@export var empty_label: Label = null
@export var stamp_label: Label = null

# ---------------------------------------------------------------------------
# Tuỳ biến theo bố cục (bản NGANG để mặc định ⇒ chạy y như cũ)
# Bản DỌC "thẻ bài lớn" (G) khai các giá trị này trong scenes/layout/portrait/archivement.tscn
# ---------------------------------------------------------------------------
## Scene thẻ riêng cho bố cục. null ⇒ dùng `ArchivementScene.CARD_SCENE`
@export var card_scene: PackedScene = null
## > 0 ⇒ ghim số thẻ mỗi trang (bố cục G: 1 thẻ/trang). 0 ⇒ màn tự tính như cũ
@export var cards_per_page := 0
## > 0 ⇒ bề rộng 1 trang (thẻ + khe) thay vì bằng khung nhìn — để lộ rìa thẻ hai bên.
## Màn tự chèn đệm 2 đầu để thẻ đầu/cuối vẫn nằm GIỮA khung.
@export var page_width := 0.0
## Hiệu ứng "thẻ bên cạnh nhỏ + mờ + nghiêng" khi page_width > 0
@export_range(0.5, 1.0) var peek_scale := 0.86
@export_range(0.0, 1.0) var peek_alpha := 0.6
@export var peek_tilt := 0.09

## Dải ảnh thu nhỏ (thay cho chấm trang). null ⇒ dùng `dots_box` như cũ
@export var thumbs_box: HBoxContainer = null
@export var thumb_scene: PackedScene = null
@export var thumb_count := 7
