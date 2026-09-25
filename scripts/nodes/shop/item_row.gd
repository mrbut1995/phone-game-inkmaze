class_name ShopItemRow
extends Control
## ============================================================================
## Thẻ HÀNG dạng NGANG (980×180) — dùng cho tab DỤNG CỤ và NẠP XU.
## setup(item) nhận 1 mục trong ShopManager.ITEMS; nút bên phải đổi theo trạng thái:
##   MUA / MUA THÊM (dụng cụ) · giá VNĐ (gói nạp) · SỬ DỤNG · ĐANG DÙNG ✓
## ============================================================================

signal action_pressed(item_id: String)

const ICON_BOX := preload("res://assets/images/icons/icon_box.svg")
const BTN_NORMAL := preload("res://assets/images/shop/btn_action_normal.svg")
const BTN_PRESSED := preload("res://assets/images/shop/btn_action_pressed.svg")
const BTN_AMBER := preload("res://assets/images/shop/btn_action_amber.svg")
const BTN_DONE := preload("res://assets/images/shop/btn_equipped.svg")
const ICONS := {
	"pen": preload("res://assets/images/icons/icon_pen.svg"),
	"ink": preload("res://assets/images/icons/icon_ink.svg"),
	"paper": preload("res://assets/images/icons/icon_paper.svg"),
	"coin": preload("res://assets/images/icons/icon_coin.svg"),
	"tool_undo": preload("res://assets/images/icons/icon_tool_undo.svg"),
	"tool_hint": preload("res://assets/images/icons/icon_tool_hint.svg"),
	"tool_reveal": preload("res://assets/images/icons/icon_tool_reveal.svg"),
	"tool_time": preload("res://assets/images/icons/icon_tool_time.svg"),
	"tool_revive": preload("res://assets/images/icons/icon_tool_revive.svg"),
	"tool_shield": preload("res://assets/images/icons/icon_tool_shield.svg"),
}

var item_id: String = ""
var item_data: Dictionary = {}


func setup(data: Dictionary) -> void:
	item_data = data
	item_id = str(data.get("id", ""))
	_refresh()


func _refresh() -> void:
	var color := Color(str(item_data.get("color", "#3D83AE")))
	_set_icon(color)
	_set_texts()
	_set_button(color)


func _set_icon(color: Color) -> void:
	var box := get_node_or_null("Panel/IconBox") as TextureRect
	if box != null:
		box.texture = ICON_BOX
		box.self_modulate = Color(color.r, color.g, color.b, 1.0).lerp(Color.WHITE, 0.78)
	var icon := get_node_or_null("Panel/IconBox/Icon") as TextureRect
	if icon != null:
		icon.texture = ICONS.get(str(item_data.get("icon", "pen")), ICONS["pen"])
		icon.self_modulate = color


func _set_texts() -> void:
	_set_label("Panel/Description/Name", TranslationServer.translate(str(item_data.get("name_key", ""))))
	_set_label("Panel/Description/Desc", TranslationServer.translate(str(item_data.get("desc_key", ""))))
	_set_label("Panel/Description/Stock", str(_stock_text()))
	var badge_key := str(item_data.get("badge_key", ""))
	var badge := get_node_or_null("Panel/Badge") as NinePatchRect
	var badge_label := get_node_or_null("Panel/Badge/BadgeLabel") as Label
	if badge != null:
		badge.visible = not badge_key.is_empty()
	if badge_label != null:
		badge_label.visible = not badge_key.is_empty()
		if not badge_key.is_empty():
			badge_label.text = TranslationServer.translate(badge_key)


## Dòng phụ: kho hàng còn lại (dụng cụ) hoặc ưu đãi (gói nạp)
func _stock_text() -> String:
	if Shop.is_consumable(item_id):
		return TranslationServer.translate("STR_SHOP_STOCK_FORMAT").format([
			Shop.tool_count(item_id),
			TranslationServer.translate("STR_SHOP_UNIT_TURN")])
	var bonus := int(item_data.get("bonus", 0))
	if bonus > 0:
		return "%s  (+%s %s)" % [
			TranslationServer.translate("STR_SHOP_BONUS_TAG"),
			Shop.thousands(bonus),
			TranslationServer.translate("STR_SHOP_UNIT_COIN")]
	return ""


func _set_button(color: Color) -> void:
	var btn := get_node_or_null("Panel/Action") as TextureButton
	var label := get_node_or_null("Panel/Action/ActionLabel") as Label
	if btn == null or label == null:
		return
	btn.disabled = false
	var category: String = str(Shop.category_of(item_id))
	var price := int(Shop.item(item_id).get("price", 0))

	if str(category) == "coin":		# Gói nạp tiền thật: nút hổ phách ghi giá VNĐ (gói xoá quảng cáo chỉ mua 1 lần)
		var vnd := int(item_data.get("vnd", 0))
		btn.texture_normal = BTN_AMBER
		btn.texture_pressed = BTN_AMBER
		if bool(item_data.get("no_ads", false)) and Shop.is_owned(item_id):
			_use_done_style(btn, label)
		else:
			label.text = Shop.vnd_text(vnd)
			label.theme_type_variation = &"ShopBtnTextAmber"
		return

	# Dụng cụ / bút / chủ đề
	if Shop.is_equipped(item_id):
		_use_done_style(btn, label)
		return
	btn.texture_normal = BTN_NORMAL
	btn.texture_pressed = BTN_PRESSED
	btn.disabled = not Shop.can_afford(item_id)
	label.theme_type_variation = &"ShopBtnText"
	if Shop.is_owned(item_id):
		label.text = TranslationServer.translate("STR_SHOP_USE")
	elif Shop.is_consumable(item_id):
		label.text = "%s  %s" % [TranslationServer.translate("STR_SHOP_BUY_MORE"), Shop.thousands(price)]
	else:
		label.text = TranslationServer.translate("STR_SHOP_PRICE_FORMAT").format([Shop.thousands(price)])


func _use_done_style(btn: TextureButton, label: Label) -> void:
	btn.texture_normal = BTN_DONE
	btn.texture_pressed = BTN_DONE
	btn.disabled = true
	label.theme_type_variation = &"ShopBtnTextDone"
	label.text = TranslationServer.translate("STR_SHOP_EQUIPPED")


func _set_label(path: String, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.text = text


func _on_action_pressed() -> void:
	action_pressed.emit(item_id)
