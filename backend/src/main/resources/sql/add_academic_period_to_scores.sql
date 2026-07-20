-- Bổ sung năm học và học kỳ cho bảng điểm.
ALTER TABLE scores
    ADD COLUMN IF NOT EXISTS academic_year VARCHAR(9) NULL,
    ADD COLUMN IF NOT EXISTS semester INT NULL;

-- Gán dữ liệu cũ theo ngày tạo: tháng 8-12 là HK1, tháng 1-7 là HK2.
UPDATE scores
SET academic_year = CONCAT(
        IF(MONTH(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')) >= 8,
           YEAR(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')),
           YEAR(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')) - 1),
        '-',
        IF(MONTH(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')) >= 8,
           YEAR(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')) + 1,
           YEAR(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')))
    ),
    semester = IF(MONTH(STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s')) >= 8, 1, 2)
WHERE academic_year IS NULL OR academic_year = '' OR semester NOT IN (1, 2);

ALTER TABLE scores
    MODIFY academic_year VARCHAR(9) NOT NULL,
    MODIFY semester INT NOT NULL;

CREATE INDEX idx_scores_academic_period
    ON scores (user_id, academic_year, semester);
