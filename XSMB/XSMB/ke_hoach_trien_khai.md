# KẾ HOẠCH TRIỂN KHAI DỰ ÁN XSMB SIÊU TỐC

> **Quy ước trạng thái:**
> - `[x] ✅` : Đã hoàn thành
> - `[!] ⚠️` : Chưa làm (Nhiệm vụ cần thực hiện)
>
> 🎨 **TIÊU CHUẨN MÀU THIẾT KẾ GỐC CỦA DỰ ÁN (`AppTheme`):**
> Toàn bộ các thành phần mới (Thống kê nhanh, Biểu đồ, Banner cảnh báo, Soi cầu) phải được **chuẩn hóa 100% theo bảng màu gốc của dự án** (không dùng màu web thô của Rồng Bạch Kim):
> - **Màu chủ đạo (Primary Red)**: `Color(0xFFDC3545)` (Đỏ XSMB / Bootstrap Danger - cho số ĐB, số nổ, header chính, cầu hot).
> - **Màu điểm nhấn (Accent Blue)**: `Color(0xFF0D6EFD)` (Xanh Bootstrap Primary - cho nút tìm kiếm, nút cào bù, link chi tiết).
> - **Màu cảnh báo (Warning Orange/Gold)**: `Color(0xFFFFC107)` / `Color(0xFFFD7E14)` (cho Banner cảnh báo ngày chưa cào, số gan cao).
> - **Màu thành công (Success Green)**: `Color(0xFF198754)` (cho cầu ăn thông, số nháy nổ).
> - **Light Mode**: Nền `Color(0xFFF8F9FA)`, Card trắng `Colors.white`, viền mềm `Color(0xFFDEE2E6)`, Text `Color(0xFF212529)`.
> - **Dark Mode**: Nền `Color(0xFF212529)`, Card `Color(0xFF2C3034)`, viền `Colors.white12`, Text `Colors.white`.

---

## Ⅰ. NỀN TẢNG DỰ ÁN ĐÃ HOÀN THÀNH

- [x] ✅ **Cấu hình & Dependencies**: `pubspec.yaml` với đầy đủ các thư viện (`dio`, `html`, `provider`, `sqflite`, `fl_chart`, `intl`...).
- [x] ✅ **Hệ thống Theme & Giao diện**: Hỗ trợ Light / Dark mode, bảng màu chuẩn, hiệu ứng bo góc hiện đại.
- [x] ✅ **Cơ sở dữ liệu cục bộ**: SQLite (`lottery_results`), bộ đọc file CSV lịch sử kết quả nhiều năm (`assets/db/xsmb_history.csv`).
- [x] ✅ **Scraper kết quả hàng ngày**: Tự động lấy kết quả XSMB trực tiếp và cập nhật vào máy.
- [x] ✅ **Các màn hình cốt lõi đã có**:
  - [x] ✅ Màn hình Lịch sử kỳ quay (`history_screen.dart`).
  - [x] ✅ Màn hình Thống kê ma trận (`thong_ke_screen.dart`).
  - [x] ✅ Màn hình Phân tích chiến thuật & Xác suất (`analysis_screen.dart`).

---

## Ⅱ. PHẦN 1: NÂNG CẤP TRANG CHỦ (`HomeScreen`)
> **Phương án đã chốt:** 
> - **Giao diện**: Phương án A - Cuộn dọc liền mạch All-in-One.
> - **Dữ liệu**: Phương án C - Cơ chế Hybrid (Kéo cache Rồng Bạch Kim + Offline SQLite fallback).

### 1. Giữ lại các thành phần cốt lõi
- [x] ✅ Thanh chuyển lịch xem ngày (`DateNavigator`).
- [x] ✅ Banner đếm ngược 18h15 & trạng thái trực tiếp (`LiveBanner`).
- [x] ✅ Bảng Kết Quả XSMB đầy đủ các giải thưởng truyền thống (`_buildResultsTable`).
- [x] ✅ Bảng thống kê 2 số cuối (Đầu - Đuôi) (`_buildHeadTailTable`).
- [x] ✅ Nút cập nhật dữ liệu (`FloatingActionButton`).

### 2. Dọn dẹp Trang chủ (Loại bỏ các phần cũ)
- [x] ✅ Bỏ khối Cầu Lô Tô cũ (`_buildCauLoto`).
- [x] ✅ Bỏ khối Cầu 2 Nháy cũ (`_buildCau2Nhay`).
- [x] ✅ Bỏ khối Cầu Đặc Biệt cũ (`_buildCauDacBiet`).
- [x] ✅ Bỏ khối Top số đáng chú ý cũ (`_buildTopNumbers`).
- [x] ✅ Bỏ khối Dự đoán đặc biệt cũ (`_buildSpecialPrediction`).
- [x] ✅ Bỏ khối Đầu - Đuôi nóng 7 ngày cũ (`_buildHotHeadTail`).
- [x] ✅ Bỏ khối Hay về theo thứ trong tuần cũ (`_buildFrequentByDay`).

### 3. Xây dựng Dữ liệu & Service Thống Kê Nhanh (Hybrid Engine)
- [x] ✅ Xây dựng `QuickStatsModel` (DTO chứa dữ liệu Lô gan, Tần suất, Max gan, Đề gan, Gan Tổng, Gan Chạm).
- [x] ✅ Xây dựng `QuickStatsService`:
  - [x] ✅ Module Online: Gọi `https://rongbachkim.net/cache/tknhanh/tknhanh_{date}.htm` và bóc tách HTML bằng thư viện `html`.
  - [x] ✅ Module Offline Fallback: Thuật toán Dart tự quét SQLite đếm gan/tần suất/tổng/chạm khi mất mạng hoặc lỗi kết nối.
- [x] ✅ Cập nhật `LotteryProvider`: Quản lý state tải và lưu cache dữ liệu Thống Kê Nhanh theo ngày đang chọn.

### 4. Thiết kế Widget Khối "THỐNG KÊ NHANH CHO NGÀY [Date]"
- [x] ✅ Header khối thống kê nhanh nổi bật phong cách Rồng Bạch Kim.
- [x] ✅ Khối 1: **Lotto lâu chưa ra (lotto gan)** - Hiển thị dạng lưới các ô số và số ngày chưa ra.
- [x] ✅ Khối 2: **Lotto ra nhiều trong tháng qua** - Lưới các số về nhiều kèm số lần xuất hiện.
- [x] ✅ Khối 3: **Cặp lotto dẫn đầu bảng gan** - Card tin tức làm nổi bật số đứng đầu bảng gan, số ngày chưa ra và kỷ lục cực đại (Max gan).
- [x] ✅ Khối 4: **Đặc biệt lâu chưa ra (Đề gan)** - Danh sách 2 số cuối giải ĐB gan lâu nhất.
- [x] ✅ Khối 5: **Biểu đồ cột Gan Đặc Biệt theo Tổng (0-9)** - Cột vẽ số ngày gan từ cao xuống thấp kèm giải thích dàn số của tổng gan nhất.
- [x] ✅ Khối 6: **Biểu đồ cột Gan Đặc Biệt theo Chạm (0-9)** - Cột vẽ số ngày gan từ cao xuống thấp kèm giải thích dàn số của chạm gan nhất.
- [x] ✅ Nhúng toàn bộ khối Thống Kê Nhanh vào vị trí ngay dưới Bảng Đầu - Đuôi trên `home_screen.dart`.

### 5. Hệ thống Cảnh Báo Ngày Chưa Cào Dữ Liệu (Missing Data Alert & Auto-Sync)
- [x] ✅ Thuật toán phát hiện ngày thiếu (Gap Detector): Tự động kiểm tra trong SQLite xem từ ngày có dữ liệu gần nhất đến ngày hôm nay có bị gián đoạn ngày nào chưa cào không (sắp xếp theo thứ tự thời gian).
- [x] ✅ Banner Cảnh Báo Khoảng Ngày Thiếu: Hiển thị thanh thông báo màu vàng cam chỉ rõ khoảng thời gian: *"Chưa cào dữ liệu từ ngày DD/MM/YYYY đến ngày DD/MM/YYYY (tổng cộng X ngày)"* (hoặc 1 ngày nếu chỉ thiếu 1 kỳ) kèm nút *"Cào bù ngay"*.
- [x] ✅ Cảnh báo trên từng ngày xem: Khi người dùng chuyển lịch xem (`DateNavigator`) đến một ngày trong quá khứ mà ngày đó chưa có kết quả trong DB, hiển thị thông báo *"Chưa có dữ liệu ngày này"* kèm nút *"Cào dữ liệu ngay"*.
- [x] ✅ Tính năng 1 chạm cào bù tự động (One-tap Auto Catch-up): Bấm vào nút cào trên banner cảnh báo sẽ tự động kích hoạt tiến trình cào bổ sung tất cả các ngày bị thiếu và nạp vào SQLite.

---

## Ⅲ. PHẦN 2: THAY THẾ TRANG SỐ VẮNG BẰNG TRANG "SOI CẦU" (`SoiCauScreen`)
> **Phương án đã chốt:**
> - **Giao diện**: Phương án B - Giao diện Search-First & Tổng hợp trực quan (Card Top Cầu Vàng + Tìm cầu làm trọng tâm).
> - **Dữ liệu**: Phương án C - Cơ chế Hybrid (Kéo endpoint `soicau.php` Rồng Bạch Kim + Quét ma trận SQLite khi offline).

### 1. Xây dựng Dữ liệu & Service Soi Cầu
- [x] ✅ Xây dựng `SoiCauModel` (DTO chứa danh sách cặp số, số lượng cầu lặp, vị trí ghép cầu $vt_1 \times vt_2$, lịch sử các ngày chạy cầu).
- [x] ✅ Xây dựng `SoiCauService`:
  - [x] ✅ Tích hợp Endpoint 1: Quét danh sách cầu đẹp (`soicau.php?soi...`).
  - [x] ✅ Tích hợp Endpoint 2: Lấy chi tiết lịch sử đường chạy cầu theo vị trí (`soicau.php?sendhtml&showcau...`).
  - [x] ✅ Tích hợp Endpoint 3: Tìm cầu cho con số bất kỳ (`soicau.php?soi&setmode=num...`).
  - [x] ✅ Thuật toán Offline Fallback: Quét ma trận vị trí 107 chữ số trong bảng kết quả SQLite khi không có mạng.
- [x] ✅ Tích hợp quản lý state vào `LotteryProvider` (hoặc tạo `SoiCauProvider` riêng biệt).

### 2. Thiết kế Màn hình Soi Cầu (`soi_cau_screen.dart`)
- [x] ✅ **Thanh tìm kiếm số nổi bật đầu trang**: Ô nhập số (VD: `79`) + Nút "Tìm cầu" để tra cứu ngay các đường cầu đang chỉ về số đó.
- [x] ✅ **Khối "Top Cầu Vàng Hôm Nay"**: Card lớn làm nổi bật các cặp số có nhiều vị trí cầu trùng nhất (VD: `23 - 32: 7 cầu 🔥`, `08 - 80: 4 cầu`...).
- [x] ✅ **Bộ lọc Biên độ chạy cầu**: Thanh chọn nhanh số ngày cầu chạy liên tiếp ($3, 4, 5, 6...$ ngày).
- [x] ✅ **Khu vực phân loại cầu**:
  - [x] ✅ Danh sách Cầu Lô Tô.
  - [x] ✅ Danh sách Cầu 2 Nháy.
  - [x] ✅ Danh sách Cầu Đặc Biệt.
- [x] ✅ **Nút tiện ích "Sao chép dàn số"**: 1 chạm copy nhanh danh sách cầu đẹp để lưu hoặc chia sẻ.
- [x] ✅ **Cửa sổ chi tiết đường chạy cầu (BottomSheet / Dialog)**:
  - Hiển thị trực quan bảng kết quả các ngày trước ($N-1, N-2, N-3, N-4, N-5$).
  - Highlight 2 vị trí chữ số tạo cầu (màu xanh lam) và cặp số nổ tương ứng (màu đỏ/vàng).

### 3. Cập nhật Điều hướng & Menu đáy
- [x] ✅ Thay thế Tab "Lô Top / Lô Gan" cũ trong `main_layout.dart` thành Tab **"Soi Cầu"** (Icon `Icons.auto_awesome`).
- [x] ✅ Cập nhật tuyến đường `/soi_cau` trong `app_routes.dart` và gỡ bỏ trang Số Vắng cũ.

---

## Ⅳ. PHẦN 3: KIỂM THỬ & TỐI ƯU HÓA (Testing & Polishing)

- [x] ✅ Kiểm tra tốc độ kéo dữ liệu online từ Rồng Bạch Kim cho cả 2 màn hình.
- [x] ✅ Kiểm tra kịch bản Offline (Ngắt mạng và xác nhận app tự động tính toán từ SQLite không bị treo/lỗi).
- [x] ✅ Kiểm tra giao diện trên cả 2 chế độ Sáng (Light Mode) và Tối (Dark Mode).
- [x] ✅ Chuẩn hóa màu sắc 100% theo `AppTheme` của dự án gốc (không dùng mã màu thô cũ của Rồng Bạch Kim, đảm bảo đồng bộ hoàn hảo với Bảng Kết Quả và Header sẵn có).
- [x] ✅ Chạy kiểm tra tĩnh (`flutter analyze` / linter) đảm bảo 0 lỗi biên dịch, code sạch và sẵn sàng build APK.
