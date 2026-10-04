class_name EditProfileItem
extends TextureButton
## ============================================================================
## 1 ô mẫu trong popup DIỆN MẠO HỒ SƠ (nodes/popups/edit_profile_item.tscn)
## — avatar hoặc viền khung (mockup popup_edit_user_display_avatar/frame.svg)
##
## Nút dùng TEXTUREBUTTON (art 4 trạng thái khai trong scene: thường/hover/nhấn/focus)
## + hiệu ứng nhấn nảy; ở đây chỉ ĐỔ DỮ LIỆU + chọn trạng thái hiển thị:
##   ĐANG DÙNG (viền xanh + dấu tick) · SỞ HỮU · KHOÁ theo mốc · giá XU
## ============================================================================

const COLOR_EQUIPPED := Color(0.1176, 0.2510, 0.6980)   # #1E40AF
const COLOR_OWNED := Color(0.3922, 0.4549, 0.5451)      # #64748B
const COLOR_LOCK_DUNGEON := Color(0.8627, 0.1490, 0.1490)  # #DC2626
const COLOR_LOCK_STREAK := Color(0.8510, 0.4667, 0.0235)   # #D97706
const COLOR_LOCK_POINTS := Color(0.8510, 0.4667, 0.0235)   # #D97706
## Nền chip trạng thái: art gốc xám #F1F5F9 × modulate ≈ #DBEAFE (xanh nhạt của mockup)
const COLOR_CHIP_EQUIPPED := Color(0.909, 0.955, 1.0)   # ≈ #DBEAFE

## Node binding: khai `node_paths` + `NodePath` trong `edit_profile_item.tscn`
@export var selected_bg: NinePatchRect = null
@export var icon: TextureRect = null
@export var frame: TextureRect = null
@export var lock_icon: TextureRect = null
@export var check: TextureRect = null
@export var name_label: Label = null
@export var state_bg: NinePatchRect = null
@export var state_label: Label = null
@export var price_chip: Control = null
@export var price_text: Label = null


func _ready() -> void:
	# Hiệu ứng nhấn nảy (guard: không gắn trùng khi node bị tái sử dụng)
	if not has_meta("bounce_attached"):
		set_meta("bounce_attached", true)
		UIAnim.attach_press_bounce(self, 0.93, 0.09)


## (GIỮ tween) Hiệu ứng xuất hiện so le khi dựng lại lưới / lật trang — thứ tự ô là dữ liệu lúc chạy
func play_entrance(delay := 0.0) -> void:
	# Lưới chưa dàn xong nên chốt tâm xoay theo cỡ KHAI BÁO trước; play_pop_in tự cập nhật nếu đã có cỡ
	if size.length_squared() <= 0.0:
		pivot_offset = custom_minimum_size * 0.5
	UIAnim.play_pop_in(self, delay, 0.88, 0.22)


## Nạp 1 món trong catalog (entry đã tính trạng thái từ PlayerProfileManager)
func set_item(entry: Dictionary) -> void:
	name_label.text = tr(str(entry.get("name_key", "")))
	var equipped := bool(entry.get("equipped", false))
	var locked := bool(entry.get("locked", false))
	var owned := bool(entry.get("owned", false))
	var price := int(entry.get("price", 0))
	selected_bg.visible = equipped
	check.visible = equipped
	lock_icon.visible = locked
	# Món bị khoá: vẫn hiện hình mờ + ổ khoá đè lên (mockup: nhìn thấy nhân vật nhưng bị khoá)
	# Tab VIỀN KHUNG dùng node `Frame` (vòng ôm quanh đĩa), tab AVATAR dùng node `Icon`.
	var icon_path := str(entry.get("icon", ""))
	var is_frame := str(entry.get("id", "")).begins_with("frame_")
	var alpha := 0.35 if locked and not equipped else 1.0
	icon.visible = not is_frame
	if not is_frame:
		icon.texture = load(icon_path) as Texture2D
	icon.modulate = Color(1, 1, 1, alpha)
	frame.visible = is_frame
	if is_frame:
		frame.texture = load(icon_path) as Texture2D
	frame.modulate = Color(1, 1, 1, alpha)
	_paint_state(equipped, locked, owned, price, entry)


func _paint_state(equipped: bool, locked: bool, owned: bool, price: int, entry: Dictionary) -> void:
	price_chip.visible = not owned and not locked and price > 0
	if price_chip.visible:
		price_text.text = tr("STR_EDIT_PRICE_FORMAT").format([price])
	# Nền chip trạng thái (mockup: "ĐANG DÙNG" nền xanh nhạt, "SỞ HỮU" nền xám nhạt);
	# món khoá thì chỉ có chữ điều kiện, không chip.
	state_bg.visible = equipped or owned
	state_bg.modulate = COLOR_CHIP_EQUIPPED if equipped else Color(1, 1, 1, 1)
	if equipped:
		state_label.text = tr("STR_EDIT_EQUIPPED")
		_tint(state_label, COLOR_EQUIPPED)
	elif locked:
		state_label.text = _lock_text(entry)
		_tint(state_label, _lock_color(str(entry.get("lock_stat", ""))))
	elif owned:
		state_label.text = tr("STR_EDIT_OWNED")
		_tint(state_label, COLOR_OWNED)
	else:
		# Món bán bằng Xu nhưng chưa mua: giá hiện trong chip vàng, nhãn trạng thái để trống
		state_label.text = ""


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
