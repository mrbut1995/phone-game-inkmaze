class_name EventCarousel
extends Control
## ============================================================================
## Node: EventCarousel — Carousel ngang chứa các EventCard.
##
## Cách dùng: đặt trong scene Main, gọi refresh() khi EventManager thay đổi.
## Snap theo trang khi thả tay (vuốt có quán tính nhẹ).
## ============================================================================

signal event_card_pressed(event_id: StringName)

## Khe giữa các thẻ (px)
const DRAG_THRESHOLD := 12.0

## Node con
@onready var scroll: ScrollContainer = $ScrollContainer
@onready var hbox: HBoxContainer = $ScrollContainer/HBox
@onready var dots: EventDots = $EventDots

## Scene thẻ event (gán trong Inspector hoặc preload)
@export var event_card_scene: PackedScene = null

## Màu chấm hiện tại / chấm khác
@export var dot_active_color: Color = Color("#256C96")
@export var dot_inactive_color: Color = Color("#D8E2E8")

var _cards: Array[EventCard] = []
var _current_page: int = 0
var _drag_active: bool = false
var _drag_moved: bool = false
var _drag_start_position := Vector2.ZERO
var _drag_start_scroll: float = 0.0
var _snap_tween: Tween


func _ready() -> void:
	if scroll != null:
		scroll.get_h_scroll_bar().value_changed.connect(_on_scroll_changed)
		if scroll.has_signal("scroll_ended"):
			scroll.scroll_ended.connect(_on_scroll_ended)
	if event_card_scene == null:
		event_card_scene = load("res://nodes/main/event_card.tscn")


## Nạp lại danh sách thẻ từ EventManager
func refresh() -> void:
	_clear_cards()
	var em := get_node_or_null("/root/EventManager")
	if em == null:
		return
	var events: Array[EventData] = em.get_active_events()
	for ev in events:
		_add_card(ev)
	# Cuộn về đầu (Daily luôn đứng đầu)
	if scroll != null:
		scroll.scroll_horizontal = 0
	_current_page = 0
	_update_dots()


func _add_card(data: EventData) -> void:
	if event_card_scene == null:
		return
	var card := event_card_scene.instantiate() as EventCard
	if card == null:
		return
	hbox.add_child(card)
	card.setup(data)
	card.card_pressed.connect(_on_card_pressed)
	_cards.append(card)


func _clear_cards() -> void:
	for card in _cards:
		if is_instance_valid(card):
			card.queue_free()
	_cards.clear()


# ---------------------------------------------------------------------------
# DOTS (chỉ phân trang)
# ---------------------------------------------------------------------------

func _update_dots() -> void:
	if dots == null:
		return
	dots.set_pages(_cards.size(), _current_page)


# ---------------------------------------------------------------------------
# SNAP / SCROLL
# ---------------------------------------------------------------------------

func _get_card_metrics() -> Vector2:
	var gap := 0.0
	if hbox != null:
		gap = float(hbox.get_theme_constant("separation"))
	var width := 0.0
	if _cards.size() > 0 and is_instance_valid(_cards[0]):
		width = _cards[0].size.x if _cards[0].size.x > 0.0 else _cards[0].custom_minimum_size.x
	return Vector2(width, gap)


func _on_scroll_changed(_value: float) -> void:
	if scroll == null or _cards.is_empty():
		return
	var metrics := _get_card_metrics()
	var total_width := metrics.x + metrics.y
	var hbar := scroll.get_h_scroll_bar()
	var max_scroll := (hbar.max_value - hbar.page) if hbar != null else 0.0
	var page: int = 0
	if max_scroll > 0.0 and scroll.scroll_horizontal >= max_scroll - 1.0:
		page = _cards.size() - 1
	elif total_width > 0.0:
		page = roundi(float(scroll.scroll_horizontal) / total_width)
	page = clampi(page, 0, _cards.size() - 1)
	if page != _current_page:
		_current_page = page
		_update_dots()


func _on_scroll_ended() -> void:
	snap_to_nearest()


## ScrollContainer nuốt thao tác kéo trên các thẻ Control, nên xử lý gesture trước GUI.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == 0:
		_update_drag(event.position)
	elif not DisplayServer.is_touchscreen_available():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_drag(event.position)
			else:
				_end_drag()
		elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_drag(event.position)


func _begin_drag(position: Vector2) -> void:
	if scroll == null or _cards.size() < 2:
		return
	var hbar := scroll.get_h_scroll_bar()
	if hbar == null or hbar.max_value <= hbar.page:
		return
	if not scroll.get_global_rect().has_point(position):
		return
	if _snap_tween != null and _snap_tween.is_running():
		_snap_tween.kill()
	_drag_active = true
	_drag_moved = false
	_drag_start_position = position
	_drag_start_scroll = float(scroll.scroll_horizontal)


func _update_drag(position: Vector2) -> void:
	if not _drag_active:
		return
	var delta := position - _drag_start_position
	if not _drag_moved:
		if absf(delta.x) < DRAG_THRESHOLD and absf(delta.y) < DRAG_THRESHOLD:
			return
		if absf(delta.x) <= absf(delta.y):
			_drag_active = false
			return
		_drag_moved = true
	if _drag_moved:
		scroll.scroll_horizontal = int(_drag_start_scroll - delta.x)


func _end_drag() -> void:
	if not _drag_active:
		return
	var did_drag := _drag_moved
	_drag_active = false
	_drag_moved = false
	if did_drag:
		snap_to_nearest()


## Snap về trang gần nhất khi thả tay
func snap_to_nearest() -> void:
	if scroll == null or _cards.is_empty():
		return
	var metrics := _get_card_metrics()
	var total_width := metrics.x + metrics.y
	var target := _current_page * total_width
	var hbar := scroll.get_h_scroll_bar()
	if hbar != null:
		var max_scroll := hbar.max_value - hbar.page
		target = minf(target, max_scroll)
	# Tween mượt
	if _snap_tween != null and _snap_tween.is_running():
		_snap_tween.kill()
	_snap_tween = create_tween()
	_snap_tween.set_ease(Tween.EASE_OUT)
	_snap_tween.set_trans(Tween.TRANS_CUBIC)
	_snap_tween.tween_property(scroll, "scroll_horizontal", int(target), 0.25)



# ---------------------------------------------------------------------------
# SIGNALS
# ---------------------------------------------------------------------------

func _on_card_pressed(event_id: StringName) -> void:
	event_card_pressed.emit(event_id)
