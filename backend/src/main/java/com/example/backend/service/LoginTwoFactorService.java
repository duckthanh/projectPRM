package com.example.backend.service;

import com.example.backend.entity.OtpEntity;
import com.example.backend.repository.OtpRepository;
import com.example.backend.security.OtpPurpose;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

/**
 * Gửi OTP SMS cho bước 2 của đăng nhập (sau khi mật khẩu đúng).
 */
@Service
@RequiredArgsConstructor
public class LoginTwoFactorService {

    private final OtpRepository otpRepository;
    private final SmsService smsService;

    private static final int OTP_LENGTH = 6;
    private static final int OTP_EXPIRY_MINUTES = 5;

    @Transactional
    public void sendLoginOtp(String phoneNumber) {
        otpRepository.deleteByPhoneNumber(phoneNumber);

        String otp = generateOtp();
        OtpEntity otpEntity = new OtpEntity();
        otpEntity.setPhoneNumber(phoneNumber);
        otpEntity.setOtp(otp);
        otpEntity.setCreatedAt(LocalDateTime.now());
        otpEntity.setExpiresAt(LocalDateTime.now().plusMinutes(OTP_EXPIRY_MINUTES));
        otpEntity.setUsed(false);
        otpEntity.setPurpose(OtpPurpose.LOGIN_2FA);

        otpRepository.save(otpEntity);

        boolean sent = smsService.sendOtp(phoneNumber, otp);
        if (!sent) {
            throw new RuntimeException("Không thể gửi mã OTP. Vui lòng thử lại sau.");
        }
    }

    private String generateOtp() {
        SecureRandom random = new SecureRandom();
        StringBuilder otp = new StringBuilder();
        for (int i = 0; i < OTP_LENGTH; i++) {
            otp.append(random.nextInt(10));
        }
        return otp.toString();
    }
}
