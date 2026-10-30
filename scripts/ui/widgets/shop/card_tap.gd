class_name ShopCardTap
extends RefCounted
## ============================================================================
## Nhận biết CHẠM trên cả THẺ món (dùng chung cho item_tile · item_row · coin_tile · noads_row)
## QUY TẮC GIAO DIỆN: chỉ thứ BẤM ĐƯỢC mới "nhô" (thẻ, nút mũi tên, nút Back…). Ô giá/trạng thái
## bên trong thẻ là PHẲNG (chỉ hiển thị) — cả thẻ là một nút lớn dễ bấm bằng ngón tay.
##  • feed() phân biệt CHẠM với KÉO/VUỐT (không kích hoạt khi người chơi đang vuốt trang)
##  • "Lên đạn" (arm): món TỐN XU phải chạm 2 lần (lần 1 chọn/xem thử, lần 2 mua) tránh lỡ tay
## ============================================================================
enum Result { NONE, DOWN, TAP, CANCEL }

## Quãng kéo tối đa (px) vẫn tính là chạm
const SLOP := 14.0
## Bỏ sự kiện trùng (cảm ứng + chuột giả lập sinh ra gần như cùng lúc)
const DEBOUNCE_MS := 120
## Thời gian giữ trạng thái "đã chọn, chạm lần nữa để mua"
const ARM_SECONDS := 4.0

static var _armed: Object = null
static var _armed_until := 0

var _down := false
var _start := Vector2.ZERO
var _last_down_ms := -1000


func feed(event: InputEvent) -> Result:
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pos = (event as InputEventMouseButton).position
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pos = (event as InputEventScreenTouch).position
		pressed = (event as InputEventScreenTouch).pressed
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _down:
		var moved: Vector2 = event.position
		if moved.distance_to(_start) > SLOP:
			_down = false
			return Result.CANCEL
		return Result.NONE
	else:
		return Result.NONE
	var now := Time.get_ticks_msec()
	if pressed:
		if now - _last_down_ms < DEBOUNCE_MS:
			return Result.NONE
		_down = true
		_start = pos
		_last_down_ms = now
		return Result.DOWN
	if not _down:
		return Result.NONE
	_down = false
	return Result.TAP if pos.distance_to(_start) <= SLOP else Result.CANCEL


## Lún nhẹ khi ngón tay chạm vào thẻ
static func press_fx(node: Control, down: bool) -> void:
	if node == null or not node.is_inside_tree():
		return
	var old: Variant = node.get_meta("_tap_fx", null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(node, "scale", Vector2(0.97, 0.97) if down else Vector2.ONE, 0.07)
	node.set_meta("_tap_fx", tw)


## Lắc ô giá khi không đủ xu
static func shake(node: Control, target: Control) -> void:
	if node == null or target == null or not node.is_inside_tree():
		return
	var x := target.position.x
	var tw := node.create_tween()
	for dx in [-5.0, 5.0, -3.0, 0.0]:
		tw.tween_property(target, "position:x", x + dx, 0.05)


static func arm(node: Object) -> void:
	if _armed != null and _armed != node and is_instance_valid(_armed) and _armed.has_method("_on_disarmed"):
		_armed.call("_on_disarmed")
	_armed = node
	_armed_until = Time.get_ticks_msec() + int(ARM_SECONDS * 1000.0)
	if node is Node and (node as Node).is_inside_tree():
		(node as Node).get_tree().create_timer(ARM_SECONDS).timeout.connect(func() -> void: _expire(node))


static func is_armed(node: Object) -> bool:
	return _armed == node and Time.get_ticks_msec() <= _armed_until


static func disarm() -> void:
	if _armed != null and is_instance_valid(_armed) and _armed.has_method("_on_disarmed"):
		_armed.call("_on_disarmed")
	_armed = null


static func _expire(node: Object) -> void:
	if _armed == node and Time.get_ticks_msec() >= _armed_until:
		disarm()
