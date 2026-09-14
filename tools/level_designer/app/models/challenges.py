"""Danh mục LOẠI THỬ THÁCH (challenge) — bản Python, khớp với game.

Game: `scripts/core/controllers/challenge_types.gd` (class ChallengeTypes).
Tool: module này. Khi thêm loại mới phải sửa CẢ HAI nơi.

Mỗi màn gắn TỐI ĐA 3 thử thách: `LevelModel.challenges = [(type_id, param), ...]`.
Để trống = game dùng 3 thử thách mặc định (no_wall · steps_max · time_max).
"""

from __future__ import annotations

MAX_PER_LEVEL = 3

NO_WALL = "no_wall"
STEPS_MAX = "steps_max"
TIME_MAX = "time_max"
ONLY_NUMBERED = "only_numbered"
AVOID_NUMBERED = "avoid_numbered"
NO_REVISIT = "no_revisit"
VISIT_ALL = "visit_all"
VISIT_ALL_NUMBERED = "visit_all_numbered"
LEN_MIN_PERCENT = "len_min_percent"
LEN_MAX_PERCENT = "len_max_percent"
SUM_LT = "sum_lt"
SUM_LE = "sum_le"
SUM_GT = "sum_gt"
SUM_GE = "sum_ge"
NO_HINT = "no_hint"
NO_UNDO = "no_undo"

PARAM_NONE = ""
PARAM_STEPS = "steps"
PARAM_SECONDS = "seconds"
PARAM_PERCENT = "percent"
PARAM_SUM = "sum"

# id -> (nhãn tiếng Việt, loại tham số, đơn vị hiển thị, mô tả ngắn)
CHALLENGES: dict[str, tuple[str, str, str, str]] = {
    NO_WALL: (
        "Không đâm vào tường vô hình",
        PARAM_NONE, "",
        "Mặc định · luôn có ở mọi màn nếu bạn không chọn gì",
    ),
    STEPS_MAX: (
        "Đi không quá N bước", PARAM_STEPS, "bước",
        "Thường đặt bằng max_steps (dư vài bước)",
    ),
    TIME_MAX: (
        "Về đích dưới N giây", PARAM_SECONDS, "giây",
        "Nên đặt bằng par_time của màn",
    ),
    ONLY_NUMBERED: (
        "Chỉ đi vào ô CÓ số", PARAM_NONE, "",
        "Mọi ô trên đường đi (trừ S/F) phải hiện số",
    ),
    AVOID_NUMBERED: (
        "Không đi vào ô CÓ số", PARAM_NONE, "",
        "Không được bước vào ô có số (kể cả ô số 0 hiển thị)",
    ),
    NO_REVISIT: (
        "Không đi đè lên đường đã đi", PARAM_NONE, "",
        "Mỗi ô chỉ được đi qua 1 lần",
    ),
    VISIT_ALL: (
        "Đi qua hết mọi ô của board", PARAM_NONE, "",
        "Dài hơn đường ngắn nhất -> chỉ hợp với màn rộng, ít tường",
    ),
    VISIT_ALL_NUMBERED: (
        "Đi qua hết mọi ô CÓ số", PARAM_NONE, "",
        "Phải ghé mọi ô hiện số trên board",
    ),
    LEN_MIN_PERCENT: (
        "Đi tối thiểu N% số ô", PARAM_PERCENT, "%",
        "N% của số ô thuộc board",
    ),
    LEN_MAX_PERCENT: (
        "Đi tối đa N% số ô", PARAM_PERCENT, "%",
        "Buộc đi đường ngắn, ít vòng",
    ),
    SUM_LT: ("Tổng số trên đường đi < N", PARAM_SUM, "", "Tổng các số hiện trên ô đã đi"),
    SUM_LE: ("Tổng số trên đường đi <= N", PARAM_SUM, "", "Tổng các số hiện trên ô đã đi"),
    SUM_GT: ("Tổng số trên đường đi > N", PARAM_SUM, "", "Buộc đi qua ô số lớn"),
    SUM_GE: ("Tổng số trên đường đi >= N", PARAM_SUM, "", "Buộc đi qua ô số lớn"),
    NO_HINT: ("Không dùng gợi ý", PARAM_NONE, "", "Không bấm nút GỢI Ý lần nào"),
    NO_UNDO: ("Không dùng hoàn tác", PARAM_NONE, "", "Không bấm nút UNDO lần nào"),
}

# Thứ tự hiển thị trong combobox
ORDER: list[str] = [
    NO_WALL,
    STEPS_MAX,
    TIME_MAX,
    ONLY_NUMBERED,
    AVOID_NUMBERED,
    NO_REVISIT,
    VISIT_ALL,
    VISIT_ALL_NUMBERED,
    LEN_MIN_PERCENT,
    LEN_MAX_PERCENT,
    SUM_LT,
    SUM_LE,
    SUM_GT,
    SUM_GE,
    NO_HINT,
    NO_UNDO,
]

DEFAULT_TYPES: list[str] = [NO_WALL, STEPS_MAX, TIME_MAX]

# Thử thách không cần tham số
NO_PARAM_TYPES: set[str] = {
    NO_WALL,
    ONLY_NUMBERED,
    AVOID_NUMBERED,
    NO_REVISIT,
    VISIT_ALL,
    VISIT_ALL_NUMBERED,
    NO_HINT,
    NO_UNDO,
}

# Giá trị tham số mặc định theo loại
PARAM_DEFAULT: dict[str, int] = {
    PARAM_STEPS: 15,
    PARAM_SECONDS: 45,
    PARAM_PERCENT: 50,
    PARAM_SUM: 20,
}

# Giới hạn nhập liệu trong tool
PARAM_RANGE: dict[str, tuple[int, int]] = {
    PARAM_STEPS: (1, 999),
    PARAM_SECONDS: (5, 3600),
    PARAM_PERCENT: (1, 100),
    PARAM_SUM: (0, 9999),
}


def is_valid(type_id: str) -> bool:
    return type_id in CHALLENGES


def label(type_id: str) -> str:
    return CHALLENGES.get(type_id, (type_id, PARAM_NONE, "", ""))[0]


def param_kind(type_id: str) -> str:
    return CHALLENGES.get(type_id, (type_id, PARAM_NONE, "", ""))[1]


def unit(type_id: str) -> str:
    return CHALLENGES.get(type_id, (type_id, PARAM_NONE, "", ""))[2]


def hint(type_id: str) -> str:
    return CHALLENGES.get(type_id, (type_id, PARAM_NONE, "", ""))[3]


def has_param(type_id: str) -> bool:
    return param_kind(type_id) != PARAM_NONE


def param_bounds(type_id: str) -> tuple[int, int]:
    return PARAM_RANGE.get(param_kind(type_id), (0, 9999))


def default_param(type_id: str, max_steps: int = 15, par_time: float = 45.0) -> int:
    """Tham số mặc định hợp lý theo màn (dùng khi người dùng vừa chọn loại mới)."""
    kind = param_kind(type_id)
    if kind == PARAM_STEPS:
        return max(1, int(max_steps))
    if kind == PARAM_SECONDS:
        return max(5, int(round(par_time)))
    return PARAM_DEFAULT.get(kind, 0)


def combo_values() -> list[str]:
    """Chuỗi hiển thị cho combobox: 'id — nhãn'."""
    return ["%s — %s" % (type_id, label(type_id)) for type_id in ORDER]


def from_combo(value: str) -> str:
    return value.split(" — ", 1)[0].strip()


def to_combo(type_id: str) -> str:
    return "%s — %s" % (type_id, label(type_id))
