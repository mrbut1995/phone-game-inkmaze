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

## Nội dung hồ sơ (profiler_content) — nhận `owner_popup` khi mở.
## Binding trong `profiler_popup.tscn` (node `Panel/Content/Profiler`).
@export var content_node: Node = null


func _on_open() -> void:
	# Nội dung tự biết đang nằm trong popup nào để nút Back đóng đúng popup này
	content_node.set("owner_popup", self)
	if content_node.has_method("refresh"):
		content_node.call("refresh")

	
## Nội dung hồ sơ bên trong popup (dùng cho test/dev).
func profiler() -> Node:
	return content_node
