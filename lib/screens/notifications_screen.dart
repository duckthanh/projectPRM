import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/application_api.dart';
import '../api/auth_storage.dart';
import '../models/application_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApplicationApi _api = ApplicationApi(ApiClient());
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final List<NotificationItem> items = [];

      if (AuthStorage.isTeacher || AuthStorage.isAdmin) {
        // Giáo viên: thông báo đơn mới cần duyệt
        final pendingApps = await _api.getPendingApplications();
        for (var app in pendingApps) {
          items.add(NotificationItem(
            id: app.id,
            type: 'NEW_APPLICATION',
            title: 'Đơn mới từ ${app.student?.fullName ?? 'Học sinh'}',
            message: app.title,
            time: app.createdAt ?? '',
            isRead: false,
            data: app,
          ));
        }
      } else {
        // Học sinh: thông báo đơn đã được xử lý
        final myApps = await _api.getMyApplications();
        for (var app in myApps) {
          if (app.status != 'PENDING') {
            items.add(NotificationItem(
              id: app.id,
              type: app.status == 'APPROVED' ? 'APPROVED' : 'REJECTED',
              title: app.status == 'APPROVED' ? 'Đơn đã được duyệt' : 'Đơn bị từ chối',
              message: app.title,
              time: app.respondedAt ?? app.createdAt ?? '',
              isRead: true,
              data: app,
            ));
          }
        }
      }

      setState(() => _notifications = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'NEW_APPLICATION':
        return Icons.description;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'NEW_APPLICATION':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showDetail(NotificationItem item) {
    final app = item.data as ApplicationModel?;
    if (app == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIcon(item.type), color: _getColor(item.type)),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRow('Tiêu đề', app.title),
              _buildRow('Loại đơn', app.typeText),
              _buildRow('Trạng thái', app.statusText),
              if (app.student != null)
                _buildRow('Học sinh', app.student!.fullName ?? 'N/A'),
              _buildRow('Ngày gửi', app.createdAt ?? 'N/A'),
              if (app.respondedAt != null)
                _buildRow('Ngày xử lý', app.respondedAt!),
              const Divider(),
              const Text('Nội dung:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(app.content),
              if (app.responseNote != null && app.responseNote!.isNotEmpty) ...[
                const Divider(),
                const Text('Phản hồi:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(app.responseNote!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Không có thông báo', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Card(
                        color: item.isRead ? null : Colors.blue.shade50,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColor(item.type).withOpacity(0.2),
                            child: Icon(_getIcon(item.type), color: _getColor(item.type)),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.message),
                              Text(
                                item.time,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: !item.isRead
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          onTap: () => _showDetail(item),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class NotificationItem {
  final int id;
  final String type;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final dynamic data;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    this.data,
  });
}
