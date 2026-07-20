import 'dart:convert';

import 'package:flutter/material.dart';
import 'loginStyle.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import '../api/api_client.dart' show ApiClient, ApiException;
import '../api/user_api.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final String displayName;
  final String phoneNumber;
  final String? className;
  final String createdAt;
  final bool twoFactorEnabled;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.phoneNumber,
    this.className,
    required this.createdAt,
    this.twoFactorEnabled = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserApi _userApi = UserApi(ApiClient());
  late String _displayName;
  late String _phoneNumber;
  String? _className;
  late String _createdAt;
  late bool _twoFactorEnabled;
  bool _twoFactorBusy = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.displayName;
    _phoneNumber = widget.phoneNumber;
    _className = widget.className;
    _createdAt = widget.createdAt;
    _twoFactorEnabled = widget.twoFactorEnabled;
  }

  String _badgeClassLabel() {
    if (_className != null && _className!.isNotEmpty) return _className!;
    return 'Học sinh';
  }

  String _classInfoLabel() {
    if (_className != null && _className!.isNotEmpty) return _className!;
    return 'Chưa cập nhật';
  }

  String _formatError(Object error) {
    if (error is ApiException && error.body.isNotEmpty) {
      try {
        final json = jsonDecode(error.body) as Map<String, dynamic>;
        return json['message']?.toString() ?? error.body;
      } catch (_) {
        return error.body;
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Avatar và tên
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(_displayName),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: LoginStyle.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName.isEmpty ? 'Chưa cập nhật' : _displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _badgeClassLabel(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Thông tin chi tiết
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin tài khoản',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Mã học sinh',
                    value: 'HS${widget.userId.toString().padLeft(5, '0')}',
                  ),
                  const Divider(height: 30),
                  
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Họ và tên',
                    value: _displayName.isEmpty ? 'Chưa cập nhật' : _displayName,
                  ),
                  const Divider(height: 30),
                  
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Số điện thoại',
                    value: _formatPhoneNumber(_phoneNumber),
                  ),
                  const Divider(height: 30),
                  
                  _buildInfoRow(
                    icon: Icons.class_outlined,
                    label: 'Lớp',
                    value: _classInfoLabel(),
                  ),
                  const Divider(height: 30),
                  
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Ngày tạo tài khoản',
                    value: _formatDate(_createdAt),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Bảo mật: 2FA
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bảo mật',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.verified_user_outlined, color: LoginStyle.primaryColor),
                    title: const Text('Xác thực 2 bước (SMS OTP)'),
                    subtitle: const Text(
                      'Khi bật, sau khi nhập đúng mật khẩu hệ thống sẽ gửi mã OTP tới số điện thoại. Cần server bật gửi SMS.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _twoFactorEnabled,
                    onChanged: _twoFactorBusy
                        ? null
                        : (v) async {
                            setState(() {
                              _twoFactorBusy = true;
                              _twoFactorEnabled = v;
                            });
                            try {
                              final u = await _userApi.setTwoFactorEnabled(v);
                              if (!mounted) return;
                              setState(() => _twoFactorEnabled = u.twoFactorEnabled);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(v ? 'Đã bật xác thực 2 bước' : 'Đã tắt xác thực 2 bước'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _twoFactorEnabled = !v);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Không thể cập nhật: ${_formatError(e)}'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _twoFactorBusy = false);
                            }
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Các nút chức năng
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Chỉnh sửa thông tin',
                    onTap: () async {
                      final updated = await Navigator.push<UserModel>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            initialFullName: _displayName,
                            initialPhone: _phoneNumber,
                            initialClassName: _className,
                          ),
                        ),
                      );
                      if (!mounted || updated == null) return;
                      setState(() {
                        final fn = updated.fullName?.trim();
                        _displayName =
                            (fn != null && fn.isNotEmpty) ? fn : updated.phoneNumber;
                        _phoneNumber = updated.phoneNumber;
                        _className = updated.className;
                        if (updated.createdAt.isNotEmpty) {
                          _createdAt = updated.createdAt;
                        }
                        _twoFactorEnabled = updated.twoFactorEnabled;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.lock_outline,
                    label: 'Đổi mật khẩu',
                    onTap: () async {
                      await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: LoginStyle.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: LoginStyle.primaryColor, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: LoginStyle.primaryColor),
              const SizedBox(width: 15),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Chưa rõ';
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
