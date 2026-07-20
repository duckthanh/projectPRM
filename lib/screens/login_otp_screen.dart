import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/api_client.dart' show ApiClient, ApiException;
import '../api/user_api.dart';
import 'loginStyle.dart';

/// Bước 2 đăng nhập: nhập mã OTP gửi qua SMS.
class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String password;

  const LoginOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.password,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _otpController = TextEditingController();
  final UserApi _userApi = UserApi(ApiClient());
  bool _loading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _err(Object e) {
    if (e is ApiException) {
      try {
        final m = jsonDecode(e.body) as Map<String, dynamic>;
        return m['message']?.toString() ?? e.body;
      } catch (_) {
        return e.body;
      }
    }
    return e.toString();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      _snack('Vui lòng nhập mã OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _userApi.verifyLoginOtp(
        phoneNumber: widget.phoneNumber,
        otp: otp,
      );
      if (!mounted) return;
      Navigator.pop(context, user);
    } catch (e) {
      if (mounted) _snack(_err(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_countdown > 0) return;
    setState(() => _loading = true);
    try {
      final loggedIn = await _userApi.resendLoginOtp(
        phoneNumber: widget.phoneNumber,
        password: widget.password,
      );
      if (!mounted) return;
      if (loggedIn != null) {
        Navigator.pop(context, loggedIn);
        return;
      }
      _startCountdown();
      _snack('Đã gửi lại mã OTP');
    } catch (e) {
      if (mounted) _snack(_err(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      appBar: AppBar(
        title: const Text('Xác thực 2 bước'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Stack(
            alignment: Alignment.center,
            children: [
              LoginStyle.buildBackgroundLayers(context),
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: LoginStyle.mainCardDecoration,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sms_outlined, size: 56, color: LoginStyle.primaryColor),
                    const SizedBox(height: 16),
                    const Text('Nhập mã OTP', style: LoginStyle.titleTextStyle),
                    const SizedBox(height: 8),
                    Text(
                      'Mã gồm 6 số đã gửi tới ${widget.phoneNumber}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.black, fontSize: 22, letterSpacing: 8),
                      textAlign: TextAlign.center,
                      decoration: LoginStyle.buildTextFieldDecoration(
                        hint: 'Mã OTP',
                        icon: Icons.pin_outlined,
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verify,
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
                            : const Text('Xác nhận', style: LoginStyle.loginButtonTextStyle),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: (_loading || _countdown > 0) ? null : _resend,
                      child: Text(
                        _countdown > 0 ? 'Gửi lại sau ${_countdown}s' : 'Gửi lại mã OTP',
                        style: TextStyle(
                          color: _countdown > 0 ? Colors.grey : LoginStyle.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
