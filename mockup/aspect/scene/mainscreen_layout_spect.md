Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **MAIN SCREEN (Màn hình chính / Menu)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia theo 2 nhóm: **Màn hình Dọc (Portrait - 6 tỉ lệ)** và **Màn hình Ngang (Landscape - 4 tỉ lệ)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc trung tâm nằm trọn trong tấm giấy menu sổ còng (Sheet) từ trên xuống: Safe Area $\to$ Logo Header + Nút Danh Hiệu $\to$ 3 Thẻ Chế Độ Chơi $\to$ 3 Nút Công Cụ $\to$ Con Dấu Version.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề ngoài màn hình (Padding X)** | 65 px | 65 px | 65 px | 65 px | 40 px | 60 px |
| **Top Safe Area (Y Offset Sheet)** | 170 px | 180 px | 200 px | 230 px | 60 px | 70 px |
| **Kích thước Tờ Giấy Menu (Sheet)** | **950 × 1630 px** | **950 × 1850 px** | **950 × 2020 px** | **950 × 2180 px** | **1000 × 1320 px** | **1080 × 1460 px** |
| **Khung Logo Header (W × H)** | 450 × 230 px | 450 × 250 px | 450 × 260 px | 450 × 280 px | 450 × 170 px | 500 × 190 px |
| **Nút Danh Hiệu (W × H)** | 150 × 150 px | 160 × 160 px | 165 × 165 px | 170 × 170 px | 135 × 135 px | 150 × 150 px |
| **Thẻ 1: Play • Chọn Màn (W × H)** | **670 × 205 px** | **670 × 215 px** | **670 × 225 px** | **670 × 230 px** | **690 × 165 px** | **740 × 185 px** |
| **Thẻ 2: Dungeon Mode (W × H)** | 670 × 195 px | 670 × 205 px | 670 × 215 px | 670 × 220 px | 690 × 155 px | 740 × 175 px |
| **Thẻ 3: Daily Challenge (W × H)**| 670 × 195 px | 670 × 205 px | 670 × 215 px | 670 × 220 px | 690 × 155 px | 740 × 175 px |
| **3 Nút Công Cụ (Mỗi nút W × H)** | 205 × 110 px | 205 × 120 px | 205 × 125 px | 205 × 130 px | 210 × 95 px | 230 × 110 px |
| **Con Dấu Version Stamp (W × H)** | 200 × 60 px | 210 × 65 px | 210 × 65 px | 210 × 65 px | 180 × 50 px | 200 × 55 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Logo Chính: "Ink Maze"** | **68 px** | **72 px** | **74 px** | **76 px** | **56 px** | **64 px** |
| **Tag: LOGIC & PUZZLE** | 15 px | 16 px | 16 px | 18 px | 14 px | 15 px |
| **Slogan phụ** | 18 px | 20 px | 20 px | 22 px | 16 px | 18 px |
| **Số Danh Hiệu (1/28)** | 22 px | 24 px | 24 px | 26 px | 20 px | 22 px |
| **Label "DANH HIỆU"** | 15 px | 16 px | 16 px | 16 px | 14 px | 15 px |
| **Tiêu đề Thẻ 1 (PLAY • CHỌN MÀN)**| **34 px** | **34 px** | **36 px** | **36 px** | **30 px** | **34 px** |
| **Tiêu đề Thẻ 2 & 3 (DUNGEON/DAILY)**| 32 px | 34 px | 34 px | 34 px | 28 px | 32 px |
| **Mô tả thẻ (Dòng 1 / Dòng 2)** | 18 px / 17 px | 18 px / 18 px | 18 px / 18 px | 20 px / 18 px | 16 px / 15 px | 18 px / 16 px |
| **Tag Huy Hiệu trên Thẻ (Màn/Kỷ lục)**| 13 px | 14 px | 14 px | 14 px | 12 px | 13 px |
| **Chữ 3 Nút Công Cụ (XẾP HẠNG...)**| 17 px | 18 px | 18 px | 18 px | 16 px | 17 px |
| **Con dấu VER 1.0.0** | 22 px | 22 px | 22 px | 22 px | 18 px | 20 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột chính trong tờ giấy menu ngang: Cột Trái (Logo Hero, Nút Danh Hiệu, Version Stamp) và Cột Phải (3 Thẻ Chế Độ Chơi xếp dọc + 3 Nút Công Cụ nằm ngang phía dưới).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 50 px | 60 px | 100 px *(Tránh Notch/Camera)* |
| **Kích thước Tờ Giấy Menu (Sheet)** | **1500 × 1100 px** | **1820 × 980 px** | **2040 × 980 px** | **2140 × 980 px** |
| **Chiều rộng Cột Trái (Hero Column)**| 530 px | 650 px | 750 px | 800 px |
| **Chiều rộng Cột Phải (Menu Column)**| 840 px | 1040 px | 1140 px | 1180 px |
| **Khung Logo Box (W × H)** | 530 × 520 px | 650 × 470 px | 750 × 470 px | 800 × 470 px |
| **Nút Danh Hiệu (W × H)** | 530 × 230 px | 650 × 210 px | 750 × 210 px | 800 × 210 px |
| **Thẻ 1: Play • Chọn Màn (W × H)** | **840 × 210 px** | **1040 × 205 px** | **1140 × 205 px** | **1180 × 205 px** |
| **Thẻ 2: Dungeon Mode (W × H)** | 840 × 195 px | 1040 × 195 px | 1140 × 195 px | 1180 × 195 px |
| **Thẻ 3: Daily Challenge (W × H)**| 840 × 195 px | 1040 × 195 px | 1140 × 195 px | 1180 × 195 px |
| **3 Nút Công Cụ (Mỗi nút W × H)** | 260 × 130 px | 325 × 140 px | 360 × 140 px | 375 × 140 px |
| **Con Dấu Version Stamp (W × H)** | 210 × 65 px | 210 × 65 px | 210 × 65 px | 210 × 65 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Logo Chính: "Ink Maze"** | **72 px** | **76 px** | **80 px** | **84 px** |
| **Tag: LOGIC & PUZZLE** | 18 px | 18 px | 18 px | 20 px |
| **Slogan phụ** | 20 px | 20 px | 20 px | 22 px |
| **Số Danh Hiệu (1/28)** | **36 px** | **40 px** | **44 px** | **48 px** |
| **Label "DANH HIỆU"** | 22 px | 24 px | 24 px | 26 px |
| **Tiêu đề Thẻ 1 (PLAY • CHỌN MÀN)**| **36 px** | **38 px** | **40 px** | **42 px** |
| **Tiêu đề Thẻ 2 & 3 (DUNGEON/DAILY)**| 34 px | 36 px | 38 px | 40 px |
| **Mô tả thẻ (Dòng 1 / Dòng 2)** | 18 px / 18 px | 20 px / 18 px | 20 px / 18 px | 22 px / 20 px |
| **Tag Huy Hiệu trên Thẻ** | 14 px | 14 px | 14 px | 15 px |
| **Chữ 3 Nút Công Cụ (XẾP HẠNG...)**| **20 px** | **22 px** | **22 px** | **24 px** |
| **Con dấu VER 1.0.0** | 22 px | 22 px | 22 px | 22 px |