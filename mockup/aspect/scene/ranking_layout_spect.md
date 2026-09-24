Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **LEADERBOARD (BẢNG XẾP HẠNG)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia theo 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**, kèm quy chuẩn hiển thị cho cả 2 chế độ **Daily** và **Dungeon**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất nằm trọn trong trang giấy sổ còng (Sheet). Thứ tự từ trên xuống: Top Header (Nút Back + Tiêu đề + Thẻ Top) $\to$ Hàng 2 Tab Chính (`DUNGEON` / `DAILY`) $\to$ Hàng 3 Sub-tabs (`HÔM NAY` / `TUẦN` / `THÁNG`) $\to$ Bục Vinh Danh Podium Top 1, 2, 3 $\to$ Danh sách cuộn các hàng rank từ `#4` $\to$ Thẻ Sticky Rank của Bạn (`#18 BẠN`) ghim cố định ở đáy $\to$ Gesture Bar.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Top Safe Area (Y Offset Sheet)** | 185 px | 200 px | 225 px | 245 px | 115 px | 125 px |
| **Kích thước Tờ Giấy Sổ (Sheet)** | **940 × 1570 px** | **940 × 1780 px** | **940 × 1940 px** | **940 × 2100 px** | **980 × 1260 px** | **1080 × 1420 px** |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px | 65 × 65 px | 70 × 70 px |
| **Thẻ Header Top/Streak (W × H)** | 200 × 70 px | 200 × 75 px | 200 × 80 px | 200 × 85 px | 210 × 65 px | 220 × 70 px |
| **2 Tab Chính (Mỗi tab W × H)** | 365 × 50 px | 365 × 52 px | 365 × 54 px | 365 × 56 px | 380 × 44 px | 415 × 48 px |
| **Khung Sub-tabs (W × H)** | 755 × 46 px | 755 × 48 px | 755 × 50 px | 755 × 52 px | 780 × 38 px | 860 × 42 px |
| **Bục Podium #1 (W × H)** | **240 × 195 px** | **240 × 200 px** | **240 × 210 px** | **240 × 220 px** | **220 × 125 px** | **260 × 155 px** |
| **Bục Podium #2 & #3 (W × H)** | 200 × 150 px | 200 × 155 px | 200 × 160 px | 200 × 165 px | 190 × 95 px | 220 × 120 px |
| **Hàng Xếp Hạng #4..#7 (W × H)** | **755 × 88 px** | **755 × 92 px** | **755 × 96 px** | **755 × 100 px** | **780 × 70 px** | **860 × 80 px** |
| **Thẻ Sticky Rank Bạn (W × H)** | **755 × 110 px** | **755 × 115 px** | **755 × 120 px** | **755 × 125 px** | **780 × 90 px** | **860 × 105 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: BẢNG XẾP HẠNG** | **44 px** | **44 px** | **46 px** | **46 px** | **36 px** | **40 px** |
| **Thẻ Header ("🔥 DAILY TOP")**| 19 px | 20 px | 20 px | 20 px | 18 px | 20 px |
| **Nhãn 2 Tab Chính (DUNGEON/DAILY)**| 18 px | 18 px | 18 px | 20 px | 16 px | 17 px |
| **Nhãn 3 Sub-tabs (HÔM NAY...)** | 16 px | 16 px | 16 px | 18 px | 14 px | 15 px |
| **Tên Top 1 (Master_King 👑)** | **24 px** | **24 px** | **24 px** | **24 px** | **18 px** | **22 px** |
| **Số Hạng Bục Top 1 ("1")** | **58 px** | **58 px** | **58 px** | **58 px** | **44 px** | **50 px** |
| **Tên Top 2 & 3** | 20 px | 20 px | 20 px | 20 px | 16 px | 18 px |
| **Số Hạng Bục Top 2 & 3 ("2", "3")**| 44 px / 40 px | 44 px / 40 px | 44 px / 40 px | 44 px / 40 px | 34 px / 30 px | 38 px / 36 px |
| **Streak / Sao trên Bục Top 1..3**| 16 px / 19 px | 16 px / 19 px | 16 px / 19 px | 16 px / 19 px | 14 px / 16 px | 15 px / 18 px |
| **Số Thứ Hạng Row ("#4", "#5"...)**| 24 px | 24 px | 24 px | 24 px | 18 px | 20 px |
| **Tên Người Chơi Row (#4..#7)** | 22 px | 22 px | 22 px | 22 px | 18 px | 20 px |
| **Streak & Sao Row ("19 NGÀY")** | 20 px / 15 px | 20 px / 15 px | 20 px / 15 px | 20 px / 15 px | 16 px / 13 px | 18 px / 14 px |
| **Số Hạng Của Bạn ("#18")** | **32 px** | **32 px** | **34 px** | **34 px** | **26 px** | **30 px** |
| **Nhãn "BẠN (Người chơi)"** | **26 px** | **26 px** | **26 px** | **26 px** | **22 px** | **24 px** |
| **Streak & Sao Của Bạn** | 26 px / 16 px | 26 px / 16 px | 26 px / 16 px | 26 px / 16 px | 22 px / 14 px | 24 px / 15 px |
| **Quote Chân Trang (Footer)** | 16 px | 16 px | 16 px | 16 px | 14 px | 15 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột độc lập:
> - **Cột Trái (Podium & My Rank):** Top Header, Bục Podium Top 1-2-3 vinh danh trang trọng, Thẻ Sticky Rank của Bạn (`#18 BẠN`) ghim cố định ở đáy.
> - **Cột Phải (Scroll List):** Cụm 2 Tab Chính + 3 Sub-tabs trên cùng, bên dưới là danh sách cuộn mượt mà các thứ hạng từ `#4` đến `#9+`.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 50 px | 60 px | 100 px *(Tránh Notch/Camera)* |
| **Kích thước Tờ Giấy Sổ (Sheet)** | **1500 × 1100 px** | **1820 × 980 px** | **2040 × 980 px** | **2140 × 980 px** |
| **Chiều rộng Cột Trái (Podium & My Rank)**| 680 px | 780 px | 860 px | 900 px |
| **Chiều rộng Cột Phải (Scroll List)** | 730 px | 960 px | 1090 px | 1140 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Thẻ Header Streak (W × H)** | 200 × 70 px | 220 × 75 px | 230 × 80 px | 240 × 85 px |
| **Bục Podium #1 (W × H)** | **230 × 300 px** | **260 × 275 px** | **280 × 275 px** | **295 × 275 px** |
| **Bục Podium #2 & #3 (W × H)** | 190 × 230 px / 195 px | 215 × 210 px / 180 px | 235 × 210 px / 180 px | 245 × 210 px / 180 px |
| **Thẻ Sticky Rank Bạn (W × H)** | **670 × 150 px** | **765 × 145 px** | **830 × 145 px** | **870 × 145 px** |
| **2 Tab Chính (Mỗi tab W × H)** | 345 × 50 px | 460 × 52 px | 530 × 54 px | 560 × 54 px |
| **Khung 3 Sub-tabs (W × H)** | 705 × 46 px | 940 × 46 px | 1080 × 48 px | 1140 × 48 px |
| **Hàng Xếp Hạng #4..#9 (W × H)** | **705 × 90 px** | **940 × 82 px** | **1080 × 85 px** | **1140 × 85 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: BẢNG XẾP HẠNG** | **26 px** | **28 px** | **30 px** | **32 px** |
| **Thẻ Header ("🔥 DAILY TOP")**| 19 px | 20 px | 20 px | 20 px |
| **Tên Top 1 (Master_King 👑)** | **24 px** | **24 px** | **24 px** | **26 px** |
| **Số Hạng Bục Top 1 ("1")** | **58 px** | **58 px** | **58 px** | **60 px** |
| **Tên Top 2 & 3** | 18 px | 20 px | 20 px | 22 px |
| **Số Hạng Bục Top 2 & 3 ("2", "3")**| 44 px / 40 px | 44 px / 40 px | 44 px / 40 px | 46 px / 42 px |
| **Streak / Sao trên Bục Top 1..3**| 15 px / 16 px | 15 px / 16 px | 15 px / 16 px | 16 px / 17 px |
| **Số Hạng Của Bạn ("#18")** | **34 px** | **34 px** | **34 px** | **36 px** |
| **Nhãn "BẠN (Người chơi)"** | **24 px** | **26 px** | **26 px** | **28 px** |
| **Streak & Sao Của Bạn** | 24 px / 16 px | 26 px / 16 px | 26 px / 16 px | 28 px / 16 px |
| **Nhãn 2 Tab Chính (DUNGEON/DAILY)**| 18 px | 18 px | 20 px | 20 px |
| **Nhãn 3 Sub-tabs (HÔM NAY...)** | 16 px | 16 px | 16 px | 16 px |
| **Số Thứ Hạng Row ("#4", "#5"...)**| 22 px | 22 px | 24 px | 24 px |
| **Tên Người Chơi Row (#4..#9)** | 20 px | 22 px | 22 px | 22 px |
| **Streak & Sao Row ("19 NGÀY")** | 18 px / 14 px | 18 px / 14 px | 20 px / 15 px | 20 px / 15 px |

---

# PHẦN 3: GHI CHÚ CHUYỂN ĐỔI CHỈ SỐ GIỮA 2 TAB (DAILY vs DUNGEON)

Khi người chơi chuyển tab từ **DAILY CHALLENGE** sang **DUNGEON**, cấu trúc layout và font chữ giữ nguyên 100%, chỉ thay đổi dữ liệu chỉ số như sau:

| Vị trí hiển thị | Chế độ DAILY CHALLENGE (Hiện tại) | Chế độ DUNGEON MODE (Khi đổi Tab) |
| :--- | :--- | :--- |
| **Màu Nhận Diện Tab** | Đỏ Cam (`#D84444`) | Xanh Dương / Nâu Cổ Điển (`#3D83AE` / `#256C96`) |
| **Thẻ Header Phải** | `🔥 DAILY TOP` | `🏰 DUNGEON TOP` |
| **Chỉ số Bục Top 1..3 (Dòng 1)** | `🔥 [X] NGÀY` (Streak liên tục) | `🏰 TẦNG [X]` (Tầng sâu nhất đạt được) |
| **Chỉ số Bục Top 1..3 (Dòng 2)** | `⭐ [X] SAO` (Tổng sao thử thách) | `👣 [X] BƯỚC` (Tổng số bước đã tiêu tốn) |
| **Chỉ số Hàng Rank #4..#9** | `🔥 [X] NGÀY` / `⭐ [X] SAO` | `🏰 TẦNG [X]` / `👣 [X] BƯỚC` |
| **Chỉ số Thẻ Rank Bạn** | Thành tích Daily • Tháng 09 | Kỷ lục Dungeon • Tầng cao nhất |