class AcademicSummaryModel {
  final int studentId;
  final String studentName;
  final String? className;
  final String academicYear;
  final double? semester1Average;
  final double? semester2Average;
  final double? yearlyAverage;
  final List<SubjectAcademicSummary> subjects;

  const AcademicSummaryModel({
    required this.studentId,
    required this.studentName,
    this.className,
    required this.academicYear,
    this.semester1Average,
    this.semester2Average,
    this.yearlyAverage,
    required this.subjects,
  });

  factory AcademicSummaryModel.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) =>
        value == null ? null : (value as num).toDouble();
    return AcademicSummaryModel(
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      className: json['className'],
      academicYear: json['academicYear'] ?? '',
      semester1Average: number(json['semester1Average']),
      semester2Average: number(json['semester2Average']),
      yearlyAverage: number(json['yearlyAverage']),
      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                SubjectAcademicSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class SubjectAcademicSummary {
  final int subjectId;
  final String subjectName;
  final double? semester1Average;
  final double? semester2Average;
  final double? yearlyAverage;
  final int semester1ScoreCount;
  final int semester2ScoreCount;

  const SubjectAcademicSummary({
    required this.subjectId,
    required this.subjectName,
    this.semester1Average,
    this.semester2Average,
    this.yearlyAverage,
    required this.semester1ScoreCount,
    required this.semester2ScoreCount,
  });

  factory SubjectAcademicSummary.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) =>
        value == null ? null : (value as num).toDouble();
    return SubjectAcademicSummary(
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      semester1Average: number(json['semester1Average']),
      semester2Average: number(json['semester2Average']),
      yearlyAverage: number(json['yearlyAverage']),
      semester1ScoreCount: json['semester1ScoreCount'] ?? 0,
      semester2ScoreCount: json['semester2ScoreCount'] ?? 0,
    );
  }
}
