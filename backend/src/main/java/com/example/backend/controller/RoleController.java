package com.example.backend.controller;

import com.example.backend.entity.RoleEntity;
import com.example.backend.service.RoleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/roles")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class RoleController {
    private final RoleService roleService;
    @GetMapping
    public ResponseEntity<List<RoleEntity>> all() {
        return ResponseEntity.ok(roleService.findAll());
    }
    @GetMapping("/{id}")
    public ResponseEntity<RoleEntity> byId(@PathVariable Integer id) {
        return roleService.findById(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());
    }
    @PostMapping
    public ResponseEntity<RoleEntity> create(@RequestBody RoleEntity e) {
        return ResponseEntity.ok(roleService.save(e));
    }
}