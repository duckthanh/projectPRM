import '../models/subject_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class SubjectApi {
  final ApiClient _client;

  SubjectApi(this._client);

  /// Lấy danh sách tất cả môn học
  Future<List<SubjectModel>> getAllSubjects() async {
    final list = await _client.getJsonList(
      ApiConfig.uri('/api/subjects'),
    );
    return list
        .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
