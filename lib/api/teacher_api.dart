import '../models/student_score_model.dart';
import '../models/class_statistics_model.dart';
import '../models/academic_summary_model.dart';
import '../models/score_import_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class TeacherApi {
  final ApiClient _client;

  TeacherApi(this._client);

  /// Lấy danh sách học sinh trong lớp
  Future<List<Map<String, dynamic>>> getStudentsByClass(int classId) async {
    final list = await _client.getJsonList(
      ApiConfig.uri('/api/teacher/class/$classId/students'),
    );
    return list.cast<Map<String, dynamic>>();
  }

  /// Lấy điểm tất cả học sinh trong lớp
  Future<List<StudentScoreModel>> getClassScores(
    int classId, {
    required String academicYear,
    required int semester,
  }) async {
    final uri = ApiConfig.uri('/api/teacher/class/$classId/scores').replace(
      queryParameters: {'academicYear': academicYear, 'semester': '$semester'},
    );
    final list = await _client.getJsonList(uri);
    return list
        .map((e) => StudentScoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lấy điểm của một học sinh
  Future<StudentScoreModel> getStudentScores(
    int studentId, {
    required String academicYear,
    required int semester,
  }) async {
    final uri = ApiConfig.uri('/api/teacher/student/$studentId/scores').replace(
      queryParameters: {'academicYear': academicYear, 'semester': '$semester'},
    );
    final json = await _client.getJson(uri);
    return StudentScoreModel.fromJson(json);
  }

  Future<AcademicSummaryModel> getAcademicSummary(
    int studentId,
    String academicYear,
  ) async {
    final uri = ApiConfig.uri(
      '/api/teacher/student/$studentId/academic-summary',
    ).replace(queryParameters: {'academicYear': academicYear});
    return AcademicSummaryModel.fromJson(await _client.getJson(uri));
  }

  /// Thống kê điểm theo lớp
  Future<ClassStatisticsModel> getClassStatistics(
    int classId, {
    required String academicYear,
    required int semester,
  }) async {
    final uri = ApiConfig.uri('/api/teacher/class/$classId/statistics').replace(
      queryParameters: {'academicYear': academicYear, 'semester': '$semester'},
    );
    final json = await _client.getJson(uri);
    return ClassStatisticsModel.fromJson(json);
  }

  /// Nhập điểm cho học sinh
  Future<Map<String, dynamic>> createScore({
    required int studentId,
    required int subjectId,
    required double score,
    double coefficient = 1.0,
    required String academicYear,
    required int semester,
  }) async {
    return await _client.postJson(
      ApiConfig.uri('/api/teacher/scores'),
      body: {
        'studentId': studentId,
        'subjectId': subjectId,
        'score': score,
        'coefficient': coefficient,
        'academicYear': academicYear,
        'semester': semester,
      },
    );
  }

  /// Cập nhật điểm
  Future<Map<String, dynamic>> updateScore({
    required int scoreId,
    double? score,
    double? coefficient,
  }) async {
    final body = <String, dynamic>{};
    if (score != null) body['score'] = score;
    if (coefficient != null) body['coefficient'] = coefficient;

    return await _client.putJson(
      ApiConfig.uri('/api/teacher/scores/$scoreId'),
      body: body,
    );
  }

  /// Xóa điểm
  Future<void> deleteScore(int scoreId) async {
    await _client.delete(ApiConfig.uri('/api/teacher/scores/$scoreId'));
  }

  Future<ScoreImportResult> previewScoreImport({
    required int classId,
    required String academicYear,
    required int semester,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final json = await _client.postMultipart(
      ApiConfig.uri('/api/teacher/scores/import/preview'),
      fields: {
        'classId': '$classId',
        'academicYear': academicYear,
        'semester': '$semester',
      },
      fileField: 'file',
      fileBytes: fileBytes,
      filename: filename,
    );
    return ScoreImportResult.fromJson(json);
  }

  Future<ScoreImportResult> importScoresExcel({
    required int classId,
    required String academicYear,
    required int semester,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final json = await _client.postMultipart(
      ApiConfig.uri('/api/teacher/scores/import'),
      fields: {
        'classId': '$classId',
        'academicYear': academicYear,
        'semester': '$semester',
      },
      fileField: 'file',
      fileBytes: fileBytes,
      filename: filename,
    );
    return ScoreImportResult.fromJson(json);
  }

  Future<List<int>> downloadScoreImportTemplate() async {
    return _client.getBytes(
      ApiConfig.uri('/api/teacher/scores/import/template'),
    );
  }
}
