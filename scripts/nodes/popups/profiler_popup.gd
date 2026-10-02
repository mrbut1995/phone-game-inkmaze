class_name ProfilerPopup
extends BasePopup
## ============================================================================
## Popup HỒ SƠ CÁ NHÂN (nodes/popups/profiler_popup.tscn)
##
## Popup = instance của `nodes/popups/base.tscn` (Dim + thẻ + hiệu ứng mở/đóng) và
## chứa NỘI DUNG hồ sơ `nodes/popups/profiler_content.tscn` tại `Panel/Content/Profiler`.
## Vùng `Panel/Content` của popup được nới rộng hơn thẻ để vừa tờ hồ sơ (xem .tscn).
## Mở từ sticker HỒ SƠ ở màn chính mà KHÔNG đổi màn hình.
##
## XẾP LỚP: nút "ĐỔI AVATAR & TÊN" trong nội dung mở tiếp popup EDIT_PROFILE —
## PopupManager luôn đặt popup mới lên trên cùng nên Edit Profile "nằm trồng lên"
## Profiler; đóng Edit Profile là quay lại đúng hồ sơ đang xem.
##
## Nút Back của nội dung được gán `owner_popup = self` lúc mở ⇒ bấm Back ĐÓNG popup
## (không điều hướng màn hình).
## ============================================================================

## Nội dung hồ sơ (profiler_content) — nhận `owner_popup` khi mở
@onready var _content: Node = _find_content()


## Tìm nội dung hồ sơ trong vùng `Panel/Content` (fallback khi node bị đổi tên)
func _find_content() -> Node:
	var direct := get_node_or_null("Panel/Content/Profiler")
	if direct != null:
		return direct
	var holder := get_node_or_null("Panel/Content")
	if holder != null and holder.get_child_count() > 0:
		return holder.get_child(0)
	return null


func _on_open() -> void:
	if _content == null:
		return
	# Nội dung tự biết đang nằm trong popup nào để nút Back đóng đúng popup này
	_content.set("owner_popup", self)
	if _content.has_method("refresh"):
		_content.call("refresh")

	
## Nội dung hồ sơ bên trong popup (dùng cho test/dev).
## Lưu ý: KHÔNG đặt tên `content` vì `BasePopup` đã có biến `content` (= Panel/Content).
func profiler() -> Node:
	return _content
