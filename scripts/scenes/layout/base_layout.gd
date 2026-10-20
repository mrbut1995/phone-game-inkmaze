extends Control
class_name BaseLayout

## Node vô hình giữ đúng rect cũ của thanh trên cục bộ. Khi có node này, `TopBar`
## (node dùng chung của base_layout) được kéo về đúng vị trí/kích thước/tỉ lệ của nó.
@export var header_anchor: Control = null


func _ready() -> void:
	_sync_shared_header()


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
	# Neo giữ chỗ phải có cùng cỡ TỐI THIỂU với thanh thật (bar chứa nút/tiêu đề),
	# nếu không container sẽ co neo còn 0 và làm sai rect đồng bộ.
	var header_row := bar.get_node_or_null("HeaderRow") as Control
	if header_row != null:
		var min_size := header_row.get_combined_minimum_size()
		if header_anchor.custom_minimum_size != min_size:
			header_anchor.custom_minimum_size = min_size
	var target_pos := header_anchor.global_position
	var target_size := header_anchor.size
	var target_scale := header_anchor.get_global_transform().get_scale()
	if bar.global_position != target_pos:
		bar.global_position = target_pos
	if bar.size != target_size:
		bar.size = target_size
	if bar.scale != target_scale:
		bar.scale = target_scale


func _on_active():
	pass
	
func _on_deactive():
	pass
	
func _on_orientation_changed():
	pass
