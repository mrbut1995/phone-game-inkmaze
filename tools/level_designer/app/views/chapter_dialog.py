"""View: hộp thoại QUẢN LÝ CHƯƠNG (tạo/sửa/xoá chương + gán màn vào chương).

Cách dùng:
    - Cột trái: danh sách chapter_*.tres (số chương · tiêu đề · phí sao · số màn).
    - Cột phải: nội dung chương đang chọn (tiêu đề, mô tả, nhãn kích thước, phí sao)
      + ô "Màn của chương" để gán thêm màn (nhập "1, 2, 3" hoặc bấm "Gán màn đang mở").
"""

from __future__ import annotations

import tkinter as tk
from tkinter import messagebox, ttk

from ..config import CHAPTER_ICONS
from ..controllers.app_controller import AppController
from ..controllers.events import EV_LEVEL_CHANGED
from ..models.chapter import ChapterModel
from ..models.chapter_repository import ChapterSummary


class ChapterDialog(tk.Toplevel):
    """Cửa sổ quản lý chương (dạng modal, đóng bằng nút Đóng)."""

    def __init__(self, master: tk.Misc, app: AppController) -> None:
        super().__init__(master)
        self.app = app
        self.title("Quản lý chương — resources/chapters")
        self.geometry("980x620")
        self.minsize(860, 520)
        self.transient(master)
        self._summaries: list[ChapterSummary] = []
        self._current: ChapterModel | None = None

        self._build()
        self._reload()
        self.app.events.on(EV_LEVEL_CHANGED, self._on_level_changed)

    # ------------------------------------------------------------------
    # Dựng giao diện
    # ------------------------------------------------------------------
    def _build(self) -> None:
        outer = ttk.Frame(self, padding=10)
        outer.pack(fill="both", expand=True)

        ttk.Label(outer, text="CHƯƠNG của game", style="Section.TLabel").pack(anchor="w")
        body = ttk.Frame(outer)
        body.pack(fill="both", expand=True, pady=(6, 8))

        # --- Cột trái: danh sách chương ---
        left = ttk.Frame(body)
        left.pack(side="left", fill="both", expand=True, padx=(0, 10))

        columns = ("id", "title", "cost", "levels")
        self.tree = ttk.Treeview(left, columns=columns, show="headings", height=18)
        for key, text, width in (("id", "Chương", 70), ("title", "Tiêu đề", 230),
                                 ("cost", "Mở khoá", 110), ("levels", "Màn", 220)):
            self.tree.heading(key, text=text)
            self.tree.column(key, width=width, anchor="w")
        self.tree.pack(side="left", fill="both", expand=True)
        scroll = ttk.Scrollbar(left, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=scroll.set)
        scroll.pack(side="right", fill="y")
        self.tree.bind("<<TreeviewSelect>>", lambda _e: self._on_select())

        list_buttons = ttk.Frame(left)
        list_buttons.pack(fill="x", pady=(6, 0))
        ttk.Button(list_buttons, text="Chương mới", command=self._new_chapter).pack(
            fill="x", pady=2)
        ttk.Button(list_buttons, text="Tạo chương theo dữ liệu màn", command=self._ensure_chapters).pack(
            fill="x", pady=2)
        ttk.Button(list_buttons, text="Xoá file chương", command=self._delete_chapter).pack(
            fill="x", pady=2)

        # --- Cột phải: nội dung chương ---
        right = ttk.Frame(body, width=380)
        right.pack(side="left", fill="both")
        right.pack_propagate(False)

        form = ttk.LabelFrame(right, text="Nội dung chương", padding=8)
        form.pack(fill="x")
        form.columnconfigure(1, weight=1)

        self.var_id = tk.StringVar()
        self.var_title = tk.StringVar()
        self.var_subtitle = tk.StringVar()
        self.var_size = tk.StringVar()
        self.var_cost = tk.StringVar()

        rows = (
            ("Số chương", self.var_id, 6),
            ("Tiêu đề", self.var_title, 28),
            ("Mô tả", self.var_subtitle, 28),
            ("Nhãn kích thước", self.var_size, 20),
            ("Phí sao mở khoá", self.var_cost, 8),
        )
        for index, (label, var, width) in enumerate(rows):
            ttk.Label(form, text=label).grid(row=index, column=0, sticky="w", pady=3)
            ttk.Entry(form, textvariable=var, width=width).grid(
                row=index, column=1, sticky="ew", pady=3)

        # Icon riêng của chương (game tra assets/images/chapters/icon_<tên>.svg)
        self.var_icon = tk.StringVar()
        ttk.Label(form, text="Icon").grid(row=len(rows), column=0, sticky="w", pady=3)
        icon_box = ttk.Combobox(form, textvariable=self.var_icon, width=16,
                                values=(*CHAPTER_ICONS, ""))
        icon_box.grid(row=len(rows), column=1, sticky="ew", pady=3)

        ttk.Label(form, style="Hint.TLabel",
                  text="Nhãn kích thước để trống = thẻ chương ẩn chip (ví dụ: 3×3 – 5×5)\n"
                       "Icon: intro · logic · trap · master (để trống = game tự chọn theo số chương)").grid(
            row=len(rows) + 1, column=0, columnspan=2, sticky="w", pady=(4, 0))

        ttk.Button(form, text="Lưu chương", style="Accent.TButton",
                   command=self._save_chapter).grid(row=len(rows) + 2, column=0,
                                                    columnspan=2, sticky="ew", pady=(8, 2))
        ttk.Button(form, text="Gợi ý nhãn kích thước theo màn", command=self._suggest_size).grid(
            row=len(rows) + 3, column=0, columnspan=2, sticky="ew")

        levels_box = ttk.LabelFrame(right, text="Màn của chương", padding=8)
        levels_box.pack(fill="both", expand=True, pady=(10, 0))
        self.var_levels = tk.StringVar()
        ttk.Label(levels_box, textvariable=self.var_levels, style="Hint.TLabel",
                  wraplength=340, justify="left").pack(anchor="w")
        ttk.Label(levels_box, text="Nhập số màn (cách nhau dấu phẩy) rồi bấm Gán:").pack(
            anchor="w", pady=(8, 2))
        self.entry_levels = ttk.Entry(levels_box)
        self.entry_levels.pack(fill="x")
        ttk.Button(levels_box, text="Gán các màn này vào chương",
                   command=self._assign_typed).pack(fill="x", pady=(6, 2))
        ttk.Button(levels_box, text="Gán MÀN ĐANG MỞ vào chương",
                   command=self._assign_current).pack(fill="x", pady=2)
        self.lbl_current = ttk.Label(levels_box, style="Hint.TLabel", text="")
        self.lbl_current.pack(anchor="w", pady=(6, 0))

        footer = ttk.Frame(outer)
        footer.pack(fill="x")
        self.status = ttk.Label(footer, style="Hint.TLabel", text="")
        self.status.pack(side="left")
        ttk.Button(footer, text="Đóng", command=self.destroy).pack(side="right")

    # ------------------------------------------------------------------
    # Dữ liệu
    # ------------------------------------------------------------------
    def _reload(self, select_id: int | None = None) -> None:
        self._summaries = self.app.chapter_summaries()
        self.tree.delete(*self.tree.get_children())
        for summary in self._summaries:
            self.tree.insert("", "end", iid=str(summary.chapter_id), values=(
                summary.chapter_id,
                summary.title,
                "mở sẵn" if summary.star_cost <= 0 else "cần %d sao" % summary.star_cost,
                summary.levels_text(),
            ))
        self._refresh_current_label()
        target = select_id if select_id is not None else (
            self._summaries[0].chapter_id if self._summaries else None)
        if target is not None and self.tree.exists(str(target)):
            self.tree.selection_set(str(target))
            self.tree.see(str(target))
            self._on_select()
        else:
            self._current = None
            self._clear_form()
        self.status.configure(text="Có %d chương trong %s" % (
            len(self._summaries), self.app.chapters_dir()))

    def _on_select(self) -> None:
        selection = self.tree.selection()
        if not selection:
            return
        chapter_id = int(selection[0])
        try:
            chapter = self.app.chapters.load(chapter_id)
        except Exception as error:  # noqa: BLE001 - file hỏng
            messagebox.showerror("Lỗi đọc chương", str(error), parent=self)
            return
        self._current = chapter
        self.var_id.set(str(chapter.chapter_id))
        self.var_title.set(chapter.title)
        self.var_subtitle.set(chapter.subtitle)
        self.var_size.set(chapter.size_label)
        self.var_cost.set(str(chapter.star_cost))
        self.var_icon.set(chapter.display_icon())
        self._refresh_current_label()

    def _clear_form(self) -> None:
        for var in (self.var_id, self.var_title, self.var_subtitle, self.var_size, self.var_cost,
                    self.var_icon):
            var.set("")
        self.var_levels.set("")

    def _refresh_current_label(self) -> None:
        level_id = int(self.app.editor.level.level_id)
        chapter = max(1, int(self.app.editor.level.chapter))
        self.lbl_current.configure(text="Màn đang mở: #%d (hiện thuộc chương %d)" % (level_id, chapter))

    def _on_level_changed(self, *_args) -> None:
        self._refresh_current_label()

    # ------------------------------------------------------------------
    # Hành động
    # ------------------------------------------------------------------
    def _new_chapter(self) -> None:
        chapter = self.app.create_chapter()
        self._current = chapter
        self.var_id.set(str(chapter.chapter_id))
        self.var_title.set(chapter.title)
        self.var_subtitle.set(chapter.subtitle)
        self.var_size.set(chapter.size_label)
        self.var_cost.set(str(chapter.star_cost))
        self.var_icon.set(chapter.display_icon())
        self.status.configure(text="Chương %d chưa có file — bấm 'Lưu chương' để tạo." % chapter.chapter_id)

    def _save_chapter(self) -> None:
        chapter = self._read_form()
        if chapter is None:
            return
        if self.app.save_chapter(chapter):
            self._reload(select_id=chapter.chapter_id)

    def _delete_chapter(self) -> None:
        selection = self.tree.selection()
        if not selection:
            messagebox.showinfo("Chưa chọn", "Hãy chọn 1 chương trong danh sách.", parent=self)
            return
        chapter_id = int(selection[0])
        if not messagebox.askyesno(
                "Xoá chương",
                "Xoá file chapter_%d.tres?\n(Màn trong chương KHÔNG bị xoá.)" % chapter_id,
                parent=self):
            return
        self.app.delete_chapter(chapter_id)
        self._reload()

    def _ensure_chapters(self) -> None:
        self.app.ensure_chapters_for_levels()
        self._reload()

    def _suggest_size(self) -> None:
        chapter = self._read_form(quiet=True)
        if chapter is None:
            return
        label = self.app.chapters.size_label_for(chapter.chapter_id)
        if label:
            self.var_size.set(label)
            self.status.configure(text="Nhãn kích thước gợi ý: %s" % label)
        else:
            self.status.configure(text="Chương chưa có màn nào để suy kích thước.")

    def _assign_typed(self) -> None:
        chapter = self._current
        if chapter is None:
            messagebox.showinfo("Chưa chọn", "Hãy chọn chương trong danh sách.", parent=self)
            return
        ids = _parse_ids(self.entry_levels.get())
        if not ids:
            messagebox.showinfo("Thiếu dữ liệu",
                                "Nhập số màn cần gán, ví dụ: 1, 2, 3", parent=self)
            return
        count = self.app.assign_levels_to_chapter(chapter.chapter_id, ids)
        self.status.configure(text="Đã gán %d/%d màn vào chương %d" % (
            count, len(ids), chapter.chapter_id))
        self._reload(select_id=chapter.chapter_id)

    def _assign_current(self) -> None:
        chapter = self._current
        if chapter is None:
            messagebox.showinfo("Chưa chọn", "Hãy chọn chương trong danh sách.", parent=self)
            return
        if self.app.assign_current_level_to_chapter(chapter.chapter_id):
            self._reload(select_id=chapter.chapter_id)

    # ------------------------------------------------------------------
    # Form -> model
    # ------------------------------------------------------------------
    def _read_form(self, quiet: bool = False) -> ChapterModel | None:
        try:
            chapter_id = int(self.var_id.get())
        except ValueError:
            if not quiet:
                messagebox.showerror("Số chương không hợp lệ", "Số chương phải là số nguyên.", parent=self)
            return None
        try:
            cost = int(float(self.var_cost.get() or "0"))
        except ValueError:
            if not quiet:
                messagebox.showerror("Phí sao không hợp lệ", "Phí sao phải là số nguyên >= 0.", parent=self)
            return None
        chapter = ChapterModel(
            chapter_id=chapter_id,
            title=self.var_title.get(),
            subtitle=self.var_subtitle.get(),
            size_label=self.var_size.get(),
            star_cost=max(0, cost),
            icon=self.var_icon.get(),
        )
        chapter.normalized()
        if chapter.chapter_id != chapter_id:
            if not quiet:
                messagebox.showerror("Số chương ngoài khoảng",
                                     "Số chương phải trong khoảng 1..99.", parent=self)
            return None
        if not chapter.is_valid():
            if not quiet:
                messagebox.showerror("Thiếu tiêu đề", "Chương cần có tiêu đề.", parent=self)
            return None
        if self._current is not None:
            chapter.source_uid = self._current.source_uid
            chapter.source_path = self._current.source_path
        return chapter


def _parse_ids(text: str) -> list[int]:
    """Đổi '1, 2; 3' -> [1, 2, 3] (bỏ giá trị không phải số)."""
    ids: list[int] = []
    for chunk in str(text).replace(";", ",").split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        try:
            value = int(chunk)
        except ValueError:
            continue
        if value not in ids:
            ids.append(value)
    return ids


def open_chapter_dialog(master: tk.Misc, app: AppController) -> ChapterDialog:
    """Mở hộp thoại quản lý chương (tiện gọi từ menu)."""
    dialog = ChapterDialog(master, app)
    dialog.focus_set()
    return dialog
