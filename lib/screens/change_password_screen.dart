import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/api_client.dart' show ApiClient, ApiException;
import '../api/user_api.dart';
import 'loginStyle.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final UserApi _userApi = UserApi(ApiClient());
  bool _loading = false;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _err(Object e) {
    if (e is ApiException) {
      try {
        final m = jsonDecode(e.body) as Map<String, dynamic>;
        if (m['errors'] is Map) {
          final errs = m['errors'] as Map;
          final first = errs.values.first;
          return first?.toString() ?? m['message']?.toString() ?? e.body;
        }
        return m['message']?.toString() ?? e.body;
      } catch (_) {
        return e.body;
      }
    }
    return e.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _userApi.changePassword(
        oldPassword: _oldController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đổi mật khẩu thành công')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_err(e)), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _oldController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: LoginStyle.buildTextFieldDecoration(
                  hint: 'Mật khẩu hiện tại',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: LoginStyle.buildTextFieldDecoration(
                  hint: 'Mật khẩu mới (ít nhất 6 ký tự)',
                  icon: Icons.lock_reset_outlined,
                  isPassword: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (v.length < 6) return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: LoginStyle.buildTextFieldDecoration(
                  hint: 'Nhập lại mật khẩu mới',
                  icon: Icons.verified_user_outlined,
                  isPassword: true,
                ),
                validator: (v) {
                  if (v != _newController.text) return 'Mật khẩu xác nhận không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: LoginStyle.loginButtonStyle,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Xác nhận đổi mật khẩu', style: LoginStyle.loginButtonTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
