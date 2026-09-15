extends Node
## ============================================================================
## Manager: ThemeManager — ÁP DỤNG CHỦ ĐỀ GIẤY + MÀU MỰC (skin) cho toàn game.
##
## TRẠNG THÁI HIỆN TẠI: **CHUẨN BỊ SẴN** (theo yêu cầu) — mọi dữ liệu, màu sắc và
## API apply_*() đã có, nhưng `apply_enabled = false` nên CHƯA đổi giao diện thật.
## Khi muốn bật: đặt `apply_enabled = true` và hiện thực phần TODO ở `_apply_now()`
## (đổi màu nền giấy/lề đỏ/đường kẻ của màn chơi + màu nét vẽ theo bút đang dùng).
##
## - Nguồn sự thật về "đang dùng món nào" là ShopManager (equipped_pen / equipped_theme);
##   ThemeManager chỉ ĐỌC lại rồi suy ra bảng màu.
## - ShopManager gọi `sync_from_shop()` mỗi khi mua/đổi đồ -> signal `skin_changed`.
## ============================================================================

signal skin_changed(theme_id: String, pen_id: String)

## Bật/tắt việc áp dụng thật vào giao diện (đang để false — chỉ ghi nhận lựa chọn)
var apply_enabled := false

## Bảng màu mặc định (Vở ô ly 4 ly — trùng tông hiện tại của game)
const DEFAULT_PALETTE := {
	"paper": "#FAF5EB",
	"paper_alt": "#FEFDFA",
	"line": "#8FB9D2",
	"margin": "#D84444",
	"ink": "#224C6D",
	"ink_soft": "#718B9E",
	"accent": "#3D83AE",
}

var _theme_id: String = ""
var _pen_id: String = ""
var _pen_color: Color = Color("#224C6D")


func _ready() -> void:
	call_deferred("sync_from_shop")


# ---------------------------------------------------------------------------
# Đọc trạng thái từ ShopManager
# ---------------------------------------------------------------------------
func shop() -> Node:
	return get_node_or_null("/root/ShopManager")


## Đọc lại bút/chủ đề đang dùng từ ShopManager rồi phát tín hiệu
func sync_from_shop() -> void:
	var shop_node := shop()
	if shop_node == null:
		return
	var theme := str(shop_node.get("equipped_theme"))
	var pen := str(shop_node.get("equipped_pen"))
	if theme == _theme_id and pen == _pen_id:
		return
	_theme_id = theme
	_pen_id = pen
	var pen_data: Variant = shop_node.call("item", pen)
	_pen_color = Color(str(pen_data.get("color", "#224C6D"))) if pen_data is Dictionary \
		else Color("#224C6D")
	if apply_enabled:
		_apply_now()
	skin_changed.emit(_theme_id, _pen_id)


# ---------------------------------------------------------------------------
# Truy vấn
# ---------------------------------------------------------------------------
func theme_id() -> String:
	return _theme_id


func pen_id() -> String:
	return _pen_id


## Màu mực của bút đang dùng (dùng cho vết vẽ/nét bút trong game)
func pen_color() -> Color:
	return _pen_color


## Bảng màu của chủ đề đang dùng (nền giấy · đường kẻ · lề đỏ · màu mực...)
func palette() -> Dictionary:
	var out := DEFAULT_PALETTE.duplicate()
	var shop_node := shop()
	if shop_node == null or _theme_id.is_empty():
		return out
	var data: Variant = shop_node.call("item", _theme_id)
	if data is Dictionary:
		if data.has("paper"):
			out["paper"] = str(data.get("paper"))
		if data.has("line"):
			out["line"] = str(data.get("line"))
	return out


## Màu cụ thể của 1 thành phần trong bảng màu (đã parse sang Color)
func color(key: String) -> Color:
	var table := palette()
	return Color(str(table.get(key, DEFAULT_PALETTE.get(key, "#FFFFFF"))))


# ---------------------------------------------------------------------------
# Chuẩn bị sẵn — apply (chưa bật)
# ---------------------------------------------------------------------------
## Người chơi bấm "SỬ DỤNG" cho 1 chủ đề: ghi nhận vào ShopManager rồi tới đây.
func apply_theme(theme_id: String) -> bool:
	var shop_node := shop()
	if shop_node == null or not bool(shop_node.call("equip", theme_id)):
		return false
	sync_from_shop()
	return true


## Người chơi bấm "SỬ DỤNG" cho 1 ngòi bút.
func apply_pen(pen_id: String) -> bool:
	var shop_node := shop()
	if shop_node == null or not bool(shop_node.call("equip", pen_id)):
		return false
	sync_from_shop()
	return true


## Áp dụng thật vào giao diện — TODO khi bật tính năng skin:
##   1. Màn chơi: đổi màu nền giấy + lề đỏ + đường kẻ ô ly theo `palette()`
##   2. Vết vẽ/người chơi: đổi màu nét theo `pen_color()`
##   3. Các màn khác: đổi tông nền giấy cho đồng bộ
func _apply_now() -> void:
	# Chưa áp dụng gì (theo yêu cầu "chuẩn bị sẵn, chưa cần apply vội").
	# Khi bật: duyệt các node cần đổi màu và set theo palette()/pen_color() ở đây.
	pass
