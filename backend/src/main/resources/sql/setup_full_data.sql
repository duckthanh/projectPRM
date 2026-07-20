-- =====================================================
-- SETUP DATA ĐẦY ĐỦ CHO HỆ THỐNG TRƯỜNG HỌC
-- Chạy toàn bộ script này trong MySQL Workbench
-- =====================================================

-- 1. THÊM LỚP HỌC (Khối 10, 11, 12)
INSERT INTO school_classes (code, name, grade_level, active) VALUES
('10A1', 'Lớp 10A1', 'Khối 10', true),
('10A2', 'Lớp 10A2', 'Khối 10', true),
('10A3', 'Lớp 10A3', 'Khối 10', true),
('11A1', 'Lớp 11A1', 'Khối 11', true),
('11A2', 'Lớp 11A2', 'Khối 11', true),
('11A3', 'Lớp 11A3', 'Khối 11', true),
('12A1', 'Lớp 12A1', 'Khối 12', true),
('12A2', 'Lớp 12A2', 'Khối 12', true),
('12A3', 'Lớp 12A3', 'Khối 12', true)
ON DUPLICATE KEY UPDATE name = VALUES(name), grade_level = VALUES(grade_level);

-- 2. THÊM MÔN HỌC
INSERT INTO subjects (code, name, credits, active) VALUES
('TOAN', 'Toán học', 2, true),
('VAN', 'Ngữ văn', 2, true),
('ANH', 'Tiếng Anh', 2, true),
('LY', 'Vật lý', 1, true),
('HOA', 'Hóa học', 1, true),
('SINH', 'Sinh học', 1, true),
('SU', 'Lịch sử', 1, true),
('DIA', 'Địa lý', 1, true),
('TIN', 'Tin học', 1, true),
('GDCD', 'GDCD', 1, true)
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- 3. XEM DANH SÁCH LỚP VÀ MÔN
SELECT * FROM school_classes ORDER BY code;
SELECT * FROM subjects ORDER BY code;

-- 4. GÁN HỌC SINH VÀO LỚP
-- Lấy ID lớp 10A1
SET @class_10a1 = (SELECT id FROM school_classes WHERE code = '10A1');

-- Gán user id=2 (Do Xuan Phong) vào lớp 10A1
INSERT INTO user_classes (user_id, class_id) 
SELECT 2, @class_10a1
WHERE NOT EXISTS (SELECT 1 FROM user_classes WHERE user_id = 2 AND class_id = @class_10a1);

-- Cập nhật class_name trong users table
UPDATE users SET class_name = '10A1' WHERE id = 2;

-- 5. THÊM ĐIỂM MẪU CHO HỌC SINH
-- Lấy ID môn học
SET @toan = (SELECT id FROM subjects WHERE code = 'TOAN');
SET @van = (SELECT id FROM subjects WHERE code = 'VAN');
SET @anh = (SELECT id FROM subjects WHERE code = 'ANH');
SET @ly = (SELECT id FROM subjects WHERE code = 'LY');
SET @hoa = (SELECT id FROM subjects WHERE code = 'HOA');

-- Xóa điểm cũ nếu có
DELETE FROM scores WHERE user_id = 2;

-- Thêm điểm mới
INSERT INTO scores (user_id, subject_id, score, coefficient, created_at, academic_year, semester) VALUES
(2, @toan, 8.5, 2.0, NOW(), '2025-2026', 2),
(2, @toan, 7.5, 1.0, NOW(), '2025-2026', 2),
(2, @van, 7.0, 2.0, NOW(), '2025-2026', 2),
(2, @van, 8.0, 1.0, NOW(), '2025-2026', 2),
(2, @anh, 9.0, 2.0, NOW(), '2025-2026', 2),
(2, @ly, 7.5, 1.0, NOW(), '2025-2026', 2),
(2, @hoa, 8.0, 1.0, NOW(), '2025-2026', 2);

-- 6. KIỂM TRA KẾT QUẢ
SELECT 
    u.id as user_id,
    u.full_name,
    u.phone_number,
    sc.code as class_code,
    sc.name as class_name,
    GROUP_CONCAT(r.code) as roles
FROM users u
LEFT JOIN user_classes uc ON u.id = uc.user_id
LEFT JOIN school_classes sc ON uc.class_id = sc.id
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
GROUP BY u.id;

-- 7. XEM ĐIỂM HỌC SINH
SELECT 
    u.full_name,
    s.name as subject,
    sc.score,
    sc.coefficient
FROM scores sc
JOIN users u ON sc.user_id = u.id
JOIN subjects s ON sc.subject_id = s.id
ORDER BY u.full_name, s.name;
