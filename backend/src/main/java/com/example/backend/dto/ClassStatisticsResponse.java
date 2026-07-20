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
public class ClassStatisticsResponse {

    private Integer classId;
    private String className;
    private Integer totalStudents;
    private Double classAverageScore;
    private Integer excellentCount;    // >= 8.5
    private Integer goodCount;          // >= 7.0
    private Integer averageCount;       // >= 5.0
    private Integer belowAverageCount;  // < 5.0
    private List<SubjectStatistics> subjectStatistics;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SubjectStatistics {
        private Integer subjectId;
        private String subjectName;
        private Double averageScore;
        private Double highestScore;
        private Double lowestScore;
    }
}
