Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **CHAPTER SELECTION (Màn Hình Chọn Chương)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia theo 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất từ trên xuống: Top Header (Nút Back + Tiêu đề + Ví Sao) $\to$ Banner Mẹo/Luật mở khóa $\to$ Danh sách Thẻ Chương xếp dọc $\to$ Nút lớn "TIẾP TỤC CHƠI" gắn ở chân trang $\to$ Gesture Bar.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề ngang màn hình (Padding X)**| 55 px | 55 px | 55 px | 55 px | 40 px | 60 px |
| **Top Safe Area (Y Offset)** | 90 px | 90 px | 110 px | 130 px | 35 px | 45 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px | 65 × 65 px | 70 × 70 px |
| **Ví Sao Player (W × H)** | 250 × 70 px | 250 × 75 px | 250 × 80 px | 250 × 85 px | 250 × 65 px | 260 × 70 px |
| **Banner Mẹo / Tip (W × H)** | 970 × 72 px | 970 × 75 px | 970 × 80 px | 970 × 85 px | 1000 × 55 px | 1080 × 65 px |
| **Thẻ Chương Card (W × H)** | **970 × 285 px** | **970 × 295 px** | **970 × 300 px** | **970 × 305 px** | **1000 × 210 px** | **1080 × 240 px** |
| **Ô Doodle Mê Cung (W × H)** | 180 × 180 px | 180 × 180 px | 190 × 190 px | 190 × 190 px | 150 × 150 px | 170 × 170 px |
| **Nút "VÀO CHƠI" (W × H)** | 200 × 85 px | 200 × 90 px | 200 × 90 px | 200 × 95 px | 220 × 80 px | 260 × 85 px |
| **Nút "MỞ KHÓA" (W × H)** | 225 × 95 px | 225 × 100 px | 225 × 100 px | 225 × 105 px | 220 × 80 px | 260 × 85 px |
| **Nút Khóa (W × H)** | 225 × 85 px | 225 × 90 px | 225 × 90 px | 225 × 95 px | 220 × 80 px | 260 × 85 px |
| **Nút Chơi Tiếp Chân Trang** | **800 × 120 px** | **800 × 130 px** | **800 × 135 px** | **800 × 140 px** | **800 × 100 px** | **800 × 115 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề: CHỌN CHƯƠNG** | **44 px** | **44 px** | **46 px** | **46 px** | **36 px** | **40 px** |
| **Số Ví Sao (28)** | 34 px | 34 px | 36 px | 36 px | 28 px | 32 px |
| **Nhãn "SAO CÓ"** | 16 px | 16 px | 16 px | 16 px | 14 px | 15 px |
| **Banner Mẹo / Tip** | 20 px | 20 px | 22 px | 22 px | 18 px | 20 px |
| **Tag Kích Thước (5×5, 7×7...)**| 13 px | 13 px | 14 px | 14 px | 12 px | 13 px |
| **Tên Chương (CHƯƠNG 1...)** | **34 px** | **34 px** | **36 px** | **36 px** | **28 px** | **32 px** |
| **Mô tả Chương (Subtext)** | 18 px | 18 px | 18 px | 18 px | 15 px | 16 px |
| **Tiến độ Sao ("28 / 30 Sao")** | 18 px | 18 px | 18 px | 18 px | 16 px | 16 px |
| **Tag Đủ Sao / Thiếu Sao** | 16 px / 13 px | 16 px / 13 px | 16 px / 14 px | 16 px / 14 px | 14 px / 12 px | 15 px / 13 px |
| **Chữ Nút "VÀO CHƠI"** | **22 px** | **22 px** | **24 px** | **24 px** | **20 px** | **22 px** |
| **Chữ Nút "MỞ KHÓA"** | **22 px** | **22 px** | **24 px** | **24 px** | **20 px** | **22 px** |
| **Chữ Nút Khóa ("CẦN 45 ⭐")** | 22 px | 22 px | 22 px | 22 px | 18 px | 20 px |
| **Nút "TIẾP TỤC CHƯƠNG 1"** | **34 px** | **34 px** | **36 px** | **36 px** | **28 px** | **32 px** |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột:
> - **Cột Trái (Sidebar / Info Hub):** Nút Back, Tiêu đề, Ví Sao, Khung giải thích luật mở khóa, Nút lớn "TIẾP TỤC CHƠI".
> - **Cột Phải (Scroll Area):** Danh sách cuộn các Thẻ Chương dạng ngang, rộng rãi.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 60 px | 70 px | 120 px *(Tránh Notch/Camera)* |
| **Chiều rộng Cột Trái (Sidebar Info)**| 460 px | 560 px | 610 px | 650 px |
| **Chiều rộng Cột Phải (Scroll List)** | 990 px | 1180 px | 1350 px | 1420 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Thẻ Ví Sao Player (W × H)** | **460 × 180 px** | **560 × 160 px** | **610 × 165 px** | **650 × 170 px** |
| **Khung Mẹo / Tip (W × H)** | 460 × 220 px | 560 × 200 px | 610 × 210 px | 650 × 215 px |
| **Nút "TIẾP TỤC CHƠI" Cố Định Trái** | **460 × 160 px** | **560 × 170 px** | **610 × 180 px** | **650 × 185 px** |
| **Thẻ Chương Item (W × H)** | **990 × 245 px** | **1180 × 215 px** | **1350 × 215 px** | **1420 × 215 px** |
| **Ô Doodle Mê Cung (W × H)** | 175 × 175 px | 175 × 175 px | 175 × 175 px | 175 × 175 px |
| **Nút "VÀO CHƠI" (W × H)** | 200 × 85 px | 220 × 95 px | 260 × 95 px | 270 × 95 px |
| **Nút "MỞ KHÓA" (W × H)** | 220 × 95 px | 240 × 105 px | 280 × 105 px | 290 × 105 px |
| **Nút Khóa (W × H)** | 220 × 85 px | 240 × 95 px | 280 × 95 px | 290 × 95 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề: CHỌN CHƯƠNG** | **36 px** | **40 px** | **42 px** | **44 px** |
| **Nhãn "VÍ SAO HIỆN CÓ"** | 20 px | 22 px | 24 px | 26 px |
| **Số Ví Sao ("⭐ 28 SAO")** | **52 px** | **54 px** | **56 px** | **58 px** |
| **Tiêu đề Khung Tip** | 20 px | 22 px | 22 px | 24 px |
| **Nội dung Tip mở khóa** | 18 px | 20 px | 20 px | 20 px |
| **Nút Tiếp Tục Chơi (Tiêu đề)** | **28 px** | **32 px** | **34 px** | **36 px** |
| **Nút Tiếp Tục Chơi (Phụ: Màn 07)**| 20 px | 22 px | 22 px | 24 px |
| **Tên Chương (CHƯƠNG 1...)** | **32 px** | **34 px** | **36 px** | **38 px** |
| **Thông tin lưới & Tiến độ Sao**| 18 px | 20 px | 20 px | 22 px |
| **Chữ Nút "VÀO CHƠI"** | **22 px** | **24 px** | **24 px** | **26 px** |
| **Chữ Nút "MỞ KHÓA"** | **22 px** | **24 px** | **24 px** | **26 px** |
| **Chữ Nút Khóa ("CẦN 45 ⭐")** | 20 px | 22 px | 22 px | 24 px |