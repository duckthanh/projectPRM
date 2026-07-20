package com.example.backend.repository;

import com.example.backend.entity.SchoolClassEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface SchoolClassRepository extends JpaRepository<SchoolClassEntity, Integer> {
    Optional<SchoolClassEntity> findByCode(String code);
    Optional<SchoolClassEntity> findByCodeIgnoreCase(String code);
    Optional<SchoolClassEntity> findByNameIgnoreCase(String name);
}
