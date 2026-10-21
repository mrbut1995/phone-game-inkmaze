class_name OutOfLifePopup
extends BasePopup
## ============================================================================
## Popup: HẾT BÚT CHÌ = hết LƯỢT CHƠI (nodes/popups/out_of_life.tscn)
##
## Hiện khi người chơi bấm vào màn chơi mà KHÔNG còn lượt (lives = 0). Hai lựa chọn:
##   1. Thoát ra      (nút xám, dấu X)       — đóng popup, ở lại màn hiện tại
##   2. Vào Cửa hàng  (nút vàng, bút chì +)  — mua thêm bút; nút Back của Cửa hàng
##                                             quay lại ĐÚNG màn này (GameManager
##                                             nhớ `shop_return_path` lúc mở Shop)
##
## Hàng bút + đếm ngược hồi bút dùng chung RetryPencils với popup Retry.
## Popup CHỈ HIỂN THỊ — số lượt do GameManager giữ.
## Dữ liệu: open({ max_lives })
## ============================================================================

signal exit_requested
signal shop_requested

## Node binding: khai `node_paths` + `NodePath` trong `out_of_life.tscn`
@export var label_title: Label = null
@export var label_subtitle: Label = null
@export var pencils: RetryPencils = null
@export var btn_exit: BaseButton = null
@export var btn_shop: BaseButton = null

var _maximum := 5


func _on_open() -> void:
	_maximum = maxi(int(data.get("max_lives", _max_lives())), 1)
	if label_title != null:
		label_title.text = tr("STR_LIFE_EMPTY_TITLE")
	_connect_life_signal()
	_refresh()


func _on_close() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and gm.is_connected("life_changed", _on_life_changed):
		gm.disconnect("life_changed", _on_life_changed)


# ---------------------------------------------------------------------------
# Lượt chơi (đọc từ GameManager, qua /root như các manager khác)
# ---------------------------------------------------------------------------
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _lives_now() -> int:
	var gm := _game_manager()
	if gm != null and gm.has_method("lives_left"):
		return int(gm.call("lives_left"))
	return 0


func _max_lives() -> int:
	var gm := _game_manager()
	if gm != null and gm.has_method("max_lives"):
		return int(gm.call("max_lives"))
	return 5


func _connect_life_signal() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and not gm.is_connected("life_changed", _on_life_changed):
		gm.connect("life_changed", _on_life_changed)


## Hồi xong 1 bút khi popup đang mở -> vẽ lại hàng bút + đổi lời nhắn
func _on_life_changed(_lives: int, _max: int) -> void:
	_refresh()


func _refresh() -> void:
	var lives := _lives_now()
	if label_subtitle != null:
		if lives > 0:
			label_subtitle.text = tr("STR_LIFE_EMPTY_RECOVERED")
		else:
			label_subtitle.text = tr("STR_LIFE_EMPTY_SUBTITLE").format([_maximum])
	if pencils == null:
		return
	var gm := _game_manager()
	var next_unix := 0.0
	if gm != null and gm.has_method("seconds_to_next_life"):
		var wait := int(gm.call("seconds_to_next_life"))
		if wait > 0:
			next_unix = Time.get_unix_time_from_system() + float(wait)
	# show_risk = false: popup này không có "bút sắp gãy"
	pencils.set_state(lives, _maximum, next_unix, false)
	# DEFERRED: tránh gọi lại set_state ngay trong lúc nó đang phát recover_finished
	if not pencils.recover_finished.is_connected(_refresh):
		pencils.recover_finished.connect(_refresh, CONNECT_DEFERRED)


# ---------------------------------------------------------------------------
# Nút bấm
# ---------------------------------------------------------------------------
func _on_exit_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	exit_requested.emit()
	close()


func _on_shop_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	shop_requested.emit()
	close()
