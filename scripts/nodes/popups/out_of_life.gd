class_name OutOfLifePopup
extends BasePopup
## ============================================================================
## Popup: HẾT LƯỢT CHƠI (nodes/popups/out_of_life.tscn)
##
## Hiện khi người chơi bấm vào màn chơi mà KHÔNG còn lượt (life = 0). Hai lựa chọn:
##   1. Thoát ra      — đóng popup, ở lại màn hiện tại
##   2. Vào Cửa hàng  — mua thêm lượt; nút Back của Cửa hàng quay lại ĐÚNG màn này
##                      (GameManager nhớ `shop_return_path` lúc mở Shop)
##
## Dữ liệu: open({ max_lives })
## ============================================================================

signal exit_requested
signal shop_requested

## Node binding: khai `node_paths` + `NodePath` trong `out_of_life.tscn`
@export var label_title: Label = null
@export var label_subtitle: Label = null
@export var label_recharge: Label = null
@export var icon_life: TextureRect = null
@export var btn_exit: BaseButton = null
@export var btn_shop: BaseButton = null


func _on_open() -> void:
	var maximum := maxi(int(data.get("max_lives", Life.max_count())), 1)
	if label_title != null:
		label_title.text = tr("STR_LIFE_EMPTY_TITLE")
	if label_subtitle != null:
		label_subtitle.text = tr("STR_LIFE_EMPTY_SUBTITLE").format([maximum])
	if icon_life != null:
		icon_life.visible = true
	_refresh_recharge()


## Đếm ngược tới lượt kế tiếp (popup có thể mở lâu — làm mới mỗi giây)
func _process(_delta: float) -> void:
	_refresh_recharge()


func _refresh_recharge() -> void:
	if label_recharge == null:
		return
	var seconds := Life.seconds_to_next()
	if seconds <= 0:
		label_recharge.text = tr("STR_LIFE_EMPTY_RECHARGE_FULL")
		return
	label_recharge.text = tr("STR_LIFE_EMPTY_RECHARGE").format([Life.clock_text(seconds)])


func _on_exit_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	exit_requested.emit()
	close()


func _on_shop_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	shop_requested.emit()
	close()
