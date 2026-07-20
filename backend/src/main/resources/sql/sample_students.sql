-- =====================================================
-- SQL Script: Thêm học sinh mẫu vào lớp
-- Chạy từng bước theo thứ tự
-- =====================================================

-- BƯỚC 1: Thêm lớp học
INSERT INTO school_classes (code, name, grade_level, active) VALUES
('10A1', 'Lớp 10A1', 'Khối 10', true),
('10A2', 'Lớp 10A2', 'Khối 10', true),
('11A1', 'Lớp 11A1', 'Khối 11', true)
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- BƯỚC 2: Thêm môn học
INSERT INTO subjects (code, name, active) VALUES
('TOAN', 'Toán học', true),
('VAN', 'Ngữ văn', true),
('ANH', 'Tiếng Anh', true),
('LY', 'Vật lý', true),
('HOA', 'Hóa học', true)
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- BƯỚC 3: Xem users hiện có
SELECT id, phone_number, full_name, class_name FROM users;

-- BƯỚC 4: Gán học sinh vào lớp (thay user_id và class_id phù hợp)
-- Ví dụ: user_id=2 vào lớp 10A1 (class_id=1)
INSERT INTO user_classes (user_id, class_id) VALUES (2, 1);

-- BƯỚC 5: Thêm điểm mẫu cho học sinh
-- Thay user_id và subject_id phù hợp
INSERT INTO scores (user_id, subject_id, score, coefficient, created_at, academic_year, semester) VALUES
(2, 1, 8.5, 2.0, NOW(), '2025-2026', 2),  -- Toán hệ số 2
(2, 2, 7.5, 2.0, NOW(), '2025-2026', 2),  -- Văn hệ số 2
(2, 3, 9.0, 1.0, NOW(), '2025-2026', 2),  -- Anh hệ số 1
(2, 4, 7.0, 1.0, NOW(), '2025-2026', 2),  -- Lý hệ số 1
(2, 5, 8.0, 1.0, NOW(), '2025-2026', 2);  -- Hóa hệ số 1

-- BƯỚC 6: Kiểm tra kết quả
SELECT 
    u.id,
    u.full_name,
    sc.name as class_name,
    s.name as subject,
    sc2.score,
    sc2.coefficient
FROM users u
JOIN user_classes uc ON u.id = uc.user_id
JOIN school_classes sc ON uc.class_id = sc.id
LEFT JOIN scores sc2 ON u.id = sc2.user_id
LEFT JOIN subjects s ON sc2.subject_id = s.id
ORDER BY u.id, s.name;
