package com.example.backend.service;

import com.example.backend.dto.ApplicationResponse;
import com.example.backend.dto.CreateApplicationRequest;
import com.example.backend.dto.RespondApplicationRequest;
import com.example.backend.entity.ApplicationEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.ApplicationRepository;
import com.example.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApplicationService {

    private final ApplicationRepository applicationRepository;
    private final UserRepository userRepository;

    @Transactional
    public ApplicationResponse createApplication(Integer studentId, CreateApplicationRequest request) {
        UserEntity student = userRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học sinh"));

        ApplicationEntity application = new ApplicationEntity();
        application.setStudent(student);
        application.setType(request.getType());
        application.setTitle(request.getTitle());
        application.setContent(request.getContent());
        application.setStatus("PENDING");

        if (request.getTeacherId() != null) {
            UserEntity teacher = userRepository.findById(request.getTeacherId())
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giáo viên"));
            application.setTeacher(teacher);
        }

        ApplicationEntity saved = applicationRepository.save(application);
        return ApplicationResponse.fromEntity(saved);
    }

    public List<ApplicationResponse> getApplicationsByStudent(Integer studentId) {
        return applicationRepository.findByStudentIdOrderByCreatedAtDesc(studentId)
                .stream()
                .map(ApplicationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ApplicationResponse> getApplicationsForTeacher(Integer teacherId) {
        return applicationRepository.findPendingForTeacher(teacherId)
                .stream()
                .map(ApplicationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ApplicationResponse> getAllPendingApplications() {
        return applicationRepository.findByStatusOrderByCreatedAtDesc("PENDING")
                .stream()
                .map(ApplicationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ApplicationResponse> getAllApplications() {
        return applicationRepository.findAllByOrderByCreatedAtDesc()
                .stream()
                .map(ApplicationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<ApplicationResponse> getApplicationsByTeacher(Integer teacherId) {
        return applicationRepository.findByTeacherIdOrderByCreatedAtDesc(teacherId)
                .stream()
                .map(ApplicationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public ApplicationResponse getApplicationById(Integer id) {
        ApplicationEntity application = applicationRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn"));
        return ApplicationResponse.fromEntity(application);
    }

    @Transactional
    public ApplicationResponse respondToApplication(Integer applicationId, Integer teacherId, RespondApplicationRequest request) {
        ApplicationEntity application = applicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn"));

        if (!"PENDING".equals(application.getStatus())) {
            throw new IllegalStateException("Đơn này đã được xử lý");
        }

        UserEntity teacher = userRepository.findById(teacherId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy giáo viên"));

        application.setTeacher(teacher);
        application.setStatus(request.getStatus());
        application.setResponseNote(request.getResponseNote());
        application.setRespondedAt(LocalDateTime.now());

        ApplicationEntity saved = applicationRepository.save(application);
        return ApplicationResponse.fromEntity(saved);
    }

    @Transactional
    public void deleteApplication(Integer applicationId, Integer studentId) {
        ApplicationEntity application = applicationRepository.findById(applicationId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy đơn"));

        if (!application.getStudent().getId().equals(studentId)) {
            throw new IllegalArgumentException("Bạn không có quyền xóa đơn này");
        }

        if (!"PENDING".equals(application.getStatus())) {
            throw new IllegalStateException("Không thể xóa đơn đã được xử lý");
        }

        applicationRepository.delete(application);
    }
}
