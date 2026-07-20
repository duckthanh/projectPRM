package com.example.backend.service;

import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.repository.SchoolClassRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class SchoolClassService {
    private final SchoolClassRepository schoolClassRepository;
    public List<SchoolClassEntity> findAll() { return schoolClassRepository.findAll(); }
    public Optional<SchoolClassEntity> findById(Integer id) { return schoolClassRepository.findById(id); }
    public SchoolClassEntity save(SchoolClassEntity e) { return schoolClassRepository.save(e); }
    public void delete(Integer id) { schoolClassRepository.deleteById(id); }

}