class_name EventScene
extends BaseScene
## ============================================================================
## View Controller: Màn chi tiết Sự kiện (Event Detail Screen).
##
## Nhận event_id qua set_event_id() trước khi scene _ready() hoặc ngay sau khi
## thêm vào scene tree.
## ============================================================================

var _event_id: StringName = &""
var _layout: EventLayout = null


func _ready() -> void:
	# Lấy event_id từ SceneManager nếu chưa được set từ bên ngoài
	if _event_id.is_empty():
		var sm := get_node_or_null("/root/SceneManager")
		if sm != null and sm.has_method("consume_pending_event_id"):
			_event_id = sm.call("consume_pending_event_id")
	_bind_layout()
	_refresh()
	orientation_changed.connect(_on_orientation_changed)


func _bind_layout() -> void:
	_layout = active_layout() as EventLayout
	if _layout == null:
		push_warning("EventScene: layout chưa gắn EventLayout")


func _on_orientation_changed(_is_landscape: bool) -> void:
	_bind_layout()
	_refresh()


## Gọi trước khi đưa màn này vào scene tree để truyền event đang xem
func set_event_id(id: StringName) -> void:
	_event_id = id
	if is_inside_tree():
		_refresh()


func _refresh() -> void:
	if _layout == null or _event_id.is_empty():
		return
	var em := get_node_or_null("/root/EventManager")
	if em == null:
		return
	var data: EventData = em.get_event(_event_id)
	if data == null:
		return
	# Tiêu đề
	if _layout.event_title != null:
		_layout.event_title.text = tr(str(data.title_key_1)) + " " + tr(str(data.title_key_2))
	if _layout.event_subtitle != null:
		_layout.event_subtitle.text = tr(str(data.sub_key_1))
	# Đếm ngược
	if _layout.event_timer != null:
		var secs: int = em.seconds_left(_event_id)
		if secs >= 172800:
			_layout.event_timer.text = tr("STR_EVENT_TIMER_DAYS").format([secs / 86400])
		elif secs >= 3600:
			_layout.event_timer.text = tr("STR_EVENT_TIMER_HOURS").format([secs / 3600])
		else:
			_layout.event_timer.text = tr("STR_EVENT_TIMER_MINUTES").format([ceili(float(secs) / 60.0)])
	# Tiến độ
	var prog: Dictionary = em.get_progress(_event_id)
	if _layout.progress_label != null:
		_layout.progress_label.text = tr("STR_EVENT_PROGRESS_FORMAT").format(
			[prog.get("done", 0), prog.get("total", 1)])
	# CTA
	if _layout.cta_button != null:
		_layout.cta_button.pressed.connect(_on_cta_pressed, CONNECT_ONE_SHOT)
	var claimed: bool = prog.get("claimed", false)
	var completed: bool = prog.get("completed", false)
	var cta_text := ""
	if claimed:
		cta_text = tr("STR_EVENT_CTA_CLAIMED")
		if _layout.cta_button != null:
			_layout.cta_button.disabled = true
	elif completed:
		cta_text = tr("STR_EVENT_CTA_CLAIM")
	else:
		cta_text = tr(str(data.cta_key))
	if _layout.cta_label != null:
		_layout.cta_label.text = cta_text
	elif _layout.cta_button != null:
		_layout.cta_button.text = cta_text
	# Nút back
	if _layout.btn_back != null and not _layout.btn_back.pressed.is_connected(_on_back_pressed):
		_layout.btn_back.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var sm := get_node_or_null("/root/SceneManager")
	if sm != null and sm.has_method("go_back"):
		sm.call("go_back")
	else:
		get_node_or_null("/root/SceneManager").call("goto_main")


func _on_cta_pressed() -> void:
	var em := get_node_or_null("/root/EventManager")
	if em == null:
		return
	var data: EventData = em.get_event(_event_id)
	if data == null:
		return
	var prog: Dictionary = em.get_progress(_event_id)
	var completed: bool = prog.get("completed", false)
	var claimed: bool = prog.get("claimed", false)
	if claimed:
		return
	if completed:
		em.claim_reward(_event_id)
		_refresh()
		return
	# Vào chơi theo loại event
	match data.type:
		EventData.Type.DAILY:
			var gm := get_node_or_null("/root/GameManager")
			if gm != null and gm.has_method("go_to_daily"):
				gm.go_to_daily()
			else:
				Nav.goto_daily()
		EventData.Type.SPECIAL_SERIES, EventData.Type.STANDARD_SERIES:
			# Tìm màn chưa xong đầu tiên
			var done_list: Array = prog.get("done_levels", [])
			for level in data.levels:
				var lid := str(level.level_id)
				if not done_list.has(lid):
					var gm := get_node_or_null("/root/GameManager")
					if gm != null and gm.has_method("start_level_from_event"):
						gm.call("start_level_from_event", level, _event_id)
					else:
						Nav.goto_game()
					return
			# Đã xong hết — mở lại từ đầu (replay)
			if data.levels.size() > 0:
				var gm := get_node_or_null("/root/GameManager")
				if gm != null and gm.has_method("start_level_from_event"):
					gm.call("start_level_from_event", data.levels[0], _event_id)
		EventData.Type.DUNGEON:
			var gm := get_node_or_null("/root/GameManager")
			if gm != null and gm.has_method("start_dungeon"):
				gm.start_dungeon()
			else:
				Nav.goto_game()
		EventData.Type.LOGIN_STREAK:
			# Popup lịch N ngày — giai đoạn 2: tạo popup riêng
			# Hiện tại: toast "sắp có"
			pass
