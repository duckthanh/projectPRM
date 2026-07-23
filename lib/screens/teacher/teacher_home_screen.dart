import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/application_api.dart';
import '../../api/auth_storage.dart';
import '../login.dart';
import 'applications_tab.dart';
import 'scores_tab.dart';
import 'statistics_tab.dart';
import 'students_tab.dart';
import 'teacher_theme.dart';

/// Màn hình chính giáo viên — 4 tab giống Teacher Web.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final ApplicationApi _appApi = ApplicationApi(ApiClient());
  int _selectedIndex = 0;
  int _pendingCount = 0;

  String get _fullName {
    final user = AuthStorage.user;
    final name = user?['fullName']?.toString();
    if (name != null && name.isNotEmpty) return name;
    return user?['phoneNumber']?.toString() ?? 'Giáo viên';
  }

  String get _phone => AuthStorage.user?['phoneNumber']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final apps = await _appApi.getPendingApplications();
      if (!mounted) return;
      setState(() => _pendingCount = apps.length);
    } catch (_) {}
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              AuthStorage.clear();
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherTheme.weak,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  const StudentsTab(),
                  const ScoresTab(),
                  ApplicationsTab(
                    onPendingCountChange: (count) {
                      setState(() => _pendingCount = count);
                    },
                  ),
                  const StatisticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 2) _loadPendingCount();
        },
        backgroundColor: Colors.white,
        indicatorColor: TeacherTheme.primary.withValues(alpha: 0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: TeacherTheme.primary),
            label: 'Học sinh',
          ),
          const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note, color: TeacherTheme.primary),
            label: 'Nhập điểm',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _pendingCount > 0,
              label: Text('$_pendingCount'),
              child: const Icon(Icons.description_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _pendingCount > 0,
              label: Text('$_pendingCount'),
              child: const Icon(Icons.description, color: TeacherTheme.primary),
            ),
            label: 'Đơn từ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: TeacherTheme.primary),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TeacherTheme.sidebar, TeacherTheme.sidebarAlt],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MyShool · Giáo viên',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fullName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (_phone.isNotEmpty)
                  Text(
                    _phone,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
