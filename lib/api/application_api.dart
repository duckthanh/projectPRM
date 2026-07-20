import '../models/application_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class ApplicationApi {
  final ApiClient _client;

  ApplicationApi(this._client);

  /// Học sinh gửi đơn mới
  Future<ApplicationModel> createApplication({
    required String type,
    required String title,
    required String content,
    int? teacherId,
  }) async {
    final body = {
      'type': type,
      'title': title,
      'content': content,
    };
    if (teacherId != null) {
      body['teacherId'] = teacherId.toString();
    }

    final json = await _client.postJson(
      ApiConfig.uri('/api/applications'),
      body: body,
    );
    return ApplicationModel.fromJson(json);
  }

  /// Học sinh xem danh sách đơn đã gửi
  Future<List<ApplicationModel>> getMyApplications() async {
    final list = await _client.getJsonList(
      ApiConfig.uri('/api/applications/my'),
    );
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Xem chi tiết đơn
  Future<ApplicationModel> getApplication(int id) async {
    final json = await _client.getJson(
      ApiConfig.uri('/api/applications/$id'),
    );
    return ApplicationModel.fromJson(json);
  }

  /// Học sinh xóa đơn
  Future<void> deleteApplication(int id) async {
    await _client.delete(
      ApiConfig.uri('/api/applications/$id'),
    );
  }

  /// Giáo viên xem đơn chờ duyệt
  Future<List<ApplicationModel>> getPendingApplications() async {
    final list = await _client.getJsonList(
      ApiConfig.uri('/api/applications/all-pending'),
    );
    return list
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Giáo viên duyệt/từ chối đơn
  Future<ApplicationModel> respondToApplication({
    required int applicationId,
    required String status,
    String? responseNote,
  }) async {
    final json = await _client.putJson(
      ApiConfig.uri('/api/applications/$applicationId/respond'),
      body: {
        'status': status,
        'responseNote': responseNote ?? '',
      },
    );
    return ApplicationModel.fromJson(json);
  }
}
