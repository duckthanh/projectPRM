-- Chạy thủ công nếu Hibernate không tự thêm cột (bảng otps đã có dữ liệu).
ALTER TABLE otps
    ADD COLUMN purpose VARCHAR(32) NOT NULL DEFAULT 'PASSWORD_RESET' AFTER used;
