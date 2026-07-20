package com.example.backend.service;

import com.example.backend.dto.LoginRequest;
import com.example.backend.dto.LoginResponse;
import com.example.backend.dto.RefreshTokenRequest;
import com.example.backend.dto.RegisterRequest;
import com.example.backend.entity.OtpEntity;
import com.example.backend.entity.RoleEntity;
import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.dto.VerifyLoginOtpRequest;
import com.example.backend.repository.OtpRepository;
import com.example.backend.repository.RoleRepository;
import com.example.backend.repository.SchoolClassRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.security.OtpPurpose;
import com.example.backend.security.CustomUserDetails;
import com.example.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final OtpRepository otpRepository;
    private final LoginTwoFactorService loginTwoFactorService;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    @Value("${app.security.two-factor-login-enabled:true}")
    private boolean twoFactorLoginEnabled;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getPhoneNumber(),
                            request.getPassword()
                    )
            );

            CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
            UserEntity user = userDetails.getUser();

            if (twoFactorLoginEnabled && Boolean.TRUE.equals(user.getTwoFactorEnabled())) {
                loginTwoFactorService.sendLoginOtp(user.getPhoneNumber());
                return LoginResponse.builder()
                        .twoFactorRequired(true)
                        .accessToken(null)
                        .refreshToken(null)
                        .tokenType("Bearer")
                        .expiresIn(null)
                        .user(null)
                        .build();
            }

            String accessToken = jwtService.generateToken(userDetails);
            String refreshToken = jwtService.generateRefreshToken(userDetails);

            return buildLoginResponse(user, accessToken, refreshToken);

        } catch (BadCredentialsException e) {
            throw new BadCredentialsException("Số điện thoại hoặc mật khẩu không chính xác");
        }
    }

    @Transactional
    public LoginResponse register(RegisterRequest request) {
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new IllegalArgumentException("Số điện thoại đã được sử dụng");
        }

        UserEntity user = new UserEntity();
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setCreatedAt(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        user.setTwoFactorEnabled(false);

        RoleEntity defaultRole = roleRepository.findByCode("USER")
                .orElseGet(() -> {
                    RoleEntity newRole = new RoleEntity();
                    newRole.setCode("USER");
                    newRole.setName("Người dùng");
                    newRole.setDescription("Người dùng thông thường");
                    newRole.setActive(true);
                    return roleRepository.save(newRole);
                });

        Set<RoleEntity> roles = new HashSet<>();
        roles.add(defaultRole);
        user.setRoles(roles);

        if (request.getClassName() != null && !request.getClassName().trim().isEmpty()) {
            String classNameOrCode = request.getClassName().trim();
            SchoolClassEntity schoolClass = schoolClassRepository.findByNameIgnoreCase(classNameOrCode)
                    .or(() -> schoolClassRepository.findByCodeIgnoreCase(classNameOrCode))
                    .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học: " + classNameOrCode));
            user.getClasses().add(schoolClass);
            user.setClassName(schoolClass.getName());
        }

        userRepository.save(user);

        CustomUserDetails userDetails = new CustomUserDetails(user);
        String accessToken = jwtService.generateToken(userDetails);
        String refreshToken = jwtService.generateRefreshToken(userDetails);

        return buildLoginResponse(user, accessToken, refreshToken);
    }

    @Transactional(readOnly = true)
    public LoginResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();
        String phoneNumber = jwtService.extractUsername(refreshToken);

        UserEntity user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy người dùng"));

        CustomUserDetails userDetails = new CustomUserDetails(user);

        if (!jwtService.isTokenValid(refreshToken, userDetails)) {
            throw new IllegalArgumentException("Refresh token không hợp lệ hoặc đã hết hạn");
        }

        String newAccessToken = jwtService.generateToken(userDetails);
        String newRefreshToken = jwtService.generateRefreshToken(userDetails);

        return buildLoginResponse(user, newAccessToken, newRefreshToken);
    }

    @Transactional
    public LoginResponse verifyLoginOtp(VerifyLoginOtpRequest request) {
        OtpEntity otpEntity = otpRepository.findByPhoneNumberAndOtpAndUsedFalseAndPurpose(
                        request.getPhoneNumber().trim(), request.getOtp().trim(), OtpPurpose.LOGIN_2FA)
                .orElseThrow(() -> new IllegalArgumentException("Mã OTP không đúng"));

        if (otpEntity.isExpired()) {
            throw new IllegalArgumentException("Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
        }

        otpEntity.setUsed(true);
        otpRepository.save(otpEntity);

        UserEntity user = userRepository.findByPhoneNumber(request.getPhoneNumber().trim())
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        CustomUserDetails userDetails = new CustomUserDetails(user);
        String accessToken = jwtService.generateToken(userDetails);
        String refreshToken = jwtService.generateRefreshToken(userDetails);

        return buildLoginResponse(user, accessToken, refreshToken);
    }


    @Transactional
    public LoginResponse resendLoginOtp(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getPhoneNumber(),
                            request.getPassword()
                    )
            );
            CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
            UserEntity user = userDetails.getUser();

            if (!twoFactorLoginEnabled || !Boolean.TRUE.equals(user.getTwoFactorEnabled())) {
                String accessToken = jwtService.generateToken(userDetails);
                String refreshToken = jwtService.generateRefreshToken(userDetails);
                return buildLoginResponse(user, accessToken, refreshToken);
            }

            loginTwoFactorService.sendLoginOtp(user.getPhoneNumber());
            return LoginResponse.builder()
                    .twoFactorRequired(true)
                    .accessToken(null)
                    .refreshToken(null)
                    .tokenType("Bearer")
                    .expiresIn(null)
                    .user(null)
                    .build();
        } catch (BadCredentialsException e) {
            throw new BadCredentialsException("Số điện thoại hoặc mật khẩu không chính xác");
        }
    }

    private LoginResponse buildLoginResponse(UserEntity user, String accessToken, String refreshToken) {
        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .twoFactorRequired(false)
                .user(LoginResponse.UserInfo.builder()
                        .id(user.getId())
                        .phoneNumber(user.getPhoneNumber())
                        .fullName(user.getFullName())
                        .roles(user.getRoles().stream()
                                .map(RoleEntity::getCode)
                                .collect(Collectors.toList()))
                        .twoFactorEnabled(user.getTwoFactorEnabled() != null && user.getTwoFactorEnabled())
                        .build())
                .build();
    }
}
