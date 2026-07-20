package com.example.backend.controller;

import com.example.backend.dto.ClassStatisticsResponse;
import com.example.backend.dto.AcademicSummaryResponse;
import com.example.backend.dto.CreateScoreRequest;
import com.example.backend.dto.StudentScoreResponse;
import com.example.backend.dto.ScoreImportResponse;
import com.example.backend.dto.UpdateScoreRequest;
import com.example.backend.entity.ScoreEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.service.TeacherService;
import com.example.backend.service.ScoreExcelImportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.MediaType;
import org.springframework.http.HttpHeaders;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/teacher")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
public class TeacherController {

    private final TeacherService teacherService;
    private final ScoreExcelImportService scoreExcelImportService;

    /**
     * Lấy danh sách học sinh trong lớp
     * GET /api/teacher/class/{classId}/students
     */
    @GetMapping("/class/{classId}/students")
    public ResponseEntity<List<UserEntity>> getStudentsByClass(@PathVariable Integer classId) {
        return ResponseEntity.ok(teacherService.getStudentsByClass(classId));
    }

    /**
     * Lấy điểm tất cả học sinh trong lớp
     * GET /api/teacher/class/{classId}/scores
     */
    @GetMapping("/class/{classId}/scores")
    public ResponseEntity<List<StudentScoreResponse>> getClassScores(
            @PathVariable Integer classId,
            @RequestParam(required = false) String academicYear,
            @RequestParam(required = false) Integer semester) {
        return ResponseEntity.ok(teacherService.getStudentScoresByClass(classId, academicYear, semester));
    }

    /**
     * Lấy điểm của một học sinh
     * GET /api/teacher/student/{studentId}/scores
     */
    @GetMapping("/student/{studentId}/scores")
    public ResponseEntity<StudentScoreResponse> getStudentScores(
            @PathVariable Integer studentId,
            @RequestParam(required = false) String academicYear,
            @RequestParam(required = false) Integer semester) {
        return ResponseEntity.ok(teacherService.getStudentScores(studentId, academicYear, semester));
    }

    @GetMapping("/student/{studentId}/academic-summary")
    public ResponseEntity<AcademicSummaryResponse> getAcademicSummary(
            @PathVariable Integer studentId,
            @RequestParam(required = false) String academicYear) {
        return ResponseEntity.ok(teacherService.getAcademicSummary(studentId, academicYear));
    }

    /**
     * Thống kê điểm theo lớp
     * GET /api/teacher/class/{classId}/statistics
     */
    @GetMapping("/class/{classId}/statistics")
    public ResponseEntity<ClassStatisticsResponse> getClassStatistics(
            @PathVariable Integer classId,
            @RequestParam(required = false) String academicYear,
            @RequestParam(required = false) Integer semester) {
        return ResponseEntity.ok(teacherService.getClassStatistics(classId, academicYear, semester));
    }

    /**
     * Nhập điểm cho học sinh
     * POST /api/teacher/scores
     */
    @PostMapping("/scores")
    public ResponseEntity<ScoreEntity> createScore(@Valid @RequestBody CreateScoreRequest request) {
        ScoreEntity score = teacherService.createScore(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(score);
    }

    @PostMapping(value = "/scores/import/preview", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ScoreImportResponse> previewScoreImport(
            @RequestParam Integer classId,
            @RequestParam String academicYear,
            @RequestParam Integer semester,
            @RequestParam MultipartFile file) {
        return ResponseEntity.ok(scoreExcelImportService.preview(
                classId, academicYear, semester, file));
    }

    @GetMapping(value = "/scores/import/template", produces =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    public ResponseEntity<byte[]> downloadScoreImportTemplate() {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=score-import-template.xlsx")
                .body(scoreExcelImportService.createTemplate());
    }

    @PostMapping(value = "/scores/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ScoreImportResponse> importScores(
            @RequestParam Integer classId,
            @RequestParam String academicYear,
            @RequestParam Integer semester,
            @RequestParam MultipartFile file) {
        return ResponseEntity.ok(scoreExcelImportService.importScores(
                classId, academicYear, semester, file));
    }

    /**
     * Cập nhật điểm
     * PUT /api/teacher/scores/{scoreId}
     */
    @PutMapping("/scores/{scoreId}")
    public ResponseEntity<ScoreEntity> updateScore(
            @PathVariable Integer scoreId,
            @Valid @RequestBody UpdateScoreRequest request) {
        return ResponseEntity.ok(teacherService.updateScore(scoreId, request));
    }

    /**
     * Xóa điểm
     * DELETE /api/teacher/scores/{scoreId}
     */
    @DeleteMapping("/scores/{scoreId}")
    public ResponseEntity<Map<String, String>> deleteScore(@PathVariable Integer scoreId) {
        teacherService.deleteScore(scoreId);
        return ResponseEntity.ok(Map.of("message", "Đã xóa điểm thành công"));
    }
}
