// 📦 Module user chia thành nhiều phần nhỏ để dễ bảo trì
pub mod router;
pub mod handler; // Xử lý HTTP request
pub mod command; // Các lệnh ghi (CQRS)
pub mod query;   // Các truy vấn dữ liệu
pub mod model;   // Struct ánh xạ dữ liệu DB
pub mod dto;     // Dữ liệu từ client gửi lên
pub mod event;   // Định nghĩa các event cho hệ thống
pub mod metadata; // Cho phép bên ngoài truy cập `user::metadata::metadata()`