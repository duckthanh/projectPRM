import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/timetable_api.dart';
import '../models/timetable_model.dart';

class TimeTableScreen extends StatefulWidget {

  final int userId;
  final String displayName;

  const TimeTableScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<TimeTableScreen> createState() => _TimeTableScreenState();
}

class _TimeTableScreenState extends State<TimeTableScreen> {
  final TimeTableApi _api = TimeTableApi(ApiClient());
  late Future<List<TimeTableModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getByUserId(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thời khóa biểu'),
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: FutureBuilder<List<TimeTableModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _future = _api.getByUserId(widget.userId);
                      }),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data ?? <TimeTableModel>[];
            final Map<String, List<TimeTableModel>> grouped = {};
            for (final it in items) {
              grouped.putIfAbsent(it.dayOfWeek, () => []).add(it);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 16),
                if (grouped.isEmpty)
                  const Center(child: Text('Chưa có thời khóa biểu')),
                ...grouped.entries.map(
                  (entry) => _buildDayCard(
                    day: entry.key,
                    items: entry.value,
                    isToday: _isToday(entry.key),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch học trong tuần ${widget.displayName.isEmpty ? 'của bạn' : 'của ${widget.displayName}'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required String day,
    required List<TimeTableModel> items,
    required bool isToday,
  }) {
    final Color accent = isToday ? const Color(0xFF1E88E5) : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isToday ? accent.withOpacity(0.5) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isToday ? Icons.today : Icons.calendar_today,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      day + (isToday ? ' (Hôm nay)' : ''),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(_buildTimeRow),
        ],
      ),
    );
  }

  Widget _buildTimeRow(TimeTableModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.slot,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phòng: ${item.room}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String dayLabel) {
    final now = DateTime.now();
    final int weekday = now.weekday;

    switch (dayLabel) {
      case 'Thứ 2':
        return weekday == DateTime.monday;
      case 'Thứ 3':
        return weekday == DateTime.tuesday;
      case 'Thứ 4':
        return weekday == DateTime.wednesday;
      case 'Thứ 5':
        return weekday == DateTime.thursday;
      case 'Thứ 6':
        return weekday == DateTime.friday;
      case 'Thứ 7':
        return weekday == DateTime.saturday;
      default:
        return false;
    }
  }
}
