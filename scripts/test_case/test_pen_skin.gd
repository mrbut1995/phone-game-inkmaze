extends SceneTree
## ============================================================================
## Test Case: SKIN NGÒI BÚT (Bút & Mực) — tính năng 2026-09
##
## 1. Bảng PenSkin: mọi bút trong ShopManager (category "pen") đều có skin đầy đủ
##    (icon con trỏ + hình ngòi bút tồn tại & đọc được, màu mực + chất liệu hợp lệ,
##    không có 2 bút dùng chung 1 icon con trỏ).
## 2. Màn chơi: con trỏ đổi đúng icon `player_cursor_*.svg` theo bút đang dùng;
##    moving_line đổi MÀU MỰC + CHẤT LIỆU (bề rộng · đầu nét · nét đứt · quầng sáng).
## ============================================================================

var _shop_backup: Dictionary = {}
var _backup_pen := ""
var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: SKIN NGOI BUT (CON TRO + MOVING LINE)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	var shop: Node = root.get_node_or_null("ShopManager")
	var themes: Node = root.get_node_or_null("ThemeManager")
	assert(shop != null, "Autoload ShopManager phai ton tai")
	assert(themes != null, "Autoload ThemeManager phai ton tai")
	_shop_backup = shop.call("export_progress")
	_backup_pen = str(shop.get("equipped_pen"))

	_section_1_table(shop)
	await _section_2_game(shop)

	# --- Khôi phục dữ liệu người chơi ---
	shop.set("equipped_pen", _backup_pen)
	shop.call("import_progress", _shop_backup)
	themes.call("sync_from_shop")
	print("[INFO] Da khoi phuc but + tien trinh nguoi choi.")

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Bảng skin
# ---------------------------------------------------------------------------
func _section_1_table(shop: Node) -> void:
	print("--- 1. BANG SKIN PEN (PenSkin) ---")
	var pens: Array = shop.call("items", "pen")
	_entry(pens.size() == PenSkin.ids().size(),
		"So but trong shop = so skin (%d vs %d)" % [pens.size(), PenSkin.ids().size()])

	var seen_cursor := {}
	for entry in pens:
		var id := str(entry.get("id", ""))
		if not PenSkin.has_pen(id):
			_entry(false, "But '%s' chua co skin trong PenSkin" % id)
			continue
		var cursor_path := PenSkin.cursor_path(id)
		var icon_path := PenSkin.icon_path(id)
		_entry(ResourceLoader.exists(cursor_path),
			"'%s' co icon con tro (%s)" % [id, cursor_path.get_file()])
		_entry(ResourceLoader.exists(icon_path),
			"'%s' co hinh ngoi but (%s)" % [id, icon_path.get_file()])
		_entry(PenSkin.cursor_texture(id) != null, "'%s' load duoc icon con tro" % id)
		_entry(PenSkin.ink_color(id) != Color.WHITE, "'%s' co mau muc rieng (%s)" % [id, PenSkin.ink_color(id).to_html(false)])
		_entry(PenSkin.STYLES.has(PenSkin.style_id(id)),
			"'%s' co chat lieu '%s'" % [id, PenSkin.style_id(id)])
		if seen_cursor.has(cursor_path):
			_entry(false, "2 but dung chung 1 con tro: %s" % cursor_path.get_file())
		seen_cursor[cursor_path] = id

	# Texture nét đứt tự sinh (cho bút chì) phải dùng được
	var dash := PenSkin.dash_texture()
	_entry(dash != null and dash.get_width() > 0, "Texture NÉT ĐỨT tự sinh dùng được")


# ---------------------------------------------------------------------------
# 2. Màn chơi: con trỏ + moving_line theo bút
# ---------------------------------------------------------------------------
func _section_2_game(shop: Node) -> void:
	print("\n--- 2. MAN CHOI: CON TRO + MOVING LINE ---")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm == null:
		_entry(false, "Khong co GameManager")
		return
	var backup_level := int(gm.get("current_level"))
	var backup_mode := str(gm.get("current_mode"))
	gm.set("current_mode", "play")
	gm.set("current_level", 1)

	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var board: Node = scene.get("board_view")
	if board == null:
		_entry(false, "Khong co board_view")
		scene.queue_free()
		return

	var cursor: Node = board.get("_cursor")
	var line: Line2D = board.get("_moving_line")
	_entry(cursor != null, "Board co con tro nguoi choi")
	_entry(line != null, "Board co moving_line")
	if cursor == null or line == null:
		scene.queue_free()
		return
	_entry(line.get_script() == preload("res://scripts/nodes/game/ink_stroke.gd"),
		"moving_line dung InkStroke (net muc song theo but)")

	var widths := {}
	widths["pen_blue"] = await _check_pen(shop, board, cursor, line, "pen_blue")
	widths["pen_pencil_2b"] = await _check_pen(shop, board, cursor, line, "pen_pencil_2b")
	widths["pen_highlighter"] = await _check_pen(shop, board, cursor, line, "pen_highlighter")
	widths["pen_gold_ink"] = await _check_pen(shop, board, cursor, line, "pen_gold_ink")
	widths["pen_navy_night"] = await _check_pen(shop, board, cursor, line, "pen_navy_night")

	# Bề rộng nét: bút dạ quang (×1.75) phải RỘNG hơn hẳn bút mực thường (×1.0),
	# và bút gel (×0.85) mảnh hơn — đúng hệ số chất liệu
	_entry(float(widths["pen_highlighter"]) > float(widths["pen_blue"]) * 1.4,
		"Dạ quang rộng hơn mực thường (%.1f > %.1f)" % [widths["pen_highlighter"], widths["pen_blue"]])
	_entry(float(widths["pen_navy_night"]) < float(widths["pen_blue"]),
		"Bút gel mảnh hơn mực thường (%.1f < %.1f)" % [widths["pen_navy_night"], widths["pen_blue"]])

	# Chất liệu đặc trưng
	await _check_pen(shop, board, cursor, line, "pen_pencil_2b")
	_entry(line.texture != null and line.texture_mode == Line2D.LINE_TEXTURE_TILE,
		"Bút chì 2B vẽ nét ĐỨT (texture lặp)")
	_entry(line.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED,
		"Nét đứt bật texture_repeat (nếu không Line2D sẽ kẹp mép -> vô hình)")
	_entry(line.get_node_or_null("Glow") == null, "Bút chì không có quầng sáng")

	await _check_pen(shop, board, cursor, line, "pen_gold_ink")
	var glow := line.get_node_or_null("Glow") as Line2D
	_entry(glow != null, "Mực nhũ hoàng gia có QUẦNG SÁNG")
	if glow != null:
		var material := glow.material as CanvasItemMaterial
		_entry(material != null and material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD,
			"Quầng sáng dùng blend CỘNG (phát sáng)")
		_entry(glow.width > line.width, "Quầng sáng rộng hơn nét chính")

	await _check_pen(shop, board, cursor, line, "pen_highlighter")
	_entry(line.begin_cap_mode == Line2D.LINE_CAP_BOX,
		"Dạ quang có đầu nét VUÔNG (lưỡi đục)")
	_entry(line.texture == null and line.material == null, "Dạ quang không dùng nét đứt")

	scene.queue_free()
	await process_frame
	gm.set("current_level", backup_level)
	gm.set("current_mode", backup_mode)


## Đổi bút đang dùng -> kiểm tra con trỏ + nét mực; trả về bề rộng nét thực tế
func _check_pen(shop: Node, board: Node, cursor: Node, line: Line2D,
		pen_id: String) -> float:
	shop.set("equipped_pen", pen_id)
	board.call("apply_pen_skin")

	var icon := cursor.get_node_or_null("Icon") as TextureRect
	_entry(icon != null and icon.texture == PenSkin.cursor_texture(pen_id),
		"'%s': con tro doi dung icon %s" % [pen_id, PenSkin.cursor_path(pen_id).get_file()])

	_entry(line.default_color.is_equal_approx(PenSkin.line_color(pen_id)),
		"'%s': nét mực đúng màu (mong %s, nhận %s)"
			% [pen_id, PenSkin.line_color(pen_id).to_html(false), line.default_color.to_html(false)])
	_entry(str(line.call("pen_id")) == pen_id, "'%s': nét mực ghi nhận đúng ngòi bút" % pen_id)
	return line.width


# ---------------------------------------------------------------------------
# Check + đếm
# ---------------------------------------------------------------------------
func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [CHECK] %s" % label)
		return
	_failed += 1
	print("  [FAIL] %s" % label)
