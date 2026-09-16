extends SceneTree

# Render thu popup huong dan ra PNG: POPUP_MODE, POPUP_PAGE, POPUP_OUT
func _init() -> void:
	var mode := OS.get_environment("POPUP_MODE")
	if mode.is_empty():
		mode = "dungeon"
	var page := int(OS.get_environment("POPUP_PAGE"))
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 1920)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("#FAF5EB")
	bg.size = Vector2(1080, 1920)
	vp.add_child(bg)
	var ps: PackedScene = load("res://nodes/popups/instruction/%s.tscn" % mode)
	if ps == null:
		printerr("khong load duoc scene ", mode)
		quit(1)
		return
	var pop := ps.instantiate()
	vp.add_child(pop)
	await process_frame
	await process_frame
	if pop.has_method("go_to_page"):
		pop.call("go_to_page", page)
		print("after go_to_page(", page, ") -> ", pop.call("current_page"))
	await process_frame
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	var out := OS.get_environment("POPUP_OUT")
	if out.is_empty():
		out = "res://tmp_popup_%s_p%d.png" % [mode, page + 1]
	img.save_png(out)
	print("saved: ", out, " page=", pop.call("current_page") if pop.has_method("current_page") else "?")
	quit(0)
