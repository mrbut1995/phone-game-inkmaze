"""View: hằng số giao diện (font, màu) dùng chung cho các widget Tkinter."""

from __future__ import annotations

import tkinter as tk
from tkinter import font as tkfont
from tkinter import ttk

from ..config import (
    COLOR_CANVAS_BG,
    COLOR_END,
    COLOR_GRID,
    COLOR_INK,
    COLOR_INK_SOFT,
    COLOR_MARGIN,
    COLOR_PAPER,
    COLOR_PAPER_ALT,
    COLOR_PATH,
    COLOR_SELECT,
    COLOR_START,
    COLOR_WALL_HIDDEN,
    COLOR_WALL_VISIBLE,
)


def pick_font(root: tk.Misc, size: int = 10, weight: str = "normal") -> tkfont.Font:
    """Chọn font hỗ trợ tiếng Việt có sẵn trên Windows/macOS/Linux."""
    family = "Segoe UI"
    available = set(tkfont.families(root))
    for candidate in ("Segoe UI", "Arial", "Helvetica", "DejaVu Sans", "Noto Sans"):
        if candidate in available:
            family = candidate
            break
    return tkfont.Font(root=root, family=family, size=size, weight=weight)


def apply_theme(root: tk.Misc) -> ttk.Style:
    """Trang trí ttk theo tông sổ ô ly của game (giấy kem + mực xanh)."""
    style = ttk.Style(root)
    try:
        style.theme_use("clam")
    except tk.TclError:
        pass

    base = pick_font(root, 10)
    style.configure(".", font=base, background=COLOR_PAPER_ALT, foreground=COLOR_INK)
    style.configure("TFrame", background=COLOR_PAPER_ALT)
    style.configure("TLabel", background=COLOR_PAPER_ALT, foreground=COLOR_INK)
    style.configure("Title.TLabel", font=pick_font(root, 14, "bold"))
    style.configure("Section.TLabel", font=pick_font(root, 10, "bold"), foreground=COLOR_INK_SOFT)
    style.configure("Hint.TLabel", foreground="#718B9E")
    style.configure("Status.TLabel", background=COLOR_PAPER, foreground=COLOR_INK)
    style.configure("Error.TLabel", foreground=COLOR_END)
    style.configure("Warning.TLabel", foreground="#B45309")
    style.configure("Ok.TLabel", foreground=COLOR_START)

    style.configure("TButton", padding=(10, 5))
    style.configure("Tool.TButton", padding=(8, 6))
    style.configure("Accent.TButton", font=pick_font(root, 10, "bold"))
    style.configure("TLabelframe", background=COLOR_PAPER_ALT)
    style.configure("TLabelframe.Label", background=COLOR_PAPER_ALT, foreground=COLOR_INK_SOFT)

    # Nút công cụ khi được chọn
    style.configure("Selected.Tool.TButton", font=pick_font(root, 10, "bold"))
    style.map(
        "Tool.TButton",
        background=[("active", "#E4EEF5")],
    )
    style.map(
        "Selected.Tool.TButton",
        background=[("!active", "#FDE9C9"), ("active", "#F7D9A6")],
    )
    return style


__all__ = [
    "apply_theme",
    "pick_font",
    "COLOR_CANVAS_BG",
    "COLOR_END",
    "COLOR_GRID",
    "COLOR_INK",
    "COLOR_INK_SOFT",
    "COLOR_MARGIN",
    "COLOR_PAPER",
    "COLOR_PAPER_ALT",
    "COLOR_PATH",
    "COLOR_SELECT",
    "COLOR_START",
    "COLOR_WALL_HIDDEN",
    "COLOR_WALL_VISIBLE",
]
