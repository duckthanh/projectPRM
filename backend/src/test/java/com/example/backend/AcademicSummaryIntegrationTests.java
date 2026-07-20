package com.example.backend;

import com.example.backend.dto.AcademicSummaryResponse;
import com.example.backend.entity.ScoreEntity;
import com.example.backend.entity.SubjectEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.ScoreRepository;
import com.example.backend.repository.SubjectRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.service.ScoreService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@Transactional
class AcademicSummaryIntegrationTests {

    @Autowired private ScoreService scoreService;
    @Autowired private ScoreRepository scoreRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private SubjectRepository subjectRepository;

    @Test
    void calculatesSemesterAndYearlyAverages() {
        UserEntity student = userRepository.findAll().get(0);
        SubjectEntity subject = subjectRepository.findAll().get(0);
        scoreRepository.save(score(student, subject, 6.0, 1));
        scoreRepository.save(score(student, subject, 9.0, 2));

        AcademicSummaryResponse result = scoreService.getAcademicSummary(student.getId(), "2099-2100");

        assertEquals(6.0, result.getSemester1Average());
        assertEquals(9.0, result.getSemester2Average());
        assertEquals(8.0, result.getYearlyAverage());
        assertEquals(8.0, result.getSubjects().get(0).getYearlyAverage());
    }

    private ScoreEntity score(UserEntity student, SubjectEntity subject, double value, int semester) {
        ScoreEntity score = new ScoreEntity();
        score.setUser(student);
        score.setSubject(subject);
        score.setScore(value);
        score.setCoefficient(1.0);
        score.setCreatedAt("2099-01-01 00:00:00");
        score.setAcademicYear("2099-2100");
        score.setSemester(semester);
        return score;
    }
}
