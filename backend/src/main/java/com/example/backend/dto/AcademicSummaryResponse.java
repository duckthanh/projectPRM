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
public class AcademicSummaryResponse {
    private Integer studentId;
    private String studentName;
    private String className;
    private String academicYear;
    private Double semester1Average;
    private Double semester2Average;
    private Double yearlyAverage;
    private List<SubjectSummary> subjects;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubjectSummary {
        private Integer subjectId;
        private String subjectName;
        private Double semester1Average;
        private Double semester2Average;
        private Double yearlyAverage;
        private Integer semester1ScoreCount;
        private Integer semester2ScoreCount;
    }
}
