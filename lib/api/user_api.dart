import '../models/login_result.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_storage.dart';

class UserApi {
  final ApiClient _client;

  UserApi(this._client);

  /// Đăng nhập: nếu server bật 2FA, trả [LoginResult.twoFactorRequired] = true (chưa có token).
  Future<LoginResult> loginByPhone({required String phoneNumber, required String password}) async {
    final json = await _client.postJson(
      ApiConfig.uri('/api/auth/login'),
      body: {'phoneNumber': phoneNumber, 'password': password},
      withAuth: false,
    );

    if (json['twoFactorRequired'] == true) {
      return const LoginResult(twoFactorRequired: true, user: null);
    }

    final accessToken = json['accessToken'] ?? '';
    AuthStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: json['refreshToken'] ?? '',
      user: json['user'] as Map<String, dynamic>?,
    );

    return LoginResult(
      twoFactorRequired: false,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Bước 2: nhập mã OTP SMS sau khi đăng nhập đúng mật khẩu.
  Future<UserModel> verifyLoginOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final json = await _client.postJson(
      ApiConfig.uri('/api/auth/login/verify-otp'),
      body: {'phoneNumber': phoneNumber, 'otp': otp},
      withAuth: false,
    );
    AuthStorage.saveTokens(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: json['user'] as Map<String, dynamic>?,
    );
    return UserModel.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Gửi lại OTP (cần đúng mật khẩu). Nếu server tắt 2FA có thể trả luôn token — trả [UserModel] để điều hướng.
  Future<UserModel?> resendLoginOtp({
    required String phoneNumber,
    required String password,
  }) async {
    final json = await _client.postJson(
      ApiConfig.uri('/api/auth/login/resend-otp'),
      body: {'phoneNumber': phoneNumber, 'password': password},
      withAuth: false,
    );
    if (json['twoFactorRequired'] != true &&
        (json['accessToken'] as String?)?.isNotEmpty == true) {
      AuthStorage.saveTokens(
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        user: json['user'] as Map<String, dynamic>?,
      );
      return UserModel.fromJson(json['user'] as Map<String, dynamic>);
    }
    return null;
  }

  void logout() {
    AuthStorage.clear();
  }

  /// Cập nhật hồ sơ (họ tên, SĐT, lớp). Nếu đổi SĐT, server trả token mới — đã lưu trong [AuthStorage].
  Future<UserModel> updateMyProfile({
    required String fullName,
    required String phoneNumber,
    required String className,
  }) async {
    final json = await _client.patchJson(
      ApiConfig.uri('/api/users/me'),
      body: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'className': className,
      },
    );
    final userMap = json['user'] as Map<String, dynamic>? ?? json;
    final access = json['accessToken'] as String?;
    final refresh = json['refreshToken'] as String?;
    AuthStorage.applyProfileAndTokens(
      profileUser: userMap,
      accessToken: access,
      refreshToken: refresh,
    );
    return UserModel.fromJson(userMap);
  }

  /// Chỉ cập nhật bật/tắt xác thực 2 bước (không đổi các trường khác).
  Future<UserModel> setTwoFactorEnabled(bool enabled) async {
    final json = await _client.patchJson(
      ApiConfig.uri('/api/users/me'),
      body: {'twoFactorEnabled': enabled},
    );
    final userMap = json['user'] as Map<String, dynamic>? ?? json;
    final access = json['accessToken'] as String?;
    final refresh = json['refreshToken'] as String?;
    AuthStorage.applyProfileAndTokens(
      profileUser: userMap,
      accessToken: access,
      refreshToken: refresh,
    );
    return UserModel.fromJson(userMap);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.postVoid(
      ApiConfig.uri('/api/users/me/change-password'),
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }
}

