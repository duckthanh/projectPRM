import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/teacher_api.dart';
import '../api/school_class_api.dart';
import '../api/subject_api.dart';
import '../api/application_api.dart';
import '../api/auth_storage.dart';
import '../models/student_score_model.dart';
import '../models/class_statistics_model.dart';
import '../models/school_class_model.dart';
import '../models/subject_model.dart';
import '../models/application_model.dart';
import '../models/academic_period.dart';
import '../models/academic_summary_model.dart';
import '../widgets/notification_badge.dart';
import 'login.dart';
import 'notifications_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final ApplicationApi _appApi = ApplicationApi(ApiClient());
  int _selectedIndex = 0;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      final apps = await _appApi.getPendingApplications();
      setState(() => _notificationCount = apps.length);
    } catch (e) {
      // Ignore errors
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Giáo viên'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          ClassListTab(),
          InputScoreTab(),
          ApplicationsTab(),
          StatisticsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.indigo,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Học sinh'),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Nhập điểm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Đơn từ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }
}

class ClassListTab extends StatefulWidget {
  const ClassListTab({super.key});

  @override
  State<ClassListTab> createState() => _ClassListTabState();
}

class _ClassListTabState extends State<ClassListTab> {
  final TeacherApi _teacherApi = TeacherApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());
  List<StudentScoreModel> _students = [];
  List<SchoolClassModel> _classes = [];
  bool _isLoading = false;
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
      });
      if (_selectedClassId != null) {
        _loadStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải lớp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    try {
      final students = await _teacherApi.getClassScores(
        _selectedClassId!,
        academicYear: _academicYear,
        semester: _semester,
      );
      setState(() => _students = students);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: _academicYear,
                items: AcademicPeriod.yearOptions()
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text(year)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _academicYear = value);
                  _loadStudents();
                },
              ),
              DropdownButton<int>(
                value: _semester,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                  DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _semester = value);
                  _loadStudents();
                },
              ),
              _classes.isEmpty
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : DropdownButton<int>(
                      value: _selectedClassId,
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedClassId = value);
                        _loadStudents();
                      },
                    ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStudents,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? const Center(child: Text('Không có học sinh'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Text(
                            student.studentName.isNotEmpty
                                ? student.studentName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(student.studentName),
                        subtitle: Text(
                          'Điểm TB: ${student.averageScore.toStringAsFixed(2)}',
                        ),
                        trailing: _buildAverageChip(student.averageScore),
                        onTap: () => _showStudentScores(student),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAverageChip(double avg) {
    Color color;
    String label;
    if (avg >= 8.5) {
      color = Colors.green;
      label = 'Giỏi';
    } else if (avg >= 7.0) {
      color = Colors.blue;
      label = 'Khá';
    } else if (avg >= 5.0) {
      color = Colors.orange;
      label = 'TB';
    } else {
      color = Colors.red;
      label = 'Yếu';
    }
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  void _showStudentScores(StudentScoreModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      student.studentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'TB: ${student.averageScore.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            FutureBuilder<AcademicSummaryModel>(
              future: _teacherApi.getAcademicSummary(
                student.studentId,
                _academicYear,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final summary = snapshot.data!;
                String value(double? score) => score?.toStringAsFixed(2) ?? '—';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryValue(
                        'HK1',
                        value(summary.semester1Average),
                      ),
                      _buildSummaryValue(
                        'HK2',
                        value(summary.semester2Average),
                      ),
                      _buildSummaryValue(
                        'Cả năm',
                        value(summary.yearlyAverage),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: student.scores.length,
                itemBuilder: (context, index) {
                  final score = student.scores[index];
                  return ListTile(
                    title: Text(score.subjectName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.score.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: score.score >= 5 ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'x${score.coefficient.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryValue(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class InputScoreTab extends StatefulWidget {
  const InputScoreTab({super.key});

  @override
  State<InputScoreTab> createState() => _InputScoreTabState();
}

class _InputScoreTabState extends State<InputScoreTab> {
  final TeacherApi _teacherApi = TeacherApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());
  final SubjectApi _subjectApi = SubjectApi(ApiClient());
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();

  List<SchoolClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<Map<String, dynamic>> _students = [];

  int? _selectedClassId;
  int? _selectedStudentId;
  int? _selectedSubjectId;
  double _coefficient = 1.0;
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  String _academicYear = AcademicPeriod.current().academicYear;
  int _semester = AcademicPeriod.current().semester;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final classes = await _classApi.getAllClasses();
      final subjects = await _subjectApi.getAllSubjects();
      setState(() {
        _classes = classes;
        _subjects = subjects;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStudents(int classId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final students = await _teacherApi.getStudentsByClass(classId);
      setState(() {
        _students = students;
        _selectedStudentId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải học sinh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _submitScore() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn học sinh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn môn học'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _teacherApi.createScore(
        studentId: _selectedStudentId!,
        subjectId: _selectedSubjectId!,
        score: double.parse(_scoreController.text),
        coefficient: _coefficient,
        academicYear: _academicYear,
        semester: _semester,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nhập điểm thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _scoreController.clear();
        setState(() => _coefficient = 1.0);
      }
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nhập điểm học sinh',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              value: _academicYear,
              decoration: const InputDecoration(
                labelText: 'Năm học',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              items: AcademicPeriod.yearOptions()
                  .map(
                    (year) => DropdownMenuItem(value: year, child: Text(year)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _academicYear = value);
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: _semester,
              decoration: const InputDecoration(
                labelText: 'Học kỳ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event_note),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _semester = value);
              },
            ),
            const SizedBox(height: 16),

            // Chọn lớp
            DropdownButtonFormField<int>(
              value: _selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Chọn lớp',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_),
              ),
              items: _classes
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedClassId = value);
                  _loadStudents(value);
                }
              },
              hint: const Text('-- Chọn lớp --'),
            ),
            const SizedBox(height: 16),

            // Chọn học sinh
            DropdownButtonFormField<int>(
              value: _selectedStudentId,
              decoration: InputDecoration(
                labelText: 'Chọn học sinh',
                border: const OutlineInputBorder(),
                prefixIcon: _isLoadingStudents
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.person),
              ),
              items: _students
                  .map(
                    (s) => DropdownMenuItem(
                      value: s['id'] as int,
                      child: Text(
                        '${s['fullName'] ?? 'N/A'} (${s['phoneNumber'] ?? ''})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedStudentId = value);
              },
              hint: Text(
                _selectedClassId == null
                    ? '-- Chọn lớp trước --'
                    : '-- Chọn học sinh --',
              ),
            ),
            const SizedBox(height: 16),

            // Chọn môn học
            DropdownButtonFormField<int>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(
                labelText: 'Chọn môn học',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSubjectId = value);
              },
              hint: const Text('-- Chọn môn học --'),
            ),
            const SizedBox(height: 16),

            // Nhập điểm
            TextFormField(
              controller: _scoreController,
              decoration: const InputDecoration(
                labelText: 'Điểm (0-10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập điểm';
                }
                final score = double.tryParse(value);
                if (score == null) {
                  return 'Điểm phải là số';
                }
                if (score < 0 || score > 10) {
                  return 'Điểm phải từ 0 đến 10';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Hệ số
            Row(
              children: [
                const Text('Hệ số: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('1'),
                  selected: _coefficient == 1.0,
                  onSelected: (_) => setState(() => _coefficient = 1.0),
                  selectedColor: Colors.indigo.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('2'),
                  selected: _coefficient == 2.0,
                  onSelected: (_) => setState(() => _coefficient = 2.0),
                  selectedColor: Colors.indigo.shade100,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('3'),
                  selected: _coefficient == 3.0,
                  onSelected: (_) => setState(() => _coefficient = 3.0),
                  selectedColor: Colors.indigo.shade100,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Nút lưu
            ElevatedButton(
              onPressed: _isLoading ? null : _submitScore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu điểm', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }
}

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final TeacherApi _teacherApi = TeacherApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());
  ClassStatisticsModel? _statistics;
  List<SchoolClassModel> _classes = [];
  bool _isLoading = false;
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
      });
      if (_selectedClassId != null) {
        _loadStatistics();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải lớp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    try {
      final stats = await _teacherApi.getClassStatistics(
        _selectedClassId!,
        academicYear: _academicYear,
        semester: _semester,
      );
      setState(() => _statistics = stats);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: _academicYear,
                items: AcademicPeriod.yearOptions()
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text(year)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _academicYear = value);
                  _loadStatistics();
                },
              ),
              DropdownButton<int>(
                value: _semester,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                  DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _semester = value);
                  _loadStatistics();
                },
              ),
              _classes.isEmpty
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : DropdownButton<int>(
                      value: _selectedClassId,
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedClassId = value);
                        _loadStatistics();
                      },
                    ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStatistics,
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _statistics == null
              ? const Center(child: Text('Không có dữ liệu'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildOverviewCard(),
                      const SizedBox(height: 16),
                      _buildDistributionCard(),
                      const SizedBox(height: 16),
                      _buildSubjectCard(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _statistics!.className,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Sĩ số', '${_statistics!.totalStudents}'),
                _buildStatItem(
                  'Điểm TB',
                  _statistics!.classAverageScore.toStringAsFixed(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDistributionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân loại học lực',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDistributionRow(
              'Giỏi (≥8.5)',
              _statistics!.excellentCount,
              Colors.green,
            ),
            _buildDistributionRow(
              'Khá (≥7.0)',
              _statistics!.goodCount,
              Colors.blue,
            ),
            _buildDistributionRow(
              'TB (≥5.0)',
              _statistics!.averageCount,
              Colors.orange,
            ),
            _buildDistributionRow(
              'Yếu (<5.0)',
              _statistics!.belowAverageCount,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, Color color) {
    final total = _statistics!.totalStudents;
    final percentage = total > 0 ? (count / total * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard() {
    if (_statistics!.subjectStatistics.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thống kê theo môn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._statistics!.subjectStatistics.map(
              (subject) => ListTile(
                title: Text(subject.subjectName),
                subtitle: Text(
                  'Cao nhất: ${subject.highestScore} | Thấp nhất: ${subject.lowestScore}',
                ),
                trailing: Text(
                  subject.averageScore.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TAB DUYỆT ĐƠN TỪ ====================

class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({super.key});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  final ApplicationApi _api = ApplicationApi(ApiClient());
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String _typeFilter = 'ALL';
  String _classFilter = 'ALL';

  List<String> get _classOptions {
    final classes =
        _applications
            .map((app) => app.student?.className?.trim())
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return classes;
  }

  List<ApplicationModel> get _filteredApplications {
    return _applications.where((app) {
      final matchesType = _typeFilter == 'ALL' || app.type == _typeFilter;
      final matchesClass =
          _classFilter == 'ALL' || app.student?.className == _classFilter;
      return matchesType && matchesClass;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final apps = await _api.getPendingApplications();
      setState(() => _applications = apps);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
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

  void _showRespondDialog(ApplicationModel app) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Học sinh', app.student?.fullName ?? 'N/A'),
              _buildInfoRow('Lớp', app.student?.className ?? 'N/A'),
              _buildInfoRow('Loại đơn', app.typeText),
              _buildInfoRow('Ngày gửi', app.createdAt ?? 'N/A'),
              const Divider(),
              const Text(
                'Nội dung:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(app.content),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú phản hồi (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _respondToApplication(
                app.id,
                'REJECTED',
                noteController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _respondToApplication(
                app.id,
                'APPROVED',
                noteController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToApplication(int id, String status, String note) async {
    try {
      await _api.respondToApplication(
        applicationId: id,
        status: status,
        responseNote: note.isNotEmpty ? note : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'APPROVED' ? 'Đã duyệt đơn' : 'Đã từ chối đơn',
            ),
            backgroundColor: status == 'APPROVED'
                ? Colors.green
                : Colors.orange,
          ),
        );
        _loadApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredApplications = _filteredApplications;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Đơn chờ duyệt (${filteredApplications.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadApplications,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  DropdownButton<String>(
                    value: _typeFilter,
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Tất cả loại đơn'),
                      ),
                      DropdownMenuItem(
                        value: 'LEAVE',
                        child: Text('Xin nghỉ phép'),
                      ),
                      DropdownMenuItem(
                        value: 'LATE',
                        child: Text('Xin đi muộn'),
                      ),
                      DropdownMenuItem(
                        value: 'CERTIFICATE',
                        child: Text('Giấy xác nhận'),
                      ),
                      DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _typeFilter = value);
                    },
                  ),
                  DropdownButton<String>(
                    value: _classOptions.contains(_classFilter)
                        ? _classFilter
                        : 'ALL',
                    items: [
                      const DropdownMenuItem(
                        value: 'ALL',
                        child: Text('Tất cả lớp'),
                      ),
                      ..._classOptions.map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _classFilter = value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredApplications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('Không có đơn phù hợp với bộ lọc'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredApplications.length,
                    itemBuilder: (context, index) {
                      final app = filteredApplications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                              app.status,
                            ).withOpacity(0.2),
                            child: Icon(
                              _getTypeIcon(app.type),
                              color: _getStatusColor(app.status),
                            ),
                          ),
                          title: Text(
                            app.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${app.student?.fullName ?? 'N/A'} - ${app.student?.className ?? ''}',
                              ),
                              Text(
                                app.createdAt ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showRespondDialog(app),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
