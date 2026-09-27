"""Tiện ích: chia GIÁ TRỊ Ô theo ĐƯỜNG ĐI (dùng chung cho công cụ 8 + make_samples).

Hai kiểu chia (khớp `app/config.py` → `MODE_EDITS[...]["path"]["fill"]`):

    · "sum"  — TỔNG các giá trị = đúng `total`, mỗi ô nằm trong [lo, hi]
               (chi phí ô của Countdown Cost · điểm ô của Sum Path).
    · "step" — giá trị TĂNG DẦN theo BƯỚC ĐI: tới ô ở bước thứ j thì đã có j bước được đi
               ⇒ giá trị cần ≥ j + 1 (MỰC của Fading Ink: `clamp(j + mực dư, lo, hi)`).
"""

from __future__ import annotations

import random


def feasible_range(count: int, lo: int, hi: int) -> tuple[int, int]:
    """Khoảng TỔNG hợp lệ khi chia cho `count` ô, mỗi ô nằm trong [lo, hi]."""
    count = max(0, int(count))
    return (count * int(lo), count * int(hi))


def distribute_sum(total: int, count: int, lo: int, hi: int,
                   rng: random.Random | None = None) -> list[int] | None:
    """Chia `total` cho `count` ô sao cho mỗi ô ∈ [lo, hi].

    Trả về `None` nếu tổng nằm ngoài khoảng hợp lệ (xem `feasible_range`).
    Chia ngẫu nhiên (bắt đầu từ `lo` rồi rắc đều phần dư) để màn không "một ô gánh hết".
    """
    count = int(count)
    lo, hi = int(lo), int(hi)
    if count <= 0:
        return None
    total = int(total)
    min_total, max_total = feasible_range(count, lo, hi)
    if total < min_total or total > max_total:
        return None

    rng = rng or random.Random()
    values = [lo] * count
    remaining = total - min_total
    while remaining > 0:
        candidates = [index for index, value in enumerate(values) if value < hi]
        values[rng.choice(candidates)] += 1
        remaining -= 1
    return values


def step_values(steps: list[int], extra: int, lo: int, hi: int) -> list[int]:
    """Giá trị theo BƯỚC ĐI: ô ở bước thứ `j` (0 = S) nhận `clamp(j + extra, lo, hi)`."""
    lo, hi = int(lo), int(hi)
    extra = int(extra)
    return [max(lo, min(hi, int(step) + extra)) for step in steps]
