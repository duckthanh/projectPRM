import 'user_model.dart';


class LoginResult {
  final bool twoFactorRequired;
  final UserModel? user;

  const LoginResult({required this.twoFactorRequired, this.user});
}
