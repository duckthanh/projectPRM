import 'api_client.dart';
import 'api_config.dart';

class PasswordResetApi {
  final ApiClient _client;

  PasswordResetApi(this._client);

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    return await _client.postJson(
      ApiConfig.uri('/api/auth/password/send-otp'),
      body: {'phoneNumber': phoneNumber},
      withAuth: false,
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return await _client.postJson(
      ApiConfig.uri('/api/auth/password/verify-otp'),
      body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      },
      withAuth: false,
    );
  }

  Future<Map<String, dynamic>> resetPassword(String phoneNumber, String otp, String newPassword) async {
    return await _client.postJson(
      ApiConfig.uri('/api/auth/password/reset'),
      body: {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      },
      withAuth: false,
    );
  }
}
