"""Level Designer - Tạo/sửa LevelData resource (.tres) cho game InkMaze.

Kiến trúc MVC:
    models/       -> dữ liệu thuần (LevelModel) + truy cập file (LevelRepository)
    services/     -> đọc/ghi .tres, giải mê cung, kiểm tra hợp lệ
    controllers/  -> điều phối: EditorController (lệnh sửa + undo), AppController (file)
    views/        -> giao diện Tkinter (không chứa logic nghiệp vụ)
"""

__version__ = "1.0.0"
__all__ = ["__version__"]
