@tool
class_name NinePatchRegionDialog
extends ConfirmationDialog

var preview_texture: Texture2D
var region_rect: Rect2
var patch_margins: Vector4 # x: left, y: top, z: right, w: bottom
var on_change_callback: Callable

var canvas: NinePatchEditorCanvas

# Mở cho ProgressBar hoặc bất kỳ node nào
static func open_generic(dlg_title: String, tex: Texture2D, initial_reg: Rect2, initial_margins: Vector4, callback: Callable) -> void:
	var dlg = NinePatchRegionDialog.new()
	dlg.title = dlg_title
	dlg.preview_texture = tex
	dlg.region_rect = initial_reg
	dlg.patch_margins = initial_margins
	dlg.on_change_callback = callback
	EditorInterface.get_base_control().add_child(dlg)
	dlg.popup_centered(Vector2i(900, 600))

# Giữ tương thích ngược với NinePatchButton
static func open_for_button(btn: NinePatchButton) -> void:
	open_generic(
		"Region Editor - " + btn.name,
		btn.texture_normal,
		btn.region_rect,
		Vector4(btn.patch_margin_left, btn.patch_margin_top, btn.patch_margin_right, btn.patch_margin_bottom),
		func(new_reg: Rect2, new_margins: Vector4):
			btn.region_rect = new_reg
			btn.patch_margin_left = new_margins.x
			btn.patch_margin_top = new_margins.y
			btn.patch_margin_right = new_margins.z
			btn.patch_margin_bottom = new_margins.w
			btn._update_styles()
	)

func _ready() -> void:
	min_size = Vector2i(700, 450)
	get_ok_button().text = "Close"
	get_cancel_button().visible = false
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)

	# Toolbar
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	main_vbox.add_child(toolbar)

	var btn_zoom_out = Button.new()
	btn_zoom_out.text = " − "
	btn_zoom_out.pressed.connect(func(): canvas.zoom_by(0.8))
	toolbar.add_child(btn_zoom_out)

	var btn_zoom_1 = Button.new()
	btn_zoom_1.text = " 1:1 "
	btn_zoom_1.pressed.connect(func(): canvas.reset_zoom())
	toolbar.add_child(btn_zoom_1)

	var btn_zoom_in = Button.new()
	btn_zoom_in.text = " + "
	btn_zoom_in.pressed.connect(func(): canvas.zoom_by(1.25))
	toolbar.add_child(btn_zoom_in)

	var hint_lbl = Label.new()
	hint_lbl.text = "   (Lăn chuột để Zoom | Giữ Chuột Phải để Pan | Kéo đường nét đứt để chỉnh Margin)"
	hint_lbl.modulate = Color(1, 1, 1, 0.5)
	toolbar.add_child(hint_lbl)

	# Canvas Editor
	canvas = NinePatchEditorCanvas.new()
	canvas.dialog = self
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.clip_contents = true
	main_vbox.add_child(canvas)


# ====================================================================
# CANVAS VẼ ĐƯỜNG NÉT ĐỨT & XỬ LÝ CHUỘT
# ====================================================================
class NinePatchEditorCanvas extends Control:
	var dialog: NinePatchRegionDialog

	var zoom: float = 2.0
	var pan_offset: Vector2 = Vector2.ZERO
	var is_panning: bool = false
	var pan_start: Vector2 = Vector2.ZERO

	enum DragTarget { NONE, LEFT, RIGHT, TOP, BOTTOM }
	var current_drag: DragTarget = DragTarget.NONE
	var hovered_drag: DragTarget = DragTarget.NONE

	const HOVER_THRESHOLD: float = 6.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(_center_view)

	func _center_view() -> void:
		if dialog and dialog.preview_texture:
			var tex_sz = dialog.preview_texture.get_size()
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

	func tex_to_screen(tex_pos: Vector2) -> Vector2:
		return (tex_pos * zoom) + pan_offset

	func screen_to_tex(screen_pos: Vector2) -> Vector2:
		return (screen_pos - pan_offset) / zoom

	func _get_reg() -> Rect2:
		var reg = dialog.region_rect
		if reg.size == Vector2.ZERO:
			reg = Rect2(Vector2.ZERO, dialog.preview_texture.get_size())
		return reg

	func _gui_input(event: InputEvent) -> void:
		if not dialog or not dialog.preview_texture:
			return

		var reg = _get_reg()

		# Zoom chuột
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
			elif event.button_index == MOUSE_BUTTON_LEFT:
				current_drag = hovered_drag if event.pressed else DragTarget.NONE
				queue_redraw()
				return
			elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
				is_panning = event.pressed
				if is_panning:
					pan_start = event.position - pan_offset
				return

		# Drag & Hover
		if event is InputEventMouseMotion:
			if is_panning:
				pan_offset = event.position - pan_start
				queue_redraw()
				return

			var m_tex = screen_to_tex(event.position)

			if current_drag != DragTarget.NONE:
				var m = dialog.patch_margins
				match current_drag:
					DragTarget.LEFT:
						m.x = clampf(roundf(m_tex.x - reg.position.x), 0.0, reg.size.x - m.z)
					DragTarget.RIGHT:
						m.z = clampf(roundf((reg.position.x + reg.size.x) - m_tex.x), 0.0, reg.size.x - m.x)
					DragTarget.TOP:
						m.y = clampf(roundf(m_tex.y - reg.position.y), 0.0, reg.size.y - m.w)
					DragTarget.BOTTOM:
						m.w = clampf(roundf((reg.position.y + reg.size.y) - m_tex.y), 0.0, reg.size.y - m.y)
				
				dialog.patch_margins = m
				if dialog.on_change_callback.is_valid():
					dialog.on_change_callback.call(dialog.region_rect, dialog.patch_margins)
				queue_redraw()
				return

			# Bắt dính chuột khi hover qua line
			var sx_left = tex_to_screen(Vector2(reg.position.x + dialog.patch_margins.x, 0)).x
			var sx_right = tex_to_screen(Vector2(reg.position.x + reg.size.x - dialog.patch_margins.z, 0)).x
			var sy_top = tex_to_screen(Vector2(0, reg.position.y + dialog.patch_margins.y)).y
			var sy_bottom = tex_to_screen(Vector2(0, reg.position.y + reg.size.y - dialog.patch_margins.w)).y

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
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.13, 0.15))

		if not dialog or not dialog.preview_texture:
			return

		var tex = dialog.preview_texture
		var reg = _get_reg()

		# Vẽ Texture
		var tex_scr_pos = tex_to_screen(Vector2.ZERO)
		var tex_scr_sz = tex.get_size() * zoom
		draw_texture_rect(tex, Rect2(tex_scr_pos, tex_scr_sz), false)

		# Khung viền Region
		var reg_scr_pos = tex_to_screen(reg.position)
		var reg_scr_sz = reg.size * zoom
		draw_rect(Rect2(reg_scr_pos, reg_scr_sz), Color(1, 1, 1, 0.8), false, 1.5)

		# Tọa độ nét đứt
		var sx_l = tex_to_screen(Vector2(reg.position.x + dialog.patch_margins.x, 0)).x
		var sx_r = tex_to_screen(Vector2(reg.position.x + reg.size.x - dialog.patch_margins.z, 0)).x
		var sy_t = tex_to_screen(Vector2(0, reg.position.y + dialog.patch_margins.y)).y
		var sy_b = tex_to_screen(Vector2(0, reg.position.y + reg.size.y - dialog.patch_margins.w)).y

		var col_line = Color(1.0, 1.0, 1.0, 0.75)
		var col_act = Color(1.0, 0.85, 0.2, 1.0)
		var d_len = 5.0

		draw_dashed_line(Vector2(sx_l, 0), Vector2(sx_l, size.y), col_act if (hovered_drag == DragTarget.LEFT or current_drag == DragTarget.LEFT) else col_line, 1.2, d_len)
		draw_dashed_line(Vector2(sx_r, 0), Vector2(sx_r, size.y), col_act if (hovered_drag == DragTarget.RIGHT or current_drag == DragTarget.RIGHT) else col_line, 1.2, d_len)
		draw_dashed_line(Vector2(0, sy_t), Vector2(size.x, sy_t), col_act if (hovered_drag == DragTarget.TOP or current_drag == DragTarget.TOP) else col_line, 1.2, d_len)
		draw_dashed_line(Vector2(0, sy_b), Vector2(size.x, sy_b), col_act if (hovered_drag == DragTarget.BOTTOM or current_drag == DragTarget.BOTTOM) else col_line, 1.2, d_len)

		# Vẽ các chấm tròn đỏ Handles
		var handle_col = Color(0.95, 0.25, 0.25)
		var r = 3.5
		draw_circle(reg_scr_pos, r, handle_col)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x, 0), r, handle_col)
		draw_circle(reg_scr_pos + Vector2(0, reg_scr_sz.y), r, handle_col)
		draw_circle(reg_scr_pos + reg_scr_sz, r, handle_col)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x * 0.5, 0), r, handle_col)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x * 0.5, reg_scr_sz.y), r, handle_col)
		draw_circle(reg_scr_pos + Vector2(0, reg_scr_sz.y * 0.5), r, handle_col)
		draw_circle(reg_scr_pos + Vector2(reg_scr_sz.x, reg_scr_sz.y * 0.5), r, handle_col)
