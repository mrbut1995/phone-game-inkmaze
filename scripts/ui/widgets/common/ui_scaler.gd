class_name UIScaler
extends Control
## ============================================================================
## Node: UIScaler — phóng ĐỀU một "khung thiết kế" lên vừa canvas.
##
## VÌ SAO CẦN: project dùng viewport 540×920 + stretch aspect `expand` ⇒ ở màn NGANG
## canvas vẫn CAO 920 (16:9 → ~1636×920). Layout ngang của Main vẽ trên khung 540 cao
## (số đo = mockup × 0,5) nên nếu để nguyên, UI chỉ chiếm ~59% chiều cao.
##
## CÁCH DÙNG: đặt node này làm con trực tiếp của layout (`Landscape`), rồi đặt TOÀN BỘ
## nội dung layout vào trong nó. Node tự tính hệ số phóng
##     s = min( canvas.y / design_height , canvas.x / design_min_width )
## và đặt `scale = s`, `size = canvas / s` ⇒ bên trong vẫn là khung thiết kế
## (cao ≥ design_height, rộng ≥ design_min_width), container/anchor tự dàn như thường.
##
## LỀ TRÁI: gáy sổ/lề đỏ của nền nằm ở CANVAS-PX cố định (`margin_x` trong background.gd),
## không bị phóng theo `s`. Gán `inset_target` (thường là `Body`) + `left_inset_canvas`
## (= content_left() của nền) ⇒ node tự đặt `offset_left = left_inset_canvas / s` để nội dung luôn
## nằm ngay bên phải lề đỏ ở mọi hệ số phóng.
## ============================================================================

## Chiều cao khung thiết kế (px, hệ 540)
@export var design_height: float = 540.0
## Bề rộng TỐI THIỂU khung thiết kế — nhỏ hơn thì phóng ít lại để nội dung không vỡ
@export var design_min_width: float = 960.0
## Node cần chừa lề trái (đặt `offset_left` của nó)
@export var inset_target: Control = null
## Lề trái tính bằng CANVAS-PX (khớp lề đỏ của nền)
@export var left_inset_canvas: float = 52.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p := get_parent() as Control
	if p != null:
		if not p.resized.is_connected(_fit):
			p.resized.connect(_fit)
		if not p.visibility_changed.is_connected(_fit):
			p.visibility_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var p := get_parent() as Control
	if p == null:
		return
	var area := p.size
	if area.x <= 1.0 or area.y <= 1.0:
		return
	var s := minf(area.y / design_height, area.x / design_min_width)
	s = maxf(s, 0.05)
	var target_scale := Vector2(s, s)
	if scale != target_scale:
		scale = target_scale
	if position != Vector2.ZERO:
		position = Vector2.ZERO
	var target_size := area / s
	if size != target_size:
		size = target_size
	if inset_target != null:
		var inset := left_inset_canvas / s
		if not is_equal_approx(inset_target.offset_left, inset):
			inset_target.offset_left = inset