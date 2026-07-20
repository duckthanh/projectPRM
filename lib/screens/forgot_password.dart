import 'package:flutter/material.dart';
import 'dart:async';
import 'loginStyle.dart';
import '../api/api_client.dart';
import '../api/password_reset_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final PasswordResetApi _api = PasswordResetApi(ApiClient());

  int _currentStep = 0; // 0: nhập SĐT, 1: nhập OTP, 2: đặt mật khẩu mới
  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
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
                child: _buildCurrentStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPhoneStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNewPasswordStep();
      default:
        return _buildPhoneStep();
    }
  }

  // Bước 1: Nhập số điện thoại
  Widget _buildPhoneStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.phone_android),
        const SizedBox(height: 20),
        const Text('Nhập số điện thoại', style: LoginStyle.titleTextStyle),
        const SizedBox(height: 10),
        Text(
          'Chúng tôi sẽ gửi mã OTP đến số điện thoại của bạn',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildTextField(
          controller: _phoneController,
          hint: 'Số điện thoại',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildButton('Gửi mã OTP', _sendOtp),
        const SizedBox(height: 15),
        _buildBackButton('Quay lại đăng nhập', () => Navigator.pop(context)),
      ],
    );
  }

  // Bước 2: Nhập OTP
  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.sms),
        const SizedBox(height: 20),
        const Text('Nhập mã OTP', style: LoginStyle.titleTextStyle),
        const SizedBox(height: 10),
        Text(
          'Mã OTP đã được gửi đến\n${_maskPhone(_phoneController.text)}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildTextField(
          controller: _otpController,
          hint: 'Nhập mã OTP (6 số)',
          icon: Icons.lock_clock,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 10),
        if (_countdown > 0)
          Text(
            'Gửi lại mã sau $_countdown giây',
            style: TextStyle(color: Colors.grey.shade600),
          )
        else
          TextButton(
            onPressed: _isLoading ? null : _resendOtp,
            child: const Text('Gửi lại mã OTP'),
          ),
        const SizedBox(height: 20),
        _buildButton('Xác nhận', _verifyOtp),
        const SizedBox(height: 15),
        _buildBackButton('Quay lại', () => setState(() => _currentStep = 0)),
      ],
    );
  }

  // Bước 3: Đặt mật khẩu mới
  Widget _buildNewPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.lock_reset),
        const SizedBox(height: 20),
        const Text('Đặt mật khẩu mới', style: LoginStyle.titleTextStyle),
        const SizedBox(height: 10),
        Text(
          'Tạo mật khẩu mới cho tài khoản của bạn',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _buildTextField(
          controller: _passwordController,
          hint: 'Mật khẩu mới',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _confirmPasswordController,
          hint: 'Xác nhận mật khẩu',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 20),
        _buildButton('Đặt lại mật khẩu', _resetPassword),
        const SizedBox(height: 15),
        _buildBackButton('Quay lại', () => setState(() => _currentStep = 1)),
      ],
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: LoginStyle.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 50, color: LoginStyle.primaryColor),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.black),
      decoration: LoginStyle.buildTextFieldDecoration(
        hint: hint,
        icon: icon,
        isPassword: isPassword,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
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
            : Text(text, style: LoginStyle.loginButtonTextStyle),
      ),
    );
  }

  Widget _buildBackButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: _isLoading ? null : onPressed,
      child: Text(text, style: LoginStyle.forgotPasswordTextStyle),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return '****';
    return '****${phone.substring(phone.length - 4)}';
  }

  // API calls
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('Vui lòng nhập số điện thoại');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.sendOtp(phone);
      _startCountdown();
      setState(() => _currentStep = 1);
      _showSuccess('Mã OTP đã được gửi');
    } catch (e) {
      _showError(_parseError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await _api.sendOtp(_phoneController.text.trim());
      _startCountdown();
      _showSuccess('Mã OTP đã được gửi lại');
    } catch (e) {
      _showError(_parseError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      _showError('Vui lòng nhập mã OTP 6 số');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.verifyOtp(_phoneController.text.trim(), otp);
      setState(() => _currentStep = 2);
    } catch (e) {
      _showError(_parseError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showError('Vui lòng nhập mật khẩu mới');
      return;
    }
    if (password.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (password != confirmPassword) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _api.resetPassword(
        _phoneController.text.trim(),
        _otpController.text.trim(),
        password,
      );
      _showSuccessDialog();
    } catch (e) {
      _showError(_parseError(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Thành công'),
          ],
        ),
        content: const Text('Mật khẩu đã được đặt lại thành công.\nVui lòng đăng nhập với mật khẩu mới.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  String _parseError(dynamic e) {
    if (e.toString().contains('message')) {
      try {
        final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(e.toString());
        if (match != null) return match.group(1)!;
      } catch (_) {}
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
