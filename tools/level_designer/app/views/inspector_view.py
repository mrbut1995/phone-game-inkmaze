"""View: bảng thuộc tính bên phải (thông tin màn, thông số luật chơi, kiểm tra)."""

from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from ..config import DIFFICULTIES, MAX_ID, MAX_SIZE, MIN_ID, MIN_SIZE, MODE_IDS
from ..controllers.app_controller import AppController
from ..controllers.editor_controller import EditorController
from ..controllers.events import EV_LEVEL_CHANGED, EV_MODEL_UPDATED, EV_STATUS
from ..models.level import Cell


class InspectorView(ttk.Frame):
    """Nhập thuộc tính LevelData + hiển thị kết quả kiểm tra/đường đi ngắn nhất."""

    def __init__(self, master: tk.Misc, app: AppController) -> None:
        super().__init__(master, padding=(10, 8))
        self.app = app
        self.editor: EditorController = app.editor
        self._suspend = False

        self._build_general()
        self._build_rules()
        self._build_tools()
        self._build_report()

        self.editor.events.on(EV_MODEL_UPDATED, lambda *_: self.refresh())
        self.editor.events.on(EV_LEVEL_CHANGED, lambda *_: self.refresh())
        self.refresh()

    # ------------------------------------------------------------------
    # Xây dựng giao diện
    # ------------------------------------------------------------------
    def _build_general(self) -> None:
        frame = ttk.LabelFrame(self, text="Thông tin màn", padding=(8, 6))
        frame.pack(fill="x", pady=(0, 8))

        self.var_id = tk.IntVar()
        self.var_title = tk.StringVar()
        self.var_chapter = tk.IntVar()
        self.var_mode = tk.StringVar()
        self.var_difficulty = tk.StringVar()

        self._spin_row(frame, 0, "level_id", self.var_id, MIN_ID, MAX_ID, self._on_int("level_id"))
        self._entry_row(frame, 1, "level_title", self.var_title, self._commit_title)
        self._spin_row(frame, 2, "chapter", self.var_chapter, 1, 99, self._on_int("chapter"))

        ttk.Label(frame, text="mode_id").grid(row=3, column=0, sticky="w", pady=2)
        mode = ttk.Combobox(frame, textvariable=self.var_mode, values=list(MODE_IDS), width=16)
        mode.grid(row=3, column=1, sticky="ew", pady=2)
        mode.bind("<<ComboboxSelected>>", lambda _e: self._commit("mode_id", self.var_mode.get()))

        ttk.Label(frame, text="difficulty").grid(row=4, column=0, sticky="w", pady=2)
        diff = ttk.Combobox(frame, textvariable=self.var_difficulty, values=list(DIFFICULTIES), width=16)
        diff.grid(row=4, column=1, sticky="ew", pady=2)
        diff.bind("<<ComboboxSelected>>", lambda _e: self._commit("difficulty", self.var_difficulty.get()))

        frame.columnconfigure(1, weight=1)

    def _build_rules(self) -> None:
        frame = ttk.LabelFrame(self, text="Lưới & luật chơi", padding=(8, 6))
        frame.pack(fill="x", pady=(0, 8))

        self.var_width = tk.IntVar()
        self.var_height = tk.IntVar()
        self.var_start_x = tk.IntVar()
        self.var_start_y = tk.IntVar()
        self.var_end_x = tk.IntVar()
        self.var_end_y = tk.IntVar()
        self.var_steps = tk.IntVar()
        self.var_par = tk.DoubleVar()

        self._spin_row(frame, 0, "width", self.var_width, MIN_SIZE, MAX_SIZE, self._on_int("width"))
        self._spin_row(frame, 1, "height", self.var_height, MIN_SIZE, MAX_SIZE, self._on_int("height"))
        self._spin_row(frame, 2, "S.x", self.var_start_x, 0, MAX_SIZE - 1, self._on_cell("start", 0))
        self._spin_row(frame, 3, "S.y", self.var_start_y, 0, MAX_SIZE - 1, self._on_cell("start", 1))
        self._spin_row(frame, 4, "F.x", self.var_end_x, 0, MAX_SIZE - 1, self._on_cell("end", 0))
        self._spin_row(frame, 5, "F.y", self.var_end_y, 0, MAX_SIZE - 1, self._on_cell("end", 1))
        self._spin_row(frame, 6, "max_steps", self.var_steps, 1, 9999, self._on_int("max_steps"))
        self._spin_row(frame, 7, "par_time", self.var_par, 1, 9999, self._on_par, increment=5)

        hint = ttk.Label(frame, text="y = 0 là hàng TRÊN cùng (giống trong game)", style="Hint.TLabel")
        hint.grid(row=8, column=0, columnspan=2, sticky="w", pady=(4, 0))
        frame.columnconfigure(1, weight=1)

    def _build_tools(self) -> None:
        frame = ttk.LabelFrame(self, text="Trợ giúp", padding=(8, 6))
        frame.pack(fill="x", pady=(0, 8))
        ttk.Button(frame, text="Tính max_steps theo đường đi", command=self.editor.auto_steps) \
            .pack(fill="x", pady=2)
        ttk.Button(frame, text="Xoá hết tường bên trong", command=self.editor.clear_walls) \
            .pack(fill="x", pady=2)
        ttk.Button(frame, text="Sinh tường ẩn ngẫu nhiên (35%)",
                   command=lambda: self.editor.fill_hidden_random(0.35)).pack(fill="x", pady=2)

    def _build_report(self) -> None:
        frame = ttk.LabelFrame(self, text="Kiểm tra & phân tích", padding=(8, 6))
        frame.pack(fill="both", expand=True)

        self.report = tk.Text(frame, height=10, wrap="word", relief="flat",
                              background="#FFFEF9", foreground="#224C6D", font=(None, 9))
        self.report.pack(fill="both", expand=True)
        self.report.configure(state="disabled")
        self.report.tag_configure("error", foreground="#D8243C")
        self.report.tag_configure("warning", foreground="#B45309")
        self.report.tag_configure("ok", foreground="#2E7D32")
        self.report.tag_configure("info", foreground="#3D83AE")

    # ------------------------------------------------------------------
    # Hàng nhập liệu
    # ------------------------------------------------------------------
    def _spin_row(self, parent: ttk.Frame, row: int, label: str, var: tk.Variable,
                  minimum: float, maximum: float, command, increment: float = 1) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", pady=2)
        spin = ttk.Spinbox(parent, textvariable=var, from_=minimum, to=maximum,
                           increment=increment, width=18, command=command)
        spin.grid(row=row, column=1, sticky="ew", pady=2)
        spin.bind("<Return>", lambda _e: command())
        spin.bind("<FocusOut>", lambda _e: command())

    def _entry_row(self, parent: ttk.Frame, row: int, label: str, var: tk.StringVar, commit) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", pady=2)
        entry = ttk.Entry(parent, textvariable=var, width=20)
        entry.grid(row=row, column=1, sticky="ew", pady=2)
        entry.bind("<Return>", lambda _e: commit())
        entry.bind("<FocusOut>", lambda _e: commit())

    # ------------------------------------------------------------------
    # Ghi giá trị vào model
    # ------------------------------------------------------------------
    def _commit(self, field: str, value) -> None:
        if self._suspend:
            return
        self.editor.set_property(field, value)

    def _commit_title(self) -> None:
        self._commit("level_title", self.var_title.get())

    def _on_int(self, field: str):
        def handler() -> None:
            try:
                value = int(self.var_of(field).get())
            except (tk.TclError, ValueError):
                return
            self._commit(field, value)
        return handler

    def _on_par(self) -> None:
        try:
            value = float(self.var_par.get())
        except (tk.TclError, ValueError):
            return
        self._commit("par_time", value)

    def _on_cell(self, name: str, axis: int):
        def handler() -> None:
            if self._suspend:
                return
            x = self.var_start_x.get() if name == "start" else self.var_end_x.get()
            y = self.var_start_y.get() if name == "start" else self.var_end_y.get()
            cell: Cell = (x, y)
            other = self.editor.level.end if name == "start" else self.editor.level.start
            if cell == other:
                self.editor.events.emit(EV_STATUS, "S và F không được trùng ô")
                self.refresh()
                return
            def action() -> None:
                if name == "start":
                    self.editor.level.start = cell
                else:
                    self.editor.level.end = cell
            self.editor.run_with_undo(action, "Cập nhật %s" % name)
        return handler

    def var_of(self, field: str) -> tk.Variable:
        return {
            "level_id": self.var_id,
            "chapter": self.var_chapter,
            "width": self.var_width,
            "height": self.var_height,
            "max_steps": self.var_steps,
        }[field]

    # ------------------------------------------------------------------
    # Cập nhật giao diện từ model
    # ------------------------------------------------------------------
    def refresh(self) -> None:
        level = self.editor.level
        self._suspend = True
        try:
            self.var_id.set(level.level_id)
            self.var_title.set(level.level_title)
            self.var_chapter.set(level.chapter)
            self.var_mode.set(level.mode_id)
            self.var_difficulty.set(level.difficulty)
            self.var_width.set(level.width)
            self.var_height.set(level.height)
            self.var_start_x.set(level.start[0])
            self.var_start_y.set(level.start[1])
            self.var_end_x.set(level.end[0])
            self.var_end_y.set(level.end[1])
            self.var_steps.set(level.max_steps)
            self.var_par.set(level.par_time)
        finally:
            self._suspend = False
        self._refresh_report()

    def _refresh_report(self) -> None:
        issues = self.app.validate_current()
        stats = self.app.stats()
        level = self.editor.level

        self.report.configure(state="normal")
        self.report.delete("1.0", "end")

        for issue in issues:
            tag = {"error": "error", "warning": "warning"}.get(issue.severity, "info")
            self.report.insert("end", "%s\n" % issue.format(), tag)
        if not issues:
            self.report.insert("end", "Không phát hiện vấn đề nào ✔\n", "ok")

        self.report.insert("end", "\n")
        self.report.insert(
            "end",
            "Lưới %dx%d · %d ô · %d tường hiện · %d tường ẩn\n" % (
                level.width, level.height, stats["cells"],
                stats["visible_walls"], stats["hidden_walls"]),
            "info",
        )
        self.report.insert("end", "Thư mục level:\n%s\n" % self.app.levels_dir(), "info")
        self.report.configure(state="disabled")
