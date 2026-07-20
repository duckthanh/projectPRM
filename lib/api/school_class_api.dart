import '../models/school_class_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class SchoolClassApi {
  final ApiClient _client;

  SchoolClassApi(this._client);

  /// Lấy danh sách tất cả lớp học
  Future<List<SchoolClassModel>> getAllClasses() async {
    final list = await _client.getJsonList(
      ApiConfig.uri('/api/school-classes'),
    );
    return list
        .map((e) => SchoolClassModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
