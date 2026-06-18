# 🛠️ Bộ công cụ Thiết lập & Tối ưu hóa Hệ điều hành (OS Setup Toolkit)

Tập hợp các script tự động hóa được thiết kế dành cho Quản trị viên hệ thống (SysAdmin) và kỹ thuật viên IT để thiết lập nhanh máy tính mới cho nhân viên, kiểm tra chuẩn đoán phần cứng, dọn dẹp hệ thống và quản lý cài đặt phần mềm.

---

## 🌟 Tính năng chính

### 1. Script tự động hóa cho Windows (`Configure-Windows.ps1`)
*   **Chuẩn đoán hệ thống:** Đọc nhanh thông tin phiên bản Windows, cấu hình RAM, và dung lượng ổ đĩa.
*   **Dọn dẹp tệp tin rác:** Quét dọn bộ nhớ đệm tạm thời (User Temp và System Temp) để giải phóng không gian ổ đĩa.
*   **Kiểm tra tường lửa:** Hiển thị trạng thái kích hoạt của các cấu hình bảo mật tường lửa (Firewall Profile).
*   **Chuẩn đoán mạng:** Đo lường độ trễ mạng và khả năng phân giải tên miền DNS.
*   **Kiểm kê phần mềm:** Tự động liệt kê danh sách các phần mềm đã cài đặt trên máy tính thông qua trình quản lý gói `Winget`.

### 2. Script tự động hóa cho Linux (`configure_linux.sh`)
*   **Thu thập cấu hình:** Đọc thông tin phiên bản Kernel, cấu hình bộ nhớ và ổ đĩa.
*   **Dọn dẹp hệ thống:** Xóa bộ nhớ cache của trình quản lý gói hệ thống (`apt-get clean`) khi chạy dưới quyền Root.
*   **Kiểm tra tường lửa:** Đọc nhanh cấu hình bảo mật UFW.

---

## 💻 Hướng dẫn chạy trên máy cá nhân

### Cách thực thi trên hệ điều hành Windows:
1.  Bấm nút Windows trên bàn phím, gõ **PowerShell** -> Click chuột phải chọn **Run as Administrator** (Chạy với quyền Quản trị).
2.  Di chuyển tới thư mục chứa script:
    ```powershell
    cd C:\Users\lenovo\Downloads\Project\13_os_setup_optimization_toolkit
    ```
3.  Cho phép thực thi script tạm thời trong phiên làm việc này và bắt đầu chạy:
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\Configure-Windows.ps1
    ```

### Cách thực thi trên hệ điều hành Linux:
1.  Mở Terminal tại thư mục dự án.
2.  Cấp quyền thực thi cho tệp script:
    ```bash
    chmod +x configure_linux.sh
    ```
3.  Chạy script chẩn đoán:
    ```bash
    ./configure_linux.sh
    ```
    *(Để chạy tính năng dọn dẹp cache hệ thống, sử dụng quyền sudo: `sudo ./configure_linux.sh`)*
