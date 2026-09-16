class_name ShopCoinTile
extends Control
## ============================================================================
## Thẻ GÓI NẠP XU 475×240 — lưới 2 cột ở tab NẠP XU (mockup/shopping_coin.svg):
##   vòng icon + ICON CẤP XU (coin_t1..coin_t5: xu đơn · cọc · đống · túi · rương)
##   · tên gói · mô tả · dòng ưu đãi · nút giá VNĐ (STUB IAP)
## ============================================================================

signal action_pressed(item_id: String)

const CARD_ART := preload("res://assets/images/shop/card_coin.svg")
const CIRCLE := preload("res://assets/images/shop/icon_circle.svg")
const BTN := preload("res://assets/images/shop/btn_coin.svg")
const ICONS := {
	"coin_t1": preload("res://assets/images/shop/icon_coin_t1.svg"),
	"coin_t2": preload("res://assets/images/shop/icon_coin_t2.svg"),
	"coin_t3": preload("res://assets/images/shop/icon_coin_t3.svg"),
	"coin_t4": preload("res://assets/images/shop/icon_coin_t4.svg"),
	"coin_t5": preload("res://assets/images/shop/icon_coin_t5.svg"),
}

var item_id: String = ""
var item_data: Dictionary = {}


func setup(data: Dictionary) -> void:
	item_data = data
	item_id = str(data.get("id", ""))
	_refresh()


## Icon cấp Xu của gói (dùng cho test + đối chiếu mockup)
func icon_texture() -> Texture2D:
	var icon := get_node_or_null("Icon") as TextureRect
	return icon.texture if icon != null else null


func _refresh() -> void:
	var color := Color(str(item_data.get("color", "#F59E0B")))
	var bar := get_node_or_null("Bar") as ColorRect
	if bar != null:
		bar.color = color
	var circle := get_node_or_null("IconCircle") as TextureRect
	if circle != null:
		circle.texture = CIRCLE
		circle.modulate = Color(color.r, color.g, color.b, 0.18)
	var icon := get_node_or_null("Icon") as TextureRect
	if icon != null:
		icon.texture = ICONS.get(str(item_data.get("icon", "coin_t1")), ICONS["coin_t1"])
	_refresh_badge()
	_set_texts()
	_set_button()


func _refresh_badge() -> void:
	var badge := get_node_or_null("Badge") as NinePatchRect
	var badge_label := get_node_or_null("BadgeLabel") as Label
	var badge_key := str(item_data.get("badge_key", ""))
	if badge == null or badge_label == null:
		return
	if badge_key.is_empty():
		badge.visible = false
		badge_label.visible = false
		return
	badge.visible = true
	badge_label.visible = true
	badge_label.text = TranslationServer.translate(badge_key)
	var width := maxf(badge_label.get_minimum_size().x + 34.0, 88.0)
	badge.position = Vector2(28, 16)
	badge.size = Vector2(width, 26)
	badge_label.position = badge.position
	badge_label.size = badge.size


func _set_texts() -> void:
	var desc := TranslationServer.translate(str(item_data.get("desc_key", "")))
	_set_label("Name", TranslationServer.translate(str(item_data.get("name_key", ""))))
	_set_label("Desc", desc)
	# Dòng ưu đãi: chỉ hiện khi MÔ TẢ chưa nhắc tới số Xu thưởng (tránh lặp 2 dòng giống nhau)
	var bonus := int(item_data.get("bonus", 0))
	var bonus_label := get_node_or_null("Bonus") as Label
	if bonus_label != null:
		var show_bonus := bonus > 0 and not desc.contains(Shop.thousands(bonus))
		bonus_label.visible = show_bonus
		if show_bonus:
			bonus_label.text = "%s +%s %s" % [
				TranslationServer.translate("STR_SHOP_BONUS_TAG"),
				Shop.thousands(bonus),
				TranslationServer.translate("STR_SHOP_UNIT_COIN")]


func _set_button() -> void:
	var btn := get_node_or_null("Action") as TextureButton
	var label := get_node_or_null("ActionLabel") as Label
	if btn == null or label == null:
		return
	btn.texture_normal = BTN
	btn.texture_pressed = BTN
	btn.texture_hover = BTN
	btn.texture_disabled = BTN
	label.theme_type_variation = &"ShopPrice"
	label.text = Shop.vnd_text(int(item_data.get("vnd", 0)))


func _set_label(path: String, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null:
		label.text = text


func _on_action_pressed() -> void:
	action_pressed.emit(item_id)
