-- Cột bật/tắt 2FA trên từng user (chạy thủ công nếu cần)
ALTER TABLE users
    ADD COLUMN two_factor_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER created_at;
