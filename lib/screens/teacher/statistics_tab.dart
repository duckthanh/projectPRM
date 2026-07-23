import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/school_class_api.dart';
import '../../api/teacher_api.dart';
import '../../models/academic_period.dart';
import '../../models/class_statistics_model.dart';
import '../../models/school_class_model.dart';
import 'teacher_theme.dart';

/// Thống kê lớp — giống StatisticsPage webapp.
class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final TeacherApi _teacherApi = TeacherApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());

  ClassStatisticsModel? _stats;
  List<SchoolClassModel> _classes = [];
  bool _loading = true;
  int? _classId;
  String _year = AcademicPeriod.current().academicYear;
  int _semester = AcademicPeriod.current().semester;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _classApi.getAllClasses();
      setState(() {
        _classes = classes;
        if (classes.isNotEmpty && _classId == null) {
          _classId = classes.first.id;
        }
      });
      if (_classId != null) {
        await _loadStats();
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được danh sách lớp'),
            backgroundColor: TeacherTheme.weak,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    if (_classId == null) return;
    setState(() => _loading = true);
    try {
      final stats = await _teacherApi.getClassStatistics(
        _classId!,
        academicYear: _year,
        semester: _semester,
      );
      setState(() => _stats = stats);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tải được thống kê'),
            backgroundColor: TeacherTheme.weak,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeacherTheme.pageHeader(
          title: 'Thống kê lớp học',
          subtitle:
              'Xem sĩ số, điểm trung bình và phân loại học lực theo từng lớp.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _shell(
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _year,
                    items: AcademicPeriod.yearOptions()
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _year = v);
                      _loadStats();
                    },
                  ),
                ),
              ),
              _shell(
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _semester,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                      DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _semester = v);
                      _loadStats();
                    },
                  ),
                ),
              ),
              _shell(
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _classId,
                    hint: const Text('Chọn lớp'),
                    items: _classes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _classId = v);
                      _loadStats();
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh, color: TeacherTheme.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _stats == null
                  ? const Center(
                      child: Text(
                        'Không có dữ liệu thống kê.',
                        style: TextStyle(color: TeacherTheme.muted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _overviewCard(),
                          const SizedBox(height: 12),
                          _distributionCard(),
                          const SizedBox(height: 12),
                          _subjectCard(),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _overviewCard() {
    final s = _stats!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TeacherTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s.className} · Học kỳ $_semester',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TeacherTheme.miniStat(
                label: 'Sĩ số',
                value: '${s.totalStudents}',
              ),
              TeacherTheme.miniStat(
                label: 'Điểm TB',
                value: s.classAverageScore.toStringAsFixed(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _distributionCard() {
    final s = _stats!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TeacherTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân loại học lực',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _bar('Giỏi', s.excellentCount, TeacherTheme.excellent),
          _bar('Khá', s.goodCount, TeacherTheme.good),
          _bar('Trung bình', s.averageCount, TeacherTheme.average),
          _bar('Yếu', s.belowAverageCount, TeacherTheme.weak),
        ],
      ),
    );
  }

  Widget _bar(String label, int count, Color color) {
    final total = _stats!.totalStudents;
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$count (${(pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(color: TeacherTheme.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: TeacherTheme.bg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard() {
    final subjects = _stats!.subjectStatistics;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TeacherTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống kê theo môn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (subjects.isEmpty)
            const Text(
              'Chưa có thống kê theo môn.',
              style: TextStyle(color: TeacherTheme.muted),
            )
          else ...[
            const ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Môn học',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                'TB · Cao · Thấp',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TeacherTheme.muted,
                ),
              ),
            ),
            const Divider(height: 1),
            ...subjects.map(
              (sub) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sub.subjectName),
                trailing: Text(
                  '${sub.averageScore.toStringAsFixed(2)} · '
                  '${sub.highestScore.toStringAsFixed(1)} · '
                  '${sub.lowestScore.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
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
