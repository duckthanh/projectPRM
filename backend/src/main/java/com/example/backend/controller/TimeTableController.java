package com.example.backend.controller;

import com.example.backend.entity.TimeTableEntity;
import com.example.backend.service.TimeTableService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/timetables")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class TimeTableController {

    private final TimeTableService timeTableService;

    @GetMapping
    public ResponseEntity<List<TimeTableEntity>> getAllTimeTables() {
        return ResponseEntity.ok(timeTableService.getAllTimeTables());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<TimeTableEntity>> getTimeTablesByUserId(@PathVariable Integer userId) {
        return ResponseEntity.ok(timeTableService.getTimeTablesByUserId(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TimeTableEntity> getTimeTableById(@PathVariable Integer id) {
        Optional<TimeTableEntity> timeTable = timeTableService.getTimeTableById(id);
        return timeTable.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<TimeTableEntity> createTimeTable(@RequestBody TimeTableEntity timeTable) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(timeTableService.createTimeTable(timeTable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<TimeTableEntity> updateTimeTable(@PathVariable Integer id, @RequestBody TimeTableEntity timeTable) {
        timeTable.setId(id);
        return ResponseEntity.ok(timeTableService.updateTimeTable(timeTable));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTimeTable(@PathVariable Integer id) {
        timeTableService.deleteTimeTable(id);
        return ResponseEntity.noContent().build();
    }
}
