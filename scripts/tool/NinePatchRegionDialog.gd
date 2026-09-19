@tool
class_name NinePatchRegionDialog
extends ConfirmationDialog

var target_button: NinePatchButton

# Component Canvas vẽ & tương tác
var canvas: NinePatchEditorCanvas

static func open_for_button(btn: NinePatchButton) -> void:
	var dlg = NinePatchRegionDialog.new()
	dlg.target_button = btn
	EditorInterface.get_base_control().add_child(dlg)
	dlg.popup_centered(Vector2i(900, 600))


func _ready() -> void:
	title = "Region Editor"
	min_size = Vector2i(700, 450)
	get_ok_button().text = "Close"
	get_cancel_button().visible = false
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)

	# ----------------- TOOLBAR (Zoom -, 1, +) -----------------
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	main_vbox.add_child(toolbar)

	var btn_zoom_out = Button.new()
	btn_zoom_out.text = " − "
	btn_zoom_out.tooltip_text = "Zoom Out"
	btn_zoom_out.pressed.connect(func(): canvas.zoom_by(0.8))
	toolbar.add_child(btn_zoom_out)

	var btn_zoom_1 = Button.new()
	btn_zoom_1.text = " 1:1 "
	btn_zoom_1.tooltip_text = "Reset Zoom"
	btn_zoom_1.pressed.connect(func(): canvas.reset_zoom())
	toolbar.add_child(btn_zoom_1)

	var btn_zoom_in = Button.new()
	btn_zoom_in.text = " + "
	btn_zoom_in.tooltip_text = "Zoom In"
	btn_zoom_in.pressed.connect(func(): canvas.zoom_by(1.25))
	toolbar.add_child(btn_zoom_in)

	var hint_lbl = Label.new()
	hint_lbl.text = "   (Lăn chuột để Zoom | Giữ Chuột Phải để Pan | Kéo các đường nét đứt để chỉnh Margin)"
	hint_lbl.modulate = Color(1, 1, 1, 0.5)
	toolbar.add_child(hint_lbl)

	# ----------------- WORKSPACE CANVAS -----------------
	canvas = NinePatchEditorCanvas.new()
	canvas.target_button = target_button
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.clip_contents = true
	main_vbox.add_child(canvas)


# ====================================================================
# CANVAS VẼ & XỬ LÝ KÉO THẢ CHUỘT TRỰC QUAN
# ====================================================================
class NinePatchEditorCanvas extends Control:
	var target_button: NinePatchButton

	var zoom: float = 2.0
	var pan_offset: Vector2 = Vector2.ZERO
	var is_panning: bool = false
	var pan_start: Vector2 = Vector2.ZERO

	enum DragTarget { NONE, LEFT, RIGHT, TOP, BOTTOM }
	var current_drag: DragTarget = DragTarget.NONE
	var hovered_drag: DragTarget = DragTarget.NONE

	const HOVER_THRESHOLD: float = 6.0 # Khoảng cách tính bằng pixel để bắt dính chuột

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_center_view)

	func _center_view() -> void:
		if target_button and target_button.texture_normal:
			var tex_sz = target_button.texture_normal.get_size()
			pan_offset = (size - tex_sz * zoom) * 0.5
			queue_redraw()

	func zoom_by(factor: float) -> void:
		var center = size * 0.5
		var tex_coord = (center - pan_offset) / zoom
		zoom = clampf(zoom * factor, 0.2, 20.0)
		pan_offset = center - tex_coord * zoom
		queue_redraw()

	func reset_zoom() -> void:
		zoom = 1.0
		_center_view()

	# Chuyển đổi tọa độ giữa Màn hình và Texture
	func tex_to_screen(tex_pos: Vector2) -> Vector2:
		return (tex_pos * zoom) + pan_offset

	func screen_to_tex(screen_pos: Vector2) -> Vector2:
		return (screen_pos - pan_offset) / zoom

	func _get_region_rect() -> Rect2:
		if not target_button or not target_button.texture_normal:
			return Rect2()
		var reg = target_button.region_rect
		if reg.size == Vector2.ZERO:
			reg = Rect2(Vector2.ZERO, target_button.texture_normal.get_size())
		return reg

	func _gui_input(event: InputEvent) -> void:
		if not target_button or not target_button.texture_normal:
			return

		var reg = _get_region_rect()

		# 1. LĂN CHUỘT ĐỂ ZOOM
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				var m_tex = screen_to_tex(event.position)
				zoom = minf(zoom * 1.15, 20.0)
				pan_offset = event.position - m_tex * zoom
				queue_redraw()
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				var m_tex = screen_to_tex(event.position)
				zoom = maxf(zoom / 1.15, 0.2)
				pan_offset = event.position - m_tex * zoom
				queue_redraw()
				return

			# 2. CLICK CHUỘT TRÁI ĐỂ KÉO ĐƯỜNG MARGIN
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					current_drag = hovered_drag
				else:
					current_drag = DragTarget.NONE
				queue_redraw()
				return

			# 3. GIỮ CHUỘT PHẢI / GIỮA ĐỂ PAN (DI CHUYỂN BẢN ĐỒ VÙNG LÀM VIỆC)
			if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					is_panning = true
					pan_start = event.position - pan_offset
				else:
					is_panning = false
				return

		# 4. KHI DI CHUỘT
		if event is InputEventMouseMotion:
			if is_panning:
				pan_offset = event.position - pan_start
				queue_redraw()
				return

			var m_tex = screen_to_tex(event.position)

			# Đang kéo 1 đường Margin
			if current_drag != DragTarget.NONE:
				match current_drag:
					DragTarget.LEFT:
						var val = m_tex.x - reg.position.x
						target_button.patch_margin_left = clampf(roundf(val), 0.0, reg.size.x - target_button.patch_margin_right)
					DragTarget.RIGHT:
						var val = (reg.position.x + reg.size.x) - m_tex.x
						target_button.patch_margin_right = clampf(roundf(val), 0.0, reg.size.x - target_button.patch_margin_left)
					DragTarget.TOP:
						var val = m_tex.y - reg.position.y
						target_button.patch_margin_top = clampf(roundf(val), 0.0, reg.size.y - target_button.patch_margin_bottom)
					DragTarget.BOTTOM:
						var val = (reg.position.y + reg.size.y) - m_tex.y
						target_button.patch_margin_bottom = clampf(roundf(val), 0.0, reg.size.y - target_button.patch_margin_top)
				queue_redraw()
				return

			# Bắt dính vị trí chuột (Hover detection)
			var sx_left = tex_to_screen(Vector2(reg.position.x + target_button.patch_margin_left, 0)).x
			var sx_right = tex_to_screen(Vector2(reg.position.x + reg.size.x - target_button.patch_margin_right, 0)).x
			var sy_top = tex_to_screen(Vector2(0, reg.position.y + target_button.patch_margin_top)).y
			var sy_bottom = tex_to_screen(Vector2(0, reg.position.y + reg.size.y - target_button.patch_margin_bottom)).y

			if absf(event.position.x - sx_left) <= HOVER_THRESHOLD:
				hovered_drag = DragTarget.LEFT
				mouse_default_cursor_shape = Control.CURSOR_HSIZE
			elif absf(event.position.x - sx_right) <= HOVER_THRESHOLD:
				hovered_drag = DragTarget.RIGHT
				mouse_default_cursor_shape = Control.CURSOR_HSIZE
			elif absf(event.position.y - sy_top) <= HOVER_THRESHOLD:
				hovered_drag = DragTarget.TOP
				mouse_default_cursor_shape = Control.CURSOR_VSIZE
			elif absf(event.position.y - sy_bottom) <= HOVER_THRESHOLD:
				hovered_drag = DragTarget.BOTTOM
				mouse_default_cursor_shape = Control.CURSOR_VSIZE
			else:
				hovered_drag = DragTarget.NONE
				mouse_default_cursor_shape = Control.CURSOR_ARROW
			queue_redraw()

	func _draw() -> void:
		# Vẽ phông nền tối giống Godot
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.13, 0.15))

		if not target_button or not target_button.texture_normal:
			return

		var tex = target_button.texture_normal
		var reg = _get_region_rect()

		# 1. Vẽ toàn bộ Texture
		var tex_scr_pos = tex_to_screen(Vector2.ZERO)
		var tex_scr_sz = tex.get_size() * zoom
		draw_texture_rect(tex, Rect2(tex_scr_pos, tex_scr_sz), false)

		# 2. Vẽ khung viền Region (Viền trắng bao quanh)
		var reg_scr_pos = tex_to_screen(reg.position)
		var reg_scr_sz = reg.size * zoom
		draw_rect(Rect2(reg_scr_pos, reg_scr_sz), Color(1, 1, 1, 0.8), false, 1.5)

		# 3. Tính tọa độ các đường cắt 9-Patch
		var sx_left = tex_to_screen(Vector2(reg.position.x + target_button.patch_margin_left, 0)).x
		var sx_right = tex_to_screen(Vector2(reg.position.x + reg.size.x - target_button.patch_margin_right, 0)).x
		var sy_top = tex_to_screen(Vector2(0, reg.position.y + target_button.patch_margin_top)).y
		var sy_bottom = tex_to_screen(Vector2(0, reg.position.y + reg.size.y - target_button.patch_margin_bottom)).y

		# 4. Vẽ các đường nét đứt (Dashed lines) cắt ngang/dọc toàn màn hình
		var line_color = Color(1.0, 1.0, 1.0, 0.75)
		var active_color = Color(1.0, 0.85, 0.2, 1.0) # Màu vàng khi đang hover hoặc kéo
		var dash_len = 5.0

		# Đường dọc Trái
		var col_l = active_color if (hovered_drag == DragTarget.LEFT or current_drag == DragTarget.LEFT) else line_color
		draw_dashed_line(Vector2(sx_left, 0), Vector2(sx_left, size.y), col_l, 1.2, dash_len)

		# Đường dọc Phải
		var col_r = active_color if (hovered_drag == DragTarget.RIGHT or current_drag == DragTarget.RIGHT) else line_color
		draw_dashed_line(Vector2(sx_right, 0), Vector2(sx_right, size.y), col_r, 1.2, dash_len)

		# Đường ngang Trên
		var col_t = active_color if (hovered_drag == DragTarget.TOP or current_drag == DragTarget.TOP) else line_color
		draw_dashed_line(Vector2(0, sy_top), Vector2(size.x, sy_top), col_t, 1.2, dash_len)

		# Đường ngang Dưới
		var col_b = active_color if (hovered_drag == DragTarget.BOTTOM or current_drag == DragTarget.BOTTOM) else line_color
		draw_dashed_line(Vector2(0, sy_bottom), Vector2(size.x, sy_bottom), col_b, 1.2, dash_len)

		# 5. Vẽ các chấm tròn đỏ (Handles) giống hệt Godot built-in Editor
		var handle_color = Color(0.95, 0.25, 0.25)
		var h_radius = 3.5

		# 4 góc Region
		draw_circle(reg_scr_pos, h_radius, handle_color)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x, 0), h_radius, handle_color)
		draw_circle(reg_scr_pos + Vector2(0, reg_scr_sz.y), h_radius, handle_color)
		draw_circle(reg_scr_pos + reg_scr_sz, h_radius, handle_color)

		# 4 điểm giữa biên
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x * 0.5, 0), h_radius, handle_color)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x * 0.5, reg_scr_sz.y), h_radius, handle_color)
		draw_circle(reg_scr_pos + Vector2(0, reg_scr_sz.y * 0.5), h_radius, handle_color)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x, reg_scr_sz.y * 0.5), h_radius, handle_color)
