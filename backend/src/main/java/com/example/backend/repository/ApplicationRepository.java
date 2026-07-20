package com.example.backend.repository;

import com.example.backend.entity.ApplicationEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApplicationRepository extends JpaRepository<ApplicationEntity, Integer> {

    List<ApplicationEntity> findByStudentIdOrderByCreatedAtDesc(Integer studentId);

    List<ApplicationEntity> findByTeacherIdOrderByCreatedAtDesc(Integer teacherId);

    List<ApplicationEntity> findByStatusOrderByCreatedAtDesc(String status);

    List<ApplicationEntity> findAllByOrderByCreatedAtDesc();

    @Query("SELECT a FROM ApplicationEntity a WHERE a.teacher.id = :teacherId AND a.status = :status ORDER BY a.createdAt DESC")
    List<ApplicationEntity> findByTeacherIdAndStatus(@Param("teacherId") Integer teacherId, @Param("status") String status);

    @Query("SELECT a FROM ApplicationEntity a WHERE a.teacher IS NULL AND a.status = 'PENDING' ORDER BY a.createdAt DESC")
    List<ApplicationEntity> findPendingWithoutTeacher();

    @Query("SELECT a FROM ApplicationEntity a WHERE (a.teacher.id = :teacherId OR a.teacher IS NULL) AND a.status = 'PENDING' ORDER BY a.createdAt DESC")
    List<ApplicationEntity> findPendingForTeacher(@Param("teacherId") Integer teacherId);
}
