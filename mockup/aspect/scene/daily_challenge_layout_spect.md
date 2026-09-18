Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **DAILY CHALLENGE (Thử Thách Hằng Ngày)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia thành 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất từ trên xuống: Top Header (Nút Back + Tiêu đề + Chuỗi Streak) $\to$ Khung Lịch Tháng (Calendar Board) $\to$ Dialog Panel 4 Nhiệm Vụ (3 Maze Missions + 1 Special Mode Mission) $\to$ Nút Lớn Hành Động Chân Trang $\to$ Gesture Bar.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Top Safe Area (Y Offset)** | 85 px | 90 px | 110 px | 130 px | 30 px | 40 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px | 65 × 65 px | 70 × 70 px |
| **Thẻ Streak (W × H)** | 200 × 70 px | 200 × 75 px | 200 × 80 px | 200 × 85 px | 210 × 65 px | 220 × 70 px |
| **Khung Lịch Tháng (W × H)** | **980 × 970 px** | **980 × 1000 px** | **980 × 1020 px** | **980 × 1060 px** | **1000 × 720 px** | **1080 × 820 px** |
| **Ô Ngày Trong Lịch (W × H)** | 130 × 150 px | 130 × 155 px | 130 × 160 px | 130 × 165 px | 135 × 110 px | 145 × 125 px |
| **Dialog Panel Thử Thách (W × H)**| **980 × 560 px** | **980 × 600 px** | **980 × 640 px** | **980 × 680 px** | **1000 × 480 px** | **1080 × 520 px** |
| **Hàng Nhiệm Vụ 1..3 (W × H)**| 950 × 75 px | 950 × 85 px | 950 × 90 px | 950 × 95 px | 970 × 65 px | 1040 × 70 px |
| **Hàng Nhiệm Vụ 4 Đặc Biệt (W × H)**| 950 × 85 px | 950 × 95 px | 950 × 100 px | 950 × 105 px | 970 × 75 px | 1040 × 80 px |
| **Nút Nhận/Vào Chơi Trên Dòng**| 150 × 46 px | 150 × 48 px | 150 × 50 px | 150 × 50 px | 150 × 42 px | 165 × 46 px |
| **Nút Chơi Chính Chân Trang** | **800 × 120 px** | **800 × 130 px** | **800 × 135 px** | **800 × 140 px** | **800 × 90 px** | **800 × 95 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: THỬ THÁCH HẰNG NGÀY**| **40 px** | **42 px** | **44 px** | **44 px** | **34 px** | **38 px** |
| **Số Chuỗi Streak ("7 NGÀY")** | 26 px | 26 px | 28 px | 28 px | 22 px | 26 px |
| **Tiêu đề Lịch ("THÁNG 09 • 2026")**| **34 px** | **36 px** | **36 px** | **36 px** | **28 px** | **32 px** |
| **Hàng Thứ (T2, T3 ... CN)** | 22 px | 22 px | 24 px | 24 px | 18 px | 20 px |
| **Số Ngày Thường Trong Lịch** | 30 px | 30 px | 32 px | 32 px | 24 px | 28 px |
| **Số Ngày Hôm Nay (Nổi bật)** | **40 px** | **42 px** | **44 px** | **44 px** | **32 px** | **36 px** |
| **Nhãn Trạng Thái Ngày ("4/4 XONG")**| 16 px | 16 px | 16 px | 16 px | 13 px | 15 px |
| **Tiêu đề Dialog Thử Thách** | 24 px | 26 px | 26 px | 28 px | 22 px | 24 px |
| **Phần thưởng Dialog ("+50 XU")**| 20 px | 20 px | 22 px | 22 px | 18 px | 20 px |
| **Tên Nhiệm Vụ (Mission Title)** | **22 px** | **22 px** | **24 px** | **24 px** | **18 px** | **20 px** |
| **Mô tả Nhiệm Vụ (Subtext)** | 16 px | 16 px | 18 px | 18 px | 14 px | 16 px |
| **Text Tiến độ Nhiệm Vụ** | 14 px | 14 px | 15 px | 15 px | 12 px | 14 px |
| **Nút Mission ("HOÀN THÀNH/CHƠI")**| **16 px** | **16 px** | **17 px** | **18 px** | **15 px** | **16 px** |
| **Tiến Độ Tổng Ngày (Footer Dialog)**| 18 px | 18 px | 20 px | 20 px | 16 px | 18 px |
| **Nút Hành Động Chính Chân Trang**| **34 px** | **34 px** | **36 px** | **36 px** | **28 px** | **30 px** |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột:
> - **Cột Trái (Calendar View):** Khung Lịch Tháng khổ lớn, bao quát trọn vẹn cả tháng.
> - **Cột Phải (Sidebar / Mission Hub):** Top Header (Back + Title + Streak), Bảng Dialog 4 Nhiệm vụ, và Nút lớn "CHƠI CHẾ ĐỘ ĐẶC BIỆT" ở dưới cùng.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 60 px | 70 px | 120 px *(Tránh Notch/Camera)* |
| **Khung Lịch Cột Trái (W × H)** | **920 × 1080 px** | **1000 × 960 px** | **1020 × 960 px** | **1040 × 960 px** |
| **Ô Ngày Trong Lịch (W × H)** | 120 × 165 px | 132 × 150 px | 135 × 150 px | 138 × 150 px |
| **Chiều rộng Cột Phải (Sidebar W)** | 550 px | 770 px | 960 px | 1060 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Thẻ Streak (W × H)** | 160 × 70 px | 190 × 75 px | 220 × 80 px | 235 × 85 px |
| **Dialog Panel Thử Thách (W × H)**| **550 × 800 px** | **770 × 670 px** | **960 × 670 px** | **1060 × 670 px** |
| **Hàng Nhiệm Vụ 1..3 (W × H)**| 520 × 115 px | 730 × 85 px | 920 × 85 px | 1010 × 85 px |
| **Hàng Nhiệm Vụ 4 Đặc Biệt (W × H)**| 520 × 125 px | 730 × 95 px | 920 × 95 px | 1010 × 95 px |
| **Nút Mission ("HOÀN THÀNH/CHƠI")**| 130 × 42 px | 140 × 46 px | 150 × 48 px | 155 × 48 px |
| **Nút Chơi Chính Chân Trang** | **550 × 160 px** | **770 × 165 px** | **960 × 165 px** | **1060 × 165 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: THỬ THÁCH HẰNG NGÀY**| **24 px** | **26 px** | **28 px** | **30 px** |
| **Số Chuỗi Streak ("🔥 7 NGÀY")** | 22 px | 24 px | 26 px | 26 px |
| **Tiêu đề Lịch ("THÁNG 09 • 2026")**| **30 px** | **32 px** | **34 px** | **36 px** |
| **Hàng Thứ (T2, T3 ... CN)** | 20 px | 22 px | 22 px | 22 px |
| **Số Ngày Thường Trong Lịch** | 28 px | 30 px | 30 px | 32 px |
| **Số Ngày Hôm Nay (Nổi bật)** | **36 px** | **40 px** | **40 px** | **42 px** |
| **Tiêu đề Dialog Thử Thách** | 22 px | 24 px | 26 px | 28 px |
| **Phần thưởng Dialog ("+50 XU")**| 20 px | 20 px | 20 px | 22 px |
| **Tên Nhiệm Vụ (Mission Title)** | **18 px** | **20 px** | **22 px** | **22 px** |
| **Mô tả Nhiệm Vụ (Subtext)** | 15 px | 16 px | 16 px | 16 px |
| **Nút Mission ("HOÀN THÀNH/CHƠI")**| **14 px** | **15 px** | **16 px** | **16 px** |
| **Tiến Độ Ngày (Footer Dialog)** | 16 px | 18 px | 18 px | 18 px |
| **Nút Hành Động Chính Chân Trang**| **26 px / 22 px** | **30 px / 24 px** | **32 px / 26 px** | **34 px / 26 px** |