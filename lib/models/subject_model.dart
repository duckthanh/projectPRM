class SubjectModel {
  final int id;
  final String code;
  final String name;
  final int? credits;
  final bool active;

  SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    this.credits,
    this.active = true,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      credits: json['credits'],
      active: json['active'] ?? true,
    );
  }
}
