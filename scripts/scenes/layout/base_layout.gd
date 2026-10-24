extends Control
class_name BaseLayout

## Node vô hình giữ đúng rect cũ của thanh trên cục bộ. Khi có node này, `TopBar`
## (node dùng chung của base_layout) được kéo về đúng vị trí/kích thước/tỉ lệ của nó.
@export var header_anchor: Control = null

## (Tuỳ chọn) Node Control dùng làm khoảng đệm dưới cho safe area Android.
## Đặt nó ở cuối VBoxContainer chính của layout — base_layout tự điều chỉnh chiều cao.
@export var bottom_safe_spacer: Control = null


func _ready() -> void:
	_sync_shared_header()
	_apply_safe_area()
	# Lắng nghe thay đổi safe area (xoay màn hình, v.v.)
	if has_node("/root/SafeArea"):
		get_node("/root/SafeArea").changed.connect(_on_safe_area_changed)


func _process(_delta: float) -> void:
	_sync_shared_header()


## Đồng bộ `TopBar` dùng chung với `HeaderAnchor` — chạy mỗi frame để bắt kịp container
## đổi kích thước, `Stage`/`Scaler` đổi tỉ lệ và lúc xoay màn hình.
func _sync_shared_header() -> void:
	if header_anchor == null or not is_inside_tree():
		return
	var bar := get_node_or_null("TopBar") as Control
	if bar == null:
		return
	# Neo giữ chỗ phải giữ đúng CHIỀU CAO tối thiểu của thanh thật (bar chứa nút/tiêu đề),
	# nếu không container sẽ co neo còn 0 và nội dung bên dưới bị thanh trên đè lên.
	# Bề rộng của neo giữ nguyên theo thiết kế (không cộng bề rộng chip) để container không nới rộng.
	var min_height := _content_min_height(bar)
	if not is_equal_approx(header_anchor.custom_minimum_size.y, min_height):
		header_anchor.custom_minimum_size = Vector2(
			header_anchor.custom_minimum_size.x, min_height)
	var target_pos := header_anchor.global_position
	var target_size := header_anchor.size
	var target_scale := header_anchor.get_global_transform().get_scale()
	if bar.global_position != target_pos:
		bar.global_position = target_pos
	if bar.size != target_size:
		bar.size = target_size
	if bar.scale != target_scale:
		bar.scale = target_scale


## Chiều cao tối thiểu của NỘI DUNG thanh trên (bỏ qua 2 chip dùng chung — chip thấp hơn nút/tiêu đề)
func _content_min_height(bar: Control) -> float:
	var height := 0.0
	for child in bar.get_children():
		if not (child is Control) or child is CoinChip or child is LifeChip:
			continue
		var ctrl := child as Control
		if not ctrl.visible:
			continue
		height = maxf(height, ctrl.get_combined_minimum_size().y)
	return height


func _on_active():
	pass
	
func _on_deactive():
	pass
	
func _on_orientation_changed():
	pass


## Áp dụng bottom safe area inset vào `bottom_safe_spacer`.
## Gọi tự động khi `_ready` và khi `SafeArea.changed` phát ra.
func _apply_safe_area() -> void:
	var sa_node := get_node_or_null("/root/SafeArea")
	var inset := 0.0
	if sa_node != null:
		inset = sa_node.bottom_ui()
	_set_bottom_safe(inset)
	_on_safe_area_applied(inset)


## Đặt chiều cao spacer dưới (px UI). Subclass có thể override nếu cần xử lý thêm.
func _set_bottom_safe(inset_px: float) -> void:
	if bottom_safe_spacer == null:
		return
	var cur_min := bottom_safe_spacer.custom_minimum_size
	if not is_equal_approx(cur_min.y, inset_px):
		bottom_safe_spacer.custom_minimum_size = Vector2(cur_min.x, inset_px)


## Hook cho subclass khi safe area được áp dụng (vd: layout có node neo tuyệt đối ở dưới).
func _on_safe_area_applied(_inset_px: float) -> void:
	pass


func _on_safe_area_changed(_insets: Rect2i) -> void:
	_apply_safe_area()


## Có được chạy hiệu ứng TRƯỢT cho node này không?
## `TopBar` dùng chung bị `header_anchor` đồng bộ vị trí mỗi frame nên KHÔNG được tween vị trí của nó
## (sẽ giật); các thanh riêng của màn (VD `TopBar/HeaderRow`, `TopBar/Wallet`) thì vẫn trượt bình thường.
func can_animate_bar(node: Control) -> bool:
	if node == null:
		return false
	if header_anchor != null and node == get_node_or_null("TopBar"):
		return false
	return true
