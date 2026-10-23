class_name ChapterProgress
extends Control
## ============================================================================
## Component: THANH TIẾN ĐỘ + 3 RƯƠNG MỐC của CHƯƠNG (màn Chọn chương)
## — `nodes/chapters/chapter_progress.tscn`, cùng ngôn ngữ hình ảnh với thanh Sao
## của màn Daily (bar `bar_track`/`bar_fill_gold` + huy hiệu rương `chest_chip`).
##
## Hiển thị chương ĐANG CHƠI: `x / y SAO` + thanh đầy theo TỈ LỆ Sao của chương, và
## 3 rương nằm đúng vị trí ngưỡng (33% · 67% · 100%) — ngưỡng do
## `GameManager.chapter_chest_defs(stars_total)` quyết định.
##
## Bấm rương đủ Sao ⇒ phát `claim_requested(index)`; màn Chọn chương gọi
## `GameManager.claim_chapter_chest()` rồi vẽ lại thanh.
##
## Widget TỰ ĐỊNH VỊ chip (không dùng container) để rương luôn nằm đúng tâm thanh
## ở mọi bề rộng/khung hình — toạ độ tính lại khi node đổi kích thước.
## ============================================================================

signal claim_requested(index: int)

## Khoảng hở hai đầu thanh để rương ở 0%/100% không bị cắt mất nửa vòng tròn
const EDGE_MARGIN := 19.0
## Lề dọc (bản dọc) để rương ở 0★ / 100% không bị cắt
const EDGE_MARGIN_V := 19.0

## `true` = thanh DỌC ở lề trái (bản dọc màn Chọn màn): 0★ ở ĐÁY, 100% ở ĐỈNH.
## `false` = thanh NGANG như cũ (bản ngang + màn Chọn chương cũ).
@export var vertical := false
## Nhãn ngưỡng "9★" nằm DƯỚI chip (bản ngang); `false` = bên phải chip (thanh dọc)
@export var threshold_below := false

@export var bar: TextureProgressBar = null
## Nhãn "x / y SAO" (góc phải trên)
@export var count_label: Label = null
## Nhãn tiêu đề nhỏ (góc trái trên)
@export var caption_label: Label = null
## Node chứa 3 chip rương (thứ tự = thứ tự mốc)
@export var chips_host: Control = null

var _chip_defs: Array[Dictionary] = []
var _stars_own := 0
var _stars_total := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if chips_host != null:
		for child in chips_host.get_children():
			var chip := child as ChapterChestChip
			if chip != null and not chip.claim_requested.is_connected(_on_chip_claim_requested):
				chip.claim_requested.connect(_on_chip_claim_requested)
	if not resized.is_connected(_layout_chips):
		resized.connect(_layout_chips)
	if bar != null and not bar.resized.is_connected(_layout_chips):
		bar.resized.connect(_layout_chips)
	_connect_locale_signal()
	_apply_texts()
	_layout_chips.call_deferred()


## Đổi ngôn ngữ (hoặc bảng dịch nạp XONG sau lần vẽ đầu) ⇒ viết lại 2 nhãn.
## Cần thiết vì `_ready()` của màn có thể chạy trước khi `LocalizationManager` nạp xong bảng dịch.
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()


## Viết lại nhãn tiêu đề + "x / y SAO" theo ngôn ngữ hiện tại
func _apply_texts() -> void:
	if caption_label != null:
		caption_label.text = tr("STR_CHAPTER_PROGRESS_TITLE")
	if count_label != null:
		# Bảng dịch chưa sẵn sàng ⇒ tr() trả lại đúng khoá; dùng mẫu mặc định để không hiện "{0}"
		var pattern := tr("STR_CHAPTER_STARS_FORMAT")
		if pattern == "STR_CHAPTER_STARS_FORMAT":
			pattern = "{0} / {1} STARS"
		count_label.text = pattern.format([_stars_own, _stars_total])


## Nạp dữ liệu của một chương: `stars_own` Sao đã đạt / `stars_total` Sao tối đa của chương
func setup(stars_own: int, stars_total: int) -> void:
	_stars_own = maxi(stars_own, 0)
	_stars_total = maxi(stars_total, 0)
	var gm := _game_manager()
	_chip_defs.clear()
	if gm != null and gm.has_method("chapter_chest_defs"):
		for def_v in gm.call("chapter_chest_defs", _stars_total):
			_chip_defs.append((def_v as Dictionary).duplicate(true))

	if bar != null:
		bar.min_value = 0.0
		bar.max_value = maxf(float(_stars_total), 1.0)
		bar.value = float(mini(_stars_own, _stars_total))
	_apply_texts()

	visible = _stars_total > 0
	_refresh_chips()
	_layout_chips()


## Vẽ lại trạng thái 3 rương theo Sao hiện có + trạng thái đã nhận (GameManager giữ)
func _refresh_chips() -> void:
	var chips := chip_list()
	for i in chips.size():
		var chip := chips[i]
		if i >= _chip_defs.size():
			chip.visible = false
			continue
		var def: Dictionary = _chip_defs[i]
		var claimed := false
		var gm := _game_manager()
		if gm != null and gm.has_method("is_chapter_chest_claimed"):
			claimed = bool(gm.call("is_chapter_chest_claimed", chapter_id(), i))
		chip.visible = true
		chip.set_label_below(threshold_below)
		chip.setup(def, _stars_own, claimed)


## Đặt 3 rương đúng tâm thanh tại tỉ lệ ngưỡng Sao của chúng
func _layout_chips() -> void:
	if bar == null or chips_host == null:
		return
	if vertical:
		_layout_chips_vertical()
		return
	var chips := chip_list()
	var span := maxf(bar.size.x - EDGE_MARGIN * 2.0, 0.0)
	var left := bar.position.x + EDGE_MARGIN
	var center_y := bar.position.y + bar.size.y * 0.5
	for i in chips.size():
		var chip := chips[i]
		if i >= _chip_defs.size() or not chip.visible:
			continue
		var threshold := int((_chip_defs[i] as Dictionary).get("stars", 0))
		var frac := 0.0 if _stars_total <= 0 else clampf(float(threshold) / float(_stars_total), 0.0, 1.0)
		var size := chip.size if chip.size.x > 0.0 else chip.custom_minimum_size
		chip.position = Vector2(
			roundf(left + span * frac - size.x * 0.5),
			roundf(center_y - size.y * 0.5))


## Bản DỌC: rương ở 0★ đáy → 100% đỉnh; tâm thanh theo trục dọc
func _layout_chips_vertical() -> void:
	var chips := chip_list()
	var span := maxf(bar.size.y - EDGE_MARGIN_V * 2.0, 0.0)
	var bottom := bar.position.y + bar.size.y - EDGE_MARGIN_V
	var center_x := bar.position.x + bar.size.x * 0.5
	for i in chips.size():
		var chip := chips[i]
		if i >= _chip_defs.size() or not chip.visible:
			continue
		var threshold := int((_chip_defs[i] as Dictionary).get("stars", 0))
		var frac := 0.0 if _stars_total <= 0 else clampf(float(threshold) / float(_stars_total), 0.0, 1.0)
		var size := chip.size if chip.size.x > 0.0 else chip.custom_minimum_size
		chip.position = Vector2(
			roundf(center_x - size.x * 0.5),
			roundf(bottom - span * frac - size.y * 0.5))


## Danh sách chip theo thứ tự mốc (con của `chips_host`)
func chip_list() -> Array[ChapterChestChip]:
	var out: Array[ChapterChestChip] = []
	if chips_host == null:
		return out
	for child in chips_host.get_children():
		var chip := child as ChapterChestChip
		if chip != null and not chip.is_queued_for_deletion():
			out.append(chip)
	return out


## Chương mà thanh này đang hiển thị (màn Chọn chương đặt khi gọi `setup`)
func chapter_id() -> int:
	return int(get_meta("chapter_id", 1))


## Độ đầy của thanh (0..1) — dùng cho test/kiểm tra hiển thị
func fraction() -> float:
	if _stars_total <= 0:
		return 0.0
	return clampf(float(_stars_own) / float(_stars_total), 0.0, 1.0)


func _on_chip_claim_requested(index: int) -> void:
	claim_requested.emit(index)


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
