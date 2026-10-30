class_name RankRow
extends Control
## ============================================================================
## Hàng danh sách xếp hạng (755x90) — mockup/ranking.svg
##
## `setup(entry, board)` nhận entry từ RankingManager:
## { rank, name, flag, primary, points, is_player, has_record }
## Hàng của người chơi tự đổi sang art nền xanh nhạt (rank_row_you.svg).
## Node UI nằm trong CẤU TRÚC: Body (HBox) → Rank · Flag · Name (giãn) · Stats (VBox: Record + Points)
## ============================================================================

## Art nền hàng + node binding: khai `node_paths` + NodePath trong `rank_row.tscn`
@export var row_art: Texture2D = null
@export var row_you_art: Texture2D = null
@export var bg: TextureRect = null
@export var rank_label: Label = null
@export var flag: TextureRect = null
@export var name_label: Label = null
@export var record_label: Label = null
@export var points_label: Label = null

## Bộ cờ có sẵn trong assets/images/icons/flags/ (không dùng emoji)
const FLAG_CODES: Array[String] = ["vi", "en", "ja", "ko", "zh_cn", "fr", "generic"]

static var _flag_cache: Dictionary = {}


func setup(entry: Dictionary, board: String) -> void:
	var is_you := bool(entry.get("is_player", false))
	bg.texture = row_you_art if is_you else row_art
	rank_label.text = Ranking.rank_text(int(entry.get("rank", 0)))
	flag.texture = flag_texture(str(entry.get("flag", "generic")))
	name_label.text = Ranking.display_name(entry)
	record_label.text = Ranking.record_text(board, entry)
	points_label.text = Ranking.points_text(entry)


## Cờ quốc gia theo mã (vi/en/ja/ko/zh_cn/fr/generic) — có cache, fallback về cờ chung
static func flag_texture(code: String) -> Texture2D:
	if _flag_cache.is_empty():
		for key in FLAG_CODES:
			var path := "res://assets/images-png/icons/flags/flag_%s.png" % key
			if ResourceLoader.exists(path):
				_flag_cache[key] = load(path)
	return _flag_cache.get(code, _flag_cache.get("generic"))
