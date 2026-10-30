class_name RetryPopup
extends BasePopup
## ============================================================================
## Popup: HỒI SINH khi thua (nodes/popups/retry.tscn)
##
## Xuất hiện TRƯỚC popup Game Over thông thường:
##   1. Xem quảng cáo (nút xanh dương)  -> HỒI SINH
##   2. Trả Xu (nút xanh lá)            -> HỒI SINH
##   3. Bỏ qua                          -> popup Game Over thật (UIController trừ 1 LƯỢT)
##
## HỒI SINH = tiếp tục ĐÚNG ván đang chơi (Level: lùi về bước trước · Dungeon: +bước),
## KHÔNG bắt đầu lại ván. Popup đã tự lo quảng cáo / trừ Xu; UIController nhận
## `revive_requested` rồi phát `revive_confirmed` -> GameController.revive_run().
##
## LƯỢT CHƠI = "bút chì": GameManager giữ số lượt (lives), mốc hồi (next_life_at)
## và trừ lượt trong register_run_loss() — popup này CHỈ HIỂN THỊ, không trừ lượt.
## Back / đóng popup mà chưa chọn = Bỏ qua (xem _on_close) ⇒ cũng mất 1 lượt.
## ============================================================================

signal revive_requested(method: String)
signal skip_requested

@export var DEFAULT_GOLD_COST: int = 100

## Node binding: gán trong nodes/popups/retry.tscn
@export var label_title: Label = null
@export var label_subtitle: Label = null
@export var btn_ad: BaseButton = null
@export var btn_gold: BaseButton = null
@export var btn_skip: BaseButton = null
## Số Xu hiện trên viên giá của nút trả Xu
@export var label_gold_cost: Label = null
## Cụm "−1 ✎" cạnh chữ BỎ QUA — chỉ hiện khi bỏ qua THẬT SỰ bị trừ lượt
@export var skip_cost: Control = null
## Hàng bút chì + đếm ngược hồi bút
@export var pencils: RetryPencils = null
@export var label_warning: Label = null

var _gold_cost: int = 100
var _chosen := false


func _on_open() -> void:
	_chosen = false
	_gold_cost = int(data.get("gold_cost", DEFAULT_GOLD_COST))

	if label_title != null:
		label_title.text = tr("STR_RETRY_POPUP_TITLE")  # keep-code: chữ theo dữ liệu (runtime)
	if label_subtitle != null:
		label_subtitle.text = _subtitle_text()
	if label_gold_cost != null:
		label_gold_cost.text = str(_gold_cost)

	_connect_life_signal()
	_refresh_pencils()

	# Cảnh báo bút CUỐI (nếu bỏ qua là hết lượt chơi). Lỗi quảng cáo/Xu sẽ ghi đè dòng này.
	_hide_warning()
	if _will_charge_life() and _lives_now() == 1:
		_show_warning("STR_RETRY_LAST_PENCIL")


## Lời nhắn theo cách hồi sinh của chế độ: Dungeon (endless) được CỘNG BƯỚC, các chế độ
## còn lại LÙI VỀ BƯỚC TRƯỚC (xem GameController.revive_run).
func _subtitle_text() -> String:
	if bool(data.get("endless", false)):
		return tr("STR_RETRY_SUBTITLE_STEPS").format([int(data.get("revive_steps", 0))])
	return tr("STR_RETRY_POPUP_SUBTITLE")


func _on_close() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and gm.is_connected("life_changed", _on_life_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		gm.disconnect("life_changed", _on_life_changed)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
	if not _chosen:
		_chosen = true
		skip_requested.emit()


# ---------------------------------------------------------------------------
# Lượt chơi (đọc từ GameManager, qua /root như các manager khác)
# ---------------------------------------------------------------------------
func _game_manager() -> Node:
	return Svc.game()


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


## Bỏ qua popup này có bị trừ 1 lượt không? Khớp UIController._charge_life_cost +
## GameManager.register_run_loss: luồng học việc (guided) và ván Debug không bị trừ.
func _will_charge_life() -> bool:
	if bool(data.get("guided", false)):
		return false
	var gm := _game_manager()
	if gm != null and bool(gm.get("debug_run")):
		return false
	return true


func _connect_life_signal() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_signal("life_changed") \
			and not gm.is_connected("life_changed", _on_life_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		gm.connect("life_changed", _on_life_changed)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


## Lượt đổi khi popup đang mở (vd hồi xong 1 bút) -> vẽ lại hàng bút
func _on_life_changed(_lives: int, _max: int) -> void:
	_refresh_pencils()


func _refresh_pencils() -> void:
	var will_charge := _will_charge_life()
	if skip_cost != null:
		skip_cost.visible = will_charge
	if pencils == null:
		return
	var gm := _game_manager()
	var next_unix := 0.0
	if gm != null and gm.has_method("seconds_to_next_life"):
		var wait := int(gm.call("seconds_to_next_life"))
		if wait > 0:
			next_unix = Time.get_unix_time_from_system() + float(wait)
	pencils.set_state(_lives_now(), _max_lives(), next_unix, will_charge)
		# Dây `recover_finished -> _refresh_pencils` (deferred) khai trong nodes/popups/retry.tscn

# ---------------------------------------------------------------------------
# Nút bấm
# ---------------------------------------------------------------------------
func _on_ad_pressed() -> void:
	if _chosen:
		return
	Sfx.play(Sfx.BTN_CLICK)

	var ads: Node = Svc.ads()
	var rewarded := true
	if ads != null and ads.has_method("show_rewarded"):
		rewarded = bool(ads.call("show_rewarded", "retry"))

	if not rewarded:
		_show_warning("STR_RETRY_AD_NOT_AVAILABLE")
		return

	_chosen = true
	revive_requested.emit("ad")
	close()


func _on_gold_pressed() -> void:
	if _chosen:
		return
	Sfx.play(Sfx.BTN_CLICK)

	if Archivement.coins() < _gold_cost or not Archivement.spend_coins(_gold_cost):
		_show_warning("STR_RETRY_NOT_ENOUGH_GOLD")
		Sfx.play(Sfx.WALL_HIT)
		return

	_chosen = true
	revive_requested.emit("gold")
	close()


func _on_skip_pressed() -> void:
	if _chosen:
		return
	_chosen = true
	Sfx.play(Sfx.BTN_WOOD_TAP)
	skip_requested.emit()
	close()


# ---------------------------------------------------------------------------
# Dòng cảnh báo
# ---------------------------------------------------------------------------
func _show_warning(key: String) -> void:
	if label_warning == null:
		return
	label_warning.text = tr(key)
	label_warning.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)


func _hide_warning() -> void:
	if label_warning == null:
		return
	label_warning.text = ""  # keep-code: chữ theo dữ liệu (runtime)
	label_warning.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)
