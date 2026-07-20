class TimeTableModel {
  final int? id;
  final int userId;
  final String dayOfWeek;
  final String slot;
  final String subject;
  final String room;

  TimeTableModel({
    this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.slot,
    required this.subject,
    required this.room,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'day_of_week': dayOfWeek,
      'slot': slot,
      'subject': subject,
      'room': room,
    };
  }

  factory TimeTableModel.fromMap(Map<String, dynamic> map) {
    return TimeTableModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      dayOfWeek: map['day_of_week'] as String,
      slot: map['slot'] as String,
      subject: map['subject'] as String,
      room: map['room'] as String,
    );
  }

  factory TimeTableModel.fromJson(Map<String, dynamic> json) {
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

    return TimeTableModel(
      id: json['id'] as int?,
      userId: userId,
      dayOfWeek: (json['dayOfWeek'] as String?) ?? '',
      slot: (json['slot'] as String?) ?? '',
      subject: subjectName,
      room: (json['room'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'dayOfWeek': dayOfWeek,
      'slot': slot,
      'subject': subject,
      'room': room,
    };
  }
}
