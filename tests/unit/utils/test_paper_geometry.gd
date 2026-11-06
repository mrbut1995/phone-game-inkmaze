extends TestCase
## Tests for PaperGeometry (scripts/utils/PaperGeometry.gd) — phần thuần toán trên Image.
## `nine_map`/`inner_rect` cần Control thật nên chỉ kiểm nhánh "panel null" ở đây.


func _make_image(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func test_sheet_rect_is_empty_without_image_or_texture_size() -> void:
	var img := _make_image(16)
	assert_eq(PaperGeometry.sheet_tex_rect(null, Vector2(16, 16)).size, Vector2.ZERO)
	assert_eq(PaperGeometry.sheet_tex_rect(img, Vector2.ZERO).size, Vector2.ZERO)


func test_sheet_rect_of_fully_transparent_image_is_empty() -> void:
	var img := _make_image(32)
	assert_eq(PaperGeometry.sheet_tex_rect(img, Vector2(32, 32)).size, Vector2.ZERO, "không có pixel đặc ⇒ không có tờ giấy")


func test_sheet_rect_of_fully_opaque_image_covers_texture() -> void:
	var img := _make_image(32)
	img.fill(Color(1, 1, 1, 1))
	var rect := PaperGeometry.sheet_tex_rect(img, Vector2(32, 32))
	assert_almost_eq(rect.position.x, 0.0, 0.5)
	assert_almost_eq(rect.position.y, 0.0, 0.5)
	assert_almost_eq(rect.size.x, 32.0, 0.5)
	assert_almost_eq(rect.size.y, 32.0, 0.5)


func test_sheet_rect_trims_transparent_border() -> void:
	var img := _make_image(64)
	img.fill_rect(Rect2i(8, 8, 48, 48), Color(1, 1, 1, 1))
	var rect := PaperGeometry.sheet_tex_rect(img, Vector2(64, 64))
	assert_true(absf(rect.position.x - 8.0) <= 1.5, "mép trái tờ giấy ~8px, thực tế " + str(rect.position.x))
	assert_true(absf(rect.size.x - 48.0) <= 2.0, "bề rộng tờ giấy ~48px, thực tế " + str(rect.size.x))


func test_margin_line_returns_minus_one_without_image() -> void:
	assert_eq(PaperGeometry.margin_line_x(null, Vector2(100, 10)), -1.0)
	assert_eq(PaperGeometry.margin_line_x(_make_image(8), Vector2.ZERO), -1.0)


func test_margin_line_finds_right_edge_of_red_line() -> void:
	var img := Image.create(100, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(20, 0, 2, 10), Color(1.0, 0.1, 0.1, 1.0))
	assert_almost_eq(PaperGeometry.margin_line_x(img, Vector2(100, 10)), 22.0, 0.001, "mép phải vạch đỏ = x + 1")


func test_margin_line_is_minus_one_when_no_red() -> void:
	var img := Image.create(100, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.2, 0.2, 1.0))
	assert_eq(PaperGeometry.margin_line_x(img, Vector2(100, 10)), -1.0)


func test_nine_map_without_panel_returns_texture_coordinate() -> void:
	assert_eq(PaperGeometry.nine_map(37.0, true, null, Vector2(100, 100)), 37.0)
