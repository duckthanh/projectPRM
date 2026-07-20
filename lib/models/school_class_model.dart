class SchoolClassModel {
  final int id;
  final String code;
  final String name;
  final String? gradeLevel;
  final bool active;

  SchoolClassModel({
    required this.id,
    required this.code,
    required this.name,
    this.gradeLevel,
    this.active = true,
  });

  factory SchoolClassModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      gradeLevel: json['gradeLevel'],
      active: json['active'] ?? true,
    );
  }
}
