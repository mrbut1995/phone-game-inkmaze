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

const ROW_ART := preload("res://assets/images/ranking/rank_row.svg")
const ROW_YOU_ART := preload("res://assets/images/ranking/rank_row_you.svg")

## Bộ cờ có sẵn trong assets/images/icons/flags/ (không dùng emoji)
const FLAG_CODES: Array[String] = ["vi", "en", "ja", "ko", "zh_cn", "fr", "generic"]

static var _flag_cache: Dictionary = {}


func setup(entry: Dictionary, board: String) -> void:
	var is_you := bool(entry.get("is_player", false))
	($Bg as TextureRect).texture = ROW_YOU_ART if is_you else ROW_ART
	($Body/Rank as Label).text = Ranking.rank_text(int(entry.get("rank", 0)))
	($Body/Flag as TextureRect).texture = flag_texture(str(entry.get("flag", "generic")))
	($Body/Name as Label).text = Ranking.display_name(entry)
	($Body/Stats/Record as Label).text = Ranking.record_text(board, entry)
	($Body/Stats/Points as Label).text = Ranking.points_text(entry)


## Cờ quốc gia theo mã (vi/en/ja/ko/zh_cn/fr/generic) — có cache, fallback về cờ chung
static func flag_texture(code: String) -> Texture2D:
	if _flag_cache.is_empty():
		for key in FLAG_CODES:
			var path := "res://assets/images/icons/flags/flag_%s.svg" % key
			if ResourceLoader.exists(path):
				_flag_cache[key] = load(path)
	return _flag_cache.get(code, _flag_cache.get("generic"))
