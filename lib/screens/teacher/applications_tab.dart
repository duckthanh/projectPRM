import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/application_api.dart';
import '../../models/application_model.dart';
import 'teacher_theme.dart';

/// Đơn từ — giống ApplicationsPage webapp.
class ApplicationsTab extends StatefulWidget {
  final ValueChanged<int>? onPendingCountChange;

  const ApplicationsTab({super.key, this.onPendingCountChange});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  final ApplicationApi _api = ApplicationApi(ApiClient());
  List<ApplicationModel> _apps = [];
  bool _loading = true;
  String _typeFilter = 'ALL';
  String _classFilter = 'ALL';

  List<String> get _classOptions {
    final list = _apps
        .map((a) => a.student?.className?.trim())
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return list;
  }

  List<ApplicationModel> get _filtered {
    return _apps.where((a) {
      final typeOk = _typeFilter == 'ALL' || a.type == _typeFilter;
      final classOk =
          _classFilter == 'ALL' || a.student?.className == _classFilter;
      return typeOk && classOk;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final apps = await _api.getAllApplications();
      setState(() => _apps = apps);
      widget.onPendingCountChange?.call(
        apps.where((a) => a.status == 'PENDING').length,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được danh sách đơn từ'),
            backgroundColor: TeacherTheme.weak,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return TeacherTheme.pending;
      case 'APPROVED':
        return TeacherTheme.excellent;
      case 'REJECTED':
        return TeacherTheme.weak;
      default:
        return TeacherTheme.muted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'LEAVE':
        return Icons.event_busy;
      case 'LATE':
        return Icons.access_time;
      case 'CERTIFICATE':
        return Icons.description;
      default:
        return Icons.note;
    }
  }

  void _openDetail(ApplicationModel app) {
    final noteCtrl = TextEditingController(text: app.responseNote ?? '');
    final pending = app.status == 'PENDING';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(app.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          app.statusText,
                          style: TextStyle(
                            color: _statusColor(app.status),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${app.student?.fullName ?? 'N/A'} · ${app.student?.className ?? ''}',
                    style: const TextStyle(color: TeacherTheme.muted),
                  ),
                  const SizedBox(height: 12),
                  _row('Loại đơn', app.typeText),
                  _row('Ngày gửi', app.createdAt ?? '—'),
                  const SizedBox(height: 10),
                  const Text(
                    'Nội dung',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TeacherTheme.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(app.content),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    enabled: pending,
                    maxLines: 3,
                    decoration: TeacherTheme.fieldDecoration(
                      label: 'Ghi chú phản hồi',
                      hint: 'Nhập ghi chú nếu cần',
                    ),
                  ),
                  if (pending) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _respond(
                                app.id,
                                'REJECTED',
                                noteCtrl.text,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: TeacherTheme.weak,
                              side: const BorderSide(color: TeacherTheme.weak),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _respond(
                                app.id,
                                'APPROVED',
                                noteCtrl.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TeacherTheme.excellent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Duyệt đơn'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(noteCtrl.dispose);
  }

  Future<void> _respond(int id, String status, String note) async {
    try {
      await _api.respondToApplication(
        applicationId: id,
        status: status,
        responseNote: note.isNotEmpty ? note : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'APPROVED' ? 'Đã duyệt đơn' : 'Đã từ chối đơn',
          ),
          backgroundColor: status == 'APPROVED'
              ? TeacherTheme.excellent
              : TeacherTheme.average,
        ),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không phản hồi được đơn'),
          backgroundColor: TeacherTheme.weak,
        ),
      );
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: TeacherTheme.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pending = _apps.where((a) => a.status == 'PENDING').length;
    final leave = _apps.where((a) => a.type == 'LEAVE').length;
    final late = _apps.where((a) => a.type == 'LATE').length;
    final cert = _apps.where((a) => a.type == 'CERTIFICATE').length;

    return Column(
      children: [
        TeacherTheme.pageHeader(
          title: 'Tất cả đơn từ',
          subtitle: 'Xem đơn chờ xử lý, đã duyệt và đã từ chối.',
          trailing: IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: TeacherTheme.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              TeacherTheme.miniStat(
                label: 'Tổng',
                value: '${_apps.length}',
                color: TeacherTheme.primary,
              ),
              TeacherTheme.miniStat(
                label: 'Xin nghỉ',
                value: '$leave',
                color: TeacherTheme.good,
              ),
              TeacherTheme.miniStat(
                label: 'Đi muộn',
                value: '$late',
                color: TeacherTheme.average,
              ),
              TeacherTheme.miniStat(
                label: 'Giấy XN',
                value: '$cert',
                color: TeacherTheme.primarySoft,
              ),
            ],
          ),
        ),
        if (pending > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$pending đơn đang chờ duyệt',
                style: const TextStyle(
                  color: TeacherTheme.pending,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _shell(
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _typeFilter,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Tất cả loại')),
                      DropdownMenuItem(value: 'LEAVE', child: Text('Xin nghỉ')),
                      DropdownMenuItem(value: 'LATE', child: Text('Đi muộn')),
                      DropdownMenuItem(
                        value: 'CERTIFICATE',
                        child: Text('Giấy xác nhận'),
                      ),
                      DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _typeFilter = v);
                    },
                  ),
                ),
              ),
              _shell(
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _classOptions.contains(_classFilter)
                        ? _classFilter
                        : 'ALL',
                    items: [
                      const DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Tất cả lớp'),
                      ),
                      ..._classOptions.map(
                        (n) => DropdownMenuItem(value: n, child: Text(n)),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _classFilter = v);
                    },
                  ),
                ),
              ),
              Text(
                '${filtered.length} kết quả',
                style: const TextStyle(color: TeacherTheme.muted),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        _apps.isEmpty
                            ? 'Chưa có đơn từ nào.'
                            : 'Không có đơn phù hợp với bộ lọc.',
                        style: const TextStyle(color: TeacherTheme.muted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final app = filtered[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: TeacherTheme.cardDecoration(radius: 18),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(app.status)
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  _typeIcon(app.type),
                                  color: _statusColor(app.status),
                                ),
                              ),
                              title: Text(
                                app.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${app.student?.fullName ?? 'N/A'} · ${app.student?.className ?? ''}',
                                  ),
                                  Text(
                                    '${app.typeText} · ${app.createdAt ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TeacherTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                app.statusText,
                                style: TextStyle(
                                  color: _statusColor(app.status),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => _openDetail(app),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _shell(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TeacherTheme.border),
      ),
      child: child,
    );
  }
}
