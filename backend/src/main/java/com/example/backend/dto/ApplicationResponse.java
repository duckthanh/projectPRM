package com.example.backend.dto;

import com.example.backend.entity.ApplicationEntity;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplicationResponse {

    private Integer id;
    private String type;
    private String title;
    private String content;
    private String status;
    private String responseNote;
    private String createdAt;
    private String updatedAt;
    private String respondedAt;
    private StudentInfo student;
    private TeacherInfo teacher;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StudentInfo {
        private Integer id;
        private String fullName;
        private String phoneNumber;
        private String className;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TeacherInfo {
        private Integer id;
        private String fullName;
        private String phoneNumber;
    }

    public static ApplicationResponse fromEntity(ApplicationEntity entity) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

        ApplicationResponseBuilder builder = ApplicationResponse.builder()
                .id(entity.getId())
                .type(entity.getType())
                .title(entity.getTitle())
                .content(entity.getContent())
                .status(entity.getStatus())
                .responseNote(entity.getResponseNote())
                .createdAt(entity.getCreatedAt() != null ? entity.getCreatedAt().format(formatter) : null)
                .updatedAt(entity.getUpdatedAt() != null ? entity.getUpdatedAt().format(formatter) : null)
                .respondedAt(entity.getRespondedAt() != null ? entity.getRespondedAt().format(formatter) : null);

        if (entity.getStudent() != null) {
            builder.student(StudentInfo.builder()
                    .id(entity.getStudent().getId())
                    .fullName(entity.getStudent().getFullName())
                    .phoneNumber(entity.getStudent().getPhoneNumber())
                    .className(entity.getStudent().getClassName())
                    .build());
        }

        if (entity.getTeacher() != null) {
            builder.teacher(TeacherInfo.builder()
                    .id(entity.getTeacher().getId())
                    .fullName(entity.getTeacher().getFullName())
                    .phoneNumber(entity.getTeacher().getPhoneNumber())
                    .build());
        }

        return builder.build();
    }
}
