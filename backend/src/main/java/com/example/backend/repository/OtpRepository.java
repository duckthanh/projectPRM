package com.example.backend.repository;

import com.example.backend.entity.OtpEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OtpRepository extends JpaRepository<OtpEntity, Integer> {
    Optional<OtpEntity> findByPhoneNumberAndOtpAndUsedFalseAndPurpose(
            String phoneNumber, String otp, String purpose);

    void deleteByPhoneNumber(String phoneNumber);
}
