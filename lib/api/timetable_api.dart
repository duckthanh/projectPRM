import '../models/timetable_model.dart';
import 'api_client.dart';
import 'api_config.dart';

class TimeTableApi {
  final ApiClient _client;

  TimeTableApi(this._client);

  Future<List<TimeTableModel>> getByUserId(int userId) async {
    final list = await _client.getJsonList(ApiConfig.uri('/api/timetables/user/$userId'));
    return list.map((e) => TimeTableModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

