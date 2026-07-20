import 'package:flutter/material.dart';
import 'loginStyle.dart';
import '../api/api_client.dart';
import '../api/score_api.dart';
import '../models/score_model.dart';
import '../models/academic_period.dart';
import '../models/academic_summary_model.dart';

class StudentScoresScreen extends StatefulWidget {
  final int userId;
  final String displayName;

  const StudentScoresScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<StudentScoresScreen> createState() => _StudentScoresScreenState();
}

class _StudentScoresScreenState extends State<StudentScoresScreen> {
  final ScoreApi _scoreApi = ScoreApi(ApiClient());
  late Future<List<ScoreModel>> _future;
  late Future<AcademicSummaryModel> _summaryFuture;
  late String _academicYear;
  late int _semester;

  @override
  void initState() {
    super.initState();
    final period = AcademicPeriod.current();
    _academicYear = period.academicYear;
    _semester = period.semester;
    _reload();
  }

  void _reload() {
    _future = _scoreApi.getScoresByUserId(
      widget.userId,
      academicYear: _academicYear,
      semester: _semester,
    );
    _summaryFuture = _scoreApi.getAcademicSummary(widget.userId, _academicYear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginStyle.backgroundColor,
      appBar: AppBar(
        title: const Text('Bảng điểm học sinh'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            LoginStyle.buildBackgroundLayers(context),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: LoginStyle.mainCardDecoration,
              child: FutureBuilder<List<ScoreModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điểm học sinh - ${widget.displayName}',
                          style: LoginStyle.titleTextStyle,
                        ),
                        const SizedBox(height: 12),
                        Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _reload();
                          }),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    );
                  }

                  final scores = snapshot.data ?? <ScoreModel>[];
                  final subjects = _summarizeScores(scores);
                  final totalCoefficient = subjects.fold<double>(
                    0,
                    (sum, item) => sum + item.totalCoefficient,
                  );
                  final average = totalCoefficient == 0
                      ? 0.0
                      : subjects.fold<double>(
                              0,
                              (sum, item) =>
                                  sum + item.average * item.totalCoefficient,
                            ) /
                            totalCoefficient;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _academicYear,
                              decoration: const InputDecoration(
                                labelText: 'Năm học',
                              ),
                              items: AcademicPeriod.yearOptions()
                                  .map(
                                    (year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _academicYear = value;
                                  _reload();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _semester,
                              decoration: const InputDecoration(
                                labelText: 'Học kỳ',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('Học kỳ 1'),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text('Học kỳ 2'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _semester = value;
                                  _reload();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Điểm học sinh${widget.displayName.isEmpty ? '' : ' - ${widget.displayName}'}',
                        style: LoginStyle.titleTextStyle,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              LoginStyle.primaryColor,
                              LoginStyle.backgroundColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Điểm trung bình',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              average.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _rankFromAverage(average),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<AcademicSummaryModel>(
                        future: _summaryFuture,
                        builder: (context, summarySnapshot) {
                          if (!summarySnapshot.hasData)
                            return const SizedBox.shrink();
                          final summary = summarySnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tổng kết năm học',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _summaryCard('HK1', summary.semester1Average),
                                  const SizedBox(width: 8),
                                  _summaryCard('HK2', summary.semester2Average),
                                  const SizedBox(width: 8),
                                  _summaryCard('Cả năm', summary.yearlyAverage),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (summary.subjects.isNotEmpty)
                                SizedBox(
                                  height: 180,
                                  child: ListView.builder(
                                    itemCount: summary.subjects.length,
                                    itemBuilder: (context, index) {
                                      final subject = summary.subjects[index];
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(subject.subjectName),
                                        subtitle: Text(
                                          'HK1: ${_formatNullableScore(subject.semester1Average)}  •  '
                                          'HK2: ${_formatNullableScore(subject.semester2Average)}',
                                        ),
                                        trailing: Text(
                                          _formatNullableScore(
                                            subject.yearlyAverage,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Chi tiết từng môn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: subjects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = subjects[index];
                            final color = _colorForScore(item.average);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.subject,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.assessmentCount == 1
                                              ? '1 đầu điểm • Hệ số ${item.totalCoefficient.toStringAsFixed(0)}'
                                              : '${item.assessmentCount} đầu điểm • Tổng hệ số ${item.totalCoefficient.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.average.toStringAsFixed(2),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _statusFromScore(item.average),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, double? value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _formatNullableScore(value),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNullableScore(double? value) => value?.toStringAsFixed(2) ?? '—';

class _SubjectScoreSummary {
  final String subject;
  final double average;
  final double totalCoefficient;
  final int assessmentCount;

  const _SubjectScoreSummary({
    required this.subject,
    required this.average,
    required this.totalCoefficient,
    required this.assessmentCount,
  });
}

List<_SubjectScoreSummary> _summarizeScores(List<ScoreModel> scores) {
  final grouped = <String, List<ScoreModel>>{};
  final seenIds = <int>{};

  for (final score in scores) {
    if (score.id != null && !seenIds.add(score.id!)) continue;
    grouped.putIfAbsent(score.subject, () => <ScoreModel>[]).add(score);
  }

  return grouped.entries.map((entry) {
    final totalCoefficient = entry.value.fold<double>(
      0,
      (sum, score) => sum + score.coefficient,
    );
    final weightedTotal = entry.value.fold<double>(
      0,
      (sum, score) => sum + score.score * score.coefficient,
    );

    return _SubjectScoreSummary(
      subject: entry.key,
      average: totalCoefficient == 0 ? 0 : weightedTotal / totalCoefficient,
      totalCoefficient: totalCoefficient,
      assessmentCount: entry.value.length,
    );
  }).toList();
}

Color _colorForScore(double score) {
  if (score >= 8.0) return Colors.green;
  if (score >= 6.5) return Colors.orange;
  return Colors.red;
}

String _statusFromScore(double score) {
  if (score >= 8.0) return 'Giỏi';
  if (score >= 6.5) return 'Khá';
  if (score >= 5.0) return 'Trung bình';
  return 'Yếu';
}

String _rankFromAverage(double avg) {
  if (avg >= 8.0) return 'Xếp loại: Giỏi';
  if (avg >= 6.5) return 'Xếp loại: Khá';
  if (avg >= 5.0) return 'Xếp loại: Trung bình';
  return 'Xếp loại: Yếu';
}
