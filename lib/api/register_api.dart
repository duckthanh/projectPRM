import '../models/user_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class RegisterApi {
  final ApiClient _client;

  RegisterApi(this._client);

  Future<UserModel> register({
    required String phoneNumber,
    required String password,
    String? fullName,
    String? className,
  }) async {
    final json = await _client.postJson(
      ApiConfig.uri('/api/auth/register'),
      body: {
        'phoneNumber': phoneNumber,
        'password': password,
        'fullName': fullName,
        'className': className,
      },
      withAuth: false,
    );
    return UserModel.fromJson(json['user'] ?? json);
  }
}

