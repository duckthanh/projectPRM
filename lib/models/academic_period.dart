class AcademicPeriod {
  final String academicYear;
  final int semester;

  const AcademicPeriod({required this.academicYear, required this.semester});

  factory AcademicPeriod.current() {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    return AcademicPeriod(
      academicYear: '$startYear-${startYear + 1}',
      semester: now.month >= 8 ? 1 : 2,
    );
  }

  static List<String> yearOptions() {
    final start = int.parse(
      AcademicPeriod.current().academicYear.substring(0, 4),
    );
    return [
      start - 1,
      start,
      start + 1,
    ].map((year) => '$year-${year + 1}').toList();
  }
}
