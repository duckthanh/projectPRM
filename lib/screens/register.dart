import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/register_api.dart';
import 'loginStyle.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _className = TextEditingController();

  final RegisterApi _api = RegisterApi(ApiClient());

  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _fullName.dispose();
    _className.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      body: SingleChildScrollView(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              LoginStyle.buildBackgroundLayers(context),
              Center(
                child: Container(
                  width: size.width * 0.88,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                  decoration: LoginStyle.mainCardDecoration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đăng ký', style: LoginStyle.titleTextStyle),
                      const SizedBox(height: 18),
                      _field(
                        controller: _phone,
                        hint: 'Số điện thoại',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _field(
                        controller: _password,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 12),
                      _field(controller: _fullName, hint: 'Họ và tên (tuỳ chọn)', icon: Icons.badge_outlined),
                      const SizedBox(height: 12),
                      _field(controller: _className, hint: 'Lớp (tuỳ chọn)', icon: Icons.class_outlined),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: LoginStyle.loginButtonStyle,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Tạo tài khoản', style: LoginStyle.loginButtonTextStyle),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Đã có tài khoản? Đăng nhập'),
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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: LoginStyle.buildTextFieldDecoration(
        hint: hint,
        icon: icon,
        isPassword: isPassword,
      ),
    );
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    final password = _password.text.trim();
    final fullName = _fullName.text.trim();
    final className = _className.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _show('Vui lòng nhập số điện thoại và mật khẩu');
      return;
    }

    setState(() => _loading = true);
    try {
      await _api.register(
        phoneNumber: phone,
        password: password,
        fullName: fullName.isEmpty ? null : fullName,
        className: className.isEmpty ? null : className,
      );
      if (!mounted) return;
      _show('Đăng ký thành công, hãy đăng nhập');
      Navigator.pop(context);
    } catch (e) {
      _show('Đăng ký thất bại: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

