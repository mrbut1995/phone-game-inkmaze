class_name Ranking
extends RefCounted
## ============================================================================
## Helper tĩnh: truy cập RankingManager (autoload) qua /root + định dạng hiển thị.
##
## Lý do tồn tại: test runner chạy bằng `godot --script ...` không resolve được
## identifier autoload lúc parse, nên script khác KHÔNG được tham chiếu thẳng
## `RankingManager`. Ở đây lấy node động qua /root/RankingManager.
##
## Ngoài ra gom luôn phần ĐỊNH DẠNG (chữ kỷ lục / điểm / tên) để màn hình, hàng
## danh sách và bục vinh quang hiển thị giống nhau tuyệt đối.
## ============================================================================


static func manager() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("RankingManager")
	return null


# ---------------------------------------------------------------------------
# Dữ liệu
# ---------------------------------------------------------------------------
static func board_ids() -> Array:
	var m := manager()
	return m.call("board_ids") if m != null and m.has_method("board_ids") else []


static func entries(board: String) -> Array:
	var m := manager()
	return m.call("entries", board) if m != null and m.has_method("entries") else []


static func podium(board: String) -> Array:
	var m := manager()
	return m.call("podium", board) if m != null and m.has_method("podium") else []


static func rest(board: String) -> Array:
	var m := manager()
	return m.call("rest", board) if m != null and m.has_method("rest") else []


static func my_entry(board: String) -> Dictionary:
	var m := manager()
	return m.call("my_entry", board) if m != null and m.has_method("my_entry") else {}


static func my_rank(board: String) -> int:
	var m := manager()
	return int(m.call("my_rank", board)) if m != null and m.has_method("my_rank") else 0


static func last_refresh_unix() -> int:
	var m := manager()
	return int(m.call("last_refresh_unix")) if m != null and m.has_method("last_refresh_unix") else 0


## Làm mới nếu đã sang khung 10 phút mới (trả về true nếu dữ liệu đổi)
static func refresh(force := false) -> bool:
	var m := manager()
	if m == null or not m.has_method("refresh"):
		return false
	return bool(m.call("refresh", force))


# ---------------------------------------------------------------------------
# Định dạng hiển thị
# ---------------------------------------------------------------------------
## Tên hiển thị: tên thật, hoặc khoá dịch (người chơi = "STR_RANK_YOU")
static func display_name(entry: Dictionary) -> String:
	var name := str(entry.get("name", ""))
	if name.begins_with("STR_"):
		return TranslationServer.translate(name)
	return name


## Chữ kỷ lục theo loại bảng: dungeon -> "TẦNG 28" · play -> "MÀN 24" · daily -> "CHUỖI 12 NGÀY"
static func record_text(board: String, entry: Dictionary) -> String:
	if not bool(entry.get("has_record", true)):
		return TranslationServer.translate("STR_RANK_NO_RECORD_SHORT")
	var value := int(entry.get("primary", 0))
	match board:
		"dungeon":
			return TranslationServer.translate("STR_RANK_RECORD_FLOOR").format([value])
		"play":
			return TranslationServer.translate("STR_RANK_RECORD_LEVEL").format([value])
		_:
			return TranslationServer.translate("STR_RANK_RECORD_STREAK").format([value])


## Điểm: "18,250 PTS"
static func points_text(entry: Dictionary) -> String:
	return TranslationServer.translate("STR_RANK_POINTS").format([thousands(int(entry.get("points", 0)))])


## Hạng: "#4"
static func rank_text(rank: int) -> String:
	return "#%d" % rank


## 18250 -> "18,250"
static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" + out) if value < 0 else out


static func _tree() -> SceneTree:
	var main_loop := Engine.get_main_loop()
	return main_loop as SceneTree if main_loop is SceneTree else null
