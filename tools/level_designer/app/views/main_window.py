"""View: cửa sổ chính - menu, thanh công cụ, 3 panel, thanh trạng thái, phím tắt."""

from __future__ import annotations

import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, simpledialog, ttk

from ..config import APP_NAME, APP_VERSION, MAX_CHAPTER_ID, TOOL_LABELS
from ..controllers.app_controller import AppController
from ..controllers.editor_controller import EditorController
from ..controllers.events import (
    EV_DIRTY_CHANGED,
    EV_LEVEL_CHANGED,
    EV_STATUS,
    EV_TOOL_CHANGED,
    EV_VIEW_OPTIONS_CHANGED,
)
from .chapter_dialog import open_chapter_dialog
from .grid_view import GridView
from .inspector_view import InspectorView
from .level_list_view import LevelListView
from .theme import apply_theme

SHORTCUTS = """Phím tắt
───────────────────────────────
1 / 2 / 3     Tường hiện · Tường ẩn · Xoá
4 / 5         Đặt điểm xuất phát S · Đích F
Chuột trái    Vẽ (kéo để vẽ liên tục)
Chuột phải    Xoá tường
Delete        Xoá tường đang trỏ tới
Ctrl + Z / Y  Hoàn tác / Làm lại
Ctrl + S      Lưu      ·  Ctrl + Shift + S: Lưu thành level khác
Ctrl + N      Màn mới
G / P / H     Bật-tắt số tường · đường đi · tường ẩn
+ / - / Ctrl+0  Phóng to · Thu nhỏ · Zoom mặc định
Ctrl + lăn chuột: zoom
───────────────────────────────
Ghi chú: y = 0 là hàng TRÊN cùng, viền ngoài luôn là tường cứng.
"""


class MainWindow(tk.Tk):
    """Cửa sổ ứng dụng Level Designer."""

    def __init__(self, app: AppController | None = None, open_level_id: int | None = None) -> None:
        super().__init__()
        self.app = app or AppController()
        self.editor: EditorController = self.app.editor

        self.title("%s %s" % (APP_NAME, APP_VERSION))
        self.geometry("1440x900")
        self.minsize(1080, 680)
        apply_theme(self)

        self._tool_buttons: dict[str, ttk.Button] = {}
        self._view_vars = {
            "show_numbers": tk.BooleanVar(value=self.editor.show_numbers),
            "show_path": tk.BooleanVar(value=self.editor.show_path),
            "show_hidden": tk.BooleanVar(value=self.editor.show_hidden),
        }

        self._build_menu()
        self._build_toolbar()
        self._build_body()
        self._build_status()
        self._bind_events()
        self._bind_keys()

        self.protocol("WM_DELETE_WINDOW", self._on_close)
        self._initial_load(open_level_id)

    # ------------------------------------------------------------------
    # Menu
    # ------------------------------------------------------------------
    def _build_menu(self) -> None:
        menubar = tk.Menu(self)

        file_menu = tk.Menu(menubar, tearoff=False)
        file_menu.add_command(label="Màn mới", accelerator="Ctrl+N", command=self.action_new)
        file_menu.add_command(label="Lưu", accelerator="Ctrl+S", command=self.action_save)
        file_menu.add_command(label="Lưu thành level khác…", accelerator="Ctrl+Shift+S", command=self.action_save_as)
        file_menu.add_command(label="Nạp lại từ đĩa", command=self.action_reload)
        file_menu.add_separator()
        file_menu.add_command(label="Xuất .tres ra file khác…", command=self.action_export_tres)
        file_menu.add_command(label="Xuất JSON (debug)…", command=self.action_export_json)
        file_menu.add_separator()
        file_menu.add_command(label="Mở thư mục levels", command=self.action_open_folder)
        file_menu.add_separator()
        file_menu.add_command(label="Thoát", command=self._on_close)
        menubar.add_cascade(label="File", menu=file_menu)

        edit_menu = tk.Menu(menubar, tearoff=False)
        edit_menu.add_command(label="Hoàn tác", accelerator="Ctrl+Z", command=self.editor.undo)
        edit_menu.add_command(label="Làm lại", accelerator="Ctrl+Y", command=self.editor.redo)
        edit_menu.add_separator()
        edit_menu.add_command(label="Xoá tường đang trỏ", accelerator="Delete", command=self.action_erase_hover)
        edit_menu.add_command(label="Xoá hết tường bên trong", command=self.editor.clear_walls)
        edit_menu.add_command(label="Sinh tường ẩn ngẫu nhiên", command=lambda: self.editor.fill_hidden_random(0.35))
        edit_menu.add_command(label="Tính max_steps theo đường đi", command=self.editor.auto_steps)
        menubar.add_cascade(label="Sửa", menu=edit_menu)

        view_menu = tk.Menu(menubar, tearoff=False)
        view_menu.add_checkbutton(label="Hiện số tường trên ô", accelerator="G",
                                  variable=self._view_vars["show_numbers"],
                                  command=lambda: self._toggle_view("show_numbers"))
        view_menu.add_checkbutton(label="Hiện đường đi ngắn nhất", accelerator="P",
                                  variable=self._view_vars["show_path"],
                                  command=lambda: self._toggle_view("show_path"))
        view_menu.add_checkbutton(label="Hiện tường ẩn", accelerator="H",
                                  variable=self._view_vars["show_hidden"],
                                  command=lambda: self._toggle_view("show_hidden"))
        view_menu.add_separator()
        view_menu.add_command(label="Phóng to", accelerator="+", command=lambda: self.grid.zoom(16))
        view_menu.add_command(label="Thu nhỏ", accelerator="-", command=lambda: self.grid.zoom(-16))
        view_menu.add_command(label="Zoom mặc định", accelerator="Ctrl+0", command=self.action_reset_zoom)
        menubar.add_cascade(label="Xem", menu=view_menu)

        chapter_menu = tk.Menu(menubar, tearoff=False)
        chapter_menu.add_command(label="Quản lý chương…", accelerator="Ctrl+Shift+C",
                                 command=self.action_manage_chapters)
        chapter_menu.add_command(label="Tạo chương theo dữ liệu màn",
                                 command=self.action_ensure_chapters)
        chapter_menu.add_separator()
        chapter_menu.add_command(label="Gán màn đang mở vào chương…",
                                 command=self.action_assign_level_chapter)
        chapter_menu.add_separator()
        chapter_menu.add_command(label="Mở thư mục chapters", command=self.action_open_chapters_folder)
        menubar.add_cascade(label="Chương", menu=chapter_menu)

        help_menu = tk.Menu(menubar, tearoff=False)
        help_menu.add_command(label="Phím tắt", command=lambda: messagebox.showinfo("Phím tắt", SHORTCUTS))
        help_menu.add_command(label="Giới thiệu", command=self.action_about)
        menubar.add_cascade(label="Trợ giúp", menu=help_menu)
        self.configure(menu=menubar)

    # ------------------------------------------------------------------
    # Thanh công cụ
    # ------------------------------------------------------------------
    def _build_toolbar(self) -> None:
        bar = ttk.Frame(self, padding=(8, 6))
        bar.pack(fill="x")

        ttk.Label(bar, text="Công cụ:", style="Section.TLabel").pack(side="left", padx=(0, 6))
        for tool, label in TOOL_LABELS:
            button = ttk.Button(bar, text=label, style="Tool.TButton",
                                command=lambda t=tool: self.editor.set_tool(t))
            button.pack(side="left", padx=2)
            self._tool_buttons[tool] = button

        ttk.Separator(bar, orient="vertical").pack(side="left", fill="y", padx=10)

        for name, text in (("show_numbers", "Số tường"), ("show_path", "Đường đi"), ("show_hidden", "Tường ẩn")):
            ttk.Checkbutton(bar, text=text, variable=self._view_vars[name],
                            command=lambda n=name: self._toggle_view(n)).pack(side="left", padx=2)

        ttk.Separator(bar, orient="vertical").pack(side="left", fill="y", padx=10)
        ttk.Button(bar, text="−", width=3, command=lambda: self.grid.zoom(-16)).pack(side="left")
        ttk.Button(bar, text="+", width=3, command=lambda: self.grid.zoom(16)).pack(side="left", padx=2)

        ttk.Button(bar, text="Lưu (Ctrl+S)", style="Accent.TButton", command=self.action_save).pack(side="right")
        ttk.Button(bar, text="Chương…", command=self.action_manage_chapters).pack(
            side="right", padx=(0, 4))

    # ------------------------------------------------------------------
    # Thân cửa sổ: 3 panel
    # ------------------------------------------------------------------
    def _build_body(self) -> None:
        panes = ttk.PanedWindow(self, orient="horizontal")
        panes.pack(fill="both", expand=True, padx=8)

        left = ttk.Frame(panes, width=300)
        self.level_list = LevelListView(
            left, self.app,
            on_open=self.action_open_level,
            on_new=self.action_new,
            on_duplicate=self.action_duplicate,
            on_delete=self.action_delete,
            on_refresh=self.app.refresh_levels,
        )
        self.level_list.pack(fill="both", expand=True)

        center = ttk.Frame(panes)
        self.grid = GridView(center, self.editor)
        self.grid.pack(fill="both", expand=True)
        caption = ttk.Label(center, style="Hint.TLabel",
                            text="Chuột trái: vẽ · Chuột phải: xoá · Ctrl+lăn chuột: zoom · "
                                 "công cụ 6: bật/tắt ô board · y=0 là hàng trên cùng")
        caption.pack(anchor="w", padx=10, pady=(2, 6))

        right = ttk.Frame(panes, width=360)
        self.inspector = InspectorView(right, self.app)
        self.inspector.pack(fill="both", expand=True)

        panes.add(left, weight=0)
        panes.add(center, weight=1)
        panes.add(right, weight=0)

    def _build_status(self) -> None:
        bar = ttk.Frame(self, padding=(10, 4))
        bar.pack(fill="x", side="bottom")
        self.status_var = tk.StringVar(value="Sẵn sàng")
        self.info_var = tk.StringVar(value="")
        ttk.Label(bar, textvariable=self.status_var, style="Status.TLabel", anchor="w").pack(
            side="left", fill="x", expand=True)
        ttk.Label(bar, textvariable=self.info_var, style="Status.TLabel", anchor="e").pack(side="right")

    # ------------------------------------------------------------------
    # Sự kiện
    # ------------------------------------------------------------------
    def _bind_events(self) -> None:
        self.app.events.on(EV_STATUS, self._on_status)
        self.app.events.on(EV_DIRTY_CHANGED, lambda *_: self._refresh_header())
        self.app.events.on(EV_TOOL_CHANGED, lambda *_: self._refresh_tool_buttons())
        self.app.events.on(EV_LEVEL_CHANGED, lambda *_: self._on_level_changed())
        self.app.events.on(EV_VIEW_OPTIONS_CHANGED, lambda *_: self._sync_view_vars())
        self._refresh_tool_buttons()
        self._refresh_header()

    def _bind_keys(self) -> None:
        for tool, label in TOOL_LABELS:
            index = label[label.rfind("(") + 1: label.rfind(")")]
            self.bind("<Key-%s>" % index, lambda _e, t=tool: self._key_tool(t))
        self.bind("<Control-s>", lambda _e: self.action_save())
        self.bind("<Control-Shift-s>", lambda _e: self.action_save_as())
        self.bind("<Control-S>", lambda _e: self.action_save_as())
        self.bind("<Control-n>", lambda _e: self.action_new())
        self.bind("<Control-Shift-C>", lambda _e: self.action_manage_chapters())
        self.bind("<Control-Shift-c>", lambda _e: self.action_manage_chapters())
        self.bind("<Control-z>", lambda _e: self.editor.undo())
        self.bind("<Control-y>", lambda _e: self.editor.redo())
        self.bind("<Control-Key-0>", lambda _e: self.action_reset_zoom())
        self.bind("<Delete>", lambda _e: self.action_erase_hover())
        self.bind("<plus>", lambda _e: self.grid.zoom(16))
        self.bind("<equal>", lambda _e: self.grid.zoom(16))
        self.bind("<KP_Add>", lambda _e: self.grid.zoom(16))
        self.bind("<minus>", lambda _e: self.grid.zoom(-16))
        self.bind("<KP_Subtract>", lambda _e: self.grid.zoom(-16))
        self.bind("<Key-g>", lambda _e: self._key_toggle("show_numbers"))
        self.bind("<Key-p>", lambda _e: self._key_toggle("show_path"))
        self.bind("<Key-h>", lambda _e: self._key_toggle("show_hidden"))

    def _in_text_field(self) -> bool:
        widget = self.focus_get()
        return isinstance(widget, (tk.Entry, ttk.Entry, tk.Spinbox, ttk.Spinbox, tk.Text))

    def _key_tool(self, tool: str) -> None:
        if not self._in_text_field():
            self.editor.set_tool(tool)

    def _key_toggle(self, name: str) -> None:
        if not self._in_text_field():
            self._toggle_view(name)

    def _toggle_view(self, name: str) -> None:
        self.editor.set_view_option(name, bool(self._view_vars[name].get()))

    def _sync_view_vars(self) -> None:
        self._view_vars["show_numbers"].set(self.editor.show_numbers)
        self._view_vars["show_path"].set(self.editor.show_path)
        self._view_vars["show_hidden"].set(self.editor.show_hidden)

    def _on_status(self, message: str) -> None:
        self.status_var.set(message)

    def _on_level_changed(self) -> None:
        self.grid.canvas.xview_moveto(0)
        self.grid.canvas.yview_moveto(0)
        self._refresh_header()
        self._refresh_tool_buttons()

    def _refresh_tool_buttons(self) -> None:
        for tool, button in self._tool_buttons.items():
            style = "Selected.Tool.TButton" if tool == self.editor.tool else "Tool.TButton"
            button.configure(style=style)
        self._refresh_header()

    def _refresh_header(self) -> None:
        level = self.editor.level
        path = level.source_path or self.app.repository.default_path(level.level_id)
        mark = " •" if self.editor.dirty else ""
        self.title("%s %s — %s%s" % (APP_NAME, APP_VERSION, Path(path).name, mark))
        tool_name = dict(TOOL_LABELS).get(self.editor.tool, self.editor.tool)
        self.info_var.set("Level #%d · %dx%d · %s%s" % (
            level.level_id, level.width, level.height, tool_name, " · chưa lưu" if self.editor.dirty else ""))

    # ------------------------------------------------------------------
    # Hành động
    # ------------------------------------------------------------------
    def _initial_load(self, open_level_id: int | None) -> None:
        self.app.refresh_levels()
        summaries = self.app.level_summaries()
        if open_level_id is not None:
            self.app.load_level(open_level_id)
        elif summaries:
            self.app.load_level(summaries[0].level_id)
        else:
            self.app.create_level(width=5, height=5)
        self.grid.redraw()
        self.inspector.refresh()

    def _confirm_discard(self) -> bool:
        if not self.editor.dirty:
            return True
        answer = messagebox.askyesnocancel(
            "Chưa lưu thay đổi",
            "Màn #%d đang có thay đổi chưa lưu. Lưu lại trước khi tiếp tục?" % self.editor.level.level_id,
        )
        if answer is None:
            return False
        if answer:
            return self.app.save_current()
        return True

    def action_open_level(self, level_id: int) -> None:
        if level_id == self.editor.level.level_id and not self.editor.dirty:
            return
        if not self._confirm_discard():
            return
        self.app.load_level(level_id)

    def action_new(self) -> None:
        if not self._confirm_discard():
            return
        level_id = simpledialog.askinteger(
            "Màn mới", "level_id (1-%d):" % 999,
            initialvalue=self.app.repository.next_free_id(), minvalue=1, maxvalue=999, parent=self)
        if level_id is None:
            return
        self.app.create_level(level_id, width=5, height=5)
        self.inspector.refresh()

    def action_duplicate(self) -> None:
        if not self._confirm_discard():
            return
        self.app.duplicate_current()
        self.inspector.refresh()

    def action_delete(self, level_id: int) -> None:
        if level_id == self.editor.level.level_id:
            messagebox.showwarning("Không xoá được", "Đây là màn đang mở. Hãy mở màn khác rồi xoá.")
            return
        if not messagebox.askyesno("Xoá màn", "Xoá vĩnh viễn level_%d.tres?" % level_id):
            return
        self.app.delete_level(level_id)

    def action_save(self, *_args) -> None:
        self.app.save_current()

    def action_save_as(self) -> None:
        level_id = simpledialog.askinteger(
            "Lưu thành màn khác", "level_id mới:", initialvalue=self.app.repository.next_free_id(),
            minvalue=1, maxvalue=999, parent=self)
        if level_id is None:
            return
        self.app.save_as(level_id)

    def action_reload(self) -> None:
        if not self._confirm_discard():
            return
        self.app.reload_current()
        self.inspector.refresh()

    def action_export_tres(self) -> None:
        path = filedialog.asksaveasfilename(
            parent=self, title="Xuất .tres", defaultextension=".tres",
            initialdir=str(self.app.levels_dir()),
            initialfile="level_%d.tres" % self.editor.level.level_id,
            filetypes=[("Godot resource", "*.tres")])
        if not path:
            return
        try:
            self.app.repository.save(self.editor.level, Path(path))
        except Exception as error:  # noqa: BLE001
            messagebox.showerror("Lỗi", "Không ghi được file:\n%s" % error)
            return
        self.app.events.emit(EV_STATUS, "Đã xuất %s" % Path(path).name)

    def action_export_json(self) -> None:
        path = filedialog.asksaveasfilename(
            parent=self, title="Xuất JSON", defaultextension=".json",
            initialfile="level_%d.json" % self.editor.level.level_id,
            filetypes=[("JSON", "*.json")])
        if path:
            self.app.export_json(Path(path))

    def action_open_folder(self) -> None:
        self.app.open_levels_dir()
        path = str(self.app.levels_dir())
        try:
            import os
            os.startfile(path)  # type: ignore[attr-defined]  # Windows
        except Exception:  # noqa: BLE001 - macOS/Linux hoặc lỗi quyền
            messagebox.showinfo("Thư mục level", path)

    # ------------------------------------------------------------------
    # Chương (màn CHỌN CHƯƠNG của game)
    # ------------------------------------------------------------------
    def action_manage_chapters(self) -> None:
        if getattr(self, "_chapter_dialog", None) is not None \
                and self._chapter_dialog.winfo_exists():
            self._chapter_dialog.lift()
            self._chapter_dialog.focus_set()
            return
        self._chapter_dialog = open_chapter_dialog(self, self.app)

    def action_ensure_chapters(self) -> None:
        """Tự tạo chapter_<n>.tres cho mọi chương đang có màn."""
        created = self.app.ensure_chapters_for_levels()
        if created == 0:
            messagebox.showinfo("Chương", "Mọi chương có màn đều đã có file .tres.")
        else:
            messagebox.showinfo("Chương", "Đã tạo %d chương trong:\n%s" % (
                created, self.app.chapters_dir()))

    def action_assign_level_chapter(self) -> None:
        """Gán màn đang mở trong editor vào 1 chương (nhập số chương)."""
        level_id = int(self.editor.level.level_id)
        current = int(self.editor.level.chapter)
        answer = simpledialog.askinteger(
            "Gán màn vào chương",
            "Màn #%d đang thuộc chương %d.\nNhập chương muốn gán vào:" % (level_id, current),
            initialvalue=current, minvalue=1, maxvalue=MAX_CHAPTER_ID, parent=self)
        if answer is None:
            return
        if self.app.assign_current_level_to_chapter(int(answer)):
            self._refresh_header()

    def action_open_chapters_folder(self) -> None:
        path = str(self.app.chapters_dir())
        try:
            import os
            os.startfile(path)  # type: ignore[attr-defined]  # Windows
        except Exception:  # noqa: BLE001
            messagebox.showinfo("Thư mục chương", path)

    def action_erase_hover(self) -> None:
        ref = self.grid.hover_ref
        if ref is None:
            return
        self.editor.run_with_undo(lambda: self.editor.erase_wall(ref), "Đã xoá tường")

    def action_reset_zoom(self) -> None:
        self.grid.reset_zoom()

    def action_about(self) -> None:
        messagebox.showinfo(
            "Giới thiệu",
            "%s %s\n\nTạo/sửa màn chơi cho game InkMaze (Number Maze).\n"
            "File lưu vào:\n%s\n\nDự án: %s" % (
                APP_NAME, APP_VERSION, self.app.levels_dir(), self.app.project_root()),
        )

    # ------------------------------------------------------------------
    # Đóng
    # ------------------------------------------------------------------
    def _on_close(self) -> None:
        if self._confirm_discard():
            self.destroy()
