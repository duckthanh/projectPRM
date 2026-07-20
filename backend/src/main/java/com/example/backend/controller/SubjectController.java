package com.example.backend.controller;

import com.example.backend.entity.SubjectEntity;
import com.example.backend.service.SubjectService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/subjects")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class SubjectController {
    private final SubjectService subjectService;
    @GetMapping
    public ResponseEntity<List<SubjectEntity>> all() {
        return ResponseEntity.ok(subjectService.findAll());
    }
    @PostMapping
    public ResponseEntity<SubjectEntity> create(@RequestBody SubjectEntity e) {
        return ResponseEntity.ok(subjectService.save(e));
    }
}