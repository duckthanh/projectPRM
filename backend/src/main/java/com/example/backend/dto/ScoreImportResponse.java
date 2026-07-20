package com.example.backend.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class ScoreImportResponse {
    private int totalRows;
    private int validRows;
    private int duplicateRows;
    private int errorRows;
    private int importedRows;
    private boolean canImport;
    private String message;
    private List<RowResult> rows;

    @Data
    @Builder
    public static class RowResult {
        private int rowNumber;
        private String phoneNumber;
        private String studentName;
        private String subjectCode;
        private Double score;
        private Double coefficient;
        private String status;
        private String message;
    }
}
