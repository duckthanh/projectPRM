package com.example.backend.service;

import com.example.backend.entity.SubjectEntity;
import com.example.backend.repository.SubjectRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class SubjectService {
    private final SubjectRepository subjectRepository;
    public List<SubjectEntity> findAll() { return subjectRepository.findAll(); }
    public Optional<SubjectEntity> findById(Integer id) { return subjectRepository.findById(id); }
    public SubjectEntity save(SubjectEntity e) { return subjectRepository.save(e); }
    public void delete(Integer id) { subjectRepository.deleteById(id); }
}