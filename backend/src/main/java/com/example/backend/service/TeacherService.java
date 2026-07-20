package com.example.backend.service;

import com.example.backend.dto.ClassStatisticsResponse;
import com.example.backend.dto.AcademicSummaryResponse;
import com.example.backend.dto.CreateScoreRequest;
import com.example.backend.dto.StudentScoreResponse;
import com.example.backend.dto.UpdateScoreRequest;
import com.example.backend.entity.ScoreEntity;
import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.entity.SubjectEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.SchoolClassRepository;
import com.example.backend.repository.ScoreRepository;
import com.example.backend.repository.SubjectRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.util.AcademicPeriodUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TeacherService {

    private final UserRepository userRepository;
    private final ScoreRepository scoreRepository;
    private final SubjectRepository subjectRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final ScoreService scoreService;

    public List<UserEntity> getStudentsByClass(Integer classId) {
        SchoolClassEntity schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học"));

        return schoolClass.getUsers().stream()
                .filter(user -> user.getRoles().stream()
                        .anyMatch(role -> "USER".equals(role.getCode()) || "STUDENT".equals(role.getCode())))
                .collect(Collectors.toList());
    }

    public List<StudentScoreResponse> getStudentScoresByClass(Integer classId, String academicYear, Integer semester) {
        String year = AcademicPeriodUtils.normalizeAcademicYear(academicYear);
        int term = AcademicPeriodUtils.normalizeSemester(semester);
        String className = schoolClassRepository.findById(classId)
                .map(SchoolClassEntity::getName)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học"));
        List<UserEntity> students = getStudentsByClass(classId);
        List<StudentScoreResponse> responses = new ArrayList<>();

        for (UserEntity student : students) {
            List<ScoreEntity> scores = scoreRepository.findByUserIdAndAcademicYearAndSemester(student.getId(), year, term);

            List<StudentScoreResponse.ScoreDetail> scoreDetails = scores.stream()
                    .map(score -> StudentScoreResponse.ScoreDetail.builder()
                            .scoreId(score.getId())
                            .subjectName(score.getSubject().getName())
                            .score(score.getScore())
                            .coefficient(score.getCoefficient())
                            .createdAt(score.getCreatedAt())
                            .academicYear(score.getAcademicYear())
                            .semester(score.getSemester())
                            .build())
                    .collect(Collectors.toList());

            double avgScore = calculateWeightedAverage(scores);

            responses.add(StudentScoreResponse.builder()
                    .studentId(student.getId())
                    .studentName(student.getFullName())
                    .className(className)
                    .scores(scoreDetails)
                    .averageScore(avgScore)
                    .academicYear(year)
                    .semester(term)
                    .build());
        }

        return responses;
    }

    public StudentScoreResponse getStudentScores(Integer studentId, String academicYear, Integer semester) {
        String year = AcademicPeriodUtils.normalizeAcademicYear(academicYear);
        int term = AcademicPeriodUtils.normalizeSemester(semester);
        UserEntity student = userRepository.findById(studentId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học sinh"));

        List<ScoreEntity> scores = scoreRepository.findByUserIdAndAcademicYearAndSemester(studentId, year, term);

        List<StudentScoreResponse.ScoreDetail> scoreDetails = scores.stream()
                .map(score -> StudentScoreResponse.ScoreDetail.builder()
                        .scoreId(score.getId())
                        .subjectName(score.getSubject().getName())
                        .score(score.getScore())
                        .coefficient(score.getCoefficient())
                        .createdAt(score.getCreatedAt())
                        .academicYear(score.getAcademicYear())
                        .semester(score.getSemester())
                        .build())
                .collect(Collectors.toList());

        double avgScore = calculateWeightedAverage(scores);

        return StudentScoreResponse.builder()
                .studentId(student.getId())
                .studentName(student.getFullName())
                .className(student.getClassName())
                .scores(scoreDetails)
                .averageScore(avgScore)
                .academicYear(year)
                .semester(term)
                .build();
    }

    public AcademicSummaryResponse getAcademicSummary(Integer studentId, String academicYear) {
        return scoreService.getAcademicSummary(studentId, academicYear);
    }

    @Transactional
    public ScoreEntity createScore(CreateScoreRequest request) {
        UserEntity student = userRepository.findById(request.getStudentId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy học sinh"));

        SubjectEntity subject = subjectRepository.findById(request.getSubjectId())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy môn học"));

        ScoreEntity score = new ScoreEntity();
        score.setUser(student);
        score.setSubject(subject);
        score.setScore(request.getScore());
        score.setCoefficient(request.getCoefficient() != null ? request.getCoefficient() : 1.0);
        score.setAcademicYear(AcademicPeriodUtils.normalizeAcademicYear(request.getAcademicYear()));
        score.setSemester(AcademicPeriodUtils.normalizeSemester(request.getSemester()));
        score.setCreatedAt(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));

        return scoreRepository.save(score);
    }

    @Transactional
    public ScoreEntity updateScore(Integer scoreId, UpdateScoreRequest request) {
        ScoreEntity score = scoreRepository.findById(scoreId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy điểm"));

        if (request.getScore() != null) {
            score.setScore(request.getScore());
        }
        if (request.getCoefficient() != null) {
            score.setCoefficient(request.getCoefficient());
        }
        if (request.getAcademicYear() != null) {
            score.setAcademicYear(AcademicPeriodUtils.normalizeAcademicYear(request.getAcademicYear()));
        }
        if (request.getSemester() != null) {
            score.setSemester(AcademicPeriodUtils.normalizeSemester(request.getSemester()));
        }

        return scoreRepository.save(score);
    }

    @Transactional
    public void deleteScore(Integer scoreId) {
        if (!scoreRepository.existsById(scoreId)) {
            throw new IllegalArgumentException("Không tìm thấy điểm");
        }
        scoreRepository.deleteById(scoreId);
    }

    public ClassStatisticsResponse getClassStatistics(Integer classId, String academicYear, Integer semester) {
        String year = AcademicPeriodUtils.normalizeAcademicYear(academicYear);
        int term = AcademicPeriodUtils.normalizeSemester(semester);
        SchoolClassEntity schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học"));

        List<UserEntity> students = getStudentsByClass(classId);

        int excellentCount = 0;
        int goodCount = 0;
        int averageCount = 0;
        int belowAverageCount = 0;
        double totalAvg = 0;

        Map<Integer, List<Double>> subjectScores = new HashMap<>();
        Map<Integer, String> subjectNames = new HashMap<>();

        for (UserEntity student : students) {
            List<ScoreEntity> scores = scoreRepository.findByUserIdAndAcademicYearAndSemester(student.getId(), year, term);
            double avg = calculateWeightedAverage(scores);
            totalAvg += avg;

            if (avg >= 8.5) excellentCount++;
            else if (avg >= 7.0) goodCount++;
            else if (avg >= 5.0) averageCount++;
            else belowAverageCount++;

            for (ScoreEntity score : scores) {
                Integer subjectId = score.getSubject().getId();
                subjectScores.computeIfAbsent(subjectId, k -> new ArrayList<>()).add(score.getScore());
                subjectNames.putIfAbsent(subjectId, score.getSubject().getName());
            }
        }

        List<ClassStatisticsResponse.SubjectStatistics> subjectStats = subjectScores.entrySet().stream()
                .map(entry -> {
                    List<Double> scores = entry.getValue();
                    return ClassStatisticsResponse.SubjectStatistics.builder()
                            .subjectId(entry.getKey())
                            .subjectName(subjectNames.get(entry.getKey()))
                            .averageScore(scores.stream().mapToDouble(Double::doubleValue).average().orElse(0))
                            .highestScore(scores.stream().mapToDouble(Double::doubleValue).max().orElse(0))
                            .lowestScore(scores.stream().mapToDouble(Double::doubleValue).min().orElse(0))
                            .build();
                })
                .collect(Collectors.toList());

        return ClassStatisticsResponse.builder()
                .classId(classId)
                .className(schoolClass.getName())
                .totalStudents(students.size())
                .classAverageScore(students.isEmpty() ? 0 : totalAvg / students.size())
                .excellentCount(excellentCount)
                .goodCount(goodCount)
                .averageCount(averageCount)
                .belowAverageCount(belowAverageCount)
                .subjectStatistics(subjectStats)
                .build();
    }

    private double calculateWeightedAverage(List<ScoreEntity> scores) {
        if (scores.isEmpty()) return 0;

        double totalWeightedScore = 0;
        double totalCoefficient = 0;

        for (ScoreEntity score : scores) {
            totalWeightedScore += score.getScore() * score.getCoefficient();
            totalCoefficient += score.getCoefficient();
        }

        return totalCoefficient > 0 ? Math.round(totalWeightedScore / totalCoefficient * 100.0) / 100.0 : 0;
    }
}
