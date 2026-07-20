package com.example.backend.repository;

import com.example.backend.entity.TimeTableEntity;
import com.example.backend.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TimeTableRepository extends JpaRepository<TimeTableEntity, Integer> {
    List<TimeTableEntity> findByUser(UserEntity user);
    List<TimeTableEntity> findByUserId(Integer userId);
    List<TimeTableEntity> findByUserIdAndDayOfWeek(Integer userId, String dayOfWeek);
}
