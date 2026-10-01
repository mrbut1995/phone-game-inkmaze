class_name EditProfileItem
extends Button
## ============================================================================
## 1 ô mẫu trong popup DIỆN MẠO HỒ SƠ (nodes/popups/edit_profile_item.tscn)
## — avatar hoặc viền khung (mockup popup_edit_user_display_avatar/frame.svg)
##
## Node tĩnh khai trong .tscn; ở đây chỉ ĐỔ DỮ LIỆU + chọn trạng thái hiển thị:
##   ĐANG DÙNG (viền xanh + dấu tick) · SỞ HỮU · KHOÁ theo mốc · giá XU
## ============================================================================

const COLOR_EQUIPPED := Color(0.1176, 0.2510, 0.6980)   # #1E40AF
const COLOR_OWNED := Color(0.3922, 0.4549, 0.5451)      # #64748B
const COLOR_LOCK_DUNGEON := Color(0.8627, 0.1490, 0.1490)  # #DC2626
const COLOR_LOCK_STREAK := Color(0.8510, 0.4667, 0.0235)   # #D97706
const COLOR_LOCK_POINTS := Color(0.8510, 0.4667, 0.0235)   # #D97706

@onready var _selected: NinePatchRect = get_node_or_null("Bg/Selected")
@onready var _icon: TextureRect = get_node_or_null("Bg/Disc/Icon")
@onready var _lock_icon: TextureRect = get_node_or_null("Bg/Disc/LockIcon")
@onready var _check: TextureRect = get_node_or_null("Bg/Check")
@onready var _name_label: Label = get_node_or_null("Bg/Name")
@onready var _state_label: Label = get_node_or_null("Bg/State")
@onready var _price_chip: Control = get_node_or_null("Bg/PriceChip")


## Nạp 1 món trong catalog (entry đã tính trạng thái từ PlayerProfileManager)
func set_item(entry: Dictionary) -> void:
	if _name_label != null:
		_name_label.text = tr(str(entry.get("name_key", "")))
	if _icon != null:
		_icon.texture = load(str(entry.get("icon", ""))) as Texture2D
	var equipped := bool(entry.get("equipped", false))
	var locked := bool(entry.get("locked", false))
	var owned := bool(entry.get("owned", false))
	var price := int(entry.get("price", 0))
	if _selected != null:
		_selected.visible = equipped
	if _check != null:
		_check.visible = equipped
	if _lock_icon != null:
		_lock_icon.visible = locked
	# Món bị khoá: vẫn hiện hình mờ + ổ khoá đè lên (mockup: nhìn thấy nhân vật nhưng bị khoá)
	if _icon != null:
		_icon.visible = true
		_icon.modulate = Color(1, 1, 1, 0.35 if locked and not equipped else 1.0)
	_paint_state(equipped, locked, owned, price, entry)


func _paint_state(equipped: bool, locked: bool, owned: bool, price: int, entry: Dictionary) -> void:
	if _price_chip != null:
		_price_chip.visible = not owned and not locked and price > 0
	if _price_chip != null and _price_chip.visible:
		var price_text := _price_chip.get_node_or_null("Text") as Label
		if price_text != null:
			price_text.text = tr("STR_EDIT_PRICE_FORMAT").format([price])
	if _state_label == null:
		return
	if equipped:
		_state_label.text = tr("STR_EDIT_EQUIPPED")
		_tint(_state_label, COLOR_EQUIPPED)
	elif locked:
		_state_label.text = _lock_text(entry)
		_tint(_state_label, _lock_color(str(entry.get("lock_stat", ""))))
	elif owned:
		_state_label.text = tr("STR_EDIT_OWNED")
		_tint(_state_label, COLOR_OWNED)
	else:
		# Món bán bằng Xu nhưng chưa mua: giá hiện trong chip vàng, nhãn trạng thái để trống
		_state_label.text = ""


## "Dungeon Tầng 50" · "Chuỗi Daily 30 ngày" · "500 AP Danh Hiệu"
func _lock_text(entry: Dictionary) -> String:
	var value := int(entry.get("lock_value", 0))
	match str(entry.get("lock_stat", "")):
		"daily_streak":
			return tr("STR_LOCK_STREAK").format([value])
		"points":
			return tr("STR_LOCK_POINTS").format([value])
		_:
			return tr("STR_LOCK_DUNGEON").format([value])


func _lock_color(stat_key: String) -> Color:
	match stat_key:
		"daily_streak":
			return COLOR_LOCK_STREAK
		"points":
			return COLOR_LOCK_POINTS
		_:
			return COLOR_LOCK_DUNGEON


func _tint(label: Label, color: Color) -> void:
	if label.label_settings == null:
		label.add_theme_color_override("font_color", color)
		return
	var settings := label.label_settings.duplicate() as LabelSettings
	settings.font_color = color
	label.label_settings = settings
