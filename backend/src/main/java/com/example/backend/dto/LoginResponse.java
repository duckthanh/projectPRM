package com.example.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private Long expiresIn;
    private UserInfo user;
    /** true khi đã đúng mật khẩu và cần nhập OTP SMS; accessToken/refreshToken/user null */
    private Boolean twoFactorRequired;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserInfo {
        private Integer id;
        private String phoneNumber;
        private String fullName;
        private List<String> roles;
        /** Người dùng có bật 2FA trong hồ sơ hay không */
        private Boolean twoFactorEnabled;
    }
}
