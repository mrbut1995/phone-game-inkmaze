class_name ShopNoadsRow
extends Control
## ============================================================================
## Hàng VIP "GÓI XOÁ QUẢNG CÁO (NO ADS)" — 980×200, nằm TRÊN CÙNG tab NẠP XU
## (mockup/shopping_coin.svg): nhãn đỏ · tiêu đề lớn · mô tả · nút giá VNĐ đỏ.
## ============================================================================

signal action_pressed(item_id: String)

const CARD_ART := preload("res://assets/images/shop/card_noads.svg")
const BTN := preload("res://assets/images/shop/btn_noads.svg")
const OWNED_BTN := preload("res://assets/images/shop/btn_equipped.svg")

var item_id: String = ""
var item_data: Dictionary = {}


func setup(data: Dictionary) -> void:
	item_data = data
	item_id = str(data.get("id", ""))
	_refresh()


func _refresh() -> void:
	_set_label("Body/Info/Title", TranslationServer.translate(str(item_data.get("name_key", ""))))
	_set_label("Body/Info/Desc", TranslationServer.translate(str(item_data.get("desc_key", ""))))
	var badge_label := get_node_or_null("Body/Info/Badge/BadgeLabel") as Label
	if badge_label != null:
		var badge_key := str(item_data.get("badge_key", ""))
		badge_label.visible = not badge_key.is_empty()
		if not badge_key.is_empty():
			badge_label.text = TranslationServer.translate(badge_key)
		var badge := get_node_or_null("Body/Info/Badge") as NinePatchRect
		if badge != null:
			badge.visible = badge_label.visible
			# chip ÔM NHÃN: chỉ đặt bề rộng TỐI THIỂU theo bề rộng chữ (vị trí do VBoxContainer dàn)
			badge.custom_minimum_size.x = badge_label.get_minimum_size().x + 12.0
	_set_button()


func _set_button() -> void:
	var btn := get_node_or_null("Body/Action") as TextureButton
	var label := get_node_or_null("Body/Action/ActionLabel") as Label
	if btn == null or label == null:
		return
	if Shop.is_owned(item_id):		# đã mua gói xoá quảng cáo -> khoá nút
		btn.texture_normal = OWNED_BTN
		btn.texture_pressed = OWNED_BTN
		btn.texture_hover = OWNED_BTN
		btn.texture_disabled = OWNED_BTN
		btn.disabled = true
		btn.modulate = Color.WHITE
		label.theme_type_variation = &"ShopBtnTextDone"
		label.text = TranslationServer.translate("STR_SHOP_OWNED_BTN")
		return
	btn.disabled = false
	btn.modulate = Color.WHITE
	btn.texture_normal = BTN
	btn.texture_pressed = BTN
	btn.texture_hover = BTN
	btn.texture_disabled = BTN
	label.theme_type_variation = &"ShopNoadsPrice"
	label.text = Shop.vnd_text(int(item_data.get("vnd", 0)))


func _set_label(path: String, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.text = text


func _on_action_pressed() -> void:
	action_pressed.emit(item_id)
