package com.example.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileResponse {
    private UserProfileDto user;
    /** Có khi đổi SĐT — client cần lưu token mới */
    private String accessToken;
    private String refreshToken;
}
