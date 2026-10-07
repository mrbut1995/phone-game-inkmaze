"""Danh mục LUẬT THỬ THÁCH (challenge) — bản Python, khớp với game.

Game: `scripts/modes/challenge_game_mode.gd` (class ChallengeGameMode).
Tool: module này. Khi thêm luật mới phải sửa CẢ HAI nơi.

Màn gắn luật bằng 3 trường của LevelData:
    mode_id        = "challenge"     (bắt buộc — luật CHỈ áp dụng ở chế độ challenge)
    challenge      = "<id luật>"     (rỗng = không gắn)
    challenge_param= <số>, 0 = game tự tính theo luật/bàn cờ (xem `suggested_param`)

Ván chơi vẫn giống Play Mode (đâm tường = thua ngay); điểm khác duy nhất:
VI PHẠM luật thử thách (hoặc quá hạn) là THUA NGAY.
"""

from __future__ import annotations

COUNTDOWN = "countdown"
MOVE_LIMIT = "move_limit"
STEP_TIMER = "step_timer"
NO_TOOL = "no_tool"
NO_MOVE_OVERLAPPED = "no_move_overlapped"
WALK_NUMBER_ONLY = "walk_number_only"
WALK_EMPTY_ONLY = "walk_empty_only"
BACKTRACK_LIMIT = "backtrack_limit"

PARAM_NONE = ""
PARAM_SECONDS = "seconds"
PARAM_STEPS = "steps"
PARAM_TURNS = "turns"

# Nhãn của lựa chọn "không gắn luật" trong combobox (from_combo trả về "")
NONE_LABEL = "— Không gắn luật —"

# id -> (nhãn tiếng Việt, loại tham số, đơn vị hiển thị, mô tả ngắn)
RULES: dict[str, tuple[str, str, str, str]] = {
    COUNTDOWN: (
        "Hoàn thành trước khi hết đếm ngược", PARAM_SECONDS, "giây",
        "Hết giờ mà chưa tới F = thua. Tham số 0 = game tự tính: 60 giây + 4 giây mỗi ô (tối thiểu 75)",
    ),
    MOVE_LIMIT: (
        "Hoàn thành trong tối đa N bước", PARAM_STEPS, "bước",
        "Vượt quá N bước = thua. Tham số 0 = dùng đúng max_steps của màn",
    ),
    STEP_TIMER: (
        "Mỗi bước phải đi trong X giây", PARAM_SECONDS, "giây",
        "Đồng hồ con reset sau mỗi bước; quá X giây chưa đi = thua. Tham số 0 = theo độ khó: "
        "dễ 30 · thường 20 · khó 15",
    ),
    NO_TOOL: (
        "Không dùng công cụ (Gợi ý / Hoàn tác)", PARAM_NONE, "",
        "Bấm GỢI Ý hoặc HOÀN TÁC lần đầu là thua ngay (gộp no_hint + no_undo cũ)",
    ),
    NO_MOVE_OVERLAPPED: (
        "Không đi lại trên đường đã đi", PARAM_NONE, "",
        "Giẫm lên ô đã đi qua = thua ngay (thay luật cũ no_revisit)",
    ),
    WALK_NUMBER_ONLY: (
        "Chỉ đi trên ô CÓ số", PARAM_NONE, "",
        "Bước vào ô KHÔNG số = thua ngay. Ô S/F luôn đi được — màn phải có ĐƯỜNG chỉ qua ô có số",
    ),
    WALK_EMPTY_ONLY: (
        "Chỉ đi trên ô KHÔNG số", PARAM_NONE, "",
        "Bước vào ô CÓ số = thua ngay. Ô S/F luôn đi được — màn phải có ĐƯỜNG chỉ qua ô không số",
    ),
    BACKTRACK_LIMIT: (
        "Quay đầu tối đa N lần", PARAM_TURNS, "lượt",
        "Lùi về ô vừa rời quá N lần = thua. Tham số 0 = 3 lượt",
    ),
}

# Thứ tự hiển thị trong combobox (khớp CHALLENGE_IDS của game)
ORDER: list[str] = [
    COUNTDOWN,
    MOVE_LIMIT,
    STEP_TIMER,
    NO_TOOL,
    NO_MOVE_OVERLAPPED,
    WALK_NUMBER_ONLY,
    WALK_EMPTY_ONLY,
    BACKTRACK_LIMIT,
]

# Luật cần tham số (còn lại tham số luôn = 0)
PARAMED_TYPES: set[str] = {COUNTDOWN, MOVE_LIMIT, STEP_TIMER, BACKTRACK_LIMIT}

# Giới hạn nhập tham số trong tool
PARAM_RANGE: dict[str, tuple[int, int]] = {
    PARAM_SECONDS: (5, 3600),
    PARAM_STEPS: (1, 9999),
    PARAM_TURNS: (1, 99),
}

# Mặc định của game khi challenge_param = 0 (xem _default_param bên GDScript)
STEP_TIMER_BY_DIFFICULTY = {"easy": 30, "medium": 20, "hard": 15}
BACKTRACK_DEFAULT = 3
COUNTDOWN_BASE = 60
COUNTDOWN_PER_CELL = 4
COUNTDOWN_MIN = 75


def is_valid(rule_id: str) -> bool:
    return rule_id in RULES


def label(rule_id: str) -> str:
    return RULES.get(rule_id, (rule_id, PARAM_NONE, "", ""))[0]


def param_kind(rule_id: str) -> str:
    return RULES.get(rule_id, (rule_id, PARAM_NONE, "", ""))[1]


def unit(rule_id: str) -> str:
    return RULES.get(rule_id, (rule_id, PARAM_NONE, "", ""))[2]


def note(rule_id: str) -> str:
    return RULES.get(rule_id, (rule_id, PARAM_NONE, "", ""))[3]


def has_param(rule_id: str) -> bool:
    return param_kind(rule_id) != PARAM_NONE


def param_bounds(rule_id: str) -> tuple[int, int]:
    return PARAM_RANGE.get(param_kind(rule_id), (0, 9999))


def suggested_param(rule_id: str, width: int = 3, height: int = 3,
                    max_steps: int = 15, difficulty: str = "medium") -> int:
    """Tham số GỢI Ý khi người chơi để 0 (mô phỏng `_default_param` của game).

    Chỉ để HIỂN THỊ trong tool — vào game, tham số 0 luôn được game tự tính lại
    theo bàn cờ/độ khó thật của màn.
    """
    if rule_id == COUNTDOWN:
        cells = max(1, int(width)) * max(1, int(height))
        return max(COUNTDOWN_MIN, COUNTDOWN_BASE + cells * COUNTDOWN_PER_CELL)
    if rule_id == MOVE_LIMIT:
        return max(int(max_steps), 4)
    if rule_id == STEP_TIMER:
        return int(STEP_TIMER_BY_DIFFICULTY.get(str(difficulty).strip().lower(), 20))
    if rule_id == BACKTRACK_LIMIT:
        return BACKTRACK_DEFAULT
    return 0


def combo_values() -> list[str]:
    """Chuỗi hiển thị cho combobox: 'id — nhãn'."""
    return ["%s — %s" % (rule_id, label(rule_id)) for rule_id in ORDER]


def from_combo(value: str) -> str:
    """Chuỗi combobox -> id luật ("" = không gắn)."""
    text = str(value or "").strip()
    if not text or text == NONE_LABEL:
        return ""
    return text.split(" — ", 1)[0].strip()


def to_combo(rule_id: str) -> str:
    if not is_valid(rule_id):
        return NONE_LABEL
    return "%s — %s" % (rule_id, label(rule_id))
