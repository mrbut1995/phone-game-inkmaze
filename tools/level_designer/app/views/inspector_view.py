"""View: bảng thuộc tính bên phải (thông tin màn, thông số luật chơi, kiểm tra)."""

from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from ..config import (
    DIFFICULTIES,
    MAX_ID,
    MAX_SIZE,
    MIN_ID,
    MIN_SIZE,
    MODE_IDS,
    MODE_LABELS,
    PLAY_MODE_ID,
    TOOL_VALUE_KEY,
    mode_edit_spec,
)
from ..controllers.app_controller import AppController
from ..controllers.editor_controller import EditorController
from ..controllers.events import EV_LEVEL_CHANGED, EV_MODEL_UPDATED, EV_PATH_CHANGED, EV_STATUS
from ..models import missions as chal
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
        self._build_missions()
        self._build_tools()
        self._build_report()

        self.editor.events.on(EV_MODEL_UPDATED, lambda *_: self.refresh())
        self.editor.events.on(EV_LEVEL_CHANGED, lambda *_: self.refresh())
        # Nét đường đi (công cụ 8) đổi → cập nhật ô "Tổng …" (tổng đang có / số ô đã tô)
        self.editor.events.on(EV_PATH_CHANGED, lambda *_: self._refresh_path_sum())
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
        self.var_mode_label = tk.StringVar()
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

        # Nhắc nghĩa của chế độ đang chọn: mode khác "play" = MÀN CHẠY CHẾ ĐỘ SPECIAL
        # (game dùng đúng bàn này làm bàn chơi của chế độ đó — xem README mục 5)
        ttk.Label(frame, textvariable=self.var_mode_label, wraplength=240, justify="left").grid(
            row=5, column=0, columnspan=2, sticky="w", pady=(2, 0))
        self.var_mode.trace_add("write", lambda *_: self._refresh_mode_hint())

        frame.columnconfigure(1, weight=1)

    ## Cập nhật dòng nhắc dưới ô chọn chế độ (nghĩa của chế độ + KIỂU EDIT tương ứng)
    def _refresh_mode_hint(self) -> None:
        mode = (self.var_mode.get() or PLAY_MODE_ID).strip().lower()
        spec = mode_edit_spec(mode)
        if mode == PLAY_MODE_ID:
            lines = ["Kiểu edit: %s" % spec["note"]]
        else:
            lines = ["◆ Màn chạy chế độ SPECIAL — %s" % MODE_LABELS.get(mode, mode),
                     "Kiểu edit: %s" % spec["note"]]
        if spec["is_cell_value"]:
            lines.append("→ dùng công cụ %s để tô %s (%d..%d %s); ô bỏ trống = game tự sinh." % (
                TOOL_VALUE_KEY, spec["tool"].lower(), spec["min"], spec["max"], spec["unit"]))
        self.var_mode_label.set("\n".join(lines))

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

        # Ô "TỔNG …" THEO ĐƯỜNG ĐI (Countdown Cost · Sum Path · Fading Ink) — chỉ hiện khi chế độ có `path`.
        # (Trước đây nằm trên THANH CÔNG CỤ nhưng làm tràn ngang cửa sổ hẹp ⇒ chuyển vào mục này.)
        self.var_path_sum = tk.IntVar()
        self._path_sum_key = ""
        self._path_sum_box = ttk.Frame(frame)
        self._path_sum_box.grid(row=8, column=0, columnspan=2, sticky="ew", pady=(6, 0))
        self.lbl_path_sum = ttk.Label(self._path_sum_box, text="")
        self.lbl_path_sum.pack(side="left")
        self.spin_path_sum = ttk.Spinbox(self._path_sum_box, textvariable=self.var_path_sum,
                                         from_=1, to=999, width=6, command=self._on_path_sum)
        self.spin_path_sum.pack(side="left", padx=(6, 4))
        self.spin_path_sum.bind("<Return>", lambda _e: self._on_path_sum())
        self.spin_path_sum.bind("<FocusOut>", lambda _e: self._on_path_sum())
        self.btn_path_sum = ttk.Button(self._path_sum_box, text="Tô theo đường đi",
                                       command=self._on_paint_path_sum)
        self.btn_path_sum.pack(side="left")
        self.lbl_path_sum_hint = ttk.Label(frame, text="", style="Hint.TLabel",
                                           wraplength=280, justify="left")
        self.lbl_path_sum_hint.grid(row=9, column=0, columnspan=2, sticky="w", pady=(2, 0))

        hint = ttk.Label(frame, text="y = 0 là hàng TRÊN cùng (giống trong game)", style="Hint.TLabel")
        hint.grid(row=10, column=0, columnspan=2, sticky="w", pady=(4, 0))
        frame.columnconfigure(1, weight=1)
        self._refresh_path_sum()

    def _build_missions(self) -> None:
        """Mỗi màn TỐI ĐA 3 nhiệm vụ (1 nhiệm vụ hoàn thành = 1 Sao).

        Để trống = game tự dùng 3 nhiệm vụ mặc định.
        """
        frame = ttk.LabelFrame(self, text="Nhiệm vụ (tối đa 3 · 1 nhiệm vụ = 1 Sao)", padding=(8, 6))
        frame.pack(fill="x", pady=(0, 8))

        self._mission_rows: list[tuple] = []
        for slot in range(chal.MAX_PER_LEVEL):
            row = ttk.Frame(frame)
            row.pack(fill="x", pady=2)
            var_type = tk.StringVar()
            var_param = tk.IntVar()
            combo = ttk.Combobox(row, textvariable=var_type, values=chal.combo_values(),
                                 width=30, state="readonly")
            combo.pack(side="left", fill="x", expand=True)
            spin = ttk.Spinbox(row, textvariable=var_param, width=6, from_=0, to=9999)
            spin.pack(side="left", padx=(4, 2))
            unit = ttk.Label(row, text="", width=5, style="Hint.TLabel")
            unit.pack(side="left")
            clear = ttk.Button(row, text="×", width=3,
                               command=lambda s=slot: self.editor.clear_mission(s))
            clear.pack(side="left", padx=(2, 0))
            combo.bind("<<ComboboxSelected>>", lambda _e, s=slot: self._on_mission_type(s))
            spin.bind("<Return>", lambda _e, s=slot: self._on_mission_param(s))
            spin.bind("<FocusOut>", lambda _e, s=slot: self._on_mission_param(s))
            self._mission_rows.append((var_type, var_param, combo, spin, unit, clear))

        buttons = ttk.Frame(frame)
        buttons.pack(fill="x", pady=(4, 0))
        ttk.Button(buttons, text="Ghi 3 mặc định", command=self.editor.fill_default_missions) \
            .pack(side="left", expand=True, fill="x", padx=(0, 4))
        ttk.Button(buttons, text="Bỏ chọn (game tự mặc định)", command=self.editor.reset_missions) \
            .pack(side="left", expand=True, fill="x")
        ttk.Label(
            frame, style="Hint.TLabel", wraplength=280, justify="left",
            text="Ô số bên phải là tham số N (bước / giây / % số ô / tổng số). "
                 "Ô nhập bị mờ = loại nhiệm vụ không cần tham số.",
        ).pack(fill="x", pady=(4, 0))

    def _build_tools(self) -> None:
        frame = ttk.LabelFrame(self, text="Trợ giúp", padding=(8, 6))
        frame.pack(fill="x", pady=(0, 8))
        ttk.Button(frame, text="Tính max_steps theo đường đi", command=self.editor.auto_steps) \
            .pack(fill="x", pady=2)
        ttk.Button(frame, text="Xoá hết tường bên trong", command=self.editor.clear_walls) \
            .pack(fill="x", pady=2)
        ttk.Button(frame, text="Sinh tường ẩn ngẫu nhiên (35%)",
                   command=lambda: self.editor.fill_hidden_random(0.35)).pack(fill="x", pady=2)
        ttk.Button(frame, text="Toàn bộ ô = board (chữ nhật)", command=self.editor.fill_board) \
            .pack(fill="x", pady=2)
        hint = ttk.Label(frame, style="Hint.TLabel", wraplength=280, justify="left",
                         text="Mẹo: chọn công cụ 6 rồi bấm/kéo trên lưới để bật-tắt ô "
                              "thuộc board (tạo hình H, hình thập tự, v.v.).")
        hint.pack(fill="x", pady=(4, 0))

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
    # Ô "TỔNG …" theo đường đi (công cụ 8) — Countdown Cost · Sum Path · Fading Ink
    # ------------------------------------------------------------------
    ## Giá trị ô "Tổng …" đang nhập (kẹp theo `sum_min..sum_max` của chế độ)
    def path_sum_value(self) -> int:
        spec = self.editor.mode_edit_spec()
        try:
            value = int(self.var_path_sum.get())
        except (tk.TclError, ValueError):
            value = int(spec["sum_default"])
        return max(int(spec["sum_min"]), min(int(spec["sum_max"]), value))

    def _on_path_sum(self) -> None:
        """Nhập xong: kẹp số rồi cập nhật dòng ghi chú."""
        self.var_path_sum.set(self.path_sum_value())
        self._refresh_path_sum()

    def _on_paint_path_sum(self) -> None:
        """Nút "Tô theo đường đi" (giống Ctrl+Enter): TÔ GIÁ TRỊ theo nét vẽ / đường ngắn nhất."""
        self.editor.apply_path_values(self.path_sum_value())
        self._refresh_path_sum()

    ## Bày/ẩn hàng "Tổng …" theo chế độ đang chọn + hiện TỔNG đang có trên đường
    def _refresh_path_sum(self) -> None:
        spec = self.editor.mode_edit_spec()
        if not (spec["paints_values"] and spec["has_sum_field"]):
            self._path_sum_box.grid_remove()
            self.lbl_path_sum_hint.grid_remove()
            return
        self._path_sum_box.grid()
        self.lbl_path_sum_hint.grid()
        if spec["mode_id"] != self._path_sum_key:
            self._path_sum_key = spec["mode_id"]
            self.var_path_sum.set(int(spec["sum_default"]))
        self.lbl_path_sum.configure(text="%s:" % spec["sum_label"])
        self.spin_path_sum.configure(from_=spec["sum_min"], to=spec["sum_max"])

        current = self.editor.path_value_sum()
        if spec["path_fill"] == "sum" and current > 0:
            self.var_path_sum.set(current)          # hiện ĐÚNG tổng đang có trên đường vừa vẽ
        if spec["path_fill"] == "sum":
            text = ("Trên đường đi: %d ô đã tô · tổng = %d · %d ô chưa tô (game tự sinh).\n"
                    "Chưa vẽ nét nào thì nút \"Tô theo đường đi\" sẽ tô theo ĐƯỜNG NGẮN NHẤT của màn."
                    % (self.editor.path_value_count(), current,
                       max(0, len(self.editor.path_paint_cells()) - self.editor.path_value_count())))
        else:
            text = ("Ô ở bước thứ j nhận mực = j + số này (kẹp %d..%d); mực mỗi ô phải ≥ số bước đi tới ô đó."
                    % (spec["min"], spec["max"]))
        self.lbl_path_sum_hint.configure(text=text)

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

    # ------------------------------------------------------------------
    # Nhiệm vụ: đọc/ghi qua controller (có undo)
    # ------------------------------------------------------------------
    def _on_mission_type(self, slot: int) -> None:
        if self._suspend:
            return
        var_type, var_param, _combo, _spin, _unit, _clear = self._mission_rows[slot]
        type_id = chal.from_combo(var_type.get())
        try:
            param = int(var_param.get())
        except (tk.TclError, ValueError):
            param = 0
        self.editor.set_mission(slot, type_id, param)

    def _on_mission_param(self, slot: int) -> None:
        if self._suspend:
            return
        var_type, var_param, _combo, _spin, _unit, _clear = self._mission_rows[slot]
        type_id = chal.from_combo(var_type.get())
        if not chal.is_valid(type_id) or not chal.has_param(type_id):
            return
        try:
            param = int(var_param.get())
        except (tk.TclError, ValueError):
            return
        self.editor.set_mission_param(slot, param)

    def _refresh_missions(self) -> None:
        items = list(self.editor.level.missions)
        for slot, widgets in enumerate(self._mission_rows):
            var_type, var_param, _combo, spin, unit, _clear = widgets
            if slot < len(items):
                type_id, param = items[slot]
                var_type.set(chal.to_combo(type_id))
                var_param.set(int(param))
                unit.configure(text=chal.unit(type_id))
                low, high = chal.param_bounds(type_id)
                spin.configure(from_=low, to=high,
                               state="normal" if chal.has_param(type_id) else "disabled")
            else:
                var_type.set("")
                var_param.set(0)
                unit.configure(text="")
                spin.configure(state="disabled")

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
        self._refresh_missions()
        self._refresh_path_sum()
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
            "Lưới %dx%d · %d/%d ô thuộc board · %d tường hiện · %d tường ẩn\n" % (
                level.width, level.height, stats["board_cells"], stats["cells"],
                stats["visible_walls"], stats["hidden_walls"]),
            "info",
        )
        self.report.insert("end", "Thư mục level:\n%s\n" % self.app.levels_dir(), "info")
        self.report.configure(state="disabled")
