class_name ArchivementCardBig
extends ArchivementCard
## ============================================================================
## Thẻ BÀI LỚN của Sổ tay thành tựu (nodes/archivements/card_big.tscn) — bố cục "G".
## KẾ THỪA ArchivementCard ⇒ dùng lại NGUYÊN `setup(entry)` + 4 trạng thái + nút NHẬN
## (cùng bộ `@export` node, cùng signal `claim_requested`). Chỉ THÊM:
##   · chip phân loại (DAILY / DUNGEON / …)   — entry["category"]
##   · tem số thứ tự "#3 / 28"                 — entry["index"], entry["total"]
## Hai khoá trên do ArchivementScene nhét thêm vào entry; thiếu khoá ⇒ phần đó tự ẩn.
## ============================================================================

const COIN_TEX := preload("res://assets/images-png/icons/icon_coin.png")  # keep-code: hằng dùng cho hiệu ứng/dữ liệu runtime (không phải bố cục tĩnh)

@export var cat_chip: Control = null
@export var cat_label: Label = null
@export var index_sticker: Control = null
@export var index_label: Label = null


func setup(entry: Dictionary) -> void:
	super.setup(entry)

	var hidden := bool(entry.get("secret_hidden", false))
	var category := str(entry.get("category", ""))
	if cat_chip != null:
		cat_chip.visible = category != "" and not hidden
		if cat_chip.visible and cat_label != null:
			cat_label.text = _category_text(category)

	# Đã nhận: chữ "(Hoàn thành)" xuống DÒNG 2 cho khỏi bị cắt (nhãn tiến độ cao 2 dòng)
	if bool(entry.get("claimed", false)) and progress_label != null:
		var text := progress_label.text
		var cut := text.find(" (")
		if cut > 0:
			progress_label.text = text.substr(0, cut) + "\n" + text.substr(cut + 1)

	var total := int(entry.get("total", 0))
	if index_sticker != null:
		index_sticker.visible = total > 0
		if total > 0 and index_label != null:
			index_label.text = "#%d / %d" % [int(entry.get("index", 1)), total]  # keep-code: chữ theo dữ liệu (runtime)


func _category_text(category: String) -> String:
	match category:
		"levels":
			return tr("STR_ACH_TAB_LEVELS")
		"dungeon":
			return tr("STR_ACH_TAB_DUNGEON")
		"daily":
			return tr("STR_ACH_TAB_DAILY")
		"special":
			return tr("STR_ACH_TAB_SPECIAL")
		_:
			return category.to_upper()


## Id danh hiệu của thẻ (màn dùng để tìm lại thẻ sau khi dựng lại trang)
func entry_id() -> String:
	return str(_entry.get("id", ""))


## Tâm nút NHẬN trong toạ độ màn hình — điểm xuất phát của xu bay lên ví
func claim_origin() -> Vector2:
	var node: Control = claim_btn if claim_btn != null and claim_btn.is_visible_in_tree() else self
	return node.get_global_rect().get_center()


## Hiệu ứng ĐÓNG DẤU khi vừa nhận thưởng (màn gọi sau khi dựng lại thẻ ở trạng thái ĐÃ ĐẠT):
## dấu mộc phóng to rồi đập xuống · huy hiệu nảy · nền loé sáng · xu bắn tung toé.
func play_claimed_fx() -> void:
	if stamp == null or not stamp.visible:
		return
	stamp.pivot_offset = stamp.size * 0.5
	var rest_rot := stamp.rotation
	stamp.scale = Vector2.ONE * 2.6  # keep-code: hoạt cảnh/trạng thái runtime (tween)
	stamp.rotation = rest_rot - 0.55
	stamp.modulate.a = 0.0

	var slam := create_tween().set_parallel(true)
	slam.tween_property(stamp, "modulate:a", 1.0, 0.08)
	slam.tween_property(stamp, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	slam.tween_property(stamp, "rotation", rest_rot, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	slam.chain().tween_callback(_on_stamp_impact.bind(rest_rot))


func _on_stamp_impact(rest_rot: float) -> void:
	# Rung dấu mộc
	var shake := create_tween()
	shake.tween_property(stamp, "rotation", rest_rot + 0.06, 0.04)
	shake.tween_property(stamp, "rotation", rest_rot - 0.04, 0.05)
	shake.tween_property(stamp, "rotation", rest_rot, 0.07)
	# Huy hiệu nảy
	var medal := icon_ring.get_parent() as Control
	if medal != null:
		medal.pivot_offset = medal.size * 0.5
		var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(medal, "scale", Vector2.ONE * 1.22, 0.12)
		pop.tween_property(medal, "scale", Vector2.ONE, 0.22)
	# Nền loé sáng rồi dịu lại
	bg.modulate = Color(1.6, 1.6, 1.35, 1.0)  # keep-code: hoạt cảnh/trạng thái runtime (tween)
	create_tween().tween_property(bg, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Xu bắn tung toé quanh dấu mộc
	_burst(stamp.get_global_rect().get_center())


## Hạt xu gắn vào ROOT của cây (không nằm trong ScrollContainer của vùng thẻ) ⇒ không bị cắt ở mép/Thumbs
func _burst(global_pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.texture = COIN_TEX
	p.z_index = 30
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 20
	p.lifetime = 0.85
	p.direction = Vector2(0, -1)
	p.spread = 150.0
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 320.0
	p.gravity = Vector2(0, 640)
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.scale_amount_min = 0.35
	p.scale_amount_max = 0.7
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	get_tree().root.add_child(p)
	p.global_position = global_pos
	p.emitting = true
	p.finished.connect(p.queue_free)


## Thẻ bên cạnh (lộ ra dưới thẻ giữa) tắt chuột để không chặn nút của thẻ đang xem
func set_interactive(on: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	if claim_btn != null:
		claim_btn.mouse_filter = filter
