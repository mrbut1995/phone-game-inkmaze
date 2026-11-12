class_name EventBoardSkin
extends Resource
## ============================================================================
## Resource: Bộ ART + MÀU của BÀN CHƠI cho một Sự kiện kiểu Dungeon (có giới hạn tầng).
## Mỗi event = 1 file .tres trong data/events/skins/, gắn vào `EventTheme.board_skin`.
## Thêm event mới chỉ cần đổi texture trong .tres — KHÔNG sửa script (data-driven).
##
## Ô trống (null) = giữ nguyên art mặc định của game cho phần đó.
## Kích thước art giữ ĐÚNG như bộ gốc: ô 88×88 · neo 27×27 · card_board 505×508.
## ============================================================================

## Ảnh nền toàn màn hình (phủ kín, giữ tỉ lệ — cắt phần thừa)
@export var background: Texture2D = null

## Tấm bảng chứa mê cung (NinePatch — cùng patch margin với card_board gốc)
@export var card_board: Texture2D = null

@export_group("Ô (cell)")
@export var cell_normal: Texture2D = null
@export var cell_pressed: Texture2D = null
@export var cell_disabled: Texture2D = null
@export var cell_start: Texture2D = null
@export var cell_finish: Texture2D = null
## Ô ĐÍCH khi còn bị khoá (đã có ổ khoá vẽ sẵn trong art)
@export var cell_finish_closed: Texture2D = null
## Ô thường bị khoá (ổ khoá + xích vẽ sẵn trong art)
@export var cell_locked: Texture2D = null
@export var icon_key: Texture2D = null
@export var icon_lock: Texture2D = null

@export_group("Neo (anchor)")
@export var anchor_normal: Texture2D = null
@export var anchor_focus: Texture2D = null
@export var anchor_pressed: Texture2D = null
@export var anchor_selected: Texture2D = null
@export var anchor_disabled: Texture2D = null

@export_group("Bố cục")
## Chừa biên TRONG tấm bảng (tỉ lệ so với phần bảng đặc): trái, trên, phải, dưới — lưới ô chỉ nằm
## trong vùng này. Vector4.ZERO = giữ biên mặc định của game (BoardView.PAPER_INSET).
@export var paper_inset: Vector4 = Vector4.ZERO

@export_group("Màu")
## Màu tiêu đề + dòng phụ trên thanh trên của màn chơi (nằm thẳng trên ảnh nền)
@export var title_color: Color = Color(0.38, 1.0, 0.72, 1.0)
@export var subtitle_color: Color = Color(0.75, 1.0, 0.88, 1.0)
## Màu số trên ô (nền ô tối ⇒ chữ sáng)
@export var cell_text_color: Color = Color(0.86, 0.98, 0.93, 1.0)
## Viền chữ số (alpha 0 = không viền)
@export var cell_text_outline: Color = Color(0.02, 0.09, 0.1, 1.0)
## Màu mực nét đi của người chơi (thay màu bút trong Shop khi chơi event)
@export var ink_color: Color = Color(0.45, 1.0, 0.76, 1.0)
## Màu đoạn tường thật lộ ra khi đâm trúng
@export var wall_color: Color = Color(0.74, 0.92, 0.86, 1.0)
## Quầng sáng sau nét đánh dấu tường
@export var wall_halo_color: Color = Color(0.03, 0.1, 0.11, 0.9)
