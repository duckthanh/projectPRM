import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/school_class_api.dart';
import '../../api/teacher_api.dart';
import '../../models/academic_period.dart';
import '../../models/academic_summary_model.dart';
import '../../models/school_class_model.dart';
import '../../models/student_score_model.dart';
import 'teacher_theme.dart';

/// Học sinh theo lớp — tương đương StudentsPage webapp.
class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final TeacherApi _teacherApi = TeacherApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());

  List<StudentScoreModel> _students = [];
  List<SchoolClassModel> _classes = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedClassId;
  String _academicYear = AcademicPeriod.current().academicYear;
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
        if (classes.isNotEmpty && _selectedClassId == null) {
          _selectedClassId = classes.first.id;
        }
        _error = null;
      });
      if (_selectedClassId != null) {
        await _loadStudents();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = 'Không tải được danh sách lớp';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students = await _teacherApi.getClassScores(
        _selectedClassId!,
        academicYear: _academicYear,
        semester: _semester,
      );
      setState(() => _students = students);
    } catch (e) {
      setState(() => _error = 'Không tải được danh sách học sinh');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  SchoolClassModel? get _selectedClass {
    for (final c in _classes) {
      if (c.id == _selectedClassId) return c;
    }
    return null;
  }

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);

  void _openStudent(StudentScoreModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          TeacherTheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        student.studentName.isNotEmpty
                            ? student.studentName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: TeacherTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.studentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$_academicYear · HK $_semester · TB ${student.averageScore.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: TeacherTheme.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Điểm học kỳ hiện tại',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (student.scores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Học sinh này chưa có điểm.',
                      style: TextStyle(color: TeacherTheme.muted),
                    ),
                  )
                else
                  ...student.scores.map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TeacherTheme.bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.subjectName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Hệ số ${s.coefficient.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: TeacherTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            s.score.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: s.score >= 5
                                  ? TeacherTheme.excellent
                                  : TeacherTheme.weak,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Tổng kết năm học $_academicYear',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                FutureBuilder<AcademicSummaryModel>(
                  future: _teacherApi.getAcademicSummary(
                    student.studentId,
                    _academicYear,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Text(
                        'Không tải được tổng kết năm học.',
                        style: TextStyle(color: TeacherTheme.muted),
                      );
                    }
                    final summary = snapshot.data!;
                    return Column(
                      children: [
                        Row(
                          children: [
                            TeacherTheme.miniStat(
                              label: 'TB HK1',
                              value: _fmt(summary.semester1Average),
                            ),
                            TeacherTheme.miniStat(
                              label: 'TB HK2',
                              value: _fmt(summary.semester2Average),
                            ),
                            TeacherTheme.miniStat(
                              label: 'Cả năm',
                              value: _fmt(summary.yearlyAverage),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (summary.subjects.isEmpty)
                          const Text(
                            'Chưa có dữ liệu theo môn.',
                            style: TextStyle(color: TeacherTheme.muted),
                          )
                        else
                          Container(
                            decoration: TeacherTheme.cardDecoration(radius: 16),
                            child: Column(
                              children: [
                                const ListTile(
                                  dense: true,
                                  title: Text(
                                    'Môn học',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  trailing: Text(
                                    'HK1 / HK2 / Cả năm',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: TeacherTheme.muted,
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                ...summary.subjects.map(
                                  (sub) => ListTile(
                                    dense: true,
                                    title: Text(sub.subjectName),
                                    trailing: Text(
                                      '${_fmt(sub.semester1Average)} · '
                                      '${_fmt(sub.semester2Average)} · '
                                      '${_fmt(sub.yearlyAverage)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeacherTheme.pageHeader(
          title: 'Học sinh theo lớp',
          subtitle: 'Xem danh sách học sinh và điểm trung bình của từng em.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _academicYear,
                    items: AcademicPeriod.yearOptions()
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _academicYear = v);
                      _loadStudents();
                    },
                  ),
                ),
              ),
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _semester,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                      DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _semester = v);
                      _loadStudents();
                    },
                  ),
                ),
              ),
              _dropdownShell(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedClassId,
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
                      setState(() => _selectedClassId = v);
                      _loadStudents();
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: _loadStudents,
                icon: const Icon(Icons.refresh, color: TeacherTheme.primary),
              ),
            ],
          ),
        ),
        if (_selectedClass != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  _selectedClass!.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${_students.length} học sinh',
                  style: const TextStyle(color: TeacherTheme.muted),
                ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: TeacherTheme.weak)),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? const Center(
                      child: Text(
                        'Không có học sinh trong lớp này.',
                        style: TextStyle(color: TeacherTheme.muted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final s = _students[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: TeacherTheme.cardDecoration(radius: 18),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: TeacherTheme.primary
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  s.studentName.isNotEmpty
                                      ? s.studentName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: TeacherTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                s.studentName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'TB học kỳ $_semester: ${s.averageScore.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: TeacherTheme.muted,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: TeacherTheme.levelBadge(s.averageScore),
                              onTap: () => _openStudent(s),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _dropdownShell({required Widget child}) {
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
