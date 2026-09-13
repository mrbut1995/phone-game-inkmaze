"""Tiện ích: bộ phát sự kiện đơn giản để view lắng nghe controller.

Cố ý không dùng thư viện ngoài: view chỉ cần đăng ký callback theo tên sự kiện.
"""

from __future__ import annotations

from typing import Any, Callable

Listener = Callable[..., None]


class EventEmitter:
    """Bộ phát sự kiện tối giản (tên sự kiện -> danh sách callback)."""

    def __init__(self) -> None:
        self._listeners: dict[str, list[Listener]] = {}

    def on(self, event: str, callback: Listener) -> Listener:
        self._listeners.setdefault(event, []).append(callback)
        return callback

    def off(self, event: str, callback: Listener) -> None:
        handlers = self._listeners.get(event, [])
        if callback in handlers:
            handlers.remove(callback)

    def emit(self, event: str, *args: Any, **kwargs: Any) -> None:
        for callback in list(self._listeners.get(event, [])):
            callback(*args, **kwargs)


# Tên các sự kiện dùng chung giữa controller và view
EV_LEVEL_CHANGED = "level_changed"      # model được thay (nạp màn khác / màn mới)
EV_MODEL_UPDATED = "model_updated"      # dữ liệu trong model vừa đổi -> vẽ lại
EV_TOOL_CHANGED = "tool_changed"        # đổi công cụ vẽ
EV_STATUS = "status"                    # thông báo trạng thái (chuỗi)
EV_DIRTY_CHANGED = "dirty_changed"      # có/không có thay đổi chưa lưu
EV_LEVELS_CHANGED = "levels_changed"    # danh sách file level thay đổi
EV_VIEW_OPTIONS_CHANGED = "view_options_changed"
