package com.example.backend.dto;

import lombok.Data;

@Data
public class UpdateProfileRequest {
    private String fullName;
    private String phoneNumber;
    private String className;
    /** null = không đổi */
    private Boolean twoFactorEnabled;
}
