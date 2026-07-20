package com.example.backend.controller;

import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.service.SchoolClassService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/school-classes")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class SchoolClassController {
    private final SchoolClassService schoolClassService;
    @GetMapping
    public ResponseEntity<List<SchoolClassEntity>> all() {
        return ResponseEntity.ok(schoolClassService.findAll());
    }
    @PostMapping
    public ResponseEntity<SchoolClassEntity> create(@RequestBody SchoolClassEntity e) {
        return ResponseEntity.ok(schoolClassService.save(e));
    }
}