class_name AutoFitLabel
extends Label
## ============================================================================
## Label TỰ CO CỠ CHỮ cho vừa khung (theo `guide/GUIDE.MD` §4.1).
##
## Dùng cho các khung hẹp (màn 3:4, bản dịch dài như tiếng Đức/Nga) hoặc khi bố cục
## đổi theo tỉ lệ màn hình mà cỡ chữ thiết kế không kịp đổi theo.
##
## Cách dùng: đặt script này lên Label — cỡ chữ lớn nhất lấy từ theme / label_settings
## hiện tại (hoặc khai `max_font_size`), tự giảm từng `step_down` cho tới khi vừa cả
## bề ngang lẫn bề cao khung. KHÔNG dùng cùng `label_settings` cỡ chữ cố định + theme
## override cùng lúc (label_settings sẽ thắng theme).
## ============================================================================

## Cỡ chữ lớn nhất (0 = lấy theo theme / label_settings hiện tại)
@export var max_font_size: int = 0
## Cỡ chữ nhỏ nhất được phép co xuống
@export var min_font_size: int = 12
## Mỗi bước giảm bao nhiêu px
@export var step_down: int = 2
## Tự fit ngay khi vào cây (tắt nếu muốn gọi tay sau khi setup dữ liệu)
@export var fit_on_ready: bool = true

var _applied_size := 0


func _ready() -> void:
	clip_text = true
	resized.connect(_queue_fit)
	if fit_on_ready:
		_queue_fit()


## Đặt nội dung mới rồi fit lại ngay (dùng khi text đổi lúc chạy)
func set_adaptive_text(new_text: String) -> void:
	text = new_text
	_queue_fit()


func _queue_fit() -> void:
	# Chờ layout xong frame này (size có thể còn 0 trong lúc container đang sắp xếp)
	_fit.call_deferred()


func _fit() -> void:
	if not is_inside_tree() or text.is_empty():
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var font := _current_font()
	if font == null:
		return
	var top: int = max_font_size if max_font_size > 0 else _current_font_size()
	var bottom: int = maxi(min_font_size, 1)
	var step: int = maxi(step_down, 1)
	var chosen: int = 0
	var probe := top
	while probe >= bottom:
		var text_size := font.get_string_size(text, horizontal_alignment, -1, probe)
		var lines := ceili(text_size.x / maxf(size.x, 1.0)) if text_size.x > 0.0 else 1
		var need_y := font.get_height(probe) * float(maxi(lines, 1))
		if text_size.x <= size.x and need_y <= size.y:
			chosen = probe
			break
		probe -= step
	if chosen == 0:
		chosen = bottom
	if chosen != _applied_size:
		_applied_size = chosen
		add_theme_font_size_override("font_size", chosen)


## Font đang dùng: ưu tiên label_settings (nếu có), rồi tới theme
func _current_font() -> Font:
	if label_settings != null and label_settings.font != null:
		return label_settings.font
	return get_theme_font("font")


func _current_font_size() -> int:
	if label_settings != null and label_settings.font_size > 0:
		return label_settings.font_size
	return get_theme_font_size("font_size")
