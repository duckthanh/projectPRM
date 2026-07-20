-- =====================================================
-- SQL Script: Tạo bảng applications (đơn từ)
-- =====================================================

-- Tạo bảng applications
CREATE TABLE IF NOT EXISTS applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    teacher_id INT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    response_note TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NULL,
    responded_at DATETIME NULL,
    
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_student_id (student_id),
    INDEX idx_teacher_id (teacher_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Xem cấu trúc bảng
DESCRIBE applications;

-- =====================================================
-- Thêm đơn mẫu (tùy chọn)
-- =====================================================

-- Thêm đơn xin nghỉ phép (thay student_id phù hợp)
-- INSERT INTO applications (student_id, type, title, content, status, created_at) VALUES
-- (2, 'LEAVE', 'Xin nghỉ phép ngày 20/03', 'Em xin phép nghỉ học ngày 20/03/2026 vì lý do gia đình.', 'PENDING', NOW()),
-- (2, 'LATE', 'Xin đi muộn buổi sáng', 'Em xin phép đi muộn 15 phút buổi sáng ngày mai do có việc gia đình.', 'PENDING', NOW());

-- Xem danh sách đơn
SELECT 
    a.id,
    a.type,
    a.title,
    a.status,
    u.full_name as student_name,
    t.full_name as teacher_name,
    a.created_at
FROM applications a
JOIN users u ON a.student_id = u.id
LEFT JOIN users t ON a.teacher_id = t.id
ORDER BY a.created_at DESC;
