class UserModel {
  final int? id;
  final int? roleId;
  final String password;
  final String phoneNumber;
  final String? fullName;
  final String? className;
  final String createdAt;
  /// Xác thực 2 bước (SMS) khi đăng nhập — bật trong hồ sơ
  final bool twoFactorEnabled;

  UserModel({
    this.id,
    this.roleId,
    required this.password,
    required this.phoneNumber,
    this.fullName,
    this.className,
    required this.createdAt,
    this.twoFactorEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_id': roleId,
      'password': password,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'class_name': className,
      'created_at': createdAt,
      'two_factor_enabled': twoFactorEnabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      roleId: map['role_id'] as int?,
      password: map['password'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      fullName: map['full_name'] as String?,
      className: map['class_name'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      twoFactorEnabled: map['two_factor_enabled'] == true,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      roleId: json['roleId'] as int?,
      password: (json['password'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      fullName: json['fullName'] as String?,
      className: json['className'] as String?,
      createdAt: (json['createdAt'] as String?) ?? '',
      twoFactorEnabled: json['twoFactorEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleId': roleId,
      'password': password,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'className': className,
      'createdAt': createdAt,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }
}
