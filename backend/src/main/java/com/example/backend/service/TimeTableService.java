package com.example.backend.service;

import com.example.backend.entity.TimeTableEntity;
import com.example.backend.repository.TimeTableRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class TimeTableService {

    private final TimeTableRepository timeTableRepository;

    public List<TimeTableEntity> getAllTimeTables() {
        return timeTableRepository.findAll();
    }

    public List<TimeTableEntity> getTimeTablesByUserId(Integer userId) {
        return timeTableRepository.findByUserId(userId);
    }

    public Optional<TimeTableEntity> getTimeTableById(Integer id) {
        return timeTableRepository.findById(id);
    }

    public TimeTableEntity createTimeTable(TimeTableEntity timeTable) {
        return timeTableRepository.save(timeTable);
    }

    public TimeTableEntity updateTimeTable(TimeTableEntity timeTable) {
        return timeTableRepository.save(timeTable);
    }

    public void deleteTimeTable(Integer id) {
        timeTableRepository.deleteById(id);
    }
}
