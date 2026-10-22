class_name PenSkin
extends RefCounted
## ============================================================================
## Bảng SKIN NGÒI BÚT (tab "BÚT & MỰC") — nguồn sự thật DUY NHẤT cho:
##   · Con trỏ người chơi trong game   (assets/images/game/player_cursor/*.svg)
##   · Hình minh hoạ ngòi bút ở shop   (assets/images/game/pen_type/*.svg)
##   · Màu mực + CHẤT LIỆU nét vẽ      (moving_line · vệt lịch sử · bàn nháp thử bút)
##
## Mỗi món category "pen" trong ShopManager map 1-1 với 1 dòng trong SKINS.
## Thêm bút mới: thêm item trong ShopManager + 1 dòng ở đây (cursor/icon/ink/style).
## ============================================================================

const DEFAULT_PEN := "pen_blue"
const CURSOR_DIR := "res://assets/images-png/game/player_cursor/"
const ICON_DIR := "res://assets/images-png/game/pen_type/"
## Bề rộng texture nét đứt mặc định (px)
const DASH_TEX_WIDTH := 16

## id món hàng -> { cursor: icon con trỏ · tip: vị trí ĐẦU BÚT trong icon (0..1) · icon: hình ngòi bút ·
##                   ink: màu mực · style: chất liệu }
const SKINS := {
	"pen_blue": {
		"cursor": CURSOR_DIR + "player_cursor_1.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_fountain_pen_nib.png",
		"ink": "#2575A7",
		"style": "ink",
	},
	"pen_purple": {
		"cursor": CURSOR_DIR + "player_cursor_7.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_fountain_pen_nib.png",
		"ink": "#7C3AED",
		"style": "ink",
	},
	"pen_pencil_2b": {
		"cursor": CURSOR_DIR + "player_cursor_2.png",
		"tip": Vector2(0.72, 0.72),
		"icon": ICON_DIR + "pen_pencil.png",
		"ink": "#4B5563",
		"style": "pencil",
	},
	"pen_red_teacher": {
		"cursor": CURSOR_DIR + "player_cursor_3.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_fountain_pen_nib.png",
		"ink": "#DC2626",
		"style": "ink",
	},
	"pen_highlighter": {
		"cursor": CURSOR_DIR + "player_cursor_4.png",
		"tip": Vector2(0.80, 0.73),
		"icon": ICON_DIR + "pen_stabilo_highlighter.png",
		"ink": "#F59E0B",
		"style": "highlighter",
	},
	"pen_gold_ink": {
		"cursor": CURSOR_DIR + "player_cursor_6.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_calligraphy_brush.png",
		"ink": "#B45309",
		"style": "gold",
	},
	"pen_green_tea": {
		"cursor": CURSOR_DIR + "player_cursor_8.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_art_brush.png",
		"ink": "#15803D",
		"style": "brush",
	},
	"pen_pink_diary": {
		"cursor": CURSOR_DIR + "player_cursor_9.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_felt-tip_marker.png",
		"ink": "#DB2777",
		"style": "marker",
	},
	"pen_graphite_4b": {
		"cursor": CURSOR_DIR + "player_cursor_5.png",
		"tip": Vector2(0.80, 0.80),
		"icon": ICON_DIR + "pen_drafting_pencil.png",
		"ink": "#374151",
		"style": "graphite",
	},
	"pen_navy_night": {
		"cursor": CURSOR_DIR + "player_cursor_10.png",
		"tip": Vector2(0.786, 0.786),
		"icon": ICON_DIR + "pen_needle_point_gel.png",
		"ink": "#1E3A8A",
		"style": "gel",
	},
}

## CHẤT LIỆU nét vẽ theo kiểu bút:
##   width      · bề rộng nét (× bề rộng gốc của Line2D)
##   alpha      · độ đậm mực (0..1)
##   cap        · kiểu đầu nét (Line2D.LINE_CAP_*: 1 = vuông phẳng, 2 = tròn)
##   dash/gap   · nét đứt + khoảng hở (× bề rộng nét; 0 = liền mạch)
##   glow*      · quầng sáng phía dưới nét (rộng × bề rộng nét · độ đậm riêng)
const STYLES := {
	"ink": {"width": 1.0, "alpha": 0.57, "cap": 2, "dash": 0.0, "gap": 0.0,
		"glow": 0.0, "glow_width": 1.0, "glow_alpha": 0.0},
	"gel": {"width": 0.85, "alpha": 0.62, "cap": 2, "dash": 0.0, "gap": 0.0,
		"glow": 1.0, "glow_width": 1.9, "glow_alpha": 0.16},
	"pencil": {"width": 0.9, "alpha": 0.46, "cap": 2, "dash": 0.3, "gap": 0.24,
		"glow": 0.0, "glow_width": 1.0, "glow_alpha": 0.0},
	"graphite": {"width": 1.05, "alpha": 0.56, "cap": 2, "dash": 0.28, "gap": 0.12,
		"glow": 1.0, "glow_width": 1.5, "glow_alpha": 0.1},
	"marker": {"width": 1.15, "alpha": 0.44, "cap": 1, "dash": 0.0, "gap": 0.0,
		"glow": 0.0, "glow_width": 1.0, "glow_alpha": 0.0},
	"highlighter": {"width": 1.75, "alpha": 0.32, "cap": 1, "dash": 0.0, "gap": 0.0,
		"glow": 1.0, "glow_width": 1.45, "glow_alpha": 0.12},
	"brush": {"width": 1.3, "alpha": 0.5, "cap": 2, "dash": 0.0, "gap": 0.0,
		"glow": 0.0, "glow_width": 1.0, "glow_alpha": 0.0},
	"gold": {"width": 1.0, "alpha": 0.72, "cap": 2, "dash": 0.0, "gap": 0.0,
		"glow": 1.0, "glow_width": 2.3, "glow_alpha": 0.3},
}

## CẢM GIÁC VIẾT theo kiểu bút (cùng khoá với STYLES) — mỗi bút một "tính cách":
##   corner     · độ bo góc khi rẽ (× bước ô) — nhỏ = góc gắt, lớn = nét lượn
##   wobble     · biên độ run tay (px) · spacing = khoảng cách giữa 2 điểm run (px)
##   start_w    · độ dày lúc BẮT ĐẦU nét (0..1) · taper = đoạn đầu vuốt lên tới 100% (tỉ lệ chiều dài)
##   swell      · nét phình ở giữa (áp lực bút lông) · noise = độ dày không đều (than chì, bút chì)
##   follow     · đầu bút đuổi theo ngón tay nhanh/chậm (nhân với TIP_FOLLOW_SPEED của Board)
##   tail       · mực "chảy" ra theo ngón tay nhanh/chậm (nhân với TAIL_GAIN)
##   lean       · bút nghiêng theo hướng quẹt nhiều/ít (1 = chuẩn)
##   press      · độ co con trỏ khi ấn bút xuống giấy (nhỏ = ấn mạnh tay hơn)
##   haptic     · thời gian rung mỗi bước (ms, chỉ khi bật HAPTIC_ON_STEP)
##   blend      · "mix" thường · "mul" = nhân màu như bút dạ quang thật (số bên dưới vẫn đọc được)
##   shimmer    · quầng sáng nhấp nháy (0 = tắt)
const FEEL_DEFAULT := {"corner": 0.26, "wobble": 0.6, "spacing": 14.0, "start_w": 1.0, "taper": 0.0,
	"swell": 0.0, "noise": 0.0, "follow": 1.0, "tail": 1.0, "lean": 1.0, "press": 0.94,
	"haptic": 8, "blend": "mix", "shimmer": 0.0}

const FEELS := {
	# Bút mực: mượt, hơi phình đầu nét, lượn vừa phải
	"ink": {"corner": 0.26, "wobble": 0.6, "spacing": 14.0, "start_w": 0.78, "taper": 0.06,
		"swell": 0.06, "noise": 0.03, "follow": 1.0, "tail": 1.0, "lean": 1.0, "press": 0.94, "haptic": 8},
	# Bút gel kim: mảnh, chính xác, đầu bút bám tay gần như tức thời
	"gel": {"corner": 0.20, "wobble": 0.15, "spacing": 18.0, "follow": 1.35, "tail": 0.95,
		"lean": 0.7, "press": 0.96, "haptic": 5},
	# Bút chì 2B: run tay nhiều, nét dày mỏng không đều, góc gắt hơn
	"pencil": {"corner": 0.16, "wobble": 1.5, "spacing": 9.0, "start_w": 0.6, "taper": 0.05,
		"noise": 0.22, "follow": 0.95, "tail": 0.9, "lean": 1.1, "press": 0.95, "haptic": 6},
	# Than chì 4B: nặng tay hơn, đậm và hơi lì
	"graphite": {"corner": 0.18, "wobble": 1.1, "spacing": 10.0, "start_w": 0.7, "taper": 0.04,
		"noise": 0.16, "follow": 0.85, "tail": 1.0, "lean": 1.0, "press": 0.93, "haptic": 9},
	# Bút dạ nét to: đầu vuông, ấn mạnh tay, ít run
	"marker": {"corner": 0.12, "wobble": 0.3, "spacing": 16.0, "follow": 0.9, "tail": 1.1,
		"lean": 0.55, "press": 0.90, "haptic": 12},
	# Dạ quang: bản to, đầu dẹt giữ thẳng, chậm rãi, nhân màu để thấy số bên dưới
	"highlighter": {"corner": 0.08, "wobble": 0.1, "spacing": 20.0, "follow": 0.75, "tail": 1.2,
		"lean": 0.4, "press": 0.97, "haptic": 14, "blend": "mul"},
	# Bút lông: nặng tay, nét lượn rộng, đầu nét mảnh rồi phình ra
	"brush": {"corner": 0.38, "wobble": 1.0, "spacing": 18.0, "start_w": 0.45, "taper": 0.12,
		"swell": 0.22, "noise": 0.08, "follow": 0.7, "tail": 1.35, "lean": 1.5, "press": 0.88, "haptic": 10},
	# Mực nhũ vàng (thư pháp): thanh đậm, lượn đẹp, quầng sáng lấp lánh
	"gold": {"corner": 0.32, "wobble": 0.45, "spacing": 16.0, "start_w": 0.4, "taper": 0.10,
		"swell": 0.18, "noise": 0.03, "follow": 0.75, "tail": 1.25, "lean": 1.3, "press": 0.90,
		"haptic": 8, "shimmer": 0.35},
}

static var _cursor_cache: Dictionary = {}
static var _icon_cache: Dictionary = {}
## Chu kỳ nét đứt (px, làm tròn) -> Texture2D (Line2D không có tuỳ chọn co giãn texture)
static var _dash_cache: Dictionary = {}


# ---------------------------------------------------------------------------
# Truy vấn dữ liệu skin
# ---------------------------------------------------------------------------
static func ids() -> Array:
	return SKINS.keys()


static func has_pen(pen_id: String) -> bool:
	return SKINS.has(pen_id)


## Dữ liệu skin của 1 ngòi bút (id lạ -> rơi về bút mặc định)
static func data(pen_id: String) -> Dictionary:
	var entry: Variant = SKINS.get(pen_id, null)
	if not entry is Dictionary:
		entry = SKINS[DEFAULT_PEN]
	return entry


static func style_id(pen_id: String) -> String:
	return str(data(pen_id).get("style", "ink"))


## Thông số CHẤT LIỆU của ngòi bút (bảng STYLES)
static func style_of(pen_id: String) -> Dictionary:
	var entry: Variant = STYLES.get(style_id(pen_id), null)
	return entry if entry is Dictionary else STYLES["ink"]


## Thông số CẢM GIÁC VIẾT của ngòi bút (bảng FEELS, thiếu khoá thì lấy FEEL_DEFAULT)
static func feel_of(pen_id: String) -> Dictionary:
	var f: Dictionary = FEEL_DEFAULT.duplicate()
	var entry: Variant = FEELS.get(style_id(pen_id), null)
	if entry is Dictionary:
		f.merge(entry, true)
	return f


## Vị trí ĐẦU BÚT trong icon con trỏ (toạ độ chuẩn hoá 0..1) — mỗi bút một vị trí khác nhau
static func tip_uv(pen_id: String) -> Vector2:
	var v: Variant = data(pen_id).get("tip", Vector2(0.786, 0.786))
	return v if v is Vector2 else Vector2(0.786, 0.786)


static func ink_color(pen_id: String) -> Color:
	return Color(str(data(pen_id).get("ink", "#2575A7")))


static func cursor_path(pen_id: String) -> String:
	return str(data(pen_id).get("cursor", ""))


static func icon_path(pen_id: String) -> String:
	return str(data(pen_id).get("icon", ""))


## Icon con trỏ người chơi trong game
static func cursor_texture(pen_id: String) -> Texture2D:
	return _texture(cursor_path(pen_id), _cursor_cache)


## Hình minh hoạ ngòi bút (shop / bàn nháp thử)
static func icon_texture(pen_id: String) -> Texture2D:
	return _texture(icon_path(pen_id), _icon_cache)


## Ngòi bút đang dùng (ShopManager.equipped_pen) — dùng khi không truyền id cụ thể
static func equipped_id() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return DEFAULT_PEN
	var shop := tree.root.get_node_or_null("ShopManager")
	if shop == null:
		return DEFAULT_PEN
	var pen := str(shop.get("equipped_pen"))
	return pen if SKINS.has(pen) else DEFAULT_PEN


# ---------------------------------------------------------------------------
# Áp vào nét vẽ (Line2D)
# ---------------------------------------------------------------------------
## Màu mực của nét vẽ (đã nhân độ đậm của chất liệu)
static func line_color(pen_id: String, alpha_scale := 1.0) -> Color:
	var ink := ink_color(pen_id)
	var style := style_of(pen_id)
	return Color(ink.r, ink.g, ink.b,
		clampf(float(style.get("alpha", 0.57)) * alpha_scale, 0.0, 1.0))


## Áp chất liệu + bề rộng cho 1 Line2D (không quầng sáng — nét lịch sử, đường phụ...)
static func apply_line(line: Line2D, pen_id: String, base_width: float,
		alpha_scale := 1.0) -> void:
	if line == null:
		return
	var style := style_of(pen_id)
	line.width = maxf(base_width * float(style.get("width", 1.0)), 1.0)
	line.default_color = line_color(pen_id, alpha_scale)
	var cap := int(style.get("cap", Line2D.LINE_CAP_ROUND))
	line.begin_cap_mode = cap as Line2D.LineCapMode
	line.end_cap_mode = cap as Line2D.LineCapMode
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	var dash := float(style.get("dash", 0.0))
	if dash > 0.0:
		# Nét đứt = TEXTURE lặp (bắt buộc bật texture_repeat cho CanvasItem,
		# nếu không Line2D sẽ lặp texture bằng cách kẹp mép -> gần như vô hình)
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line.texture = dash_texture_for((dash + float(style.get("gap", 0.0))) * line.width,
			line.width)
		line.material = null
	else:
		line.texture_mode = Line2D.LINE_TEXTURE_NONE
		line.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
		line.texture = null
		line.material = null


## Quầng sáng của chất liệu: {width_mult, alpha} — {} = ngòi bút không có quầng sáng
static func glow_of(pen_id: String) -> Dictionary:
	var style := style_of(pen_id)
	var alpha := float(style.get("glow_alpha", 0.0))
	var width_mult := float(style.get("glow_width", 1.0))
	if alpha <= 0.0 or width_mult <= 1.0 or float(style.get("glow", 0.0)) <= 0.0:
		return {}
	return {"width_mult": width_mult, "alpha": alpha}


## Texture NÉT ĐỨT theo đúng CHU KỲ (px): ~62% nét đặc + phần còn lại trong suốt.
## - Line2D lặp texture theo pixel nên phải sinh riêng cho mỗi chu kỳ (có cache).
## - Chiều CAO texture = bề rộng nét để không bị sọc ngang khi bật texture_repeat.
static func dash_texture_for(period_px: float, height_px := 8.0) -> Texture2D:
	var period := maxi(int(round(period_px)), 6)
	var height := clampi(int(round(height_px)), 4, 64)
	var key := "%dx%d" % [period, height]
	if _dash_cache.has(key):
		return _dash_cache[key] as Texture2D
	var dash_len := maxi(int(round(float(period) * 0.62)), 3)
	var img := Image.create_empty(period, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in dash_len:
		for y in height:
			img.set_pixel(x, y, Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	_dash_cache[key] = tex
	return tex


## Texture nét đứt chu kỳ mặc định (API tiện dụng cho test)
static func dash_texture() -> Texture2D:
	return dash_texture_for(DASH_TEX_WIDTH)


static func _texture(path: String, cache: Dictionary) -> Texture2D:
	if path.is_empty():
		return null
	if cache.has(path):
		return cache[path] as Texture2D
	var res: Resource = load(path) if ResourceLoader.exists(path) else null
	var tex := res as Texture2D
	cache[path] = tex
	return tex
