class StudentScoreModel {
  final int studentId;
  final String studentName;
  final String? className;
  final List<ScoreDetail> scores;
  final double averageScore;
  final String academicYear;
  final int semester;

  StudentScoreModel({
    required this.studentId,
    required this.studentName,
    this.className,
    required this.scores,
    required this.averageScore,
    required this.academicYear,
    required this.semester,
  });

  factory StudentScoreModel.fromJson(Map<String, dynamic> json) {
    return StudentScoreModel(
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      className: json['className'],
      scores:
          (json['scores'] as List<dynamic>?)
              ?.map((e) => ScoreDetail.fromJson(e))
              .toList() ??
          [],
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      academicYear: json['academicYear'] ?? '',
      semester: json['semester'] ?? 0,
    );
  }
}

class ScoreDetail {
  final int scoreId;
  final String subjectName;
  final double score;
  final double coefficient;
  final String? createdAt;
  final String academicYear;
  final int semester;

  ScoreDetail({
    required this.scoreId,
    required this.subjectName,
    required this.score,
    required this.coefficient,
    this.createdAt,
    required this.academicYear,
    required this.semester,
  });

  factory ScoreDetail.fromJson(Map<String, dynamic> json) {
    return ScoreDetail(
      scoreId: json['scoreId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      coefficient: (json['coefficient'] ?? 1).toDouble(),
      createdAt: json['createdAt'],
      academicYear: json['academicYear'] ?? '',
      semester: json['semester'] ?? 0,
    );
  }
}
