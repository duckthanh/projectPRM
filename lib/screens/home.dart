import 'package:flutter/material.dart';
import 'loginStyle.dart';
import 'student_scores.dart';
import 'time_table.dart';
import 'profile.dart';
import 'login.dart';
import 'student_applications.dart';
import 'notifications_screen.dart';
import '../api/auth_storage.dart';
import '../api/api_client.dart';
import '../api/application_api.dart';
import '../widgets/notification_badge.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String displayName;
  final String phoneNumber;
  final String? className;
  final String createdAt;
  final bool twoFactorEnabled;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.displayName,
    required this.phoneNumber,
    this.className,
    this.createdAt = '',
    this.twoFactorEnabled = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApplicationApi _appApi = ApplicationApi(ApiClient());
  int _notificationCount = 0;
  late bool _twoFactorEnabled;
  late String _displayName;
  late String _phoneNumber;
  String? _className;
  late String _createdAt;

  @override
  void initState() {
    super.initState();
    _twoFactorEnabled = widget.twoFactorEnabled;
    _displayName = widget.displayName;
    _phoneNumber = widget.phoneNumber;
    _className = widget.className;
    _createdAt = widget.createdAt;
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final apps = await _appApi.getMyApplications();
      // Đếm số đơn đã được xử lý (có thể thêm logic đánh dấu đã đọc sau)
      final processedCount = apps.where((a) => a.status != 'PENDING').length;
      setState(() => _notificationCount = processedCount);
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: LoginStyle.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          NotificationBadge(
            count: _notificationCount,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _loadNotificationCount();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [LoginStyle.primaryColor, LoginStyle.backgroundColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, ${_displayName.isEmpty ? 'bạn' : _displayName}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chào mừng bạn đến với ứng dụng',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Tính năng',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: widget.userId,
                      displayName: _displayName,
                      phoneNumber: _phoneNumber,
                      className: _className,
                      createdAt: _createdAt,
                      twoFactorEnabled: _twoFactorEnabled,
                    ),
                  ),
                );
                if (mounted) {
                  final user = AuthStorage.user;
                  setState(() {
                    final fullName = user?['fullName']?.toString().trim();
                    final phoneNumber = user?['phoneNumber']?.toString();
                    final className = user?['className']?.toString();
                    final createdAt = user?['createdAt']?.toString();

                    _displayName = (fullName != null && fullName.isNotEmpty)
                        ? fullName
                        : (phoneNumber ?? _displayName);
                    if (phoneNumber != null && phoneNumber.isNotEmpty) {
                      _phoneNumber = phoneNumber;
                    }
                    _className = className;
                    if (createdAt != null && createdAt.isNotEmpty) {
                      _createdAt = createdAt;
                    }
                    _twoFactorEnabled = AuthStorage.user?['twoFactorEnabled'] == true;
                  });
                }
              },
              child: _buildFeatureCard(
                icon: Icons.person,
                title: 'Thông tin cá nhân',
                description: 'Xem và cập nhật thông tin tài khoản',
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentScoresScreen(
                      userId: widget.userId,
                      displayName: widget.displayName,
                    ),
                  ),
                );
              },
              child: _buildFeatureCard(
                icon: Icons.grade,
                title: 'Xem điểm học sinh',
                description: 'Xem bảng điểm chi tiết theo từng môn',
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimeTableScreen(
                      userId: widget.userId,
                      displayName: widget.displayName,
                    ),
                  ),
                );
              },
              child: _buildFeatureCard(
                icon: Icons.calendar_today,
                title: 'Thời khóa biểu',
                description: 'Xem lịch học trong tuần',
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentApplicationsScreen(),
                  ),
                );
              },
              child: _buildFeatureCard(
                icon: Icons.description,
                title: 'Đơn từ',
                description: 'Gửi và theo dõi đơn xin phép',
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 30),

            // Nút đăng xuất
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthStorage.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
