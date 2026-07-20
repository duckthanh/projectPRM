package com.example.backend.repository;

import com.example.backend.entity.ScoreEntity;
import com.example.backend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

@Repository
public interface ScoreRepository extends JpaRepository<ScoreEntity, Integer> {
    List<ScoreEntity> findByUser(UserEntity user);
    List<ScoreEntity> findByUserId(Integer userId);
    List<ScoreEntity> findByUserIdAndAcademicYearAndSemester(Integer userId, String academicYear, Integer semester);
    List<ScoreEntity> findByUserIdAndAcademicYear(Integer userId, String academicYear);
    boolean existsByUserIdAndSubjectIdAndAcademicYearAndSemesterAndScoreAndCoefficient(
            Integer userId,
            Integer subjectId,
            String academicYear,
            Integer semester,
            Double score,
            Double coefficient);

    @Query("select distinct s.academicYear from ScoreEntity s where s.user.id = :userId order by s.academicYear desc")
    List<String> findAcademicYearsByUserId(@Param("userId") Integer userId);
}
