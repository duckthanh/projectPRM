package com.example.backend.dto;

import com.example.backend.entity.UserEntity;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileDto {
    private Integer id;
    private String phoneNumber;
    private String fullName;
    private String className;
    private String createdAt;
    private Boolean twoFactorEnabled;

    public static UserProfileDto fromEntity(UserEntity user) {
        return UserProfileDto.builder()
                .id(user.getId())
                .phoneNumber(user.getPhoneNumber())
                .fullName(user.getFullName())
                .className(user.getClassName())
                .createdAt(user.getCreatedAt())
                .twoFactorEnabled(Boolean.TRUE.equals(user.getTwoFactorEnabled()))
                .build();
    }
}
