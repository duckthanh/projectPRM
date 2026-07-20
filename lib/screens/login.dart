import 'dart:convert';

import 'package:flutter/material.dart';
import 'loginStyle.dart';
import 'home.dart';
import 'forgot_password.dart';
import 'login_otp_screen.dart';
import 'register.dart';
import 'teacher_home.dart';
import '../api/api_client.dart' show ApiClient, ApiException;
import '../api/user_api.dart';
import '../api/auth_storage.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy số điện thoại và mật khẩu
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserApi _userApi = UserApi(ApiClient());
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để tính toán layout chính xác
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      // SingleChildScrollView giúp tránh lỗi đen màn hình khi bàn phím đẩy UI lên
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          height: size.height, // Ép Container cao bằng toàn bộ màn hình
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Lớp trang trí (Background Layers)
              LoginStyle.buildBackgroundLayers(context),

              // 2. Card Đăng nhập chính
              Center(
                child: Container(
                  width: size.width * 0.85,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: LoginStyle.mainCardDecoration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: LoginStyle.primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 42,
                          color: LoginStyle.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'my',
                              style: LoginStyle.titleTextStyle.copyWith(
                                fontSize: 28,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: 'shool',
                              style: LoginStyle.titleTextStyle.copyWith(
                                fontSize: 28,
                                color: LoginStyle.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Đăng nhập bằng tài khoản',
                        style: LoginStyle.titleTextStyle,
                      ),
                      const SizedBox(height: 30),

                      // Ô nhập số điện thoại
                      _buildTextField(
                        controller: _phoneController,
                        hint: 'Số điện thoại',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),

                      // Ô nhập mật khẩu
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),

                      // Quên mật khẩu
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Quên mật khẩu',
                            style: LoginStyle.forgotPasswordTextStyle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Nút Đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: LoginStyle.loginButtonStyle,
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            'Đăng nhập',
                            style: LoginStyle.loginButtonTextStyle,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Nút Đăng ký
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: LoginStyle.ssoButtonStyle,
                          child: const Text(
                            'Đăng Ký',
                            textAlign: TextAlign.center,
                            style: LoginStyle.ssoButtonTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget dùng chung cho TextField
  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      autofocus: false,
      style: const TextStyle(color: Colors.black),
      decoration: LoginStyle.buildTextFieldDecoration(
        hint: hint,
        icon: icon,
        isPassword: isPassword,
      ),
    );
  }

  // Logic xử lý đăng nhập
  Future<void> _handleLogin() async {
    final phoneNumber = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phoneNumber.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _userApi.loginByPhone(
        phoneNumber: phoneNumber,
        password: password,
      );

      if (!mounted) return;

      UserModel user;
      if (result.twoFactorRequired) {
        final verified = await Navigator.push<UserModel>(
          context,
          MaterialPageRoute(
            builder: (context) => LoginOtpScreen(
              phoneNumber: phoneNumber,
              password: password,
            ),
          ),
        );
        if (!mounted || verified == null) return;
        user = verified;
      } else {
        user = result.user!;
      }

      final String displayName = user.fullName ?? user.phoneNumber;

      if (AuthStorage.isTeacher || AuthStorage.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherHomeScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: user.id ?? 0,
              displayName: displayName,
              phoneNumber: user.phoneNumber,
              className: user.className,
              createdAt: user.createdAt,
              twoFactorEnabled: user.twoFactorEnabled,
            ),
          ),
        );
      }
    } catch (e) {
      _showError(_buildLoginErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildLoginErrorMessage(Object error) {
    if (error is ApiException) {
      try {
        final json = jsonDecode(error.body) as Map<String, dynamic>;
        final message = json['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      } catch (_) {
        // Ignore parse errors and fall through to friendly defaults.
      }

      if (error.statusCode == 401 || error.statusCode == 404) {
        return 'Số điện thoại hoặc mật khẩu không chính xác';
      }
    }

    return 'Không thể đăng nhập. Vui lòng thử lại.';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}