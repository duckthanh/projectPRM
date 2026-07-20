package com.example.backend.controller;

import com.example.backend.dto.ApplicationResponse;
import com.example.backend.dto.CreateApplicationRequest;
import com.example.backend.dto.RespondApplicationRequest;
import com.example.backend.security.CustomUserDetails;
import com.example.backend.service.ApplicationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/applications")
@RequiredArgsConstructor
public class ApplicationController {

    private final ApplicationService applicationService;

    /**
     * Học sinh gửi đơn mới
     * POST /api/applications
     */
    @PostMapping
    public ResponseEntity<ApplicationResponse> createApplication(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody CreateApplicationRequest request) {
        ApplicationResponse response = applicationService.createApplication(
                userDetails.getUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * Học sinh xem danh sách đơn đã gửi
     * GET /api/applications/my
     */
    @GetMapping("/my")
    public ResponseEntity<List<ApplicationResponse>> getMyApplications(
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        return ResponseEntity.ok(
                applicationService.getApplicationsByStudent(userDetails.getUserId()));
    }

    /**
     * Xem chi tiết một đơn
     * GET /api/applications/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApplicationResponse> getApplication(@PathVariable Integer id) {
        return ResponseEntity.ok(applicationService.getApplicationById(id));
    }

    /**
     * Học sinh xóa đơn (chỉ đơn PENDING)
     * DELETE /api/applications/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteApplication(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Integer id) {
        applicationService.deleteApplication(id, userDetails.getUserId());
        return ResponseEntity.ok(Map.of("message", "Đã xóa đơn thành công"));
    }

    /**
     * Giáo viên xem danh sách đơn cần duyệt
     * GET /api/applications/pending
     */
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<ApplicationResponse>> getPendingApplications(
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        return ResponseEntity.ok(
                applicationService.getApplicationsForTeacher(userDetails.getUserId()));
    }

    /**
     * Giáo viên xem tất cả đơn chờ duyệt
     * GET /api/applications/all-pending
     */
    @GetMapping("/all-pending")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<ApplicationResponse>> getAllPendingApplications() {
        return ResponseEntity.ok(applicationService.getAllPendingApplications());
    }

    /**
     * Giáo viên xem tất cả đơn từ
     * GET /api/applications/all
     */
    @GetMapping("/all")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<List<ApplicationResponse>> getAllApplications() {
        return ResponseEntity.ok(applicationService.getAllApplications());
    }

    /**
     * Giáo viên duyệt/từ chối đơn
     * PUT /api/applications/{id}/respond
     */
    @PutMapping("/{id}/respond")
    @PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
    public ResponseEntity<ApplicationResponse> respondToApplication(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @PathVariable Integer id,
            @Valid @RequestBody RespondApplicationRequest request) {
        ApplicationResponse response = applicationService.respondToApplication(
                id, userDetails.getUserId(), request);
        return ResponseEntity.ok(response);
    }
}
