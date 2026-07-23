class ScoreImportResult {
  final int totalRows;
  final int validRows;
  final int duplicateRows;
  final int errorRows;
  final int importedRows;
  final bool canImport;
  final String message;
  final List<ScoreImportRow> rows;

  const ScoreImportResult({
    required this.totalRows,
    required this.validRows,
    required this.duplicateRows,
    required this.errorRows,
    required this.importedRows,
    required this.canImport,
    required this.message,
    required this.rows,
  });

  factory ScoreImportResult.fromJson(Map<String, dynamic> json) {
    return ScoreImportResult(
      totalRows: json['totalRows'] ?? 0,
      validRows: json['validRows'] ?? 0,
      duplicateRows: json['duplicateRows'] ?? 0,
      errorRows: json['errorRows'] ?? 0,
      importedRows: json['importedRows'] ?? 0,
      canImport: json['canImport'] == true,
      message: json['message']?.toString() ?? '',
      rows: (json['rows'] as List<dynamic>? ?? [])
          .map((e) => ScoreImportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScoreImportRow {
  final int rowNumber;
  final String? phoneNumber;
  final String? studentName;
  final String? subjectCode;
  final double? score;
  final double? coefficient;
  final String status;
  final String? message;

  const ScoreImportRow({
    required this.rowNumber,
    this.phoneNumber,
    this.studentName,
    this.subjectCode,
    this.score,
    this.coefficient,
    required this.status,
    this.message,
  });

  factory ScoreImportRow.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) =>
        value == null ? null : (value as num).toDouble();
    return ScoreImportRow(
      rowNumber: json['rowNumber'] ?? 0,
      phoneNumber: json['phoneNumber']?.toString(),
      studentName: json['studentName']?.toString(),
      subjectCode: json['subjectCode']?.toString(),
      score: number(json['score']),
      coefficient: number(json['coefficient']),
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'VALID':
        return 'Hợp lệ';
      case 'DUPLICATE':
        return 'Trùng';
      case 'ERROR':
        return 'Lỗi';
      default:
        return status;
    }
  }
}
