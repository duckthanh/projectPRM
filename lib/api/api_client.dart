import 'dart:convert';

import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, body: $body)';
}

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({bool withAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth && AuthStorage.accessToken != null) {
      headers['Authorization'] = 'Bearer ${AuthStorage.accessToken}';
    }
    return headers;
  }

  Future<Map<String, dynamic>> postJson(Uri uri, {Map<String, dynamic>? body, bool withAuth = true}) async {
    final res = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }


  Future<void> postVoid(Uri uri, {Map<String, dynamic>? body, bool withAuth = true}) async {
    final res = await _client.post(
      uri,
      headers: _buildHeaders(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }

  Future<List<dynamic>> getJsonList(Uri uri) async {
    final res = await _client.get(uri, headers: _buildHeaders());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final res = await _client.get(uri, headers: _buildHeaders());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(Uri uri, {Map<String, dynamic>? body, bool withAuth = true}) async {
    final res = await _client.put(
      uri,
      headers: _buildHeaders(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchJson(Uri uri, {Map<String, dynamic>? body, bool withAuth = true}) async {
    final res = await _client.patch(
      uri,
      headers: _buildHeaders(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> delete(Uri uri, {bool withAuth = true}) async {
    final res = await _client.delete(
      uri,
      headers: _buildHeaders(withAuth: withAuth),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }

  /// Multipart POST (import Excel). Không set Content-Type để boundary tự gắn.
  Future<Map<String, dynamic>> postMultipart(
    Uri uri, {
    required Map<String, String> fields,
    required String fileField,
    required List<int> fileBytes,
    required String filename,
    bool withAuth = true,
  }) async {
    final request = http.MultipartRequest('POST', uri);
    if (withAuth && AuthStorage.accessToken != null) {
      request.headers['Authorization'] = 'Bearer ${AuthStorage.accessToken}';
    }
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename),
    );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    if (res.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<int>> getBytes(Uri uri, {bool withAuth = true}) async {
    final headers = <String, String>{};
    if (withAuth && AuthStorage.accessToken != null) {
      headers['Authorization'] = 'Bearer ${AuthStorage.accessToken}';
    }
    final res = await _client.get(uri, headers: headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return res.bodyBytes;
  }
}

