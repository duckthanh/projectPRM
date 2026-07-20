package com.example.backend.service;

import com.example.backend.dto.RegisterRequest;
import com.example.backend.dto.UpdateProfileRequest;
import com.example.backend.dto.UpdateProfileResponse;
import com.example.backend.dto.UserProfileDto;
import com.example.backend.entity.RoleEntity;
import com.example.backend.entity.SchoolClassEntity;
import com.example.backend.entity.UserEntity;
import com.example.backend.repository.RoleRepository;
import com.example.backend.repository.SchoolClassRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.security.CustomUserDetails;
import com.example.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public List<UserEntity> getAllUsers() {
        return userRepository.findAll();
    }

    public Optional<UserEntity> getUserById(Integer id) {
        return userRepository.findById(id);
    }

    public Optional<UserEntity> getUserByPhone(String phoneNumber) {
        return userRepository.findByPhoneNumber(phoneNumber);
    }

    public Optional<UserEntity> login(String phoneNumber, String password) {
        Optional<UserEntity> userOpt = userRepository.findByPhoneNumber(phoneNumber);
        if (userOpt.isPresent() && passwordEncoder.matches(password, userOpt.get().getPassword())) {
            return userOpt;
        }
        return Optional.empty();
    }

    public UserEntity createUser(UserEntity user) {
        if (user.getCreatedAt() == null || user.getCreatedAt().isEmpty()) {
            user.setCreatedAt(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }
        if (user.getPassword() != null && !user.getPassword().startsWith("$2a$")) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        return userRepository.save(user);
    }

    public UserEntity register(RegisterRequest req) {
        final String phone = req.getPhoneNumber() == null ? "" : req.getPhoneNumber().trim();
        final String password = req.getPassword() == null ? "" : req.getPassword().trim();

        if (phone.isEmpty() || password.isEmpty()) {
            throw new IllegalArgumentException("Thiếu thông tin đăng ký");
        }
        if (userRepository.existsByPhoneNumber(phone)) {
            throw new IllegalArgumentException("Số điện thoại đã tồn tại");
        }

        final UserEntity u = new UserEntity();
        u.setPassword(passwordEncoder.encode(password));
        u.setPhoneNumber(phone);
        u.setFullName(req.getFullName());
        u.setClassName(req.getClassName());
        u.setCreatedAt(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        u.setTwoFactorEnabled(false);

        RoleEntity studentRole = roleRepository.findByCode("STUDENT").orElse(null);
        if (studentRole != null) {
            u.getRoles().add(studentRole);
        }

        return userRepository.save(u);
    }

    public UserEntity updateUser(UserEntity user) {
        if (user.getPassword() != null && !user.getPassword().startsWith("$2a$")) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        return userRepository.save(user);
    }

    /**
     * Cập nhật hồ sơ (họ tên, SĐT, lớp). Khi đổi SĐT, trả về access/refresh token mới vì JWT dùng SĐT làm subject.
     */
    @Transactional
    public UpdateProfileResponse updateProfile(Integer userId, UpdateProfileRequest req) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        boolean phoneChanged = false;

        if (req.getFullName() != null) {
            String fn = req.getFullName().trim();
            user.setFullName(fn.isEmpty() ? null : fn);
        }
        if (req.getClassName() != null) {
            String cn = req.getClassName().trim();
            syncClassMembership(user, cn);
        }
        if (req.getPhoneNumber() != null) {
            String phone = req.getPhoneNumber().trim();
            if (phone.isEmpty()) {
                throw new IllegalArgumentException("Số điện thoại không hợp lệ");
            }
            if (!phone.equals(user.getPhoneNumber())) {
                userRepository.findByPhoneNumber(phone).ifPresent(other -> {
                    if (!other.getId().equals(userId)) {
                        throw new IllegalArgumentException("Số điện thoại đã được sử dụng");
                    }
                });
                user.setPhoneNumber(phone);
                phoneChanged = true;
            }
        }
        if (req.getTwoFactorEnabled() != null) {
            user.setTwoFactorEnabled(req.getTwoFactorEnabled());
        }

        user = userRepository.save(user);
        UserProfileDto dto = UserProfileDto.fromEntity(user);

        if (phoneChanged) {
            CustomUserDetails details = new CustomUserDetails(user);
            return UpdateProfileResponse.builder()
                    .user(dto)
                    .accessToken(jwtService.generateToken(details))
                    .refreshToken(jwtService.generateRefreshToken(details))
                    .build();
        }

        return UpdateProfileResponse.builder()
                .user(dto)
                .accessToken(null)
                .refreshToken(null)
                .build();
    }

    private void syncClassMembership(UserEntity user, String classNameOrCode) {
        user.getClasses().clear();
        if (classNameOrCode.isEmpty()) {
            user.setClassName(null);
            return;
        }

        SchoolClassEntity schoolClass = schoolClassRepository.findByNameIgnoreCase(classNameOrCode)
                .or(() -> schoolClassRepository.findByCodeIgnoreCase(classNameOrCode))
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lớp học: " + classNameOrCode));

        user.getClasses().add(schoolClass);
        user.setClassName(schoolClass.getName());
    }

    public void changePassword(Integer userId, String oldPassword, String newPassword) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng"));

        if (newPassword == null || newPassword.length() < 6) {
            throw new IllegalArgumentException("Mật khẩu mới phải có ít nhất 6 ký tự");
        }

        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new IllegalArgumentException("Mật khẩu hiện tại không chính xác");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    public void deleteUser(Integer id) {
        userRepository.deleteById(id);
    }

    public boolean isPhoneNumberExists(String phoneNumber) {
        return userRepository.existsByPhoneNumber(phoneNumber);
    }
}
