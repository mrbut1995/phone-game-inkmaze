"""View: danh sách các màn chơi trong resources/levels + nút thao tác file."""

from __future__ import annotations

import tkinter as tk
from tkinter import ttk
from typing import Callable, Optional

from ..controllers.app_controller import AppController
from ..controllers.events import EV_LEVELS_CHANGED, EV_LEVEL_CHANGED
from ..models.repository import LevelSummary


class LevelListView(ttk.Frame):
    """Panel bên trái: liệt kê level_*.tres và các nút Tạo/Nhân bản/Xoá."""

    def __init__(
        self,
        master: tk.Misc,
        app: AppController,
        on_open: Callable[[int], None],
        on_new: Callable[[], None],
        on_duplicate: Callable[[], None],
        on_delete: Callable[[int], None],
        on_refresh: Callable[[], None],
    ) -> None:
        super().__init__(master, padding=(8, 8))
        self.app = app
        self._on_open = on_open
        self._ids: list[int] = []
        self._current_id: Optional[int] = None

        ttk.Label(self, text="Danh sách màn", style="Section.TLabel").pack(anchor="w")

        list_frame = ttk.Frame(self)
        list_frame.pack(fill="both", expand=True, pady=(4, 6))
        self.listbox = tk.Listbox(
            list_frame, activestyle="dotbox", exportselection=False,
            background="#FFFEF9", foreground="#224C6D",
            selectbackground="#FDE9C9", selectforeground="#224C6D",
            highlightthickness=1, highlightbackground="#DCE9F2", relief="flat",
        )
        scroll = ttk.Scrollbar(list_frame, orient="vertical", command=self.listbox.yview)
        self.listbox.configure(yscrollcommand=scroll.set)
        self.listbox.pack(side="left", fill="both", expand=True)
        scroll.pack(side="right", fill="y")
        self.listbox.bind("<Double-Button-1>", lambda _e: self._open_selected())
        self.listbox.bind("<Return>", lambda _e: self._open_selected())

        buttons = ttk.Frame(self)
        buttons.pack(fill="x")
        buttons.columnconfigure(0, weight=1)
        buttons.columnconfigure(1, weight=1)
        ttk.Button(buttons, text="Mở", command=self._open_selected).grid(row=0, column=0, sticky="ew", padx=1, pady=1)
        ttk.Button(buttons, text="Làm mới", command=on_refresh).grid(row=0, column=1, sticky="ew", padx=1, pady=1)
        ttk.Button(buttons, text="Màn mới", command=on_new).grid(row=1, column=0, sticky="ew", padx=1, pady=1)
        ttk.Button(buttons, text="Nhân bản", command=on_duplicate).grid(row=1, column=1, sticky="ew", padx=1, pady=1)
        ttk.Button(buttons, text="Xoá file", command=self._delete_selected).grid(
            row=2, column=0, columnspan=2, sticky="ew", padx=1, pady=1)

        self.app.events.on(EV_LEVELS_CHANGED, self._populate)
        self.app.events.on(EV_LEVEL_CHANGED, lambda *_: self.highlight_current())
        self._populate(self.app.level_summaries())

    # ------------------------------------------------------------------
    # Danh sách
    # ------------------------------------------------------------------
    def _populate(self, summaries: list[LevelSummary]) -> None:
        self.listbox.delete(0, "end")
        self._ids = []
        for summary in summaries:
            self._ids.append(summary.level_id)
            self.listbox.insert("end", self._label(summary))
        self.highlight_current()

    @staticmethod
    def _label(summary: LevelSummary) -> str:
        size = "%dx%d" % (summary.width, summary.height) if summary.width else "?"
        title = summary.title or "(không có tiêu đề)"
        return "#%-3d %-7s %s" % (summary.level_id, size, title)

    def highlight_current(self) -> None:
        self._current_id = self.app.editor.level.level_id
        for index, level_id in enumerate(self._ids):
            if level_id == self._current_id:
                self.listbox.selection_clear(0, "end")
                self.listbox.selection_set(index)
                self.listbox.see(index)
                return

    def selected_id(self) -> Optional[int]:
        selection = self.listbox.curselection()
        if not selection:
            return None
        return self._ids[selection[0]]

    # ------------------------------------------------------------------
    # Nút
    # ------------------------------------------------------------------
    def _open_selected(self) -> None:
        level_id = self.selected_id()
        if level_id is None:
            return
        self._on_open(level_id)

    def _delete_selected(self) -> None:
        level_id = self.selected_id()
        if level_id is None:
            return
        self._on_delete(level_id)
