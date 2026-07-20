package com.example.backend.service;

import com.example.backend.entity.OtpEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.OtpRepository;
import com.example.backend.security.OtpPurpose;
import com.example.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private final UserRepository userRepository;
    private final OtpRepository otpRepository;
    private final SmsService smsService;
    private final PasswordEncoder passwordEncoder;

    private static final int OTP_LENGTH = 6;
    private static final int OTP_EXPIRY_MINUTES = 5;

    @Transactional
    public void sendOtp(String phoneNumber) {
        UserEntity user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("Số điện thoại không tồn tại trong hệ thống"));

        otpRepository.deleteByPhoneNumber(phoneNumber);

        String otp = generateOtp();

        OtpEntity otpEntity = new OtpEntity();
        otpEntity.setPhoneNumber(phoneNumber);
        otpEntity.setOtp(otp);
        otpEntity.setCreatedAt(LocalDateTime.now());
        otpEntity.setExpiresAt(LocalDateTime.now().plusMinutes(OTP_EXPIRY_MINUTES));
        otpEntity.setUsed(false);
        otpEntity.setPurpose(OtpPurpose.PASSWORD_RESET);

        otpRepository.save(otpEntity);

        boolean sent = smsService.sendOtp(phoneNumber, otp);
        if (!sent) {
            throw new RuntimeException("Không thể gửi mã OTP. Vui lòng thử lại sau.");
        }
    }

    @Transactional
    public boolean verifyOtp(String phoneNumber, String otp) {
        OtpEntity otpEntity = otpRepository.findByPhoneNumberAndOtpAndUsedFalseAndPurpose(
                        phoneNumber, otp, OtpPurpose.PASSWORD_RESET)
                .orElseThrow(() -> new IllegalArgumentException("Mã OTP không đúng"));

        if (otpEntity.isExpired()) {
            throw new IllegalArgumentException("Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        return true;
    }

    @Transactional
    public void resetPassword(String phoneNumber, String otp, String newPassword) {
        OtpEntity otpEntity = otpRepository.findByPhoneNumberAndOtpAndUsedFalseAndPurpose(
                        phoneNumber, otp, OtpPurpose.PASSWORD_RESET)
                .orElseThrow(() -> new IllegalArgumentException("Mã OTP không đúng"));

        if (otpEntity.isExpired()) {
            throw new IllegalArgumentException("Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("Mật khẩu phải có ít nhất 6 ký tự");
        }

        UserEntity user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        otpEntity.setUsed(true);
        otpRepository.save(otpEntity);
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
