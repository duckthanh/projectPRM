package com.example.backend.controller;

import com.example.backend.dto.ResetPasswordRequest;
import com.example.backend.dto.SendOtpRequest;
import com.example.backend.dto.VerifyOtpRequest;
import com.example.backend.service.PasswordResetService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth/password")
@RequiredArgsConstructor
public class PasswordResetController {

    private final PasswordResetService passwordResetService;

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, String>> sendOtp(@Valid @RequestBody SendOtpRequest request) {
        passwordResetService.sendOtp(request.getPhoneNumber());
        return ResponseEntity.ok(Map.of(
                "message", "Mã OTP đã được gửi đến số điện thoại của bạn",
                "phoneNumber", maskPhoneNumber(request.getPhoneNumber())
        ));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, Object>> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        boolean valid = passwordResetService.verifyOtp(request.getPhoneNumber(), request.getOtp());
        return ResponseEntity.ok(Map.of(
                "valid", valid,
                "message", "Mã OTP hợp lệ"
        ));
    }

    @PostMapping("/reset")
    public ResponseEntity<Map<String, String>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.resetPassword(
                request.getPhoneNumber(),
                request.getOtp(),
                request.getNewPassword()
        );
        return ResponseEntity.ok(Map.of("message", "Đặt lại mật khẩu thành công"));
    }

    private String maskPhoneNumber(String phoneNumber) {
        if (phoneNumber.length() < 4) return "****";
        return "****" + phoneNumber.substring(phoneNumber.length() - 4);
    }
}
