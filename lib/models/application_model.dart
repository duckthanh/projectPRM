class ApplicationModel {
  final int id;
  final String type;
  final String title;
  final String content;
  final String status;
  final String? responseNote;
  final String? createdAt;
  final String? updatedAt;
  final String? respondedAt;
  final StudentInfo? student;
  final TeacherInfo? teacher;

  ApplicationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.status,
    this.responseNote,
    this.createdAt,
    this.updatedAt,
    this.respondedAt,
    this.student,
    this.teacher,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      status: json['status'] ?? 'PENDING',
      responseNote: json['responseNote'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      respondedAt: json['respondedAt'],
      student: json['student'] != null
          ? StudentInfo.fromJson(json['student'])
          : null,
      teacher: json['teacher'] != null
          ? TeacherInfo.fromJson(json['teacher'])
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Chờ duyệt';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Từ chối';
      default:
        return status;
    }
  }

  String get typeText {
    switch (type) {
      case 'LEAVE':
        return 'Xin nghỉ phép';
      case 'LATE':
        return 'Xin đi muộn';
      case 'CERTIFICATE':
        return 'Xin giấy xác nhận';
      case 'OTHER':
        return 'Khác';
      default:
        return type;
    }
  }
}

class StudentInfo {
  final int id;
  final String? fullName;
  final String? phoneNumber;
  final String? className;

  StudentInfo({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.className,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] ?? 0,
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      className: json['className'],
    );
  }
}

class TeacherInfo {
  final int id;
  final String? fullName;
  final String? phoneNumber;

  TeacherInfo({
    required this.id,
    this.fullName,
    this.phoneNumber,
  });

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    return TeacherInfo(
      id: json['id'] ?? 0,
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
