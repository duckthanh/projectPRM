package com.example.backend.util;

import java.time.LocalDate;

public final class AcademicPeriodUtils {

    private AcademicPeriodUtils() {
    }

    public static String currentAcademicYear() {
        LocalDate today = LocalDate.now();
        int startYear = today.getMonthValue() >= 8 ? today.getYear() : today.getYear() - 1;
        return startYear + "-" + (startYear + 1);
    }

    public static int currentSemester() {
        int month = LocalDate.now().getMonthValue();
        return month >= 8 ? 1 : 2;
    }

    public static String normalizeAcademicYear(String academicYear) {
        String value = academicYear == null || academicYear.isBlank()
                ? currentAcademicYear()
                : academicYear.trim();
        if (!value.matches("\\d{4}-\\d{4}")) {
            throw new IllegalArgumentException("Năm học phải có định dạng YYYY-YYYY");
        }
        int start = Integer.parseInt(value.substring(0, 4));
        int end = Integer.parseInt(value.substring(5));
        if (end != start + 1) {
            throw new IllegalArgumentException("Năm học phải gồm hai năm liên tiếp");
        }
        return value;
    }

    public static int normalizeSemester(Integer semester) {
        int value = semester == null ? currentSemester() : semester;
        if (value != 1 && value != 2) {
            throw new IllegalArgumentException("Học kỳ chỉ nhận giá trị 1 hoặc 2");
        }
        return value;
    }
}
