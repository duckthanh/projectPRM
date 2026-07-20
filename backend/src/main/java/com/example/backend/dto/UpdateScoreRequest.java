package com.example.backend.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateScoreRequest {

    @Min(value = 0, message = "Score must be at least 0")
    @Max(value = 10, message = "Score must be at most 10")
    private Double score;

    @Min(value = 1, message = "Coefficient must be at least 1")
    @Max(value = 3, message = "Coefficient must be at most 3")
    private Double coefficient;

    @Pattern(regexp = "\\d{4}-\\d{4}", message = "Academic year must have format YYYY-YYYY")
    private String academicYear;

    @Min(value = 1, message = "Semester must be 1 or 2")
    @Max(value = 2, message = "Semester must be 1 or 2")
    private Integer semester;
}
