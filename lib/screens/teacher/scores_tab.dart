import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/school_class_api.dart';
import '../../api/subject_api.dart';
import '../../api/teacher_api.dart';
import '../../models/academic_period.dart';
import '../../models/school_class_model.dart';
import '../../models/score_import_model.dart';
import '../../models/subject_model.dart';
import 'native_file.dart';
import 'teacher_theme.dart';

/// Nhập điểm — Excel + nhập tay, giống ScoresPage webapp.
class ScoresTab extends StatefulWidget {
  const ScoresTab({super.key});

  @override
  State<ScoresTab> createState() => _ScoresTabState();
}

class _ScoresTabState extends State<ScoresTab> {
  final TeacherApi _teacherApi = TeacherApi(ApiClient());
  final SchoolClassApi _classApi = SchoolClassApi(ApiClient());
  final SubjectApi _subjectApi = SubjectApi(ApiClient());
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();

  List<SchoolClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  List<Map<String, dynamic>> _students = [];

  int? _classId;
  int? _studentId;
  int? _subjectId;
  double _coefficient = 1;
  bool _saving = false;
  bool _loadingStudents = false;
  String _year = AcademicPeriod.current().academicYear;
  int _semester = AcademicPeriod.current().semester;

  // Import
  int? _importClassId;
  String _importYear = AcademicPeriod.current().academicYear;
  int _importSemester = AcademicPeriod.current().semester;
  String? _fileName;
  List<int>? _fileBytes;
  ScoreImportResult? _preview;
  bool _importLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final classes = await _classApi.getAllClasses();
      final subjects = await _subjectApi.getAllSubjects();
      setState(() {
        _classes = classes;
        _subjects = subjects;
      });
    } catch (e) {
      _toast('Không tải được dữ liệu ban đầu', error: true);
    }
  }

  Future<void> _loadStudents(int classId) async {
    setState(() => _loadingStudents = true);
    try {
      final list = await _teacherApi.getStudentsByClass(classId);
      setState(() {
        _students = list;
        _studentId = null;
      });
    } catch (_) {
      _toast('Không tải được học sinh', error: true);
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _saveScore() async {
    if (_studentId == null || _subjectId == null) {
      _toast('Vui lòng chọn học sinh và môn học', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _teacherApi.createScore(
        studentId: _studentId!,
        subjectId: _subjectId!,
        score: double.parse(_scoreController.text),
        coefficient: _coefficient,
        academicYear: _year,
        semester: _semester,
      );
      _scoreController.clear();
      setState(() {
        _coefficient = 1;
        _studentId = null;
        _subjectId = null;
      });
      _toast('Đã nhập điểm thành công');
    } catch (e) {
      _toast('Không thể lưu điểm', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _fileName = file.name;
      _fileBytes = file.bytes;
      _preview = null;
    });
  }

  Future<void> _downloadTemplate() async {
    setState(() => _importLoading = true);
    try {
      final bytes = await _teacherApi.downloadScoreImportTemplate();
      await saveAndOpenBytes(bytes, 'score-import-template.xlsx');
      _toast(
        kIsWeb
            ? 'Đã nhận file mẫu từ server. Dùng app mobile/desktop để mở file.'
            : 'Đã tải file Excel mẫu',
      );
    } catch (_) {
      _toast('Không tải được file mẫu', error: true);
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  Future<void> _previewImport() async {
    if (_importClassId == null || _fileBytes == null) {
      _toast('Chọn lớp và file .xlsx', error: true);
      return;
    }
    setState(() => _importLoading = true);
    try {
      final result = await _teacherApi.previewScoreImport(
        classId: _importClassId!,
        academicYear: _importYear,
        semester: _importSemester,
        fileBytes: _fileBytes!,
        filename: _fileName ?? 'scores.xlsx',
      );
      setState(() => _preview = result);
    } catch (_) {
      setState(() => _preview = null);
      _toast('Không thể đọc file Excel', error: true);
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  Future<void> _confirmImport() async {
    if (_importClassId == null || _fileBytes == null) return;
    setState(() => _importLoading = true);
    try {
      final result = await _teacherApi.importScoresExcel(
        classId: _importClassId!,
        academicYear: _importYear,
        semester: _importSemester,
        fileBytes: _fileBytes!,
        filename: _fileName ?? 'scores.xlsx',
      );
      setState(() {
        _preview = result;
        if (result.importedRows > 0) {
          _fileBytes = null;
          _fileName = null;
        }
      });
      _toast(result.message, error: result.errorRows > 0);
    } catch (_) {
      _toast('Không thể nhập điểm từ Excel', error: true);
    } finally {
      if (mounted) setState(() => _importLoading = false);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? TeacherTheme.weak : TeacherTheme.excellent,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'VALID':
        return TeacherTheme.excellent;
      case 'DUPLICATE':
        return TeacherTheme.average;
      case 'ERROR':
        return TeacherTheme.weak;
      default:
        return TeacherTheme.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TeacherTheme.pageHeader(
            title: 'Nhập điểm học sinh',
            subtitle:
                'Nhập từng điểm hoặc tải file Excel để xử lý hàng loạt theo học kỳ.',
          ),
          _excelCard(),
          const SizedBox(height: 12),
          _manualCard(),
        ],
      ),
    );
  }

  Widget _excelCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: TeacherTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhập điểm bằng Excel',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tải file mẫu, điền dữ liệu, xem trước lỗi rồi xác nhận lưu.',
                      style: TextStyle(color: TeacherTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _importLoading ? null : _downloadTemplate,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('File mẫu'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _importClassId,
            decoration: TeacherTheme.fieldDecoration(
              label: 'Lớp',
              icon: Icons.class_,
            ),
            items: _classes
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() {
              _importClassId = v;
              _preview = null;
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _importYear,
                  decoration: TeacherTheme.fieldDecoration(label: 'Năm học'),
                  items: AcademicPeriod.yearOptions()
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _importYear = v;
                      _preview = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _importSemester,
                  decoration: TeacherTheme.fieldDecoration(label: 'Học kỳ'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                    DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _importSemester = v;
                      _preview = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _importLoading ? null : _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName ?? 'Chọn file .xlsx'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TeacherTheme.primary,
              side: const BorderSide(color: TeacherTheme.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _importLoading ? null : _previewImport,
            style: TeacherTheme.primaryButtonStyle,
            child: _importLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Xem trước và kiểm tra lỗi'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 14),
            _previewBlock(_preview!),
          ],
        ],
      ),
    );
  }

  Widget _previewBlock(ScoreImportResult p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('Tổng ${p.totalRows}', TeacherTheme.muted),
            _chip('Hợp lệ ${p.validRows}', TeacherTheme.excellent),
            _chip('Trùng ${p.duplicateRows}', TeacherTheme.average),
            _chip('Lỗi ${p.errorRows}', TeacherTheme.weak),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          p.message,
          style: TextStyle(
            color: p.errorRows > 0 ? TeacherTheme.weak : TeacherTheme.excellent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...p.rows.map(
          (row) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TeacherTheme.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      _statusColor(row.status).withValues(alpha: 0.15),
                  child: Text(
                    '${row.rowNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(row.status),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${row.studentName ?? '—'} · ${row.subjectCode ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Điểm ${row.score ?? '—'} · HS ${row.coefficient ?? '—'} · ${row.message ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: TeacherTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  row.statusLabel,
                  style: TextStyle(
                    color: _statusColor(row.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _importLoading || !p.canImport || p.importedRows > 0
              ? null
              : _confirmImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherTheme.excellent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            p.importedRows > 0
                ? 'Đã nhập ${p.importedRows} dòng'
                : 'Xác nhận nhập điểm',
          ),
        ),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _manualCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: TeacherTheme.cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nhập một điểm',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Dùng khi cần thêm nhanh một đầu điểm cho học sinh.',
              style: TextStyle(color: TeacherTheme.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _classId,
              decoration: TeacherTheme.fieldDecoration(
                label: 'Chọn lớp',
                icon: Icons.class_,
              ),
              items: _classes
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _classId = v);
                _loadStudents(v);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _studentId,
              decoration: TeacherTheme.fieldDecoration(
                label: 'Chọn học sinh',
                icon: _loadingStudents ? null : Icons.person,
                hint: _classId == null ? 'Chọn lớp trước' : 'Chọn học sinh',
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
              onChanged: (v) => setState(() => _studentId = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _year,
                    decoration: TeacherTheme.fieldDecoration(label: 'Năm học'),
                    items: AcademicPeriod.yearOptions()
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _year = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _semester,
                    decoration: TeacherTheme.fieldDecoration(label: 'Học kỳ'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Học kỳ 1')),
                      DropdownMenuItem(value: 2, child: Text('Học kỳ 2')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _semester = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _subjectId,
              decoration: TeacherTheme.fieldDecoration(
                label: 'Chọn môn học',
                icon: Icons.book,
              ),
              items: _subjects
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _subjectId = v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _scoreController,
              decoration: TeacherTheme.fieldDecoration(
                label: 'Điểm (0-10)',
                icon: Icons.grade,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập điểm';
                final n = double.tryParse(v);
                if (n == null) return 'Điểm phải là số';
                if (n < 0 || n > 10) return 'Điểm từ 0 đến 10';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Hệ số:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                for (final c in [1.0, 2.0, 3.0]) ...[
                  ChoiceChip(
                    label: Text(c.toStringAsFixed(0)),
                    selected: _coefficient == c,
                    selectedColor: TeacherTheme.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: _coefficient == c
                          ? TeacherTheme.primary
                          : TeacherTheme.text,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _coefficient = c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _saveScore,
              style: TeacherTheme.primaryButtonStyle,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu điểm'),
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
