package com.example.backend.security;

/**
 * Mục đích OTP — phân biệt OTP đăng nhập 2 bước và OTP đặt lại mật khẩu.
 */
public final class OtpPurpose {

    public static final String PASSWORD_RESET = "PASSWORD_RESET";
    public static final String LOGIN_2FA = "LOGIN_2FA";

    private OtpPurpose() {}
}
