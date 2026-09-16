extends SceneTree

# Render nhanh 1 file guideline ra PNG de kiem tra bang mat thuong.
func _init() -> void:
	var path: String = OS.get_environment("GUIDE_RENDER_PATH")
	if path.is_empty():
		path = "res://assets/images/instructions/guideline_image/image_guideline_instruction_dungeon_p1.svg"
	var tex: Texture2D = load(path)
	if tex == null:
		printerr("Khong load duoc: ", path)
		quit(1)
		return
	print("texture size = ", tex.get_size())
	var vp := SubViewport.new()
	vp.size = Vector2i(810, 560)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color.WHITE
	bg.size = Vector2(810, 560)
	vp.add_child(bg)
	var tr := TextureRect.new()
	tr.texture = tex
	var zoom := float(OS.get_environment("GUIDE_RENDER_ZOOM")) if not OS.get_environment("GUIDE_RENDER_ZOOM").is_empty() else 1.0
	tr.size = Vector2(785 * zoom, 535 * zoom)
	tr.position = Vector2(-float(OS.get_environment("GUIDE_RENDER_X")) if not OS.get_environment("GUIDE_RENDER_X").is_empty() else 0.0,
			-float(OS.get_environment("GUIDE_RENDER_Y")) if not OS.get_environment("GUIDE_RENDER_Y").is_empty() else 0.0)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vp.add_child(tr)
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image() if vp.get_texture() != null else null
	if img == null:
		printerr("Khong lay duoc image (renderer?)")
		quit(1)
		return
	var out := OS.get_environment("GUIDE_RENDER_OUT")
	if out.is_empty():
		out = "res://temp_guide_render.png"
	img.save_png(out)
	print("saved: ", out)
	quit(0)
