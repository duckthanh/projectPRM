package com.example.backend.service;

import com.example.backend.dto.AcademicSummaryResponse;
import com.example.backend.entity.ScoreEntity;
import com.example.backend.repository.ScoreRepository;
import com.example.backend.util.AcademicPeriodUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ScoreService {

    private final ScoreRepository scoreRepository;

    public List<ScoreEntity> getAllScores() {
        return scoreRepository.findAll();
    }

    public List<ScoreEntity> getScoresByUserId(Integer userId) {
        return scoreRepository.findByUserId(userId);
    }

    public List<ScoreEntity> getScoresByUserId(Integer userId, String academicYear, Integer semester) {
        String year = AcademicPeriodUtils.normalizeAcademicYear(academicYear);
        int term = AcademicPeriodUtils.normalizeSemester(semester);
        return scoreRepository.findByUserIdAndAcademicYearAndSemester(userId, year, term);
    }

    public List<String> getAcademicYears(Integer userId) {
        List<String> years = new ArrayList<>(scoreRepository.findAcademicYearsByUserId(userId));
        String current = AcademicPeriodUtils.currentAcademicYear();
        if (!years.contains(current)) years.add(0, current);
        return years;
    }

    public AcademicSummaryResponse getAcademicSummary(Integer userId, String academicYear) {
        String year = AcademicPeriodUtils.normalizeAcademicYear(academicYear);
        List<ScoreEntity> scores = scoreRepository.findByUserIdAndAcademicYear(userId, year);

        Map<Integer, List<ScoreEntity>> grouped = new LinkedHashMap<>();
        scores.stream()
                .sorted(Comparator.comparing(score -> score.getSubject().getName()))
                .forEach(score -> grouped.computeIfAbsent(score.getSubject().getId(), key -> new ArrayList<>()).add(score));

        List<AcademicSummaryResponse.SubjectSummary> subjects = new ArrayList<>();
        List<Double> semester1Subjects = new ArrayList<>();
        List<Double> semester2Subjects = new ArrayList<>();
        List<Double> yearlySubjects = new ArrayList<>();

        for (List<ScoreEntity> subjectScores : grouped.values()) {
            List<ScoreEntity> semester1 = subjectScores.stream().filter(score -> score.getSemester() == 1).toList();
            List<ScoreEntity> semester2 = subjectScores.stream().filter(score -> score.getSemester() == 2).toList();
            Double semester1Average = weightedAverageOrNull(semester1);
            Double semester2Average = weightedAverageOrNull(semester2);
            Double yearlyAverage = semester1Average != null && semester2Average != null
                    ? round2((semester1Average + semester2Average * 2) / 3)
                    : null;

            if (semester1Average != null) semester1Subjects.add(semester1Average);
            if (semester2Average != null) semester2Subjects.add(semester2Average);
            if (yearlyAverage != null) yearlySubjects.add(yearlyAverage);

            ScoreEntity sample = subjectScores.get(0);
            subjects.add(AcademicSummaryResponse.SubjectSummary.builder()
                    .subjectId(sample.getSubject().getId())
                    .subjectName(sample.getSubject().getName())
                    .semester1Average(semester1Average)
                    .semester2Average(semester2Average)
                    .yearlyAverage(yearlyAverage)
                    .semester1ScoreCount(semester1.size())
                    .semester2ScoreCount(semester2.size())
                    .build());
        }

        ScoreEntity sample = scores.isEmpty() ? null : scores.get(0);
        return AcademicSummaryResponse.builder()
                .studentId(userId)
                .studentName(sample == null ? null : sample.getUser().getFullName())
                .className(sample == null ? null : sample.getUser().getClassName())
                .academicYear(year)
                .semester1Average(simpleAverageOrNull(semester1Subjects))
                .semester2Average(simpleAverageOrNull(semester2Subjects))
                .yearlyAverage(simpleAverageOrNull(yearlySubjects))
                .subjects(subjects)
                .build();
    }

    public Optional<ScoreEntity> getScoreById(Integer id) {
        return scoreRepository.findById(id);
    }

    public ScoreEntity createScore(ScoreEntity score) {
        if (score.getCreatedAt() == null || score.getCreatedAt().isEmpty()) {
            score.setCreatedAt(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }
        if (score.getCoefficient() == null) {
            score.setCoefficient(1.0);
        }
        score.setAcademicYear(AcademicPeriodUtils.normalizeAcademicYear(score.getAcademicYear()));
        score.setSemester(AcademicPeriodUtils.normalizeSemester(score.getSemester()));
        return scoreRepository.save(score);
    }

    public ScoreEntity updateScore(ScoreEntity score) {
        score.setAcademicYear(AcademicPeriodUtils.normalizeAcademicYear(score.getAcademicYear()));
        score.setSemester(AcademicPeriodUtils.normalizeSemester(score.getSemester()));
        return scoreRepository.save(score);
    }

    public void deleteScore(Integer id) {
        scoreRepository.deleteById(id);
    }

    private Double weightedAverageOrNull(List<ScoreEntity> scores) {
        if (scores.isEmpty()) return null;
        double weighted = 0;
        double coefficients = 0;
        for (ScoreEntity score : scores) {
            weighted += score.getScore() * score.getCoefficient();
            coefficients += score.getCoefficient();
        }
        return coefficients == 0 ? null : round2(weighted / coefficients);
    }

    private Double simpleAverageOrNull(List<Double> values) {
        return values.isEmpty() ? null : round2(values.stream().mapToDouble(Double::doubleValue).average().orElse(0));
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
