class_name EventHeader
extends Control
## ============================================================================
## Node: EventHeader — tiêu đề khối Sự kiện trên Main Screen.
## Badge cam hiện SỐ event đang mở (kể cả Daily); link "Xem tất cả" (giai đoạn 1
## có thể ẩn — xem §B5).
## ============================================================================

signal view_all_pressed

## Bề rộng tối thiểu của cụm chấm phân trang khi dời cạnh badge số event.
## Đủ chỗ cho ~6 chấm (chấm 5 px + nhịp 4 px); dư thì `Dots` tự căn giữa.
const DOTS_MIN_WIDTH := 54.0  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)

@onready var title_label: Label = $Title
@onready var count_label: Label = $Badge/CountLabel
@onready var view_all: Button = $ViewAll


## Dây `ViewAll.pressed` khai trong nodes/main/event_header.tscn
func _on_view_all_pressed() -> void:
	view_all_pressed.emit()


## Số event đang mở (hiện trên badge cam)
func set_count(count: int) -> void:
	if count_label != null:
		count_label.text = str(count)


## Ẩn/hiện link "Xem tất cả" (giai đoạn 1 ẩn)
func set_view_all_visible(shown: bool) -> void:
	if view_all != null:
		view_all.visible = shown


## Gắn CHẤM PHÂN TRANG của carousel vào ngay cạnh badge số event (thay vì dưới carousel).
## EventCarousel vẫn tự cập nhật chấm qua tham chiếu cũ nên chỉ cần dời node (gọi 1 lần từ Main).
func attach_dots(dots: Control) -> void:
	var slot := get_node_or_null("DotsSlot") as Control
	if slot == null or dots == null or dots.get_parent() == slot:
		return
	dots.reparent(slot, false)
	dots.custom_minimum_size = Vector2(DOTS_MIN_WIDTH, 6.0)  # keep-code: chấm trang sinh lúc chạy (runtime)
	dots.size_flags_horizontal = Control.SIZE_SHRINK_END  # keep-code: chấm trang sinh lúc chạy (runtime)
	dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # keep-code: chấm trang sinh lúc chạy (runtime)
