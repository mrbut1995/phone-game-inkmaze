class_name RetryPopup
extends BasePopup
## ============================================================================
## Popup: Thử lại màn chơi khi Game Over (nodes/popups/retry.tscn)
##
## Xuất hiện TRƯỚC popup Game Over thông thường:
##   1. Xem quảng cáo (Advert) để thử lại
##   2. Trả Gold (Xu) để thử lại
##   3. Bỏ qua -> chuyển sang popup Game Over thực sự (gameover_level / gameover_challenge)
## ============================================================================

signal retry_requested(method: String)
signal skip_requested

@export var DEFAULT_GOLD_COST: int = 100

## Node binding: gán trong nodes/popups/retry.tscn
@export var label_title: Label = null
@export var label_subtitle: Label = null
@export var btn_ad: BaseButton = null
@export var btn_gold: BaseButton = null
@export var btn_skip: BaseButton = null
@export var label_ad_title: Label = null
@export var label_ad_desc: Label = null
@export var label_gold_title: Label = null
@export var label_gold_desc: Label = null
@export var label_warning: Label = null

var _gold_cost: int = 100
var _chosen := false


func _on_open() -> void:
	_chosen = false
	_gold_cost = int(data.get("gold_cost", DEFAULT_GOLD_COST))

	if label_title != null:
		label_title.text = tr("STR_RETRY_POPUP_TITLE")
	if label_subtitle != null:
		label_subtitle.text = tr("STR_RETRY_POPUP_SUBTITLE")

	if label_ad_title != null:
		label_ad_title.text = tr("STR_RETRY_AD_TITLE")
	if label_ad_desc != null:
		label_ad_desc.text = tr("STR_RETRY_AD_DESC")

	if label_gold_title != null:
		label_gold_title.text = tr("STR_RETRY_GOLD_TITLE").format([_gold_cost])

	_update_coins_display()

	if label_warning != null:
		label_warning.text = ""
		label_warning.visible = false


func _update_coins_display() -> void:
	var current_coins: int = Archivement.coins()
	if label_gold_desc != null:
		label_gold_desc.text = tr("STR_RETRY_GOLD_DESC").format([current_coins])


func _on_ad_pressed() -> void:
	if _chosen:
		return
	Sfx.play(Sfx.BTN_CLICK)

	var ads: Node = get_node_or_null("/root/AdsManager")
	var rewarded := true
	if ads != null and ads.has_method("show_rewarded"):
		rewarded = bool(ads.call("show_rewarded", "retry"))

	if not rewarded:
		if label_warning != null:
			label_warning.text = tr("STR_RETRY_AD_NOT_AVAILABLE")
			label_warning.visible = true
		return

	_chosen = true
	retry_requested.emit("ad")
	close()


func _on_gold_pressed() -> void:
	if _chosen:
		return
	Sfx.play(Sfx.BTN_CLICK)

	var current_coins: int = Archivement.coins()
	if current_coins < _gold_cost:
		if label_warning != null:
			label_warning.text = tr("STR_RETRY_NOT_ENOUGH_GOLD")
			label_warning.visible = true
		Sfx.play(Sfx.WALL_HIT)
		return

	if not Archivement.spend_coins(_gold_cost):
		if label_warning != null:
			label_warning.text = tr("STR_RETRY_NOT_ENOUGH_GOLD")
			label_warning.visible = true
		return

	_chosen = true
	retry_requested.emit("gold")
	close()


func _on_skip_pressed() -> void:
	if _chosen:
		return
	_chosen = true
	Sfx.play(Sfx.BTN_WOOD_TAP)
	skip_requested.emit()
	close()


func _on_close() -> void:
	if not _chosen:
		_chosen = true
		skip_requested.emit()
