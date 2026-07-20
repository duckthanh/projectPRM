package com.example.backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class UserEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    /**
     * Quan hệ nhiều-nhiều User <-> Role.
     * Tạo bảng nối: user_roles(user_id, role_id)
     */
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "user_roles",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @JsonIgnoreProperties("users")
    private Set<RoleEntity> roles = new HashSet<>();

    /**
     * User <-> SchoolClass (nhiều-nhiều)
     * Tạo bảng nối: user_classes(user_id, class_id)
     */
    @ManyToMany
    @JoinTable(
            name = "user_classes",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "class_id")
    )
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @JsonIgnoreProperties("users")
    private Set<SchoolClassEntity> classes = new HashSet<>();

    @Column(nullable = false)
    private String password;

    @Column(name = "phone_number", nullable = false, unique = true)
    private String phoneNumber;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "class_name")
    private String className;

    @Column(name = "created_at", nullable = false)
    private String createdAt;

    /** Bật xác thực 2 bước (SMS OTP) khi đăng nhập — chỉ áp dụng nếu app.security.two-factor-login-enabled = true */
    @Column(name = "two_factor_enabled", nullable = false)
    private Boolean twoFactorEnabled = false;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @JsonIgnoreProperties("user")
    private Set<ScoreEntity> scores = new HashSet<>();

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @JsonIgnoreProperties("user")
    private Set<TimeTableEntity> timetables = new HashSet<>();

}