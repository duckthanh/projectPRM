import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConfig {
  /// Ghi đè khi chạy máy thật: ví dụ 'http://192.168.1.10:8080'
  static const String? overrideBaseUrl = null;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    if (kIsWeb) return 'http://localhost:8080';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  static Uri uri(String path) => Uri.parse('$baseUrl$path');
}
