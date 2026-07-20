package com.example.backend.service;

import com.example.backend.entity.RoleEntity;
import com.example.backend.repository.RoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class RoleService {
    private final RoleRepository roleRepository;
    public List<RoleEntity> findAll() { return roleRepository.findAll(); }
    public Optional<RoleEntity> findById(Integer id) { return roleRepository.findById(id); }
    public Optional<RoleEntity> findByCode(String code) { return roleRepository.findByCode(code); }
    public RoleEntity save(RoleEntity e) { return roleRepository.save(e); }
    public void delete(Integer id) { roleRepository.deleteById(id); }
}