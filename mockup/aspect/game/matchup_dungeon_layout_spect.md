Dưới đây là Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh cho chế độ DUNGEON
MODE trên toàn bộ 10 tỉ lệ màn hình, được chia thành 2 nhóm: Màn hình Dọc
(Portrait) và Màn hình Ngang (Landscape).

PHẦN 1: NHÓM MÀN HÌNH DỌC (6 TỈ LỆ)

Bố cục: 1 cột dọc duy nhất (từ trên xuống: Safe Area \to Header \to HUD 3 khối
\to Board \to Tip \to Controls \to Gesture Bar).

1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI                    | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440  | 3:4 · 1200×1600  |
| :------------------------------- | :------------------------ | :--------------- | :----------------- | :--------------- | :--------------- | :--------------- |
| **Lề ngang (Padding X)**         | 50 px                     | 50 px            | 50 px              | 50 px            | 40 px            | 60 px            |
| **Top Safe Area (Y Offset)**     | 70 px                     | 90 px            | 110 px             | 130 px           | 35 px            | 45 px            |
| **Bàn cờ vuông (Board)**         | **980 × 980 px**          | **980 × 980 px** | **980 × 980 px**   | **980 × 980 px** | **800 × 800 px** | **920 × 920 px** |
| **Header Panel (W × H)**         | 980 × 80 px               | 980 × 85 px      | 980 × 90 px        | 980 × 95 px      | 1000 × 65 px     | 1080 × 85 px     |
| **HUD Trái: Timer (W × H)**      | 250 × 138 px              | 250 × 150 px     | 250 × 155 px       | 250 × 165 px     | 250 × 115 px     | 280 × 135 px     |
| **HUD Giữa: Step Count (W × H)** | **440 × 158 px**          | **440 × 168 px** | **440 × 175 px**   | **440 × 185 px** | **460 × 128 px** | **480 × 152 px** |
| **HUD Phải: Floor (W × H)**      | 250 × 138 px              | 250 × 150 px     | 250 × 155 px       | 250 × 165 px     | 250 × 115 px     | 280 × 135 px     |
| **Banner Mẹo / Tip (W × H)**     | 980 × 90 px               | 980 × 90 px      | 980 × 100 px       | 980 × 110 px     | 1000 × 65 px     | 1080 × 80 px     |
| **Nút Vẽ / Ghi Nhớ (W × H)**     | 360 × 150 px              | 360 × 160 px     | 360 × 165 px       | 360 × 175 px     | 360 × 135 px     | 395 × 160 px     |
| **Nút Undo / Hint (W × H)**      | 105 × 150 px              | 105 × 160 px     | 105 × 165 px       | 105 × 175 px     | 110 × 135 px     | 115 × 160 px     |

2. Font Spec (Cỡ chữ)

| Text Item                          | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--------------------------------- | :------------------------ | :--------------- | :----------------- | :--------------- | :-------------- | :-------------- |
| **Header: DUNGEON MODE**           | 42 px                     | 42 px            | 44 px              | 44 px            | 36 px           | 42 px           |
| **Label "THỜI GIAN"**              | 18 px                     | 20 px            | 22 px              | 22 px            | 16 px           | 20 px           |
| **Giá trị Đồng hồ (01:24)**        | **46 px**                 | **48 px**        | **50 px**          | **52 px**        | **40 px**       | **46 px**       |
| **Label "SỐ BƯỚC"**                | 30 px                     | 30 px            | 32 px              | 32 px            | 24 px           | 28 px           |
| **Giá trị Số Bước (To giữa)**      | **72 px**                 | **74 px**        | **76 px**          | **80 px**        | **62 px**       | **70 px**       |
| **Label "TẦNG"**                   | 18 px                     | 20 px            | 22 px              | 22 px            | 16 px           | 20 px           |
| **Giá trị Tầng (04)**              | **60 px**                 | **62 px**        | **64 px**          | **66 px**        | **50 px**       | **58 px**       |
| **Số manh mối trên Board**         | **52 px**                 | **52 px**        | **52 px**          | **52 px**        | **44 px**       | **50 px**       |
| **Banner Mẹo / Luật chơi**         | 22 px                     | 24 px            | 24 px              | 24 px            | 20 px           | 24 px           |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)**      | 28 px                     | 28 px            | 30 px              | 30 px            | 26 px           | 30 px           |
| **Mô tả Nút Chính ("Kéo từ tâm")** | 18 px                     | 18 px            | 18 px              | 18 px            | 16 px           | 20 px           |
| **Nhãn Nút Phụ (UNDO / HINT)**     | 18 px                     | 18 px            | 18 px              | 18 px            | 16 px           | 20 px           |

PHẦN 2: NHÓM MÀN HÌNH NGANG (4 TỈ LỆ)

Bố cục: Chia đôi màn hình (Bên Trái: Bàn cờ vuông; Bên Phải: Cột Sidebar chứa
Header, HUD, Tip và Controls).

1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI                         | 4:3 · 1600×1200                | 16:9 · 1920×1080 *(Base)*   | 18:9 · 2160×1080            | 19.5:9 · 2340×1080            |
| :------------------------------------ | :----------------------------- | :-------------------------- | :-------------------------- | :---------------------------- |
| **Lề an toàn (Safe Area Left/Right)** | 60 px                          | 60 px                       | 80 px                       | 100 px *(Tránh Notch/Camera)* |
| **Bàn cờ vuông (Board)**              | **1040 × 1040 px**             | **960 × 960 px**            | **960 × 960 px**            | **960 × 960 px**              |
| **Chiều rộng Cột Phải (Sidebar W)**   | 420 px                         | 810 px                      | 980 px                      | 1120 px                       |
| **Header Panel (W × H)**              | 420 × 90 px                    | 810 × 75 px                 | 980 × 80 px                 | 1120 × 85 px                  |
| **HUD: Timer (W × H)**                | 200 × 130 px                   | 210 × 180 px                | 250 × 190 px                | 280 × 200 px                  |
| **HUD: Step Count (W × H)**           | **420 × 160 px** *(To ở trên)* | **350 × 200 px** *(Ở giữa)* | **440 × 215 px** *(Ở giữa)* | **510 × 225 px** *(Ở giữa)*   |
| **HUD: Tầng / Floor (W × H)**         | 200 × 130 px                   | 210 × 180 px                | 250 × 190 px                | 280 × 200 px                  |
| **Banner Mẹo / Tip (W × H)**          | 420 × 100 px                   | 810 × 75 px                 | 980 × 80 px                 | 1120 × 85 px                  |
| **Nút Chính: Vẽ Đường (W × H)**       | 420 × 190 px                   | 810 × 235 px                | 475 × 245 px                | 540 × 255 px                  |
| **Nút Chính: Ghi Nhớ (W × H)**        | 420 × 140 px                   | 460 × 165 px                | 475 × 245 px                | 555 × 255 px                  |
| **Nút Phụ: Undo / Hint (W × H)**      | 200 × 90 px *(Mỗi nút)*        | 155 × 165 px *(Mỗi nút)*    | 475 × 145 px *(Ngang)*      | 540 × 150 px *(Ngang)*        |

2. Font Spec (Cỡ chữ)

| Text Item                          | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--------------------------------- | :-------------- | :------------------------ | :--------------- | :----------------- |
| **Header: DUNGEON MODE**           | 38 px           | 40 px                     | 42 px            | 44 px              |
| **Label "THỜI GIAN"**              | 18 px           | 18 px                     | 20 px            | 22 px              |
| **Giá trị Đồng hồ (01:24)**        | **40 px**       | **48 px**                 | **52 px**        | **56 px**          |
| **Label "SỐ BƯỚC"**                | 28 px           | 28 px                     | 30 px            | 32 px              |
| **Giá trị Số Bước (To nổi bật)**   | **74 px**       | **80 px**                 | **88 px**        | **92 px**          |
| **Label "TẦNG"**                   | 18 px           | 18 px                     | 20 px            | 22 px              |
| **Giá trị Tầng (04)**              | **48 px**       | **56 px**                 | **60 px**        | **64 px**          |
| **Số manh mối trên Board**         | **56 px**       | **52 px**                 | **52 px**        | **52 px**          |
| **Banner Mẹo / Luật chơi**         | 20 px           | 22 px                     | 24 px            | 24 px              |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)**      | **32 px**       | **36 px**                 | **36 px**        | **38 px**          |
| **Mô tả Nút Chính ("Kéo từ tâm")** | 20 px           | 22 px                     | 22 px            | 24 px              |
| **Nhãn Nút Phụ (UNDO / HINT)**     | 22 px           | 20 px                     | 26 px            | 28 px              |

