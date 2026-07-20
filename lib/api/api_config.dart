class ApiConfig {
  /// Android emulator: http://10.0.2.2:8080
  /// Real device: dùng IP LAN của máy chạy backend, ví dụ http://192.168.1.10:8080
  /// Web: http://localhost:8080 (nếu chạy backend cùng máy)
  static const String baseUrl = 'http://10.0.2.2:8080';

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}

