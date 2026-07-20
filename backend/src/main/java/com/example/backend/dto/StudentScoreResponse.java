package com.example.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentScoreResponse {

    private Integer studentId;
    private String studentName;
    private String className;
    private List<ScoreDetail> scores;
    private Double averageScore;
    private String academicYear;
    private Integer semester;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ScoreDetail {
        private Integer scoreId;
        private String subjectName;
        private Double score;
        private Double coefficient;
        private String createdAt;
        private String academicYear;
        private Integer semester;
    }
}
