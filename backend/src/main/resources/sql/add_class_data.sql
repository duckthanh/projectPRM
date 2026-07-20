-- =====================================================
-- SQL Script: Thêm dữ liệu lớp học và gán học sinh
-- =====================================================

-- 1. Thêm các lớp học
INSERT INTO school_classes (code, name, grade_level, active) VALUES
('10A1', 'Lớp 10A1', 'Khối 10', true),
('10A2', 'Lớp 10A2', 'Khối 10', true),
('11A1', 'Lớp 11A1', 'Khối 11', true),
('11A2', 'Lớp 11A2', 'Khối 11', true),
('12A1', 'Lớp 12A1', 'Khối 12', true)
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 2. Thêm các môn học
INSERT INTO subjects (code, name, active) VALUES
('TOAN', 'Toán học', true),
('VAN', 'Ngữ văn', true),
('ANH', 'Tiếng Anh', true),
('LY', 'Vật lý', true),
('HOA', 'Hóa học', true),
('SINH', 'Sinh học', true),
('SU', 'Lịch sử', true),
('DIA', 'Địa lý', true),
('TIN', 'Tin học', true),
('GDCD', 'Giáo dục công dân', true)
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 3. Xem danh sách lớp
SELECT * FROM school_classes;

-- 4. Xem danh sách môn học
SELECT * FROM subjects;

-- =====================================================
-- Gán học sinh vào lớp
-- =====================================================

-- Lấy ID của lớp 10A1
SET @class_10a1 = (SELECT id FROM school_classes WHERE code = '10A1');

-- Gán user có id = 1 vào lớp 10A1
-- INSERT INTO user_classes (user_id, class_id) VALUES (1, @class_10a1);

-- Hoặc gán bằng phone number:
-- INSERT INTO user_classes (user_id, class_id)
-- SELECT u.id, @class_10a1
-- FROM users u
-- WHERE u.phone_number = '0123456789';

-- =====================================================
-- Thêm nhiều học sinh mẫu
-- =====================================================

-- Tạo học sinh mẫu (password: 123456 đã mã hóa BCrypt)
-- Bạn cần chạy lệnh này từ ứng dụng hoặc sử dụng password đã hash

-- Ví dụ thêm học sinh thủ công (nếu chưa có):
-- INSERT INTO users (phone_number, password, full_name, class_name, created_at) VALUES
-- ('0901000001', '$2a$10$...', 'Nguyễn Văn A', '10A1', NOW()),
-- ('0901000002', '$2a$10$...', 'Trần Thị B', '10A1', NOW()),
-- ('0901000003', '$2a$10$...', 'Lê Văn C', '10A1', NOW());

-- =====================================================
-- Gán role USER cho học sinh
-- =====================================================

-- SET @user_role = (SELECT id FROM roles WHERE code = 'USER');
-- INSERT INTO user_roles (user_id, role_id)
-- SELECT id, @user_role FROM users WHERE phone_number IN ('0901000001', '0901000002', '0901000003');

-- =====================================================
-- Kiểm tra học sinh trong lớp
-- =====================================================
SELECT 
    sc.code as class_code,
    sc.name as class_name,
    u.id as student_id,
    u.full_name,
    u.phone_number
FROM school_classes sc
LEFT JOIN user_classes uc ON sc.id = uc.class_id
LEFT JOIN users u ON uc.user_id = u.id
ORDER BY sc.code, u.full_name;
