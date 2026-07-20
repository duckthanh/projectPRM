import '../models/score_model.dart';
import '../models/academic_summary_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class ScoreApi {
  final ApiClient _client;

  ScoreApi(this._client);

  Future<List<ScoreModel>> getScoresByUserId(
    int userId, {
    required String academicYear,
    required int semester,
  }) async {
    final uri = ApiConfig.uri('/api/scores/user/$userId').replace(
      queryParameters: {'academicYear': academicYear, 'semester': '$semester'},
    );
    final list = await _client.getJsonList(uri);
    return list
        .map((e) => ScoreModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicSummaryModel> getAcademicSummary(
    int userId,
    String academicYear,
  ) async {
    final uri = ApiConfig.uri(
      '/api/scores/user/$userId/academic-summary',
    ).replace(queryParameters: {'academicYear': academicYear});
    return AcademicSummaryModel.fromJson(await _client.getJson(uri));
  }
}
