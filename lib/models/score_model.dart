class ScoreModel {
  final int? id;
  final int userId;
  final String subject;
  final double score;
  final double coefficient;
  final String createdAt;
  final String academicYear;
  final int semester;

  ScoreModel({
    this.id,
    required this.userId,
    required this.subject,
    required this.score,
    this.coefficient = 1.0,
    required this.createdAt,
    this.academicYear = '',
    this.semester = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'score': score,
      'coefficient': coefficient,
      'created_at': createdAt,
      'academic_year': academicYear,
      'semester': semester,
    };
  }

  factory ScoreModel.fromMap(Map<String, dynamic> map) {
    return ScoreModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      subject: map['subject'] as String,
      score: (map['score'] as num).toDouble(),
      coefficient: (map['coefficient'] as num?)?.toDouble() ?? 1.0,
      createdAt: map['created_at'] as String,
      academicYear: map['academic_year'] as String? ?? '',
      semester: map['semester'] as int? ?? 0,
    );
  }

  factory ScoreModel.fromJson(Map<String, dynamic> json) {
    // Backend trả về user và subject là object
    int userId = 0;
    if (json['user'] != null && json['user'] is Map) {
      userId = (json['user']['id'] as num?)?.toInt() ?? 0;
    } else if (json['userId'] != null) {
      userId = (json['userId'] as num).toInt();
    }

    String subjectName = '';
    if (json['subject'] != null && json['subject'] is Map) {
      subjectName = (json['subject']['name'] as String?) ?? '';
    } else if (json['subject'] is String) {
      subjectName = json['subject'] as String;
    }

    return ScoreModel(
      id: json['id'] as int?,
      userId: userId,
      subject: subjectName,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      createdAt: (json['createdAt'] as String?) ?? '',
      academicYear: (json['academicYear'] as String?) ?? '',
      semester: (json['semester'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'score': score,
      'coefficient': coefficient,
      'createdAt': createdAt,
      'academicYear': academicYear,
      'semester': semester,
    };
  }
}
