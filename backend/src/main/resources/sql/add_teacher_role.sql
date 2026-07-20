-- =====================================================
-- SQL Script: Thêm role TEACHER và phân quyền
-- =====================================================

-- 1. Thêm role TEACHER
INSERT INTO roles (code, name, description, active) 
VALUES ('TEACHER', 'Giáo viên', 'Giáo viên có quyền quản lý điểm học sinh', true)
ON DUPLICATE KEY UPDATE name = 'Giáo viên';

-- 2. Thêm role ADMIN (nếu chưa có)
INSERT INTO roles (code, name, description, active) 
VALUES ('ADMIN', 'Quản trị viên', 'Quản trị viên hệ thống', true)
ON DUPLICATE KEY UPDATE name = 'Quản trị viên';

-- 3. Xem danh sách roles
SELECT * FROM roles;

-- =====================================================
-- Gán role TEACHER cho user (thay đổi user_id phù hợp)
-- =====================================================

-- Lấy role_id của TEACHER
SET @teacher_role_id = (SELECT id FROM roles WHERE code = 'TEACHER');

-- Gán role TEACHER cho user có id = ? (thay ? bằng id user thực tế)
-- INSERT INTO user_roles (user_id, role_id) VALUES (?, @teacher_role_id);

-- =====================================================
-- Ví dụ: Gán TEACHER cho user có phone_number cụ thể
-- =====================================================
-- INSERT INTO user_roles (user_id, role_id) 
-- SELECT u.id, r.id 
-- FROM users u, roles r 
-- WHERE u.phone_number = '0987654321' AND r.code = 'TEACHER';

-- =====================================================
-- Kiểm tra user đã có role gì
-- =====================================================
SELECT u.id, u.full_name, u.phone_number, GROUP_CONCAT(r.code) as roles
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
GROUP BY u.id;
