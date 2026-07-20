class ClassStatisticsModel {
  final int classId;
  final String className;
  final int totalStudents;
  final double classAverageScore;
  final int excellentCount;
  final int goodCount;
  final int averageCount;
  final int belowAverageCount;
  final List<SubjectStatistics> subjectStatistics;

  ClassStatisticsModel({
    required this.classId,
    required this.className,
    required this.totalStudents,
    required this.classAverageScore,
    required this.excellentCount,
    required this.goodCount,
    required this.averageCount,
    required this.belowAverageCount,
    required this.subjectStatistics,
  });

  factory ClassStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ClassStatisticsModel(
      classId: json['classId'] ?? 0,
      className: json['className'] ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      classAverageScore: (json['classAverageScore'] ?? 0).toDouble(),
      excellentCount: json['excellentCount'] ?? 0,
      goodCount: json['goodCount'] ?? 0,
      averageCount: json['averageCount'] ?? 0,
      belowAverageCount: json['belowAverageCount'] ?? 0,
      subjectStatistics: (json['subjectStatistics'] as List<dynamic>?)
              ?.map((e) => SubjectStatistics.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class SubjectStatistics {
  final int subjectId;
  final String subjectName;
  final double averageScore;
  final double highestScore;
  final double lowestScore;

  SubjectStatistics({
    required this.subjectId,
    required this.subjectName,
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
  });

  factory SubjectStatistics.fromJson(Map<String, dynamic> json) {
    return SubjectStatistics(
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      highestScore: (json['highestScore'] ?? 0).toDouble(),
      lowestScore: (json['lowestScore'] ?? 0).toDouble(),
    );
  }
}
