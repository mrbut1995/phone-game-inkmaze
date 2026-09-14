class_name UIController
extends Node
## ============================================================================
## Controller: Quản lý HUD và các popup trong ván chơi.
##
## Popup KHÔNG còn instance sẵn trong scenes/game.tscn. Controller chỉ yêu cầu
## PopupManager tạo popup khi cần; mọi nút bên trong popup tự phát signal riêng
## (winning/gameover/next_floor/pause) và được nối tại đây.
## ============================================================================

signal continue_requested
signal retry_requested
signal quit_requested
signal home_requested
signal pause_toggled(is_paused: bool)
signal revive_requested
## Pha GHI NHỚ (Blind Memory) đếm ngược xong -> GameController ẩn tường và chạy đồng hồ
signal memorize_finished

@export var level_label: Label = null
## Dòng phụ nhỏ dưới tiêu đề (VD "PLAY MODE · CHƯƠNG 1"). Rỗng = ẩn.
@export var subtitle_label: Label = null

## HUD của chế độ đang chơi (BaseHUD). GameScene gắn vào qua set_hud() khi đổi chế độ.
var hud: BaseHUD = null

## Thông tin ván đang chơi (GameController cập nhật) - dùng cho popup tạm dừng
var run_info: Dictionary = {}


func set_run_info(info: Dictionary) -> void:
	run_info = info


## Gắn HUD của chế độ đang chơi (GameScene gọi trong _apply_hud_for_mode).
func set_hud(p_hud: BaseHUD) -> void:
	hud = p_hud


# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------
func update_hud(
	title: String,
	subtitle: String,
	steps_remaining: int,
	elapsed_time: float,
	floor_number: int,
	extra_info := "",
	mode: BaseGameMode = null
) -> void:
	if level_label != null:
		level_label.text = title
	if subtitle_label != null:
		subtitle_label.text = subtitle
		subtitle_label.visible = not subtitle.is_empty()

	# Mọi thành phần trong khung Information do HUD của từng chế độ tự vẽ
	if hud != null:
		hud.update_hud({
			"title": title,
			"subtitle": subtitle,
			"steps_remaining": steps_remaining,
			"elapsed_time": elapsed_time,
			"floor_number": floor_number,
			"extra": extra_info,
			"mode": mode,
		})


# ---------------------------------------------------------------------------
# Popup kết quả màn chơi (Dungeon -> phiếu thông qua tầng, chế độ thường -> win)
# ---------------------------------------------------------------------------
func show_floor_complete(result: Dictionary) -> void:
	Popups.close_all()
	var id := Popups.NEXT_FLOOR if bool(result.get("endless", false)) else Popups.WIN
	# SFX: con dấu "cộp" lên giấy
	Sfx.play(Sfx.STAMP_IMPACT)

	var popup := Popups.open(id, result)
	if popup == null:
		return

	if popup.has_signal("next_requested"):
		_connect_once(popup, "next_requested", _emit_continue)
	elif popup.has_signal("enter_requested"):
		_connect_once(popup, "enter_requested", _emit_continue)
	if popup.has_signal("replay_requested"):
		_connect_once(popup, "replay_requested", _emit_retry)
	if popup.has_signal("rest_requested"):
		_connect_once(popup, "rest_requested", _emit_home)

	if id == Popups.WIN:
		_play_star_sequence()


func show_game_over(result: Dictionary) -> void:
	Popups.close_all()
	# SFX: tiếng vo tròn tờ giấy nháp ném đi
	Sfx.play(Sfx.GAME_OVER)

	# Dungeon Mode thua vì HẾT BƯỚC (phiếu giấy + điểm an ủi);
	# các chế độ khác thua vì ĐÂM TƯỜNG (phiếu nêu 3 thử thách + số Sao đạt được)
	var id := Popups.GAME_OVER if bool(result.get("endless", true)) else Popups.GAME_OVER_LEVEL
	var popup := Popups.open(id, result)
	if popup == null:
		return
	if popup.has_signal("retry_requested"):
		_connect_once(popup, "retry_requested", _emit_retry)
	if popup.has_signal("menu_requested"):
		_connect_once(popup, "menu_requested", _emit_home)
	if popup.has_signal("revive_requested"):
		_connect_once(popup, "revive_requested", _emit_revive)


# ---------------------------------------------------------------------------
# Popup tạm dừng (Pause menu)
# ---------------------------------------------------------------------------
func toggle_settings() -> void:
	# SFX: gõ thẻ giấy cho nút Pause trên HUD
	Sfx.play(Sfx.BTN_WOOD_TAP)
	if Popups.is_open(Popups.PAUSE):
		Popups.close_id(Popups.PAUSE)
		return

	var data := run_info.duplicate()
	var popup := Popups.open(Popups.PAUSE, data)
	if popup == null:
		return
	_connect_once(popup, "resume_requested", _on_pause_closed)
	_connect_once(popup, "restart_requested", _on_pause_restart)
	_connect_once(popup, "menu_requested", _on_pause_menu)
	pause_toggled.emit(true)


## Nối signal một lần duy nhất (popup có thể được mở lại trên cùng một node)
func _connect_once(source: Object, signal_name: String, handler: Callable) -> void:
	if not source.is_connected(signal_name, handler):
		source.connect(signal_name, handler)


## Popup đếm ngược pha GHI NHỚ của Blind Memory.
## Popup không có nền mờ nên mê cung (đang hiện toàn bộ tường) vẫn nhìn rõ để ghi nhớ.
## Nếu vì lý do nào đó không mở được popup thì báo `memorize_finished` luôn để ván chơi không bị kẹt.
func show_memorize_countdown(seconds: int) -> void:
	var popup := Popups.open(Popups.MEMORIZE, {"seconds": maxi(seconds, 1)})
	if popup == null:
		memorize_finished.emit()
		return
	_connect_once(popup, "finished", _emit_memorize_finished)


func _emit_memorize_finished() -> void:
	memorize_finished.emit()


func _emit_continue() -> void:
	continue_requested.emit()


func _emit_retry() -> void:
	retry_requested.emit()


func _emit_home() -> void:
	home_requested.emit()


func _emit_revive() -> void:
	revive_requested.emit()


func _on_pause_restart() -> void:
	pause_toggled.emit(false)
	retry_requested.emit()


func _on_pause_menu() -> void:
	pause_toggled.emit(false)
	home_requested.emit()


func _on_pause_closed() -> void:
	pause_toggled.emit(false)


## Đóng mọi popup đang hiển thị
func hide_overlays() -> void:
	Popups.close_all()


## Các nút của popup ngắt sẵn trong .tscn (nếu scene còn nối) đi qua các hàm này
func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	continue_requested.emit()


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	retry_requested.emit()


func _on_home_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	home_requested.emit()


func _on_resume_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	pause_toggled.emit(false)


## 3 ngôi sao hiện lần lượt trên popup thắng -> 3 tiếng chuông gỗ cao dần
func _play_star_sequence() -> void:
	for i in 3:
		if not is_inside_tree():
			return
		var tw := create_tween()
		tw.tween_interval(0.45 + i * 0.22)
		tw.tween_callback(func() -> void: Sfx.star_pop(i))
