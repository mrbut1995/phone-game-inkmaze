"""View: cửa sổ chính - menu, thanh công cụ, 3 panel, thanh trạng thái, phím tắt."""

from __future__ import annotations

import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, simpledialog, ttk

from ..config import (
    APP_NAME,
    APP_VERSION,
    MAX_CHAPTER_ID,
    MODE_LABELS,
    TOOL_LABELS,
    TOOL_PATH,
    TOOL_PATH_KEY,
    TOOL_VALUE,
    TOOL_VALUE_KEY,
)
from ..controllers.app_controller import AppController
from ..controllers.editor_controller import EditorController
from ..controllers.events import (
    EV_DIRTY_CHANGED,
    EV_EDIT_VALUE_CHANGED,
    EV_LEVEL_CHANGED,
    EV_MODEL_UPDATED,
    EV_PATH_CHANGED,
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
6             Bật/tắt ô board (polyomino)
7             Tô dữ liệu riêng của CHẾ ĐỘ đang chọn
              (Ghim mìn · Điểm ô · Chi phí ô — xem menu Sửa)
8             VẼ ĐƯỜNG ĐI: kéo chuột vẽ đường S → F
Ctrl + Enter  ÁP DỤNG cho đường vừa vẽ — tuỳ chế độ:
              · chế độ thường   → sinh TƯỜNG quanh đường (đường đó
                                  trở thành ĐƯỜNG DUY NHẤT của màn)
              · Countdown Cost  → tô CHI PHÍ ô sao cho tổng = ô “Tổng chi phí”
              · Sum Path        → tô ĐIỂM ô sao cho tổng = ô “Tổng điểm”
              · Fading Ink      → cấp MỰC tăng dần theo bước (+ “Mực dư”)
Esc           Xoá nét đường đang vẽ
Chuột trái    Vẽ (kéo để vẽ liên tục)
Chuột phải    Xoá (ưu tiên xoá giá trị riêng của ô · ở công cụ 8 = xoá nét vẽ)
Delete        Xoá tường đang trỏ tới
Ctrl + Z / Y  Hoàn tác / Làm lại
Ctrl + S      Lưu      ·  Ctrl + Shift + S: Lưu thành level khác
Ctrl + N      Màn mới
G / P / H     Bật-tắt số tường · đường đi · tường ẩn
+ / - / Ctrl+0  Phóng to · Thu nhỏ · Zoom mặc định
Ctrl + lăn chuột: zoom
───────────────────────────────
CÁCH NHANH ĐỂ CÓ MÀN CÓ ĐƯỜNG ĐI:
  1. Công cụ 6 — bật các ô board muốn chơi (hoặc để nguyên hình chữ nhật)
  2. Công cụ 8 — kéo chuột từ ô Xuất phát tới ô Đích
  3. Ctrl + Enter — sinh tường quanh đường (hoặc TÔ GIÁ TRỊ nếu chế độ
     có dữ liệu ô: Countdown Cost · Sum Path · Fading Ink)
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
        self._mode_edit_key: tuple | None = None
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
        edit_menu.add_command(label="Xoá hết giá trị riêng của chế độ", command=self.action_clear_custom_values)
        edit_menu.add_separator()
        edit_menu.add_command(label="Áp dụng cho đường đi vừa vẽ (sinh tường / tô giá trị)",
                              accelerator="Ctrl+Enter", command=self.action_apply_path)
        edit_menu.add_command(label="Xoá nét đường đang vẽ", accelerator="Esc",
                              command=self.action_clear_path_draft)
        edit_menu.add_separator()
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
        # THANH CÔNG CỤ 2 DÒNG (trước đây 1 dòng nên cửa sổ hẹp là tràn/clip nút):
        #   dòng 1 = công cụ vẽ + khối GIÁ TRỊ của chế độ
        #   dòng 2 = tuỳ chọn xem · zoom · khối ĐƯỜNG ĐI (hiện khi có nét vẽ) · Lưu/Chương
        wrap = ttk.Frame(self, padding=(8, 6))
        wrap.pack(fill="x")
        bar = ttk.Frame(wrap)
        bar.pack(fill="x")
        bar2 = ttk.Frame(wrap)
        bar2.pack(fill="x", pady=(6, 0))
        ## 2 dòng của thanh công cụ (test GUI đo tràn ngang dựa vào đây)
        self._toolbar_rows = (bar, bar2)

        ttk.Label(bar, text="Công cụ:", style="Section.TLabel").pack(side="left", padx=(0, 6))
        for tool, label in TOOL_LABELS:
            button = ttk.Button(bar, text=label, style="Tool.TButton",
                                command=lambda t=tool: self.editor.set_tool(t))
            button.pack(side="left", padx=2)
            self._tool_buttons[tool] = button

        ttk.Separator(bar, orient="vertical").pack(side="left", fill="y", padx=10)

        # KHỐI "GIÁ TRỊ" (dòng 2): công cụ tô dữ liệu RIÊNG của chế độ đang chọn — chỉ hiện khi chế
        # độ có kiểu edit "cell_value" VÀ đang KHÔNG có nét vẽ (nhường chỗ cho khối ĐƯỜNG ĐI).
        self._zoom_box = ttk.Frame(bar2)
        self._value_box = ttk.Frame(bar2)
        self._value_var = tk.StringVar(value="1")
        self._value_button = ttk.Button(self._value_box, text="Giá trị (%s)" % TOOL_VALUE_KEY,
                                        style="Tool.TButton",
                                        command=lambda: self.editor.set_tool(TOOL_VALUE))
        self._value_button.pack(side="left", padx=2)
        self._tool_buttons[TOOL_VALUE] = self._value_button
        self._value_unit = ttk.Label(self._value_box, text="")
        self._value_unit.pack(side="left", padx=(2, 0))
        self._value_spin = ttk.Spinbox(self._value_box, from_=1, to=9, width=4,
                                       textvariable=self._value_var, command=self._on_value_change)
        self._value_spin.pack(side="left", padx=2)
        self._value_spin.bind("<Return>", lambda _e: self._on_value_change())
        self._value_spin.bind("<FocusOut>", lambda _e: self._on_value_change())
        ttk.Button(self._value_box, text="Xoá giá trị", command=self.editor.clear_custom_values) \
            .pack(side="left", padx=(4, 2))

        # KHỐI "ĐƯỜNG ĐI": chỉ hiện khi đang có NÉT VẼ của công cụ 8. Nhãn nút đổi theo chế độ:
        #   · chế độ thường → "Sinh tường quanh đường" (nét vẽ thành ĐƯỜNG DUY NHẤT)
        #   · chế độ có giá trị ô (Countdown Cost · Sum Path · Fading Ink) → "Sinh giá trị trên đường"
        # Ô "Tổng …" (tổng chi phí / tổng điểm / mực dư) nằm ở BẢNG PHẢI, mục "Lưới & luật chơi".
        self._path_box = ttk.Frame(bar2)
        self._path_apply_button = ttk.Button(self._path_box, text="Sinh tường (Ctrl+Enter)",
                                             style="Accent.TButton", command=self.action_apply_path)
        self._path_apply_button.pack(side="left", padx=2)
        ttk.Button(self._path_box, text="Xoá nét (Esc)",
                   command=self.action_clear_path_draft).pack(side="left", padx=2)
        self._path_hint = ttk.Label(self._path_box, text="", style="Hint.TLabel")
        self._path_hint.pack(side="left", padx=(6, 0))

        self._view_label = ttk.Label(bar2, text="Hiện:", style="Section.TLabel")
        self._view_label.pack(side="left", padx=(0, 4))
        for name, text in (("show_numbers", "Số tường"), ("show_path", "Đường đi"),
                           ("show_hidden", "Tường ẩn")):
            ttk.Checkbutton(bar2, text=text, variable=self._view_vars[name],
                            command=lambda n=name: self._toggle_view(n)).pack(side="left", padx=2)

        ttk.Separator(bar2, orient="vertical").pack(side="left", fill="y", padx=10)
        self._zoom_box.pack(side="left")
        ttk.Button(self._zoom_box, text="−", width=3, command=lambda: self.grid.zoom(-16)).pack(side="left")
        ttk.Button(self._zoom_box, text="+", width=3, command=lambda: self.grid.zoom(16)).pack(side="left", padx=2)

        ttk.Button(bar2, text="Lưu (Ctrl+S)", style="Accent.TButton", command=self.action_save).pack(side="right")
        ttk.Button(bar2, text="Chương…", command=self.action_manage_chapters).pack(
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
        self._caption = ttk.Label(center, style="Hint.TLabel", text="")
        self._caption.pack(anchor="w", padx=10, pady=(2, 6))

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
        # Chế độ đổi (inspector) hoặc giá trị đang cầm đổi → bày/ẩn lại công cụ giá trị
        self.app.events.on(EV_MODEL_UPDATED, lambda *_: self._refresh_mode_edit())
        self.app.events.on(EV_EDIT_VALUE_CHANGED, lambda *_: self._refresh_mode_edit())
        # Nét đường đi (công cụ 8) vừa đổi → bày/ẩn khối "Đường đi" trên thanh công cụ
        self.app.events.on(EV_PATH_CHANGED, lambda *_: self._refresh_path_box())
        self._refresh_tool_buttons()
        self._refresh_mode_edit()
        self._refresh_path_box()
        self._refresh_header()

    def _bind_keys(self) -> None:
        for tool, label in TOOL_LABELS:
            index = label[label.rfind("(") + 1: label.rfind(")")]
            self.bind("<Key-%s>" % index, lambda _e, t=tool: self._key_tool(t))
        self.bind("<Key-%s>" % TOOL_VALUE_KEY, lambda _e: self._key_value_tool())
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
        self.bind("<Control-Return>", lambda _e: self.action_apply_path())
        self.bind("<Control-KP_Enter>", lambda _e: self.action_apply_path())
        self.bind("<Escape>", lambda _e: self.action_clear_path_draft())
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

    def _key_value_tool(self) -> None:
        """Phím 7: chọn công cụ tô dữ liệu riêng của chế độ (chỉ khi chế độ CÓ kiểu edit đó)."""
        if self._in_text_field():
            return
        if not self.editor.mode_edit_spec()["is_cell_value"]:
            self.status_var.set("Chế độ đang chọn không có dữ liệu riêng để tô "
                                "(xem ô mode_id ở bảng phải)")
            return
        self.editor.set_tool(TOOL_VALUE)

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
        self._refresh_mode_edit()
        self._refresh_path_box()

    def _refresh_mode_edit(self) -> None:
        """Bày/ẩn công cụ GIÁ TRỊ theo `kiểu edit` của chế độ đang chọn.

        (Ô "Tổng …" + nút *Tô theo đường đi* của các chế độ có `path` nằm ở BẢNG PHẢI,
        mục "Lưới & luật chơi" — xem `InspectorView`.)
        """
        spec = self.editor.mode_edit_spec()
        key = (spec["mode_id"], spec["kind"], spec["min"], spec["max"], spec["tool"],
               spec["path_action"], spec["path_fill"], spec["sum_label"])
        if key == self._mode_edit_key:
            return
        self._mode_edit_key = key
        if spec["is_cell_value"]:
            self._value_button.configure(text="%s (%s)" % (spec["tool"], TOOL_VALUE_KEY))
            self._value_spin.configure(from_=spec["min"], to=spec["max"])
            self._value_unit.configure(text=str(spec["unit"]))
            self._value_var.set(str(self.editor.edit_value))

        # Nhãn nút Ctrl+Enter đổi theo chế độ (sinh TƯỜNG hay TÔ GIÁ TRỊ)
        self._path_apply_button.configure(
            text="Sinh giá trị (Ctrl+Enter)" if spec["paints_values"]
            else "Sinh tường (Ctrl+Enter)")
        self._sync_toolbar_boxes()
        self._update_caption()
        self._refresh_header()

    def _sync_toolbar_boxes(self) -> None:
        """Bày/ẩn 2 khối động trên thanh công cụ — KHÔNG bao giờ cùng lúc (tránh tràn ngang):

        · đang có NÉT VẼ → hiện khối **ĐƯỜNG ĐI** (Ctrl+Enter + xoá nét)
        · còn lại        → hiện khối **GIÁ TRỊ** nếu chế độ có dữ liệu ô (công cụ 7)
        """
        spec = self.editor.mode_edit_spec()
        has_path = self.editor.path_length() > 0
        show_value = bool(spec["is_cell_value"]) and not has_path
        if show_value and not self._value_box.winfo_manager():
            self._value_box.pack(side="left", padx=(0, 8), before=self._view_label)
        elif not show_value and self._value_box.winfo_manager():
            self._value_box.pack_forget()
        if has_path and not self._path_box.winfo_manager():
            self._path_box.pack(side="left", before=self._zoom_box)
        elif not has_path and self._path_box.winfo_manager():
            self._path_box.pack_forget()

    def _on_value_change(self) -> None:
        """Ô nhập giá trị đang cầm để tô (kẹp theo khoảng của chế độ)."""
        try:
            value = int(self._value_var.get())
        except (tk.TclError, ValueError):
            self._value_var.set(str(self.editor.edit_value))
            return
        self.editor.set_edit_value(value)
        self._value_var.set(str(self.editor.edit_value))

    def _refresh_path_box(self) -> None:
        """Cập nhật khối "ĐƯỜNG ĐI" (chỉ hiện khi có NÉT VẼ của công cụ 8 — xem `_sync_toolbar_boxes`).

        Nhãn chỉ hiện SỐ Ô cho gọn (thanh công cụ không tràn); hướng dẫn nằm ở dòng trạng thái.
        """
        count = self.editor.path_length()
        if count:
            self._path_hint.configure(text="%d ô" % count)
        self._sync_toolbar_boxes()
        self._update_caption()

    def action_apply_path(self) -> None:
        """Menu Sửa / Ctrl+Enter — ÁP DỤNG cho đường đi vừa vẽ, tuỳ chế độ đang chọn:

        · Chế độ có giá trị ô (Countdown Cost · Sum Path · Fading Ink) → **TÔ GIÁ TRỊ** lên đường
          sao cho tổng đúng bằng ô "Tổng …" (hoặc mực tăng dần theo bước với Fading Ink).
        · Chế độ còn lại → **SINH TƯỜNG** quanh đường (đường đã vẽ thành ĐƯỜNG DUY NHẤT).
        Không có nét vẽ thì tô theo **đường NGẮN NHẤT** của màn.
        """
        spec = self.editor.mode_edit_spec()
        if spec["paints_values"]:
            self.editor.apply_path_values(self.inspector.path_sum_value())
            self.inspector.refresh()
        else:
            self.editor.apply_path_walls()
        self._refresh_path_box()

    def action_clear_path_draft(self) -> None:
        """Esc / chuột phải ở công cụ 8: bỏ nét đường đang vẽ (không đụng tới màn chơi)."""
        if self.editor.path_length() == 0:
            return
        self.editor.clear_path_draft()
        self._refresh_path_box()

    def _update_caption(self) -> None:
        spec = self.editor.mode_edit_spec()
        text = ("Chuột trái: vẽ · Chuột phải: xoá · Ctrl+lăn chuột: zoom · công cụ 6: bật/tắt ô board · "
                "y=0 là hàng trên cùng")
        if spec["is_cell_value"]:
            text += " · công cụ %s: tô %s cho từng ô (chuột phải để xoá giá trị ô)" % (
                TOOL_VALUE_KEY, spec["tool"].lower())
        if self.editor.tool == TOOL_PATH:
            if spec["paints_values"]:
                text += " · CÔNG CỤ %s: kéo chuột vẽ đường rồi Ctrl+Enter để TÔ %s theo đường" \
                        " (Esc = xoá nét) — không vẽ gì thì tô theo đường ngắn nhất" \
                        % (TOOL_PATH_KEY, spec["tool"].lower())
            else:
                text += " · CÔNG CỤ %s: kéo chuột vẽ đường S→F rồi Ctrl+Enter để sinh tường quanh đường" \
                        " (Esc = xoá nét)" % TOOL_PATH_KEY
        if spec["has_sum_field"]:
            text += " · ô \"%s\" ở BẢNG PHẢI (Lưới & luật chơi) — bấm Tô theo đường đi để chia theo tổng" \
                    % spec["sum_label"]
        self._caption.configure(text=text)

    def action_clear_custom_values(self) -> None:
        """Menu Sửa: xoá hết dữ liệu riêng của chế độ trong màn đang mở."""
        self.editor.clear_custom_values()

    def _tool_label(self, tool: str) -> str:
        if tool == TOOL_VALUE:
            spec = self.editor.mode_edit_spec()
            return "%s (%s)" % (spec["tool"], TOOL_VALUE_KEY) if spec["is_cell_value"] \
                else "Giá trị (%s)" % TOOL_VALUE_KEY
        return dict(TOOL_LABELS).get(tool, tool)

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
        tool_name = self._tool_label(self.editor.tool)
        self.info_var.set("Level #%d · %dx%d · %s · %s%s" % (
            level.level_id, level.width, level.height,
            MODE_LABELS.get(level.mode_id, level.mode_id), tool_name,
            " · chưa lưu" if self.editor.dirty else ""))

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
