package com.example.backend.controller;

import com.example.backend.dto.AcademicSummaryResponse;
import com.example.backend.entity.ScoreEntity;
import com.example.backend.service.ScoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/scores")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ScoreController {

    private final ScoreService scoreService;

    @GetMapping
    public ResponseEntity<List<ScoreEntity>> getAllScores() {
        return ResponseEntity.ok(scoreService.getAllScores());
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ScoreEntity>> getScoresByUserId(
            @PathVariable Integer userId,
            @RequestParam(required = false) String academicYear,
            @RequestParam(required = false) Integer semester) {
        if (academicYear == null && semester == null) {
            return ResponseEntity.ok(scoreService.getScoresByUserId(userId));
        }
        return ResponseEntity.ok(scoreService.getScoresByUserId(userId, academicYear, semester));
    }

    @GetMapping("/user/{userId}/academic-years")
    public ResponseEntity<List<String>> getAcademicYears(@PathVariable Integer userId) {
        return ResponseEntity.ok(scoreService.getAcademicYears(userId));
    }

    @GetMapping("/user/{userId}/academic-summary")
    public ResponseEntity<AcademicSummaryResponse> getAcademicSummary(
            @PathVariable Integer userId,
            @RequestParam(required = false) String academicYear) {
        return ResponseEntity.ok(scoreService.getAcademicSummary(userId, academicYear));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ScoreEntity> getScoreById(@PathVariable Integer id) {
        Optional<ScoreEntity> score = scoreService.getScoreById(id);
        return score.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<ScoreEntity> createScore(@RequestBody ScoreEntity score) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(scoreService.createScore(score));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ScoreEntity> updateScore(@PathVariable Integer id, @RequestBody ScoreEntity score) {
        score.setId(id);
        return ResponseEntity.ok(scoreService.updateScore(score));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteScore(@PathVariable Integer id) {
        scoreService.deleteScore(id);
        return ResponseEntity.noContent().build();
    }
}
